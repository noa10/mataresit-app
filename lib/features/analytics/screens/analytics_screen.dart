import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final pieChartData = ref.watch(categoryPieChartProvider);
    final lineChartData = ref.watch(spendingTrendChartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(analyticsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummaryCards(context, analytics),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Category Spending Chart
            if (pieChartData.isNotEmpty) ...[
              _buildSectionTitle(context, 'Spending by Category'),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildCategoryPieChart(context, analytics, pieChartData),
              
              const SizedBox(height: AppConstants.largePadding),
            ],
            
            // Spending Trend Chart
            if (analytics.spendingTrend.isNotEmpty) ...[
              _buildSectionTitle(context, 'Spending Trend'),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildSpendingTrendChart(context, lineChartData),
              
              const SizedBox(height: AppConstants.largePadding),
            ],
            
            // Payment Methods
            if (analytics.paymentMethodBreakdown.isNotEmpty) ...[
              _buildSectionTitle(context, 'Payment Methods'),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildPaymentMethodsList(context, analytics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AnalyticsData analytics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Total Spending',
                '\$${analytics.totalSpending.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Transactions',
                analytics.totalTransactions.toString(),
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Average',
                '\$${analytics.averageTransaction.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Top Category',
                analytics.topCategory,
                Icons.category,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryPieChart(
    BuildContext context,
    AnalyticsData analytics,
    List<PieChartSectionData> sections,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildCategoryLegend(context, analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(BuildContext context, AnalyticsData analytics) {
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

    final entries = analytics.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: AppConstants.defaultPadding,
      runSpacing: AppConstants.smallPadding,
      children: entries.take(colors.length).map((entry) {
        final index = entries.indexOf(entry);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSpendingTrendChart(BuildContext context, LineChartData chartData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: LineChart(chartData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(BuildContext context, AnalyticsData analytics) {
    final entries = analytics.paymentMethodBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: entries.map((entry) {
            final percentage = (entry.value / analytics.totalSpending) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Text(
                    '\$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
