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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

            const SizedBox(height: 16),

            // Status filter
            _buildStatusFilter(),

            const SizedBox(height: 16),

            // Priority filter
            _buildPriorityFilter(),

            const SizedBox(height: 16),

            // Amount range filter
            _buildAmountRangeFilter(),

            const SizedBox(height: 16),

            // Category filter
            _buildCategoryFilter(),

            const SizedBox(height: 16),

            // Date range filter
            _buildDateRangeFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ClaimStatus.values.map((status) {
            final isSelected = _currentFilters.status == status;
            return FilterChip(
              label: Text(status.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    status: selected ? status : null,
                  );
                });
                _updateFilters();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriorityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ClaimPriority.values.map((priority) {
            final isSelected = _currentFilters.priority == priority;
            Color chipColor;
            switch (priority) {
              case ClaimPriority.low:
                chipColor = Colors.green;
                break;
              case ClaimPriority.medium:
                chipColor = Colors.orange;
                break;
              case ClaimPriority.high:
                chipColor = Colors.red;
                break;
              case ClaimPriority.urgent:
                chipColor = Colors.red.shade700;
                break;
            }

            return FilterChip(
              label: Text(priority.name.toUpperCase()),
              selected: isSelected,
              selectedColor: chipColor.withValues(alpha: 0.2),
              checkmarkColor: chipColor,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    priority: selected ? priority : null,
                  );
                });
                _updateFilters();
              },
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
        Text(
          'Amount Range',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      amountMin: amount,
                    );
                  });
                  _updateFilters();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      amountMax: amount,
                    );
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
        Text(
          'Category',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            isDense: true,
            suffixIcon: Icon(Icons.category),
          ),
          onChanged: (value) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
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
                      _currentFilters = _currentFilters.copyWith(
                        dateFrom: date,
                      );
                    });
                    _updateFilters();
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _currentFilters.dateFrom != null
                      ? AppDateUtils.formatDate(_currentFilters.dateFrom!)
                      : 'From Date',
                  style: const TextStyle(fontSize: 12),
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
                      _currentFilters = _currentFilters.copyWith(dateTo: date);
                    });
                    _updateFilters();
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _currentFilters.dateTo != null
                      ? AppDateUtils.formatDate(_currentFilters.dateTo!)
                      : 'To Date',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
