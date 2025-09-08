import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/subscription_config.dart';
import '../providers/subscription_provider.dart';

/// Pricing tier card widget
/// This displays a subscription tier with its features and pricing
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
    final subscriptionState = ref.watch(subscriptionProvider);
    final isLoading = subscriptionState.isLoading;
    
    return Card(
      elevation: isPopular ? 8 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isPopular
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tier name and popular badge
              _buildHeader(context),
              const SizedBox(height: 16),

              // Pricing
              _buildPricing(context),
              const SizedBox(height: 24),

              // Features list
              _buildFeatures(context),
              const SizedBox(height: 24),

              // CTA button
              _buildCTAButton(context, isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Tier icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTierColor(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTierIcon(),
            color: _getTierColor(context),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Tier name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getTierName(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'POPULAR',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _getTierDescription(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricing(BuildContext context) {
    final price = PricingInfo.getPrice(tier, billingInterval);
    final monthlyEquivalent = PricingInfo.getMonthlyEquivalentPrice(tier, billingInterval);
    final savings = PricingInfo.getAnnualSavingsPercentage(tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price == 0 ? 'Free' : '\$${price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getTierColor(context),
              ),
            ),
            if (price > 0) ...[
              const SizedBox(width: 4),
              Text(
                '/${billingInterval.value}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (billingInterval == BillingInterval.annual && price > 0) ...[
          const SizedBox(height: 4),
          Text(
            '\$${monthlyEquivalent.toStringAsFixed(2)}/month',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (savings > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Save ${savings.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final limits = TierConfig.getLimits(tier);
    final features = _getFeatureList(limits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: _getTierColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, bool isLoading) {
    String buttonText;
    bool isEnabled = !isLoading;

    if (isCurrentTier) {
      buttonText = 'Current Plan';
      isEnabled = false;
    } else if (tier == SubscriptionTier.free) {
      buttonText = 'Downgrade to Free';
    } else {
      buttonText = 'Choose ${_getTierName()}';
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isEnabled ? () => onSelectTier(tier) : null,
        style: FilledButton.styleFrom(
          backgroundColor: isCurrentTier
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : (isPopular ? Theme.of(context).colorScheme.primary : null),
          foregroundColor: isCurrentTier
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(buttonText),
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

  IconData _getTierIcon() {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.upload;
      case SubscriptionTier.pro:
        return Icons.flash_on;
      case SubscriptionTier.max:
        return Icons.workspace_premium;
    }
  }

  Color _getTierColor(BuildContext context) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.green;
      case SubscriptionTier.pro:
        return Theme.of(context).colorScheme.primary;
      case SubscriptionTier.max:
        return Colors.purple;
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
