import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../shared/models/receipt_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _openPage(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    await context.push(path);
    if (context.mounted) ref.invalidate(dashboardSummaryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dashboardSummaryProvider);
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.yMMMM(locale).format(DateTime.now());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            ref.invalidate(dashboardSummaryProvider);
            await ref.read(dashboardSummaryProvider.future);
          } catch (_) {
            // The provider's error state is rendered below.
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    month,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontFamily: 'InstrumentSerif',
                      color: colors.onSurface,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your receipts and spending this month.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openPage(context, ref, AppRoutes.receipts),
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text('View receipts'),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            _openPage(context, ref, AppRoutes.receiptCapture),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Capture receipt'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  overview.when(
                    // Never leave the previous workspace's numbers on screen
                    // while a different workspace or a refresh is loading.
                    skipLoadingOnRefresh: false,
                    skipLoadingOnReload: false,
                    loading: () => const _OverviewLoading(),
                    error: (error, _) => error is DashboardWorkspaceLoading
                        ? const _OverviewLoading()
                        : _OverviewError(
                            onRetry: () =>
                                ref.invalidate(dashboardSummaryProvider),
                          ),
                    data: (summary) => _OverviewContent(
                      summary: summary,
                      openReceipt: (id) =>
                          _openPage(context, ref, '/receipts/$id'),
                      openReceipts: () =>
                          _openPage(context, ref, AppRoutes.receipts),
                      captureReceipt: () =>
                          _openPage(context, ref, AppRoutes.receiptCapture),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Panel(
                    title: 'Explore',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _destination(
                            context,
                            ref,
                            'search.title'.tr(),
                            Icons.search,
                            AppRoutes.search,
                          ),
                          _destination(
                            context,
                            ref,
                            'Analytics',
                            Icons.bar_chart,
                            AppRoutes.analytics,
                          ),
                          _destination(
                            context,
                            ref,
                            'duplicates.title'.tr(),
                            Icons.content_copy_outlined,
                            AppRoutes.duplicates,
                          ),
                          _destination(
                            context,
                            ref,
                            'gamification.missions.title'.tr(),
                            Icons.flag_outlined,
                            AppRoutes.missions,
                          ),
                          _destination(
                            context,
                            ref,
                            'gamification.leaderboard.title'.tr(),
                            Icons.leaderboard_outlined,
                            AppRoutes.leaderboard,
                          ),
                          _destination(
                            context,
                            ref,
                            'navigation.settings'.tr(),
                            Icons.settings_outlined,
                            AppRoutes.settings,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    String path,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _openPage(context, ref, path),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.summary,
    required this.openReceipt,
    required this.openReceipts,
    required this.captureReceipt,
  });

  final DashboardSummary summary;
  final ValueChanged<String> openReceipt;
  final VoidCallback openReceipts;
  final VoidCallback captureReceipt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEmpty = summary.receiptCount == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.truncated) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Showing the latest ${summary.receiptCount} receipts this month. Totals and review counts are partial.',
              style: TextStyle(color: colors.onSecondaryContainer),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Spend',
                value: _formatAmount(summary.spend, summary.currency),
                meta: _amountMeta(summary, summary.amountCount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Receipts',
                value: '${summary.receiptCount}',
                meta: 'Dated this month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricCard(
                label: 'To review',
                value: '${summary.reviewCount}',
                meta: 'Unreviewed receipts',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Tax',
                value: _formatAmount(summary.tax, summary.currency),
                meta: _amountMeta(summary, summary.taxCount),
              ),
            ),
          ],
        ),
        if (summary.otherCurrencyCount > 0 ||
            summary.unknownCurrencyCount > 0) ...[
          const SizedBox(height: 10),
          Text(
            [
              if (summary.otherCurrencyCount > 0)
                '+${summary.otherCurrencyCount} '
                    '${summary.otherCurrencyCount == 1 ? 'receipt' : 'receipts'} '
                    'in other currencies',
              if (summary.unknownCurrencyCount > 0)
                '${summary.unknownCurrencyCount} '
                    '${summary.unknownCurrencyCount == 1 ? 'receipt' : 'receipts'} '
                    'without a recognized currency',
            ].join('; '),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 16),
        _Panel(
          title: 'Categories',
          subtitle: summary.currency == null
              ? null
              : 'Amounts in ${summary.currency}',
          child: summary.categories.isEmpty
              ? const _PanelMessage(
                  'No categorized amounts available for this month.',
                )
              : Column(
                  children: [
                    for (final category in summary.categories)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(category.name)),
                            const SizedBox(width: 12),
                            Text(
                              _formatAmount(category.amount, summary.currency),
                              style: _dataStyle(context),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'To review',
          subtitle: 'Unreviewed this month',
          action: TextButton(
            onPressed: openReceipts,
            child: const Text('View receipts'),
          ),
          child: summary.reviewPreview.isEmpty
              ? _PanelMessage(
                  summary.truncated
                      ? 'No unreviewed receipts in the loaded results.'
                      : 'No receipts to review this month.',
                )
              : Column(
                  children: [
                    for (final receipt in summary.reviewPreview)
                      _ReceiptRow(
                        receipt: receipt,
                        onTap: () => openReceipt(receipt.id),
                        showConfidence: true,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Recent receipts',
          subtitle: 'Dated this month',
          action: TextButton(
            onPressed: openReceipts,
            child: const Text('View all'),
          ),
          child: isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No receipts are dated this month. New receipts appear here once their date is saved.',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: captureReceipt,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Capture receipt'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final receipt in summary.recent)
                      _ReceiptRow(
                        receipt: receipt,
                        onTap: () => openReceipt(receipt.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _amountMeta(DashboardSummary summary, int count) {
  if (summary.currency == null) return 'No known currency';
  return 'Across $count ${count == 1 ? 'receipt' : 'receipts'}';
}

String _formatAmount(double? value, String? currency) {
  if (value == null) return '—';
  if (currency == null) {
    return '${NumberFormat('#,##0.00', 'en_US').format(value)} (currency unknown)';
  }
  return NumberFormat.currency(
    locale: 'en_US',
    name: currency,
    symbol: '$currency ',
  ).format(value);
}

TextStyle? _dataStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .bodyMedium
    ?.copyWith(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.w500);

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.meta,
  });
  final String label;
  final String value;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  Flexible(child: action!),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          child,
        ],
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.receipt,
    required this.onTap,
    this.showConfidence = false,
  });
  final DashboardReceipt receipt;
  final VoidCallback onTap;
  final bool showConfidence;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final merchant = receipt.merchant ?? 'Unknown merchant';
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale).format(receipt.date);
    final status = receipt.status == ReceiptStatus.reviewed
        ? 'Reviewed'
        : 'Unreviewed';
    final confidence = receipt.confidence;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  merchant.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showConfidence
                          ? (confidence == null
                                ? 'Confidence unavailable'
                                : '$confidence% confidence')
                          : '$date · $status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  _formatAmount(receipt.amount, receipt.currency),
                  textAlign: TextAlign.end,
                  style: _dataStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewLoading extends StatelessWidget {
  const _OverviewLoading();

  @override
  Widget build(BuildContext context) => const _Panel(
    title: 'Overview',
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Loading overview…')),
        ],
      ),
    ),
  );
}

class _OverviewError extends StatelessWidget {
  const _OverviewError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Overview unavailable',
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load your receipts. Check your connection and try again.',
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
