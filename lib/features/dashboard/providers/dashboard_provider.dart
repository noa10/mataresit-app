import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../receipts/providers/receipts_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../core/services/app_logger.dart';

/// Dashboard statistics
class DashboardStats {
  final int totalReceipts;
  final int thisMonthReceipts;
  final double totalAmount;
  final int totalTeams;
  final List<ReceiptModel> recentReceipts;
  final Map<String, int> categoryBreakdown;
  final Map<String, double> monthlySpending;

  const DashboardStats({
    this.totalReceipts = 0,
    this.thisMonthReceipts = 0,
    this.totalAmount = 0.0,
    this.totalTeams = 0,
    this.recentReceipts = const [],
    this.categoryBreakdown = const {},
    this.monthlySpending = const {},
  });

  DashboardStats copyWith({
    int? totalReceipts,
    int? thisMonthReceipts,
    double? totalAmount,
    int? totalTeams,
    List<ReceiptModel>? recentReceipts,
    Map<String, int>? categoryBreakdown,
    Map<String, double>? monthlySpending,
  }) {
    return DashboardStats(
      totalReceipts: totalReceipts ?? this.totalReceipts,
      thisMonthReceipts: thisMonthReceipts ?? this.thisMonthReceipts,
      totalAmount: totalAmount ?? this.totalAmount,
      totalTeams: totalTeams ?? this.totalTeams,
      recentReceipts: recentReceipts ?? this.recentReceipts,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      monthlySpending: monthlySpending ?? this.monthlySpending,
    );
  }
}

/// Dashboard provider that computes statistics from receipts
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final receiptsState = ref.watch(receiptsProvider);
  final receipts = receiptsState.receipts;

  // Watch teams state to get the correct teams count
  final teamsState = ref.watch(teamsProvider);
  final totalTeams = teamsState.teams.length;

  AppLogger.info(
    '📊 Dashboard calculating stats from ${receipts.length} receipts',
  );

  if (receipts.isEmpty) {
    AppLogger.warning(
      '📊 No receipts found, returning stats with teams count only',
    );
    return DashboardStats(totalTeams: totalTeams);
  }

  // Calculate total receipts
  final totalReceipts = receipts.length;

  // Calculate this month's receipts using transaction date if available
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);
  final thisMonthReceipts = receipts.where((receipt) {
    final dateToCheck = receipt.transactionDate ?? receipt.createdAt;
    return dateToCheck.isAfter(thisMonth);
  }).length;

  // Calculate total amount (filter out null and zero values)
  final totalAmount = receipts
      .where(
        (receipt) => receipt.totalAmount != null && receipt.totalAmount! > 0,
      )
      .fold<double>(0.0, (sum, receipt) => sum + receipt.totalAmount!);

  // Get recent receipts (last 5)
  final recentReceipts = receipts.take(5).toList();

  // Calculate category breakdown
  final categoryBreakdown = <String, int>{};
  for (final receipt in receipts) {
    final category = receipt.category ?? 'Uncategorized';
    categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
  }

  // Calculate monthly spending (last 6 months)
  final monthlySpending = <String, double>{};
  for (int i = 0; i < 6; i++) {
    final month = DateTime(now.year, now.month - i);
    final monthName = _getMonthName(month.month);
    final monthReceipts = receipts.where((receipt) {
      return receipt.createdAt.year == month.year &&
          receipt.createdAt.month == month.month;
    });

    final monthTotal = monthReceipts
        .where((receipt) => receipt.totalAmount != null)
        .fold<double>(0.0, (sum, receipt) => sum + receipt.totalAmount!);

    monthlySpending[monthName] = monthTotal;
  }

  AppLogger.info(
    '📈 Dashboard stats calculated: Total: $totalReceipts, This month: $thisMonthReceipts, Amount: \$${totalAmount.toStringAsFixed(2)}, Teams: $totalTeams',
  );

  return DashboardStats(
    totalReceipts: totalReceipts,
    thisMonthReceipts: thisMonthReceipts,
    totalAmount: totalAmount,
    totalTeams: totalTeams,
    recentReceipts: recentReceipts,
    categoryBreakdown: categoryBreakdown,
    monthlySpending: monthlySpending,
  );
});

String _getMonthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
