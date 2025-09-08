import 'package:flutter/material.dart';
import '../../../core/config/subscription_config.dart';

/// Billing interval toggle widget
/// Allows users to switch between monthly and annual billing
class BillingIntervalToggle extends StatelessWidget {
  final BillingInterval selectedInterval;
  final Function(BillingInterval) onChanged;

  const BillingIntervalToggle({
    super.key,
    required this.selectedInterval,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context,
            BillingInterval.monthly,
            'Monthly',
            selectedInterval == BillingInterval.monthly,
          ),
          _buildToggleButton(
            context,
            BillingInterval.annual,
            'Annual',
            selectedInterval == BillingInterval.annual,
            showSavings: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    BillingInterval interval,
    String label,
    bool isSelected, {
    bool showSavings = false,
  }) {
    return GestureDetector(
      onTap: () => onChanged(interval),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (showSavings && isSelected) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Save 10%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
