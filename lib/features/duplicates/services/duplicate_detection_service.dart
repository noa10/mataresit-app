import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/receipt_model.dart';
import '../models/duplicate_models.dart';

/// Result of the pure grouping step: the duplicate groups plus the number of
/// receipts that had to be skipped because they carry no merchant at all.
typedef DuplicateGrouping = ({
  List<DuplicateGroup> groups,
  int skippedNoMerchant,
});

/// Client-side duplicate detection over the `receipts` table.
///
/// Mirrors the web client (`src/services/duplicateDetectionService.ts`) while
/// fixing three defects it has: paged scanning (instead of a silent
/// `limit(1000)`), a symmetric date window, and reported -- not swallowed --
/// receipts without a merchant.
class DuplicateDetectionService {
  /// Page size used while scanning.
  static const int scanBatchSize = 1000;

  /// Hard ceiling on how many receipts one scan reads.
  static const int scanMaxReceipts = 10000;

  final SupabaseClient _client;
  final Logger _logger;

  DuplicateDetectionService(this._client, {Logger? logger})
    : _logger = logger ?? Logger();

  // =============================================
  // PUBLIC API
  // =============================================

  /// Scan the receipts visible to [userId] (or to [teamId] when given) and
  /// return the duplicate groups found.
  Future<ScanResult> scan({
    required ScanConfig config,
    required String userId,
    String? teamId,
  }) async {
    try {
      final fetched = await _fetchRows(userId: userId, teamId: teamId);

      final scanned = <ScannedReceipt>[];
      for (final row in fetched.rows) {
        try {
          scanned.add(ScannedReceipt.fromRow(row));
        } catch (e) {
          // A row that cannot be mapped is logged rather than dropped in
          // silence; scannedCount below still reports the true row count.
          _logger.w(
            'Skipping unreadable receipt row ${row['id'] ?? '(no id)'}: $e',
          );
        }
      }

      final grouping = groupDuplicates(scanned, config);

      return ScanResult.fromGroups(
        groups: grouping.groups,
        scannedCount: fetched.rows.length,
        skippedNoMerchant: grouping.skippedNoMerchant,
        wasCapped: fetched.wasCapped,
      );
    } catch (e) {
      throw Exception('Failed to scan for duplicate receipts: $e');
    }
  }

  /// Permanently delete the `receipts` rows with [ids].
  ///
  /// Only the receipt rows themselves are touched; no cascade is issued from
  /// the client.
  Future<void> deleteReceipts(List<String> ids) async {
    if (ids.isEmpty) return;

    try {
      await _client.from('receipts').delete().inFilter('id', ids);
    } catch (e) {
      throw Exception('Failed to delete receipts: $e');
    }
  }

  // =============================================
  // GROUPING (pure, no network)
  // =============================================

  /// Group [receipts] into duplicate clusters using [config].
  ///
  /// The shape matches the web client: one grouping key per receipt, receipts
  /// bucketed by key equality, groups of one discarded. Merchant is always
  /// part of the key; date/total/tax/currency join it when enabled.
  static DuplicateGrouping groupDuplicates(
    List<ScannedReceipt> receipts,
    ScanConfig config,
  ) {
    // Deliberate fix over the web client: receipts without a merchant are
    // counted and reported through ScanResult.skippedNoMerchant. The web
    // version `continue`s past them with no signal, so the user never learns
    // that part of the receipt set was not comparable.
    final buckets = <String, List<ScannedReceipt>>{};
    var skippedNoMerchant = 0;

    for (final scanned in receipts) {
      final merchantKey = _merchantKey(scanned);
      if (merchantKey == null) {
        skippedNoMerchant++;
        continue;
      }
      final key = _bucketKey(merchantKey, scanned.receipt, config);
      buckets.putIfAbsent(key, () => <ScannedReceipt>[]).add(scanned);
    }

    final groups = <DuplicateGroup>[];
    for (final bucket in buckets.values) {
      // Deliberate fix over the web client: the date is not folded into a
      // fixed, epoch-anchored bucket (see _clusterByDateWindow).
      final clusters = config.dateEnabled
          ? _clusterByDateWindow(bucket, config.dateToleranceDays)
          : <List<ScannedReceipt>>[bucket];

      for (final cluster in clusters) {
        if (cluster.length <= 1) continue;

        final sorted = [...cluster]..sort(_byDateThenCreatedAt);
        groups.add(
          DuplicateGroup(
            id: 'duplicate-group-${groups.length + 1}',
            receipts: [for (final scanned in sorted) scanned.receipt],
            matchCriteria: config.matchCriteria,
            keptReceiptId: sorted.first.receipt.id,
          ),
        );
      }
    }

    return (groups: groups, skippedNoMerchant: skippedNoMerchant);
  }

  // =============================================
  // QUERY HELPERS
  // =============================================

  /// Page through the scan query for the current user or team.
  Future<({List<Map<String, dynamic>> rows, bool wasCapped})> _fetchRows({
    required String userId,
    String? teamId,
  }) {
    return collectPages(
      batchSize: scanBatchSize,
      maxRows: scanMaxReceipts,
      fetchPage: (offset, limit) => _fetchBatch(
        userId: userId,
        teamId: teamId,
        offset: offset,
        limit: limit,
      ),
    );
  }

  /// Collect pages from [fetchPage] until the rows run out or [maxRows] is hit.
  ///
  /// The web client issues a single `.limit(1000)` with no `ORDER BY`, which
  /// truncates large accounts and returns an arbitrary subset in silence. Here
  /// the rows are paged with `.range(...)` (plus a total `ORDER BY`, so pages
  /// cannot overlap) and hitting the cap is reported through `wasCapped`.
  static Future<({List<Map<String, dynamic>> rows, bool wasCapped})>
  collectPages({
    required int batchSize,
    required int maxRows,
    required Future<List<Map<String, dynamic>>> Function(int offset, int limit)
    fetchPage,
  }) async {
    final rows = <Map<String, dynamic>>[];

    // Ask for one row past the cap: if it arrives, the account holds more rows
    // than the scan can cover, which is reported without a second request.
    final target = maxRows + 1;

    while (rows.length < target) {
      final remaining = target - rows.length;
      final take = remaining < batchSize ? remaining : batchSize;
      final batch = await fetchPage(rows.length, take);
      rows.addAll(batch);
      if (batch.length < take) break; // Last page reached.
    }

    final wasCapped = rows.length > maxRows;
    if (wasCapped) {
      rows.removeRange(maxRows, rows.length);
    }

    return (rows: rows, wasCapped: wasCapped);
  }

  Future<List<Map<String, dynamic>>> _fetchBatch({
    required String userId,
    String? teamId,
    required int offset,
    required int limit,
  }) async {
    var query = _client.from('receipts').select();

    if (teamId != null) {
      query = query.eq('team_id', teamId);
    } else {
      query = query.eq('user_id', userId).isFilter('team_id', null);
    }

    return await query
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
  }

  // =============================================
  // KEY BUILDING
  // =============================================

  /// Merchant token for the grouping key, or null when the receipt has none.
  ///
  /// Prefers the `normalized_merchant` column and falls back to the raw
  /// merchant name, both trimmed and lowercased.
  static String? _merchantKey(ScannedReceipt scanned) {
    final normalized = scanned.normalizedMerchant?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized.toLowerCase();
    }

    final raw = scanned.receipt.merchantName?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw.toLowerCase();
    }

    return null;
  }

  /// Key parts other than the date: merchant, total, tax, currency.
  static String _bucketKey(
    String merchantKey,
    ReceiptModel receipt,
    ScanConfig config,
  ) {
    final parts = <String>[merchantKey];

    if (config.totalEnabled) {
      parts.add(
        'total=${_amountBucket(receipt.totalAmount, config.totalTolerance)}',
      );
    }
    if (config.taxEnabled) {
      parts.add(
        'tax=${_amountBucket(receipt.taxAmount, config.totalTolerance)}',
      );
    }
    if (config.currencyEnabled) {
      parts.add('currency=${(receipt.currency ?? '').toUpperCase()}');
    }

    return parts.join('|');
  }

  /// Bucket a money value at [tolerance] as an integer bucket index.
  ///
  /// The web client keys on `round(amount / tolerance) * tolerance`, i.e. a
  /// float, which can put arithmetically equal amounts into different groups
  /// through float representation. Keying on the integer quotient instead is
  /// the same bucketing without that hazard.
  ///
  /// Deliberate fix over the web client: `tolerance == 0` means an exact match
  /// on the rounded-to-cents amount. The web version writes
  /// `config.totalTolerance || 0.01`, so `0` silently becomes `0.01` and exact
  /// matching is impossible.
  ///
  /// A missing amount is treated as `0`, matching the web client's
  /// `tax ?? 0` convention; such receipts still participate in the scan.
  static String _amountBucket(double? amount, double tolerance) {
    final value = amount ?? 0;
    if (tolerance <= 0) {
      return (value * 100).round().toString();
    }
    return (value / tolerance).round().toString();
  }

  // =============================================
  // DATE WINDOW
  // =============================================

  /// Split [bucket] into clusters whose dates lie within
  /// `toleranceDays` of each other.
  ///
  /// Deliberate fix over the web client: the web version computes
  /// `floor(epoch / windowMs) * windowMs`, an epoch-anchored fixed window that
  /// can split two receipts one day apart into different buckets even though
  /// the "tolerance in days" setting promises otherwise. Here dates are
  /// compared by absolute difference in calendar days
  /// (`abs(daysBetween(a, b)) <= toleranceDays`), which is symmetric.
  ///
  /// With `toleranceDays == 0` this is exact calendar-day equality. With a
  /// larger tolerance the comparison is applied to dates sorted ascending and
  /// linked transitively, so a chain of receipts at most `toleranceDays` apart
  /// ends up in one cluster (e.g. tolerance 1 links day 0 -> 1 -> 2).
  static List<List<ScannedReceipt>> _clusterByDateWindow(
    List<ScannedReceipt> bucket,
    int toleranceDays,
  ) {
    final dated = <ScannedReceipt>[];
    final undated = <ScannedReceipt>[];

    for (final scanned in bucket) {
      if (scanned.receipt.transactionDate == null) {
        undated.add(scanned);
      } else {
        dated.add(scanned);
      }
    }

    final clusters = <List<ScannedReceipt>>[];

    if (dated.isNotEmpty) {
      final sorted = [...dated]
        ..sort(
          (a, b) =>
              a.receipt.transactionDate!.compareTo(b.receipt.transactionDate!),
        );

      final parent = List<int>.generate(sorted.length, (index) => index);

      int find(int index) {
        var root = index;
        while (parent[root] != root) {
          parent[root] = parent[parent[root]];
          root = parent[root];
        }
        return root;
      }

      void union(int a, int b) {
        final rootA = find(a);
        final rootB = find(b);
        if (rootA != rootB) parent[rootB] = rootA;
      }

      // Sorted ascending, the window of in-range dates only slides forward as
      // the left endpoint advances, so a single right pointer visits each
      // candidate pair once.
      var right = 1;
      for (var i = 0; i < sorted.length; i++) {
        if (right <= i) right = i + 1;
        while (right < sorted.length &&
            _calendarDaysBetween(
                  sorted[i].receipt.transactionDate!,
                  sorted[right].receipt.transactionDate!,
                ) <=
                toleranceDays) {
          union(i, right);
          right++;
        }
      }

      final byRoot = <int, List<ScannedReceipt>>{};
      for (var i = 0; i < sorted.length; i++) {
        byRoot.putIfAbsent(find(i), () => <ScannedReceipt>[]).add(sorted[i]);
      }
      clusters.addAll(byRoot.values);
    }

    // Receipts without a transaction date cannot be compared on date, so they
    // only group with other undated receipts instead of being dropped.
    if (undated.isNotEmpty) {
      clusters.add(undated);
    }

    return clusters;
  }

  /// Whole calendar days from [from] to [to], compared in local time.
  ///
  /// The difference is taken between UTC midnights of the two local calendar
  /// dates so daylight-saving shifts cannot skew the count.
  static int _calendarDaysBetween(DateTime from, DateTime to) {
    final localFrom = from.toLocal();
    final localTo = to.toLocal();
    final dayFrom = DateTime.utc(
      localFrom.year,
      localFrom.month,
      localFrom.day,
    );
    final dayTo = DateTime.utc(localTo.year, localTo.month, localTo.day);
    return dayTo.difference(dayFrom).inDays;
  }

  /// Ascending by transaction date, then by creation time.
  ///
  /// The receipt id is a final tiebreaker so the kept receipt is deterministic
  /// when two rows share both timestamps.
  static int _byDateThenCreatedAt(ScannedReceipt a, ScannedReceipt b) {
    final dateA = a.receipt.transactionDate;
    final dateB = b.receipt.transactionDate;

    if (dateA != null && dateB != null) {
      final byDate = dateA.compareTo(dateB);
      if (byDate != 0) return byDate;
    } else if (dateA == null && dateB != null) {
      return 1;
    } else if (dateA != null) {
      return -1;
    }

    final byCreatedAt = a.receipt.createdAt.compareTo(b.receipt.createdAt);
    if (byCreatedAt != 0) return byCreatedAt;

    return a.receipt.id.compareTo(b.receipt.id);
  }
}
