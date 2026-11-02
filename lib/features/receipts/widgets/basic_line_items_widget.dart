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
    final colors = theme.colorScheme;

    if (lineItems.isEmpty) {
      return _buildPanel(
        context,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No line items detected',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Add items to see detailed breakdown',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAddLineItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildPanel(
      context,
      header: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Line Items (${lineItems.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currency.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (isEditing)
            IconButton(
              onPressed: onAddLineItem,
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'Add Item',
              style: IconButton.styleFrom(
                foregroundColor: colors.primary,
                minimumSize: const Size(44, 44),
              ),
            ),
        ],
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lineItems.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: colors.outlineVariant),
            itemBuilder: (context, index) {
              final item = lineItems[index];

              return Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Details
                    Expanded(
                      child: isEditing
                          ? TextFormField(
                              key: ValueKey('line-item-description-${item.id}'),
                              initialValue: item.description,
                              decoration: const InputDecoration(
                                labelText: 'Item description',
                              ),
                              onChanged: (value) {
                                final updatedItem = item.copyWith(
                                  description: value,
                                );
                                onLineItemChanged(index, updatedItem);
                              },
                            )
                          : Text(
                              item.description.isEmpty
                                  ? 'Unnamed item'
                                  : item.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),

                    // Amount and Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isEditing)
                          SizedBox(
                            width: 112,
                            child: TextFormField(
                              key: ValueKey('line-item-amount-${item.id}'),
                              initialValue: item.amount.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              onChanged: (value) {
                                final amount = double.tryParse(value) ?? 0.0;
                                final updatedItem = item.copyWith(
                                  amount: amount,
                                );
                                onLineItemChanged(index, updatedItem);
                              },
                            ),
                          )
                        else
                          _buildCurrencyDisplay(
                            item.amount,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'IBMPlexMono',
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),

                        if (isEditing) ...[
                          const SizedBox(height: 4),
                          IconButton(
                            onPressed: () => onRemoveLineItem(index),
                            icon: const Icon(Icons.remove_circle_outline),
                            color: colors.error,
                            tooltip: 'Remove item',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
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
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Subtotal (${lineItems.length} items)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildCurrencyDisplay(
                  _calculateSubtotal(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context, {
    required Widget child,
    Widget? header,
  }) {
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
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: header,
            ),
            Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          ],
          child,
        ],
      ),
    );
  }
}
