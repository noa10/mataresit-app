import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/line_item_model.dart';
import '../../../shared/widgets/currency_display_widget.dart';

class BasicLineItemsWidget extends StatelessWidget {
  final List<LineItemModel> lineItems;
  final String currency;
  final bool isEditing;
  final Function(int index, LineItemModel lineItem) onLineItemChanged;
  final VoidCallback onAddLineItem;
  final Function(int index) onRemoveLineItem;

  const BasicLineItemsWidget({
    super.key,
    required this.lineItems,
    required this.currency,
    required this.isEditing,
    required this.onLineItemChanged,
    required this.onAddLineItem,
    required this.onRemoveLineItem,
  });

  double _calculateSubtotal() {
    return lineItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  Widget _buildCurrencyDisplay(double amount, {TextStyle? style}) {
    return CompactCurrencyDisplay(
      amount: amount,
      currencyCode: currency,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (lineItems.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No line items detected',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add items to see detailed breakdown',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAddLineItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Line Items (${lineItems.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (isEditing)
                  IconButton(
                    onPressed: onAddLineItem,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Item',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),

          // Line Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lineItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = lineItems[index];

              return Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing)
                            TextFormField(
                              initialValue: item.description,
                              decoration: const InputDecoration(
                                labelText: 'Item description',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                final updatedItem = item.copyWith(description: value);
                                onLineItemChanged(index, updatedItem);
                              },
                            )
                          else
                            Text(
                              item.description.isEmpty ? 'Unnamed item' : item.description,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                color: colorScheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Amount and Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isEditing)
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              initialValue: item.amount.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              onChanged: (value) {
                                final amount = double.tryParse(value) ?? 0.0;
                                final updatedItem = item.copyWith(amount: amount);
                                onLineItemChanged(index, updatedItem);
                              },
                            ),
                          )
                        else
                          _buildCurrencyDisplay(
                            item.amount,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              color: colorScheme.primary,
                            ),
                          ),
                        
                        if (isEditing) ...[
                          const SizedBox(height: 8),
                          IconButton(
                            onPressed: () => onRemoveLineItem(index),
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.red,
                            tooltip: 'Remove item',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Summary
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Subtotal (${lineItems.length} items)',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                _buildCurrencyDisplay(
                  _calculateSubtotal(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
