import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/receipts_provider.dart';

/// Compact horizontal date filter bar for quick access
class DateFilterBar extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const DateFilterBar({super.key, this.onFilterChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final currentFilter = receiptsState.dateFilter;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          // Current filter indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  AppDateUtils.getFilterOptionDisplayName(currentFilter.option),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Quick filter buttons
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildQuickFilterButtons(context, ref, currentFilter),
              ),
            ),
          ),

          // More options button
          IconButton(
            onPressed: () => _showFilterBottomSheet(context, ref),
            icon: const Icon(Icons.tune),
            tooltip: 'More filters',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuickFilterButtons(
    BuildContext context,
    WidgetRef ref,
    DateRange currentFilter,
  ) {
    final quickFilters = [
      DateFilterOption.today,
      DateFilterOption.yesterday,
      DateFilterOption.thisWeek,
      DateFilterOption.last7Days,
      DateFilterOption.last30Days,
    ];

    return quickFilters.map((option) {
      final isSelected = currentFilter.option == option;

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(
            AppDateUtils.getFilterOptionDisplayName(option),
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) => _applyQuickFilter(ref, option),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          checkmarkColor: Theme.of(context).colorScheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );
    }).toList();
  }

  Future<void> _applyQuickFilter(WidgetRef ref, DateFilterOption option) async {
    await ref.read(receiptsProvider.notifier).applyQuickDateFilter(option);
    onFilterChanged?.call();
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _FilterBottomSheet(onFilterChanged: onFilterChanged),
    );
  }
}

/// Bottom sheet for advanced filtering options
class _FilterBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onFilterChanged;

  const _FilterBottomSheet({this.onFilterChanged});

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final receiptsState = ref.watch(receiptsProvider);
    final currentFilter = receiptsState.dateFilter;

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.defaultPadding,
        right: AppConstants.defaultPadding,
        top: AppConstants.defaultPadding,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            AppConstants.defaultPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'Filter Receipts',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // All filter options
          Text(
            'Date Range',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _buildAllFilterOptions(currentFilter),

          const SizedBox(height: 20),

          // Custom date range
          if (currentFilter.option == DateFilterOption.custom) ...[
            Text(
              'Custom Range',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCustomDateRange(currentFilter),
            const SizedBox(height: 20),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllFilterOptions(DateRange currentFilter) {
    final allOptions = [
      DateFilterOption.all,
      DateFilterOption.today,
      DateFilterOption.yesterday,
      DateFilterOption.thisWeek,
      DateFilterOption.thisMonth,
      DateFilterOption.last7Days,
      DateFilterOption.last30Days,
      DateFilterOption.custom,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allOptions.map((option) {
        final isSelected = currentFilter.option == option;
        return FilterChip(
          label: Text(AppDateUtils.getFilterOptionDisplayName(option)),
          selected: isSelected,
          onSelected: (selected) => _applyFilter(option),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildCustomDateRange(DateRange currentFilter) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(
            label: 'From',
            date: currentFilter.startDate,
            onTap: () => _selectStartDate(currentFilter),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateButton(
            label: 'To',
            date: currentFilter.endDate,
            onTap: () => _selectEndDate(currentFilter),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? AppDateUtils.formatDisplayDate(date)
                  : 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: date != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyFilter(DateFilterOption option) async {
    if (option == DateFilterOption.custom) {
      // Just set the option, user will select dates
      final newFilter = DateRange(
        startDate: null,
        endDate: null,
        option: option,
      );
      await ref.read(receiptsProvider.notifier).setDateFilter(newFilter);
    } else {
      await ref.read(receiptsProvider.notifier).applyQuickDateFilter(option);
    }

    setState(() {}); // Refresh UI
    widget.onFilterChanged?.call();
  }

  Future<void> _selectStartDate(DateRange currentFilter) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentFilter.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final newFilter = currentFilter.copyWith(
        startDate: date,
        option: DateFilterOption.custom,
      );
      await ref.read(receiptsProvider.notifier).setDateFilter(newFilter);
      widget.onFilterChanged?.call();
    }
  }

  Future<void> _selectEndDate(DateRange currentFilter) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentFilter.endDate ?? DateTime.now(),
      firstDate: currentFilter.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final newFilter = currentFilter.copyWith(
        endDate: date,
        option: DateFilterOption.custom,
      );
      await ref.read(receiptsProvider.notifier).setDateFilter(newFilter);
      widget.onFilterChanged?.call();
    }
  }

  Future<void> _clearFilters() async {
    await ref.read(receiptsProvider.notifier).clearAllFilters();
    widget.onFilterChanged?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
