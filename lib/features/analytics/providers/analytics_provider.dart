import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../receipts/providers/receipts_provider.dart';

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
      paymentMethodBreakdown: paymentMethodBreakdown ?? this.paymentMethodBreakdown,
    );
  }
}

/// Analytics provider that computes detailed statistics and chart data
final analyticsProvider = Provider<AnalyticsData>((ref) {
  final receiptsState = ref.watch(receiptsProvider);
  final receipts = receiptsState.receipts;

  if (receipts.isEmpty) {
    return const AnalyticsData();
  }

  // Filter receipts with valid amounts
  final validReceipts = receipts.where((r) => r.totalAmount != null && r.totalAmount! > 0).toList();
  
  if (validReceipts.isEmpty) {
    return const AnalyticsData();
  }

  // Calculate category spending
  final categorySpending = <String, double>{};
  final categoryCount = <String, int>{};
  
  for (final receipt in validReceipts) {
    final category = receipt.category ?? 'Uncategorized';
    categorySpending[category] = (categorySpending[category] ?? 0.0) + receipt.totalAmount!;
    categoryCount[category] = (categoryCount[category] ?? 0) + 1;
  }

  // Calculate monthly spending (last 12 months)
  final monthlySpending = <String, double>{};
  final now = DateTime.now();
  
  for (int i = 0; i < 12; i++) {
    final month = DateTime(now.year, now.month - i);
    final monthName = _getMonthName(month.month);
    
    final monthReceipts = validReceipts.where((receipt) {
      return receipt.createdAt.year == month.year &&
          receipt.createdAt.month == month.month;
    });
    
    final monthTotal = monthReceipts.fold<double>(0.0, (sum, receipt) => sum + receipt.totalAmount!);
    monthlySpending[monthName] = monthTotal;
  }

  // Calculate spending trend for chart
  final spendingTrend = <FlSpot>[];
  final sortedMonths = monthlySpending.entries.toList()
    ..sort((a, b) => _getMonthIndex(a.key).compareTo(_getMonthIndex(b.key)));
  
  for (int i = 0; i < sortedMonths.length; i++) {
    spendingTrend.add(FlSpot(i.toDouble(), sortedMonths[i].value));
  }

  // Calculate payment method breakdown
  final paymentMethodBreakdown = <String, double>{};
  for (final receipt in validReceipts) {
    final method = receipt.paymentMethod ?? 'Unknown';
    paymentMethodBreakdown[method] = (paymentMethodBreakdown[method] ?? 0.0) + receipt.totalAmount!;
  }

  // Calculate summary statistics
  final totalSpending = validReceipts.fold<double>(0.0, (sum, receipt) => sum + receipt.totalAmount!);
  final averageTransaction = totalSpending / validReceipts.length;
  final totalTransactions = validReceipts.length;
  
  // Find top category
  final topCategory = categorySpending.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

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
});

/// Get month name from month number
String _getMonthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months.indexOf(monthName);
}

/// Provider for category pie chart data
final categoryPieChartProvider = Provider<List<PieChartSectionData>>((ref) {
  final analytics = ref.watch(analyticsProvider);
  
  if (analytics.categorySpending.isEmpty) {
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
  final entries = analytics.categorySpending.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (int i = 0; i < entries.length && i < colors.length; i++) {
    final entry = entries[i];
    final percentage = (entry.value / analytics.totalSpending) * 100;
    
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
  final analytics = ref.watch(analyticsProvider);
  
  if (analytics.spendingTrend.isEmpty) {
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
        spots: analytics.spendingTrend,
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
