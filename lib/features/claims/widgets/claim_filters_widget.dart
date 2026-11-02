import 'package:flutter/material.dart';

import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../../../shared/utils/date_utils.dart';

class ClaimFiltersWidget extends StatefulWidget {
  final ClaimFilters filters;
  final Function(ClaimFilters) onFiltersChanged;
  final VoidCallback onClearFilters;

  const ClaimFiltersWidget({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.onClearFilters,
  });

  @override
  State<ClaimFiltersWidget> createState() => _ClaimFiltersWidgetState();
}

class _ClaimFiltersWidgetState extends State<ClaimFiltersWidget> {
  static const Object _unset = Object();

  late ClaimFilters _currentFilters;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
    _initializeControllers();
  }

  @override
  void didUpdateWidget(ClaimFiltersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      _currentFilters = widget.filters;
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _minAmountController.text = _currentFilters.amountMin?.toString() ?? '';
    _maxAmountController.text = _currentFilters.amountMax?.toString() ?? '';
    _categoryController.text = _currentFilters.category ?? '';
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    widget.onFiltersChanged(_currentFilters);
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters = const ClaimFilters();
      _initializeControllers();
    });
    widget.onClearFilters();
  }

  /// Rebuilds the filter set while allowing nullable fields to be cleared.
  ClaimFilters _updated({
    Object? status = _unset,
    Object? priority = _unset,
    Object? amountMin = _unset,
    Object? amountMax = _unset,
    Object? category = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
  }) {
    return ClaimFilters(
      status: identical(status, _unset)
          ? _currentFilters.status
          : status as ClaimStatus?,
      priority: identical(priority, _unset)
          ? _currentFilters.priority
          : priority as ClaimPriority?,
      claimantId: _currentFilters.claimantId,
      dateFrom: identical(dateFrom, _unset)
          ? _currentFilters.dateFrom
          : dateFrom as DateTime?,
      dateTo: identical(dateTo, _unset)
          ? _currentFilters.dateTo
          : dateTo as DateTime?,
      amountMin: identical(amountMin, _unset)
          ? _currentFilters.amountMin
          : amountMin as double?,
      amountMax: identical(amountMax, _unset)
          ? _currentFilters.amountMax
          : amountMax as double?,
      category: identical(category, _unset)
          ? _currentFilters.category
          : category as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_currentFilters.hasFilters)
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusFilter(),
                const SizedBox(height: 16),
                _buildPriorityFilter(),
                const SizedBox(height: 16),
                _buildAmountRangeFilter(),
                const SizedBox(height: 16),
                _buildCategoryFilter(),
                const SizedBox(height: 16),
                _buildDateRangeFilter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('Status'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ClaimStatus.values.map((status) {
            final isSelected = _currentFilters.status == status;
            final (background, foreground) = _statusTone(colors, status);
            return FilterChip(
              label: Text(_statusLabel(status)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _updated(status: selected ? status : null);
                });
                _updateFilters();
              },
              selectedColor: background,
              checkmarkColor: foreground,
              backgroundColor: colors.surface,
              side: BorderSide(
                color: isSelected ? background : colors.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? foreground : colors.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriorityFilter() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('Priority'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ClaimPriority.values.map((priority) {
            final isSelected = _currentFilters.priority == priority;
            final (background, foreground) = _priorityTone(colors, priority);
            return FilterChip(
              label: Text(priority.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _updated(
                    priority: selected ? priority : null,
                  );
                });
                _updateFilters();
              },
              selectedColor: background,
              checkmarkColor: foreground,
              backgroundColor: colors.surface,
              side: BorderSide(
                color: isSelected ? background : colors.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? foreground : colors.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('Amount Range'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Amount',
                  prefixText: 'MYR ',
                  isDense: true,
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _currentFilters = _updated(amountMin: amount);
                  });
                  _updateFilters();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Amount',
                  prefixText: 'MYR ',
                  isDense: true,
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _currentFilters = _updated(amountMax: amount);
                  });
                  _updateFilters();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('Category'),
        const SizedBox(height: 8),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category',
            isDense: true,
            suffixIcon: Icon(Icons.category_outlined, size: 18),
          ),
          onChanged: (value) {
            setState(() {
              _currentFilters = _updated(
                category: value.isEmpty ? null : value,
              );
            });
            _updateFilters();
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    final theme = Theme.of(context);
    final dateStyle = theme.textTheme.labelSmall?.copyWith(
      fontFamily: 'IBMPlexMono',
      fontSize: 11,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterLabel('Date Range'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _currentFilters.dateFrom ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _currentFilters = _updated(dateFrom: date);
                    });
                    _updateFilters();
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 15),
                label: Text(
                  _currentFilters.dateFrom != null
                      ? AppDateUtils.formatDate(_currentFilters.dateFrom!)
                      : 'From Date',
                  style: dateStyle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _currentFilters.dateTo ?? DateTime.now(),
                    firstDate: _currentFilters.dateFrom ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _currentFilters = _updated(dateTo: date);
                    });
                    _updateFilters();
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 15),
                label: Text(
                  _currentFilters.dateTo != null
                      ? AppDateUtils.formatDate(_currentFilters.dateTo!)
                      : 'To Date',
                  style: dateStyle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _statusLabel(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return 'DRAFT';
      case ClaimStatus.submitted:
        return 'SUBMITTED';
      case ClaimStatus.pending:
        return 'PENDING';
      case ClaimStatus.underReview:
        return 'UNDER REVIEW';
      case ClaimStatus.approved:
        return 'APPROVED';
      case ClaimStatus.rejected:
        return 'REJECTED';
      case ClaimStatus.paid:
        return 'PAID';
    }
  }

  static (Color, Color) _statusTone(ColorScheme colors, ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
      case ClaimStatus.paid:
        return (colors.primaryContainer, colors.onPrimaryContainer);
      case ClaimStatus.submitted:
      case ClaimStatus.pending:
      case ClaimStatus.underReview:
        return (colors.tertiaryContainer, colors.onTertiaryContainer);
      case ClaimStatus.rejected:
        return (colors.errorContainer, colors.onErrorContainer);
      case ClaimStatus.draft:
        return (colors.surfaceContainerHighest, colors.onSurfaceVariant);
    }
  }

  static (Color, Color) _priorityTone(
    ColorScheme colors,
    ClaimPriority priority,
  ) {
    switch (priority) {
      case ClaimPriority.low:
        return (colors.surfaceContainerHighest, colors.onSurfaceVariant);
      case ClaimPriority.medium:
        return (colors.tertiaryContainer, colors.onTertiaryContainer);
      case ClaimPriority.high:
      case ClaimPriority.urgent:
        return (colors.errorContainer, colors.onErrorContainer);
    }
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
