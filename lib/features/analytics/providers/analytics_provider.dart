import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Analytics data for charts and reports
class AnalyticsData {
  final Map<String, double> categorySpending;
  final Map<String, double> monthlySpending;
  final Map<String, int> categoryCount;
  final List<FlSpot> spendingTrend;
  final double totalSpending;
  final double averageTransaction;
  final int totalTransactions;
  final String topCategory;
  final double monthOverMonthGrowth;
  final Map<String, double> paymentMethodBreakdown;

  const AnalyticsData({
    this.categorySpending = const {},
    this.monthlySpending = const {},
    this.categoryCount = const {},
    this.spendingTrend = const [],
    this.totalSpending = 0.0,
    this.averageTransaction = 0.0,
    this.totalTransactions = 0,
    this.topCategory = 'N/A',
    this.monthOverMonthGrowth = 0.0,
    this.paymentMethodBreakdown = const {},
  });

  AnalyticsData copyWith({
    Map<String, double>? categorySpending,
    Map<String, double>? monthlySpending,
    Map<String, int>? categoryCount,
    List<FlSpot>? spendingTrend,
    double? totalSpending,
    double? averageTransaction,
    int? totalTransactions,
    String? topCategory,
    double? monthOverMonthGrowth,
    Map<String, double>? paymentMethodBreakdown,
  }) {
    return AnalyticsData(
      categorySpending: categorySpending ?? this.categorySpending,
      monthlySpending: monthlySpending ?? this.monthlySpending,
      categoryCount: categoryCount ?? this.categoryCount,
      spendingTrend: spendingTrend ?? this.spendingTrend,
      totalSpending: totalSpending ?? this.totalSpending,
      averageTransaction: averageTransaction ?? this.averageTransaction,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      topCategory: topCategory ?? this.topCategory,
      monthOverMonthGrowth: monthOverMonthGrowth ?? this.monthOverMonthGrowth,
      paymentMethodBreakdown:
          paymentMethodBreakdown ?? this.paymentMethodBreakdown,
    );
  }
}

/// Analytics state for async data loading
class AnalyticsState {
  final AnalyticsData data;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const AnalyticsState({
    this.data = const AnalyticsData(),
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  AnalyticsState copyWith({
    AnalyticsData? data,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AnalyticsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Analytics notifier that fetches data from Supabase using the analytics service
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref ref;

  AnalyticsNotifier(this.ref) : super(const AnalyticsState()) {
    loadAnalytics();
  }

  /// Load analytics data from Supabase
  Future<void> loadAnalytics({String? startDate, String? endDate}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final analyticsService = ref.read(analyticsServiceProvider);

      // Fetch data using the analytics service (matching React web version)
      final futures = await Future.wait([
        analyticsService.fetchDailyExpenses(
          startDateISO: startDate,
          endDateISO: endDate,
          userId: user.id,
        ),
        analyticsService.fetchExpensesByCategory(
          startDateISO: startDate,
          endDateISO: endDate,
          userId: user.id,
        ),
        analyticsService.fetchReceiptDetailsForRange(
          startDateISO: startDate,
          endDateISO: endDate,
          userId: user.id,
        ),
      ]);

      final dailyExpenses = futures[0] as List<DailyExpenseData>;
      final categoryExpenses = futures[1] as List<CategoryExpenseData>;
      final receiptSummaries = futures[2] as List<ReceiptSummary>;

      // Transform data to match the existing AnalyticsData structure
      final analyticsData = _transformToAnalyticsData(
        dailyExpenses,
        categoryExpenses,
        receiptSummaries,
      );

      state = state.copyWith(
        data: analyticsData,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load analytics: ${e.toString()}',
      );
    }
  }

  /// Transform service data to AnalyticsData structure
  AnalyticsData _transformToAnalyticsData(
    List<DailyExpenseData> dailyExpenses,
    List<CategoryExpenseData> categoryExpenses,
    List<ReceiptSummary> receiptSummaries,
  ) {
    // Calculate category spending and counts
    final categorySpending = <String, double>{};
    final categoryCount = <String, int>{};

    for (final category in categoryExpenses) {
      categorySpending[category.category] = category.totalSpent;
      // Count receipts for each category from receipt summaries
      categoryCount[category.category] = receiptSummaries
          .where((r) => _getCategoryForReceipt(r) == category.category)
          .length;
    }

    // Calculate monthly spending from daily expenses
    final monthlySpending = <String, double>{};
    final now = DateTime.now();

    for (final daily in dailyExpenses) {
      final date = DateTime.parse(daily.date);
      final monthName = _getMonthName(date.month);
      monthlySpending[monthName] =
          (monthlySpending[monthName] ?? 0.0) + daily.total;
    }

    // Calculate spending trend for chart
    final spendingTrend = <FlSpot>[];
    final sortedMonths = monthlySpending.entries.toList()
      ..sort((a, b) => _getMonthIndex(a.key).compareTo(_getMonthIndex(b.key)));

    for (int i = 0; i < sortedMonths.length; i++) {
      spendingTrend.add(FlSpot(i.toDouble(), sortedMonths[i].value));
    }

    // Calculate payment method breakdown from receipt summaries
    final paymentMethodBreakdown = <String, double>{};
    for (final receipt in receiptSummaries) {
      final method = receipt.paymentMethod ?? 'Unknown';
      paymentMethodBreakdown[method] =
          (paymentMethodBreakdown[method] ?? 0.0) + (receipt.total ?? 0.0);
    }

    // Calculate summary statistics
    final totalSpending = receiptSummaries.fold<double>(
      0.0,
      (sum, receipt) => sum + (receipt.total ?? 0.0),
    );
    final validReceipts = receiptSummaries
        .where((r) => r.total != null && r.total! > 0)
        .toList();
    final averageTransaction = validReceipts.isNotEmpty
        ? totalSpending / validReceipts.length
        : 0.0;
    final totalTransactions = validReceipts.length;

    // Find top category
    final topCategory = categorySpending.isNotEmpty
        ? categorySpending.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
        : 'N/A';

    // Calculate month-over-month growth
    final currentMonth = monthlySpending[_getMonthName(now.month)] ?? 0.0;
    final lastMonth = monthlySpending[_getMonthName(now.month - 1)] ?? 0.0;
    final monthOverMonthGrowth = lastMonth > 0
        ? ((currentMonth - lastMonth) / lastMonth) * 100
        : 0.0;

    return AnalyticsData(
      categorySpending: categorySpending,
      monthlySpending: monthlySpending,
      categoryCount: categoryCount,
      spendingTrend: spendingTrend,
      totalSpending: totalSpending,
      averageTransaction: averageTransaction,
      totalTransactions: totalTransactions,
      topCategory: topCategory,
      monthOverMonthGrowth: monthOverMonthGrowth,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );
  }

  /// Get category for a receipt (simplified - would need more logic for custom categories)
  String _getCategoryForReceipt(ReceiptSummary receipt) {
    // This is a simplified version - in a real implementation, you'd need to
    // fetch the category information for each receipt
    return 'General'; // Placeholder
  }

  /// Refresh analytics data
  Future<void> refresh() async {
    await loadAnalytics();
  }
}

/// Analytics provider that uses the new service-based approach
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
      return AnalyticsNotifier(ref);
    });

/// Convenience provider for just the analytics data
final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  return ref.watch(analyticsProvider).data;
});

/// Get month name from month number
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

  // Handle negative months (for previous year)
  if (month <= 0) {
    return months[12 + month - 1];
  }

  return months[month - 1];
}

/// Get month index for sorting
int _getMonthIndex(String monthName) {
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
  return months.indexOf(monthName);
}

/// Provider for category pie chart data
final categoryPieChartProvider = Provider<List<PieChartSectionData>>((ref) {
  final analyticsData = ref.watch(analyticsDataProvider);

  if (analyticsData.categorySpending.isEmpty) {
    return [];
  }

  final colors = [
    const Color(0xFF2563EB), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Orange
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFF97316), // Orange-600
    const Color(0xFF84CC16), // Lime
  ];

  final sections = <PieChartSectionData>[];
  final entries = analyticsData.categorySpending.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (int i = 0; i < entries.length && i < colors.length; i++) {
    final entry = entries[i];
    final percentage = (entry.value / analyticsData.totalSpending) * 100;

    sections.add(
      PieChartSectionData(
        color: colors[i],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  return sections;
});

/// Provider for spending trend line chart data
final spendingTrendChartProvider = Provider<LineChartData>((ref) {
  final analyticsData = ref.watch(analyticsDataProvider);

  if (analyticsData.spendingTrend.isEmpty) {
    return LineChartData(lineBarsData: []);
  }

  return LineChartData(
    gridData: const FlGridData(show: true),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              '\$${value.toInt()}',
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
            if (value.toInt() < months.length) {
              return Text(
                months[value.toInt()],
                style: const TextStyle(fontSize: 10),
              );
            }
            return const Text('');
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    borderData: FlBorderData(show: true),
    lineBarsData: [
      LineChartBarData(
        spots: analyticsData.spendingTrend,
        isCurved: true,
        color: const Color(0xFF2563EB),
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
        ),
        dotData: const FlDotData(show: true),
      ),
    ],
  );
});
