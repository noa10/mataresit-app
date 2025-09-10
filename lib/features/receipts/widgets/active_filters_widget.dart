import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/utils/date_utils.dart';

import '../providers/receipts_provider.dart';
import '../../categories/providers/categories_provider.dart';

/// Widget to display active filters as removable chips
class ActiveFiltersWidget extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const ActiveFiltersWidget({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    
    if (!receiptsState.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final activeFilters = <Widget>[];

    // Date filter chip
    if (receiptsState.dateFilter.option != DateFilterOption.all) {
      activeFilters.add(
        _buildFilterChip(
          context,
          label: AppDateUtils.getFilterOptionDisplayName(receiptsState.dateFilter.option),
          icon: Icons.date_range,
          onRemove: () {
            ref.read(receiptsProvider.notifier).setDateFilter(
              const DateRange(option: DateFilterOption.all),
            );
            onFilterChanged?.call();
          },
        ),
      );
    }

    // Search query chip
    if (receiptsState.searchQuery.isNotEmpty) {
      activeFilters.add(
        _buildFilterChip(
          context,
          label: 'Search: "${receiptsState.searchQuery}"',
          icon: Icons.search,
          onRemove: () {
            ref.read(receiptsProvider.notifier).setSearchQuery('');
            onFilterChanged?.call();
          },
        ),
      );
    }

    // Status filter chip
    if (receiptsState.statusFilter != null) {
      activeFilters.add(
        _buildFilterChip(
          context,
          label: 'Status: ${receiptsState.statusFilter!.displayName}',
          icon: Icons.flag,
          onRemove: () {
            ref.read(receiptsProvider.notifier).setStatusFilter(null);
            onFilterChanged?.call();
          },
        ),
      );
    }

    // Category filter chips
    for (final categoryId in receiptsState.categoryFilters) {
      final category = categoriesState.categories
          .where((c) => c.id == categoryId)
          .firstOrNull;
      
      if (category != null) {
        activeFilters.add(
          _buildFilterChip(
            context,
            label: category.name,
            icon: Icons.category,
            color: _parseColor(category.color, context),
            onRemove: () {
              ref.read(receiptsProvider.notifier).removeCategoryFilter(categoryId);
              onFilterChanged?.call();
            },
          ),
        );
      }
    }

    // Reviewed status filter chip
    if (receiptsState.reviewedStatusFilter != ReviewedStatusFilter.all) {
      activeFilters.add(
        _buildFilterChip(
          context,
          label: receiptsState.reviewedStatusFilter.displayName,
          icon: receiptsState.reviewedStatusFilter == ReviewedStatusFilter.reviewed
              ? Icons.check_circle_outline
              : Icons.pending_outlined,
          color: receiptsState.reviewedStatusFilter == ReviewedStatusFilter.reviewed
              ? Colors.green
              : Colors.orange,
          onRemove: () {
            ref.read(receiptsProvider.notifier).setReviewedStatusFilter(
              ReviewedStatusFilter.all,
            );
            onFilterChanged?.call();
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Filters (${activeFilters.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ref.read(receiptsProvider.notifier).clearAllFilters();
                  onFilterChanged?.call();
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
    Color? color,
  }) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: color ?? Theme.of(context).colorScheme.outline,
        width: 1,
      ),
    );
  }

  Color _parseColor(String colorString, BuildContext context) {
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Theme.of(context).colorScheme.primary;
    }
  }
}

/// Compact version showing just the count of active filters
class ActiveFiltersCountWidget extends ConsumerWidget {
  final VoidCallback? onTap;

  const ActiveFiltersCountWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    
    if (!receiptsState.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    int filterCount = 0;
    
    if (receiptsState.dateFilter.option != DateFilterOption.all) filterCount++;
    if (receiptsState.searchQuery.isNotEmpty) filterCount++;
    if (receiptsState.statusFilter != null) filterCount++;
    if (receiptsState.categoryFilters.isNotEmpty) filterCount += receiptsState.categoryFilters.length;
    if (receiptsState.reviewedStatusFilter != ReviewedStatusFilter.all) filterCount++;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '$filterCount',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
