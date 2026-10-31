import 'package:flutter/material.dart';
import '../../../core/config/subscription_config.dart';

/// Billing interval toggle widget
/// Allows users to switch between monthly and annual billing.
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
    final colors = Theme.of(context).colorScheme;
    final savings = PricingInfo.getAnnualSavingsPercentage(
      SubscriptionTier.pro,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(8),
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
            savingsLabel: savings > 0
                ? 'SAVE ${savings.toStringAsFixed(0)}%'
                : null,
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
    String? savingsLabel,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? colors.onSurface : colors.surface,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => onChanged(interval),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colors.surface
                        : colors.onSurfaceVariant,
                  ),
                ),
                if (savingsLabel != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      savingsLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
