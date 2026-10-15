import 'package:equatable/equatable.dart';
import '../../../shared/models/receipt_model.dart';

/// Configuration for a duplicate scan.
///
/// Defaults mirror the web client
/// (`src/services/duplicateDetectionService.ts` -> `ScanConfig`), with
/// [totalTolerance] keeping its exact-match meaning at `0` (see
/// [DuplicateDetectionService] for the reasoning).
class ScanConfig extends Equatable {
  /// Lower bound (inclusive) for [dateToleranceDays], in whole days.
  static const int minDateToleranceDays = 0;

  /// Upper bound (inclusive) for [dateToleranceDays], in whole days.
  static const int maxDateToleranceDays = 30;

  /// Lower bound (inclusive) for [totalTolerance], as a relative fraction.
  static const double minTotalTolerance = 0.0;

  /// Upper bound (inclusive) for [totalTolerance], as a relative fraction.
  static const double maxTotalTolerance = 1.0;

  /// Merchant matching anchors every duplicate group, so it is always on.
  /// Kept as a field for parity with the web config; the UI renders it locked.
  final bool merchantEnabled;

  /// Whether the transaction date participates in the grouping key.
  final bool dateEnabled;

  /// Symmetric date window, in whole days: two receipts match on date when
  /// their calendar days differ by at most this many days. `0` means the
  /// calendar days must be identical.
  final int dateToleranceDays;

  /// Whether the total amount participates in the grouping key.
  final bool totalEnabled;

  /// Relative fraction used to bucket the total (and tax) amount.
  ///
  /// `0.01` groups amounts that agree to the nearest 0.01 of currency,
  /// `0` requires an exact match on the rounded-to-cents amount.
  final double totalTolerance;

  /// Whether the tax amount participates in the grouping key.
  final bool taxEnabled;

  /// Whether the currency participates in the grouping key.
  final bool currencyEnabled;

  const ScanConfig({
    this.merchantEnabled = true,
    this.dateEnabled = true,
    this.dateToleranceDays = 0,
    this.totalEnabled = true,
    this.totalTolerance = 0.01,
    this.taxEnabled = false,
    this.currencyEnabled = false,
  });

  /// Stable field tokens that make up the grouping key, in scan order.
  ///
  /// The UI translates each token (`duplicates.criteria.<token>`), so these
  /// stay untranslated identifiers here.
  List<String> get matchFields => [
    'merchant',
    if (dateEnabled) 'date',
    if (totalEnabled) 'total',
    if (taxEnabled) 'tax',
    if (currencyEnabled) 'currency',
  ];

  /// Human readable label for the enabled fields, e.g. `merchant + date + total`.
  String get matchCriteria => matchFields.join(' + ');

  ScanConfig copyWith({
    bool? merchantEnabled,
    bool? dateEnabled,
    int? dateToleranceDays,
    bool? totalEnabled,
    double? totalTolerance,
    bool? taxEnabled,
    bool? currencyEnabled,
  }) {
    return ScanConfig(
      merchantEnabled: merchantEnabled ?? this.merchantEnabled,
      dateEnabled: dateEnabled ?? this.dateEnabled,
      dateToleranceDays: dateToleranceDays ?? this.dateToleranceDays,
      totalEnabled: totalEnabled ?? this.totalEnabled,
      totalTolerance: totalTolerance ?? this.totalTolerance,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      currencyEnabled: currencyEnabled ?? this.currencyEnabled,
    );
  }

  @override
  List<Object?> get props => [
    merchantEnabled,
    dateEnabled,
    dateToleranceDays,
    totalEnabled,
    totalTolerance,
    taxEnabled,
    currencyEnabled,
  ];
}

/// A receipt plus the raw `normalized_merchant` column for a scan.
///
/// [ReceiptModel] has no field for `normalized_merchant` even though the
/// column exists in the shared database, so the raw row map is read here
/// instead of silently falling back to the raw merchant name.
class ScannedReceipt extends Equatable {
  final ReceiptModel receipt;

  /// Value of the `normalized_merchant` column, when present and non-empty.
  final String? normalizedMerchant;

  const ScannedReceipt({required this.receipt, this.normalizedMerchant});

  /// Build from a raw `receipts` row (PostgREST `select *` payload).
  factory ScannedReceipt.fromRow(Map<String, dynamic> row) {
    final normalized = row['normalized_merchant'];
    return ScannedReceipt(
      receipt: ReceiptModel.fromJson(row),
      normalizedMerchant: normalized is String ? normalized : null,
    );
  }

  @override
  List<Object?> get props => [receipt, normalizedMerchant];
}

/// A set of receipts that share the same grouping key.
class DuplicateGroup extends Equatable {
  /// Identifier, unique within one scan result (e.g. `duplicate-group-1`).
  final String id;

  /// Group members sorted by transaction date, then by creation time.
  final List<ReceiptModel> receipts;

  /// Label of the fields that produced this group, e.g. `merchant + total`.
  final String matchCriteria;

  /// Id of the receipt that should be kept: the oldest one after sorting.
  final String keptReceiptId;

  const DuplicateGroup({
    required this.id,
    required this.receipts,
    required this.matchCriteria,
    required this.keptReceiptId,
  });

  ReceiptModel? get keptReceipt {
    for (final receipt in receipts) {
      if (receipt.id == keptReceiptId) return receipt;
    }
    return null;
  }

  /// Every receipt except the kept one: the ones a delete action may remove.
  List<ReceiptModel> get deletableReceipts => [
    for (final receipt in receipts)
      if (receipt.id != keptReceiptId) receipt,
  ];

  List<String> get deletableReceiptIds => [
    for (final receipt in deletableReceipts) receipt.id,
  ];

  @override
  List<Object?> get props => [id, receipts, matchCriteria, keptReceiptId];
}

/// Outcome of a completed duplicate scan.
class ScanResult extends Equatable {
  /// Results older than this are flagged in the UI as possibly out of date.
  static const Duration staleAfter = Duration(minutes: 5);

  final List<DuplicateGroup> groups;

  /// Every receipt inside every group, including the kept one.
  ///
  /// This matches the web client's definition; the UI labels it separately
  /// from [deletableCount] so the number is not misleading.
  final int totalDuplicates;

  /// [totalDuplicates] minus one kept receipt per group.
  final int deletableCount;

  /// How many receipts the scan actually read from the database.
  final int scannedCount;

  /// Receipts that could not take part because they have no merchant at all.
  final int skippedNoMerchant;

  /// True when more receipts exist than the scan maximum, so the scan stopped
  /// early and the result only covers part of the account.
  final bool wasCapped;

  final DateTime scannedAt;

  const ScanResult({
    required this.groups,
    required this.totalDuplicates,
    required this.deletableCount,
    required this.scannedCount,
    required this.skippedNoMerchant,
    required this.wasCapped,
    required this.scannedAt,
  });

  /// Build a result from [groups], deriving the duplicate counts.
  factory ScanResult.fromGroups({
    required List<DuplicateGroup> groups,
    required int scannedCount,
    required int skippedNoMerchant,
    required bool wasCapped,
    DateTime? scannedAt,
  }) {
    final totalDuplicates = groups.fold<int>(
      0,
      (sum, group) => sum + group.receipts.length,
    );
    return ScanResult(
      groups: groups,
      totalDuplicates: totalDuplicates,
      deletableCount: totalDuplicates - groups.length,
      scannedCount: scannedCount,
      skippedNoMerchant: skippedNoMerchant,
      wasCapped: wasCapped,
      scannedAt: scannedAt ?? DateTime.now(),
    );
  }

  bool get hasGroups => groups.isNotEmpty;

  bool get hasPartialInfo => wasCapped || skippedNoMerchant > 0;

  /// Ids of every receipt that may be deleted (all but the kept one per group).
  List<String> get deletableReceiptIds => [
    for (final group in groups) ...group.deletableReceiptIds,
  ];

  /// Ids of every receipt that takes part in a duplicate group.
  List<String> get duplicateReceiptIds => [
    for (final group in groups)
      for (final receipt in group.receipts) receipt.id,
  ];

  /// Whether this result is older than [staleAfter] relative to [now].
  bool isStaleAt(DateTime now) => now.difference(scannedAt) > staleAfter;

  /// Whether this result is older than [staleAfter] relative to the clock.
  bool get isStale => isStaleAt(DateTime.now());

  /// Copy of this result without [ids], used after a successful delete.
  ///
  /// Groups that fall below two members disappear, and if the kept receipt was
  /// removed the oldest remaining member takes its place.
  ScanResult withoutReceipts(Set<String> ids) {
    if (ids.isEmpty) return this;

    final remainingGroups = <DuplicateGroup>[];
    for (final group in groups) {
      final remaining = [
        for (final receipt in group.receipts)
          if (!ids.contains(receipt.id)) receipt,
      ];
      if (remaining.length <= 1) continue;

      final keptId =
          remaining.any((receipt) => receipt.id == group.keptReceiptId)
          ? group.keptReceiptId
          : remaining.first.id;

      remainingGroups.add(
        DuplicateGroup(
          id: group.id,
          receipts: remaining,
          matchCriteria: group.matchCriteria,
          keptReceiptId: keptId,
        ),
      );
    }

    final totalDuplicates = remainingGroups.fold<int>(
      0,
      (sum, group) => sum + group.receipts.length,
    );

    return ScanResult(
      groups: remainingGroups,
      totalDuplicates: totalDuplicates,
      deletableCount: totalDuplicates - remainingGroups.length,
      scannedCount: scannedCount,
      skippedNoMerchant: skippedNoMerchant,
      wasCapped: wasCapped,
      scannedAt: scannedAt,
    );
  }

  @override
  List<Object?> get props => [
    groups,
    totalDuplicates,
    deletableCount,
    scannedCount,
    skippedNoMerchant,
    wasCapped,
    scannedAt,
  ];
}
