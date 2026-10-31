import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../../../shared/models/receipt_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/teams_provider.dart';

/// A receipt as displayed on the workspace overview. Unknown amounts and
/// currencies remain unknown; they must not be silently converted to zero.
class DashboardReceipt {
  const DashboardReceipt({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.status,
    this.merchant,
    this.amount,
    this.tax,
    this.currency,
    this.category,
    this.confidence,
  });

  final String id;
  final DateTime date;
  final DateTime createdAt;
  final ReceiptStatus status;
  final String? merchant;
  final double? amount;
  final double? tax;
  final String? currency;
  final String? category;
  final int? confidence;
}

class DashboardCategory {
  const DashboardCategory(this.name, this.amount);

  final String name;
  final double amount;
}

class DashboardSummary {
  const DashboardSummary({
    required this.month,
    required this.receiptCount,
    required this.reviewCount,
    required this.currency,
    required this.spend,
    required this.tax,
    required this.currencyReceiptCount,
    required this.amountCount,
    required this.taxCount,
    required this.otherCurrencyCount,
    required this.unknownCurrencyCount,
    required this.categories,
    required this.recent,
    required this.reviewPreview,
    this.truncated = false,
  });

  final DateTime month;
  final int receiptCount;
  final int reviewCount;
  final String? currency;
  final double? spend;
  final double? tax;
  final int currencyReceiptCount;
  final int amountCount;
  final int taxCount;
  final int otherCurrencyCount;
  final int unknownCurrencyCount;
  final List<DashboardCategory> categories;
  final List<DashboardReceipt> recent;
  final List<DashboardReceipt> reviewPreview;
  final bool truncated;
}

/// The same workspace and receipt-date scope as the web overview, independent
/// of the receipt list's filters, pagination, and demonstration-data fallback.
class DashboardSummaryService {
  const DashboardSummaryService(this.client);

  final SupabaseClient client;
  static const pageSize = 1000;
  static const maxRows = 5000;
  static const _columns = '''
    id, merchant, date, total, tax, currency, status, predicted_category,
    created_at, confidence_scores, custom_categories(name)
  ''';

  Future<DashboardSummary> fetch({
    required String userId,
    String? teamId,
    DateTime? month,
    bool Function()? isCancelled,
  }) async {
    final now = month ?? DateTime.now();
    final firstDay = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    String isoDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final rows = <Map<String, dynamic>>[];
    final ids = <String>{};
    int? expectedCount;
    while (rows.length < maxRows) {
      var query = client
          .from('receipts')
          .select(_columns)
          .gte('date', isoDate(firstDay))
          .lt('date', isoDate(nextMonth));
      query = teamId == null
          ? query.eq('user_id', userId).isFilter('team_id', null)
          : query.eq('team_id', teamId);
      final remaining = maxRows - rows.length;
      final limit = remaining < pageSize ? remaining : pageSize;
      final response = await query
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .order('id')
          .range(rows.length, rows.length + limit - 1)
          .count();

      // Do not show apparently complete totals if a concurrent change shifts
      // the pages while they are being read.
      if (expectedCount != null && expectedCount != response.count) {
        throw StateError('Receipt count changed while loading the overview');
      }
      expectedCount = response.count;
      final page = response.data;
      if (isCancelled?.call() ?? false) {
        throw const DashboardSummaryCancelled();
      }
      if (page.length > limit || rows.length + page.length > expectedCount) {
        throw StateError('Receipt overview returned an inconsistent page');
      }
      if (page.isEmpty) {
        if (rows.length < expectedCount) {
          throw StateError('Receipt overview returned an incomplete page');
        }
        break;
      }
      for (final row in page) {
        final id = row['id'];
        if (id is! String || id.isEmpty || !ids.add(id)) {
          throw StateError(
            'Receipt overview returned an invalid or duplicate row',
          );
        }
        rows.add(row);
      }
      if (rows.length >= expectedCount) break;
    }

    return buildDashboardSummary(
      rows,
      month: firstDay,
      truncated: (expectedCount ?? 0) > rows.length,
    );
  }
}

/// Aggregates only amounts with a known currency, keeping other currencies and
/// missing values separate. The primary currency is chosen by receipt count,
/// never by comparing amounts in different currencies.
DashboardSummary buildDashboardSummary(
  List<Map<String, dynamic>> rows, {
  required DateTime month,
  bool truncated = false,
}) {
  final receipts = rows.map(_parseReceipt).toList();
  receipts.sort(_compareRecent);

  final currencyCounts = <String, int>{};
  for (final receipt in receipts) {
    final currency = receipt.currency;
    if (currency != null) {
      currencyCounts[currency] = (currencyCounts[currency] ?? 0) + 1;
    }
  }
  final currencies = currencyCounts.keys.toList()
    ..sort((a, b) {
      final countOrder = currencyCounts[b]!.compareTo(currencyCounts[a]!);
      return countOrder != 0 ? countOrder : a.compareTo(b);
    });
  final primary = currencies.isEmpty ? null : currencies.first;
  final primaryReceipts = receipts.where(
    (receipt) => primary != null && receipt.currency == primary,
  );
  var spend = 0.0;
  var tax = 0.0;
  var amountCount = 0;
  var taxCount = 0;
  final categoryTotals = <String, double>{};
  for (final receipt in primaryReceipts) {
    if (receipt.amount != null) {
      spend += receipt.amount!;
      amountCount++;
      final category = receipt.category ?? 'Uncategorized';
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + receipt.amount!;
    }
    if (receipt.tax != null) {
      tax += receipt.tax!;
      taxCount++;
    }
  }
  final categories =
      categoryTotals.entries
          .map((entry) => DashboardCategory(entry.key, entry.value))
          .toList()
        ..sort((a, b) {
          final amountOrder = b.amount.compareTo(a.amount);
          return amountOrder != 0 ? amountOrder : a.name.compareTo(b.name);
        });
  final needsReview = receipts
      .where((receipt) => receipt.status == ReceiptStatus.unreviewed)
      .toList();
  needsReview.sort((a, b) {
    if (a.confidence == null && b.confidence != null) return 1;
    if (a.confidence != null && b.confidence == null) return -1;
    final confidenceOrder = (a.confidence ?? 0).compareTo(b.confidence ?? 0);
    return confidenceOrder != 0 ? confidenceOrder : _compareRecent(a, b);
  });

  final unknownCurrencyCount = receipts.where((r) => r.currency == null).length;
  final primaryCount = primary == null ? 0 : currencyCounts[primary]!;
  return DashboardSummary(
    month: DateTime(month.year, month.month),
    receiptCount: receipts.length,
    reviewCount: needsReview.length,
    currency: primary,
    spend: amountCount == 0 ? null : spend,
    tax: taxCount == 0 ? null : tax,
    currencyReceiptCount: primaryCount,
    amountCount: amountCount,
    taxCount: taxCount,
    otherCurrencyCount: receipts.length - primaryCount - unknownCurrencyCount,
    unknownCurrencyCount: unknownCurrencyCount,
    categories: categories,
    recent: receipts.take(5).toList(),
    reviewPreview: needsReview.take(3).toList(),
    truncated: truncated,
  );
}

DashboardReceipt _parseReceipt(Map<String, dynamic> row) {
  final id = row['id'];
  final date = DateTime.tryParse(row['date']?.toString() ?? '');
  if (id is! String || id.isEmpty || date == null) {
    throw const FormatException('Invalid receipt in overview');
  }
  String? text(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  double? number(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  final rawCurrency = text(row['currency'])?.toUpperCase();
  // A missing or non-ISO currency must not be counted as MYR (or converted).
  final currency =
      rawCurrency != null && RegExp(r'^[A-Z]{3}$').hasMatch(rawCurrency)
      ? rawCurrency
      : null;
  final relation = row['custom_categories'];
  final categoryObject = relation is List
      ? (relation.isEmpty ? null : relation.first)
      : relation;
  final customCategory = categoryObject is Map
      ? text(categoryObject['name'])
      : null;
  final scores = row['confidence_scores'];
  return DashboardReceipt(
    id: id,
    date: date,
    createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? date,
    merchant: text(row['merchant']),
    amount: number(row['total']),
    tax: number(row['tax']),
    currency: currency,
    status: row['status'] == 'reviewed'
        ? ReceiptStatus.reviewed
        : ReceiptStatus.unreviewed,
    category: customCategory ?? text(row['predicted_category']),
    confidence: scores is Map ? _confidence(scores) : null,
  );
}

int? _confidence(Map scores) {
  double? normalize(dynamic value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null || !parsed.isFinite) return null;
    return (parsed < 1 ? parsed * 100 : parsed)
        .round()
        .clamp(0, 100)
        .toDouble();
  }

  final overall = normalize(scores['overall']);
  if (overall != null) return overall.round();
  const weights = {
    'merchant': 0.3,
    'date': 0.2,
    'total': 0.3,
    'payment_method': 0.1,
    'tax': 0.1,
  };
  var weight = 0.0;
  var sum = 0.0;
  for (final entry in weights.entries) {
    final value = normalize(scores[entry.key]);
    if (value != null) {
      weight += entry.value;
      sum += value * entry.value;
    }
  }
  return weight == 0 ? null : (sum / weight).round();
}

int _compareRecent(DashboardReceipt a, DashboardReceipt b) {
  final dateOrder = b.date.compareTo(a.date);
  if (dateOrder != 0) return dateOrder;
  final createdOrder = b.createdAt.compareTo(a.createdAt);
  return createdOrder != 0 ? createdOrder : a.id.compareTo(b.id);
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  final teamState = ref.watch(currentTeamProvider);
  if (userId == null) throw StateError('Sign in to load the overview');
  // Receipts loads while the saved workspace is still being restored. Wait
  // instead of briefly presenting personal totals as a team's totals.
  if (teamState.isLoading) throw const DashboardWorkspaceLoading();
  final client = ref.watch(supabaseClientProvider);
  if (client.auth.currentSession?.user.id != userId) {
    throw StateError('Your session has expired');
  }
  return DashboardSummaryService(client).fetch(
    userId: userId,
    teamId: teamState.currentTeam?.id,
    isCancelled: () {
      final current = ref.read(currentTeamProvider);
      return current.isLoading ||
          current.currentTeam?.id != teamState.currentTeam?.id;
    },
  );
});

/// Internal cancellation signal when the active workspace changes mid-read.
class DashboardSummaryCancelled implements Exception {
  const DashboardSummaryCancelled();
}

/// Signals that the active workspace has not finished restoring. The screen
/// renders this as loading rather than as an error.
class DashboardWorkspaceLoading implements Exception {
  const DashboardWorkspaceLoading();
}

/// Compatibility for existing non-UI consumers of the former synchronous
/// provider. New screens must use [dashboardSummaryProvider] to distinguish
/// loading and errors from an empty workspace.
@Deprecated('Use dashboardSummaryProvider and handle its loading and errors')
class DashboardStats {
  const DashboardStats({
    this.totalReceipts = 0,
    this.thisMonthReceipts = 0,
    this.totalAmount = 0,
    this.totalTeams = 0,
    this.recentReceipts = const [],
    this.categoryBreakdown = const {},
    this.monthlySpending = const {},
  });
  final int totalReceipts;
  final int thisMonthReceipts;
  final double totalAmount;
  final int totalTeams;
  final List<ReceiptModel> recentReceipts;
  final Map<String, int> categoryBreakdown;
  final Map<String, double> monthlySpending;
}

@Deprecated('Use dashboardSummaryProvider and handle its loading and errors')
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final summary = ref.watch(dashboardSummaryProvider).asData?.value;
  return DashboardStats(
    totalReceipts: summary?.receiptCount ?? 0,
    thisMonthReceipts: summary?.receiptCount ?? 0,
    totalAmount: summary?.spend ?? 0,
  );
});
