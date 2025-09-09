import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedTimeframe = 'Last 30 Days';

  final List<String> _timeframeOptions = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final analytics = analyticsState.data;
    final pieChartData = ref.watch(categoryPieChartProvider);
    final lineChartData = ref.watch(spendingTrendChartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: _onTimeframeSelected,
            itemBuilder: (context) => _timeframeOptions.map((option) {
              return PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      _selectedTimeframe == option ? Icons.check : null,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: analyticsState.isLoading
                ? null
                : () {
                    _refreshAnalytics();
                  },
          ),
        ],
      ),
      body: analyticsState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            )
          : analyticsState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analyticsState.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(analyticsProvider.notifier).refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range and last updated info
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTimeframe == 'Custom Range' &&
                                        _selectedDateRange != null
                                    ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                                    : _selectedTimeframe,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (analyticsState.lastUpdated != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.update,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(analyticsState.lastUpdated!),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

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

  /// Handle timeframe selection
  void _onTimeframeSelected(String timeframe) {
    setState(() {
      _selectedTimeframe = timeframe;
    });

    final now = DateTime.now();
    DateTimeRange? newRange;

    switch (timeframe) {
      case 'Last 7 Days':
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
        break;
      case 'Last 30 Days':
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      case 'Last 3 Months':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
        break;
      case 'Last 6 Months':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );
        break;
      case 'Last Year':
        newRange = DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
        break;
      case 'Custom Range':
        _showDateRangePicker();
        return;
    }

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
      _refreshAnalytics();
    }
  }

  /// Show date range picker for custom range
  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedTimeframe = 'Custom Range';
      });
      _refreshAnalytics();
    }
  }

  /// Refresh analytics with current date range
  void _refreshAnalytics() {
    if (_selectedDateRange != null) {
      ref
          .read(analyticsProvider.notifier)
          .loadAnalytics(
            startDate: _selectedDateRange!.start.toIso8601String().split(
              'T',
            )[0],
            endDate: _selectedDateRange!.end.toIso8601String().split('T')[0],
          );
    } else {
      ref.read(analyticsProvider.notifier).refresh();
    }
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format date for display (without time)
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
            Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSpendingTrendChart(
    BuildContext context,
    LineChartData chartData,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [SizedBox(height: 200, child: LineChart(chartData))],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(
    BuildContext context,
    AnalyticsData analytics,
  ) {
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
                  Expanded(child: Text(entry.key)),
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
