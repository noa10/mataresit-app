import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/subscription_config.dart';
import '../../../shared/utils/currency_utils.dart';
import '../providers/subscription_provider.dart';

/// Pricing tier card widget
/// This displays a subscription tier with its features and pricing using the
/// ledger styling shared with the web workspace.
class PricingTierCard extends ConsumerWidget {
  final SubscriptionTier tier;
  final BillingInterval billingInterval;
  final bool isCurrentTier;
  final bool isPopular;
  final Function(SubscriptionTier) onSelectTier;

  const PricingTierCard({
    super.key,
    required this.tier,
    required this.billingInterval,
    required this.isCurrentTier,
    this.isPopular = false,
    required this.onSelectTier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLoading = ref.watch(subscriptionProvider).isLoading;
    final isHighlighted = isCurrentTier || isPopular;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 14),
          _buildPricing(context),
          const SizedBox(height: 16),
          _buildCTAButton(context, isLoading),
          const SizedBox(height: 18),
          Container(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 14),
          _buildFeatures(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTierName(),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'InstrumentSerif',
                  fontSize: 28,
                  height: 1.05,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getTierDescription(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (isCurrentTier || isPopular) ...[
          const SizedBox(width: 10),
          _MonoPill(
            label: isCurrentTier ? 'CURRENT' : 'POPULAR',
            background: colors.primaryContainer,
            foreground: colors.onPrimaryContainer,
          ),
        ],
      ],
    );
  }

  Widget _buildPricing(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final price = PricingInfo.getPrice(tier, billingInterval);
    final isFree = tier == SubscriptionTier.free;
    final isAnnual = billingInterval == BillingInterval.annual;

    final priceText = isFree
        ? 'Free'
        : CurrencyUtils.formatCurrency(price, 'MYR', precision: 0);
    final periodText = isFree
        ? '/ forever'
        : isAnnual
        ? '/ year'
        : '/ month';

    final noteText = isFree
        ? 'No card required'
        : isAnnual
        ? 'Billed annually · '
              '${CurrencyUtils.formatCurrency(PricingInfo.getMonthlyEquivalentPrice(tier, billingInterval), 'MYR')} / month'
        : 'Billed monthly';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                priceText,
                maxLines: 1,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontWeight: FontWeight.w500,
                  fontSize: 32,
                  height: 1,
                  letterSpacing: -0.5,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                periodText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          noteText,
          maxLines: 2,
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'IBMPlexMono',
            fontSize: 10.5,
            letterSpacing: 0.2,
            height: 1.4,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final limits = TierConfig.getLimits(tier);
    final features = _getFeatureList(limits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.check, size: 15, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isFree = tier == SubscriptionTier.free;
    final isEnabled = !isLoading && !isCurrentTier;

    final label = isCurrentTier
        ? 'Current Plan'
        : isFree
        ? 'Downgrade to Free'
        : 'Choose ${_getTierName()}';

    final child = isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.onSurfaceVariant,
            ),
          )
        : Text(label);

    final onPressed = isEnabled ? () => onSelectTier(tier) : null;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: isFree && !isCurrentTier
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: child,
            ),
    );
  }

  String _getTierName() {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.max:
        return 'Max';
    }
  }

  String _getTierDescription() {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Perfect for getting started';
      case SubscriptionTier.pro:
        return 'Best for small businesses';
      case SubscriptionTier.max:
        return 'For growing enterprises';
    }
  }

  List<String> _getFeatureList(SubscriptionLimits limits) {
    final features = <String>[];

    // Receipt limits
    if (limits.monthlyReceipts == -1) {
      features.add('Unlimited receipts per month');
    } else {
      features.add('${limits.monthlyReceipts} receipts per month');
    }

    // Storage limits
    if (limits.storageLimitMB == -1) {
      features.add('Unlimited storage');
    } else {
      final storageGB = (limits.storageLimitMB / 1024).toStringAsFixed(0);
      features.add('${storageGB}GB storage');
    }

    // Batch upload
    features.add('Batch upload up to ${limits.batchUploadLimit} receipts');

    // Data retention
    features.add('${limits.retentionDays} days data retention');

    // Feature-specific items
    if (limits.features.versionControl) {
      features.add('Version control');
    }

    if (limits.features.customBranding) {
      features.add('Custom branding');
    }

    if (limits.features.apiAccess) {
      features.add('API access');
    }

    // Team features
    if (limits.features.maxUsers == -1) {
      features.add('Unlimited team members');
    } else if (limits.features.maxUsers > 1) {
      features.add('Up to ${limits.features.maxUsers} team members');
    } else {
      features.add('Single user');
    }

    // Support level
    switch (limits.features.supportLevel) {
      case 'priority':
        features.add('Priority support');
        break;
      case 'standard':
        features.add('Standard support');
        break;
      default:
        features.add('Basic support');
    }

    return features;
  }
}

/// Small uppercase mono pill used for plan and status markers.
class _MonoPill extends StatelessWidget {
  const _MonoPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'IBMPlexMono',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: foreground,
        ),
      ),
    );
  }
}
