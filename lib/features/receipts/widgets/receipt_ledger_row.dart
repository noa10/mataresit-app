import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/receipt_model.dart';
import '../../../shared/utils/confidence_utils.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/confidence_indicator.dart';
import '../../../shared/widgets/currency_display_widget.dart';
import '../../categories/providers/categories_provider.dart';
import '../providers/receipts_provider.dart';

/// A single receipt in the inbox ledger, shared by grouped and flat views.
class ReceiptLedgerRow extends ConsumerWidget {
  const ReceiptLedgerRow({
    super.key,
    required this.receipt,
    this.showConvertedAmount = false,
    this.showDate = true,
    this.isFirst = false,
    this.isLast = false,
  });

  final ReceiptModel receipt;
  final bool showConvertedAmount;
  final bool showDate;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = ref.watch(receiptsProvider);
    final categories = ref.watch(categoriesProvider).displayCategories;
    final notifier = ref.read(receiptsProvider.notifier);
    final selected = state.selectedReceiptIds.contains(receipt.id);
    final merchant = receipt.merchantName?.trim();
    final merchantLabel = merchant == null || merchant.isEmpty
        ? 'Unknown Merchant'
        : merchant;
    final customCategory = categories
        .where((category) => category.id == receipt.customCategoryId)
        .firstOrNull;
    final predictedCategory = receipt.category?.trim();
    final categoryLabel =
        customCategory?.name ??
        (predictedCategory == null || predictedCategory.isEmpty
            ? 'Uncategorized'
            : predictedCategory);
    final date = receipt.transactionDate ?? receipt.createdAt;
    final hasConfidence =
        (receipt.aiSuggestions?.containsKey('confidence') ?? false) ||
        (receipt.confidenceScores?.isNotEmpty ?? false);
    final isProcessing =
        receipt.processingStatus == ProcessingStatus.processing;

    void activate() {
      if (state.isSelectionMode) {
        notifier.toggleReceiptSelection(receipt.id);
      } else {
        context.push('/receipts/${receipt.id}');
      }
    }

    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(9) : Radius.zero,
      bottom: isLast ? const Radius.circular(9) : Radius.zero,
    );

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.45)
          : colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: activate,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isSelectionMode) ...[
                SizedBox(
                  width: 30,
                  height: 34,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => activate(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _MonogramTile(name: merchantLabel),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                merchantLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                categoryLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: _buildAmount(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ReviewChip(status: receipt.status),
                        if (showDate)
                          Text(
                            DateFormat('dd MMM').format(date).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                          ),
                        if (receipt.processingStatus !=
                            ProcessingStatus.completed)
                          Text(
                            receipt.processingStatus.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  receipt.processingStatus ==
                                      ProcessingStatus.failed
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        if (hasConfidence || isProcessing)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CompactConfidenceIndicator(
                                score: hasConfidence
                                    ? ConfidenceUtils.calculateAggregateConfidence(
                                        receipt,
                                      )
                                    : null,
                                loading: !hasConfidence && isProcessing,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmount(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontFamily: 'IBMPlexMono',
      fontWeight: FontWeight.w600,
    );
    if (receipt.totalAmount == null) {
      return Text('—', style: style, textAlign: TextAlign.end);
    }
    if (showConvertedAmount) {
      return Align(
        alignment: Alignment.centerRight,
        child: CompactCurrencyDisplay(
          amount: receipt.totalAmount!,
          currencyCode: receipt.currency ?? 'MYR',
          style: style,
        ),
      );
    }
    return Text(
      CurrencyUtils.formatCurrencySafe(receipt.totalAmount, receipt.currency),
      textAlign: TextAlign.end,
      style: style,
    );
  }
}

/// Summary for the loaded portion of the receipt ledger.
class ReceiptLedgerInfo extends ConsumerWidget {
  const ReceiptLedgerInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiptsProvider);
    if (state.receipts.isEmpty && state.error == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final count = state.totalCount;
    final countText = count == 1 ? '1 receipt' : '$count receipts';
    final loaded = state.hasMore && count > 0 ? ' loaded' : '';
    final summary = count == 0
        ? 'No receipts'
        : '$countText$loaded • MYR ${state.totalAmount.toStringAsFixed(2)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: colors.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(receiptsProvider.notifier).refresh(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onErrorContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (state.hasActiveFilters) ...[
                const SizedBox(width: 8),
                Text(
                  'Filtered',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MonogramTile extends StatelessWidget {
  const _MonogramTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length > 1
        ? '${words[0].characters.first}${words[1].characters.first}'
        : words[0].characters.take(2).toString();

    return ExcludeSemantics(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          initials.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.status});

  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reviewed = status == ReceiptStatus.reviewed;
    final foreground = reviewed
        ? colors.onPrimaryContainer
        : colors.onTertiaryContainer;
    final background = reviewed
        ? colors.primaryContainer
        : colors.tertiaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
