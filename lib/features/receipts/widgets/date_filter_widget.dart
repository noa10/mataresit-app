import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/receipts_provider.dart';

/// Widget for date filtering with quick options and custom range picker
class DateFilterWidget extends ConsumerStatefulWidget {
  final VoidCallback? onFilterChanged;

  const DateFilterWidget({
    super.key,
    this.onFilterChanged,
  });

  @override
  ConsumerState<DateFilterWidget> createState() => _DateFilterWidgetState();
}

class _DateFilterWidgetState extends ConsumerState<DateFilterWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final receiptsState = ref.watch(receiptsProvider);
    final currentFilter = receiptsState.dateFilter;

    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with current filter and expand/collapse button
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Filter',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateUtils.formatDateRange(currentFilter),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (receiptsState.hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${receiptsState.totalCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expandable filter options
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick filter buttons
                  Text(
                    'Quick Filters',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickFilterButtons(currentFilter),
                  
                  const SizedBox(height: 16),
                  
                  // Custom date range
                  Text(
                    'Custom Range',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCustomDateRange(currentFilter),
                  
                  const SizedBox(height: 16),
                  
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
                          onPressed: () => setState(() => _isExpanded = false),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilterButtons(DateRange currentFilter) {
    final quickFilters = [
      DateFilterOption.today,
      DateFilterOption.yesterday,
      DateFilterOption.thisWeek,
      DateFilterOption.thisMonth,
      DateFilterOption.last7Days,
      DateFilterOption.last30Days,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickFilters.map((option) {
        final isSelected = currentFilter.option == option;
        return FilterChip(
          label: Text(DateUtils.getFilterOptionDisplayName(option)),
          selected: isSelected,
          onSelected: (selected) => _applyQuickFilter(option),
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
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
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
                  ? DateUtils.formatDisplayDate(date)
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

  Future<void> _applyQuickFilter(DateFilterOption option) async {
    await ref.read(receiptsProvider.notifier).applyQuickDateFilter(option);
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
  }
}
