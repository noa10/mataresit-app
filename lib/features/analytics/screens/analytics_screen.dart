import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/utils/currency_utils.dart';
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

    final hasData =
        analytics.totalTransactions > 0 ||
        pieChartData.isNotEmpty ||
        analytics.spendingTrend.isNotEmpty ||
        analytics.paymentMethodBreakdown.isNotEmpty;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(context, analyticsState),
                const SizedBox(height: 20),
                if (analyticsState.isLoading)
                  const _AnalyticsLoadingPanel()
                else if (analyticsState.error != null)
                  _AnalyticsErrorPanel(
                    error: analyticsState.error!,
                    onRetry: () =>
                        ref.read(analyticsProvider.notifier).refresh(),
                  )
                else ...[
                  _buildSummaryCards(context, analytics),
                  const SizedBox(height: 16),
                  if (!hasData)
                    const _AnalyticsEmptyPanel()
                  else ...[
                    if (pieChartData.isNotEmpty) ...[
                      _buildCategoryPanel(context, analytics, pieChartData),
                      const SizedBox(height: 16),
                    ],
                    if (analytics.spendingTrend.isNotEmpty) ...[
                      _buildTrendPanel(context, lineChartData),
                      const SizedBox(height: 16),
                    ],
                    if (analytics.paymentMethodBreakdown.isNotEmpty)
                      _buildPaymentMethodsPanel(context, analytics),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, AnalyticsState analyticsState) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ANALYSIS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Analytics',
          style: theme.textTheme.displaySmall?.copyWith(
            fontFamily: 'InstrumentSerif',
            fontSize: 32,
            height: 1.05,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Spending, categories and payment methods for the selected period.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildRangeMenu(context),
            OutlinedButton.icon(
              onPressed: analyticsState.isLoading ? null : _refreshAnalytics,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
            if (analyticsState.lastUpdated != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.update, size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(analyticsState.lastUpdated!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Date range',
      onSelected: _onTimeframeSelected,
      itemBuilder: (context) => _timeframeOptions.map((option) {
        final selected = option == _selectedTimeframe;
        return PopupMenuItem<String>(
          value: option,
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: selected
                    ? Icon(Icons.check, size: 16, color: colors.primary)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(option),
            ],
          ),
        );
      }).toList(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_outlined, size: 18, color: colors.onSurface),
            const SizedBox(width: 8),
            Text(
              _rangeLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more, size: 18, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String get _rangeLabel =>
      _selectedTimeframe == 'Custom Range' && _selectedDateRange != null
      ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
      : _selectedTimeframe;

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
    final topSpend = analytics.categorySpending[analytics.topCategory] ?? 0.0;
    final topShare = analytics.totalSpending > 0 && topSpend > 0
        ? '${(topSpend / analytics.totalSpending * 100).toStringAsFixed(0)}% of spend'
        : 'No spend recorded';

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Total Spending',
                value: CurrencyUtils.formatCurrency(
                  analytics.totalSpending,
                  'MYR',
                ),
                meta: _rangeLabel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                label: 'Transactions',
                value: analytics.totalTransactions.toString(),
                meta: 'Receipts in range',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Average',
                value: CurrencyUtils.formatCurrency(
                  analytics.averageTransaction,
                  'MYR',
                ),
                meta: 'Per receipt',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                label: 'Top Category',
                value: analytics.topCategory,
                meta: topShare,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryPanel(
    BuildContext context,
    AnalyticsData analytics,
    List<PieChartSectionData> sections,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _Panel(
      title: 'Spending by Category',
      meta: _rangeLabel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                  IgnorePointer(
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TOTAL',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 9,
                              letterSpacing: 1,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyUtils.formatCurrency(
                                analytics.totalSpending,
                                'MYR',
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: colors.outlineVariant),
            const SizedBox(height: 12),
            _buildCategoryLegend(context, analytics, sections),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(
    BuildContext context,
    AnalyticsData analytics,
    List<PieChartSectionData> sections,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = analytics.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = entries.take(sections.length).toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (var i = 0; i < visible.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: sections[i].color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                visible[i].key,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                CurrencyUtils.formatCurrency(visible[i].value, 'MYR'),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTrendPanel(BuildContext context, LineChartData chartData) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final themedChartData = chartData.copyWith(
      lineBarsData: [
        for (final bar in chartData.lineBarsData)
          bar.copyWith(
            color: colors.primary,
            belowBarData: BarAreaData(
              show: bar.belowBarData.show,
              color: colors.primary.withValues(alpha: 0.12),
            ),
            dotData: FlDotData(
              show: bar.dotData.show,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 3,
                    color: colors.primary,
                    strokeWidth: 2,
                    strokeColor: colors.surface,
                  ),
            ),
          ),
      ],
      gridData: FlGridData(
        show: chartData.gridData.show,
        drawHorizontalLine: chartData.gridData.drawHorizontalLine,
        drawVerticalLine: chartData.gridData.drawVerticalLine,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: colors.outlineVariant, strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: colors.outlineVariant, strokeWidth: 1),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: colors.outlineVariant),
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );

    return _Panel(
      title: 'Spending Trend',
      meta: _rangeLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: SizedBox(
          height: 200,
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: colors.onSurfaceVariant,
            ),
            child: LineChart(themedChartData),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsPanel(
    BuildContext context,
    AnalyticsData analytics,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = analytics.paymentMethodBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Panel(
      title: 'Payment Methods',
      meta: _rangeLabel,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: colors.outlineVariant),
            _buildPaymentMethodRow(
              context,
              entries[i],
              analytics.totalSpending,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(
    BuildContext context,
    MapEntry<String, double> entry,
    double totalSpending,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final percentage = totalSpending > 0
        ? (entry.value / totalSpending) * 100
        : 0.0;
    final fraction = (percentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${CurrencyUtils.formatCurrency(entry.value, 'MYR')} (${percentage.toStringAsFixed(1)}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared ledger panel: surface fill, hairline border, header and divider.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.meta});

  final String title;
  final String? meta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      meta!,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        letterSpacing: 0.4,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          child,
        ],
      ),
    );
  }
}

/// KPI tile matching the ledger metric cards.
class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.meta,
  });

  final String label;
  final String value;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLoadingPanel extends StatelessWidget {
  const _AnalyticsLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _Panel(
      title: 'Analytics',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading analytics...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsErrorPanel extends StatelessWidget {
  const _AnalyticsErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _Panel(
      title: 'Analytics',
      meta: 'Error',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: colors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading analytics',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsEmptyPanel extends StatelessWidget {
  const _AnalyticsEmptyPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 28,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'No spending in this period',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload a receipt or widen the date range to see analytics.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
