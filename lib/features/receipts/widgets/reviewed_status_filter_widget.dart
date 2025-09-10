import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/receipt_model.dart';
import '../providers/receipts_provider.dart';

/// Widget for filtering receipts by reviewed status
class ReviewedStatusFilterWidget extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const ReviewedStatusFilterWidget({super.key, this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final currentFilter = receiptsState.reviewedStatusFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Status',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReviewedStatusFilter.values.map((filter) {
            final isSelected = currentFilter == filter;
            return FilterChip(
              label: Text(filter.displayName),
              selected: isSelected,
              onSelected: (selected) => _onFilterChanged(ref, filter),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _onFilterChanged(WidgetRef ref, ReviewedStatusFilter filter) {
    ref.read(receiptsProvider.notifier).setReviewedStatusFilter(filter);
    onFilterChanged?.call();
  }
}

/// Compact version for use in filter bars
class CompactReviewedStatusFilterWidget extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const CompactReviewedStatusFilterWidget({super.key, this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final currentFilter = receiptsState.reviewedStatusFilter;
    final hasFilter = currentFilter != ReviewedStatusFilter.all;

    return PopupMenuButton<ReviewedStatusFilter>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFilter
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(20),
          color: hasFilter
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(currentFilter),
              size: 16,
              color: hasFilter
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              currentFilter.displayName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: hasFilter
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => ReviewedStatusFilter.values.map((filter) {
        final isSelected = currentFilter == filter;
        return PopupMenuItem<ReviewedStatusFilter>(
          value: filter,
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Icon(
                _getStatusIcon(filter),
                size: 18,
                color: _getStatusColor(filter, context),
              ),
              const SizedBox(width: 8),
              Text(filter.displayName),
            ],
          ),
        );
      }).toList(),
      onSelected: (filter) {
        ref.read(receiptsProvider.notifier).setReviewedStatusFilter(filter);
        onFilterChanged?.call();
      },
    );
  }

  IconData _getStatusIcon(ReviewedStatusFilter filter) {
    switch (filter) {
      case ReviewedStatusFilter.all:
        return Icons.list_alt;
      case ReviewedStatusFilter.reviewed:
        return Icons.check_circle_outline;
      case ReviewedStatusFilter.unreviewed:
        return Icons.pending_outlined;
    }
  }

  Color _getStatusColor(ReviewedStatusFilter filter, BuildContext context) {
    switch (filter) {
      case ReviewedStatusFilter.all:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case ReviewedStatusFilter.reviewed:
        return Colors.green;
      case ReviewedStatusFilter.unreviewed:
        return Colors.orange;
    }
  }
}

/// Tab-style reviewed status filter (similar to React web version)
class ReviewedStatusTabsWidget extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const ReviewedStatusTabsWidget({super.key, this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final currentFilter = receiptsState.reviewedStatusFilter;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReviewedStatusFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return GestureDetector(
            onTap: () => _onFilterChanged(ref, filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(filter),
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.displayName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onFilterChanged(WidgetRef ref, ReviewedStatusFilter filter) {
    ref.read(receiptsProvider.notifier).setReviewedStatusFilter(filter);
    onFilterChanged?.call();
  }

  IconData _getStatusIcon(ReviewedStatusFilter filter) {
    switch (filter) {
      case ReviewedStatusFilter.all:
        return Icons.list_alt;
      case ReviewedStatusFilter.reviewed:
        return Icons.check_circle_outline;
      case ReviewedStatusFilter.unreviewed:
        return Icons.pending_outlined;
    }
  }
}
