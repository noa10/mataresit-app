import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/subscription_config.dart';
import '../providers/subscription_provider.dart';

/// Subscription limits widget
/// Shows usage limits and upgrade prompts throughout the app
class SubscriptionLimitsWidget extends ConsumerWidget {
  final String? feature;
  final bool showUpgradePrompt;
  final bool compact;

  const SubscriptionLimitsWidget({
    super.key,
    this.feature,
    this.showUpgradePrompt = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final subscription = subscriptionState.subscription;
    final usage = subscriptionState.usage;

    if (subscription == null || usage == null) {
      return const SizedBox.shrink();
    }

    // If a specific feature is requested, check if it's available
    if (feature != null && !subscription.isFeatureAvailable(feature!)) {
      return _buildFeatureUnavailableWidget(context, subscription);
    }

    // Show receipt limits if near or at limit
    if (subscription.receiptUsagePercentage > 0.8) {
      return _buildReceiptLimitWidget(context, subscription);
    }

    return const SizedBox.shrink();
  }

  Widget _buildFeatureUnavailableWidget(BuildContext context, subscription) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Feature Not Available',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    'This feature requires ${_getRequiredTierForFeature(feature!).value.toUpperCase()} plan or higher.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showUpgradePrompt) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/pricing'),
              child: const Text('Upgrade'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptLimitWidget(BuildContext context, subscription) {
    final remaining = subscription.remainingReceipts;
    final total = subscription.limits.monthlyReceipts;
    final used = subscription.receiptsUsedThisMonth;
    final percentage = subscription.receiptUsagePercentage;
    
    final isAtLimit = remaining <= 0;
    final isNearLimit = percentage > 0.9;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAtLimit
            ? Theme.of(context).colorScheme.errorContainer
            : isNearLimit
                ? Colors.orange.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAtLimit
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
              : isNearLimit
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isAtLimit ? Icons.warning : Icons.info,
                color: isAtLimit
                    ? Theme.of(context).colorScheme.error
                    : isNearLimit
                        ? Colors.orange[700]
                        : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAtLimit
                      ? 'Receipt Limit Reached'
                      : isNearLimit
                          ? 'Approaching Receipt Limit'
                          : 'Receipt Usage',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isAtLimit
                        ? Theme.of(context).colorScheme.error
                        : isNearLimit
                            ? Colors.orange[700]
                            : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showUpgradePrompt && subscription.tier != SubscriptionTier.max) ...[
                TextButton(
                  onPressed: () => context.push('/pricing'),
                  child: const Text('Upgrade'),
                ),
              ],
            ],
          ),
          
          if (!compact) ...[
            const SizedBox(height: 8),
            
            // Usage bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAtLimit
                          ? Theme.of(context).colorScheme.error
                          : isNearLimit
                              ? Colors.orange
                              : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  total == -1 ? '$used' : '$used / $total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              isAtLimit
                  ? 'You\'ve reached your monthly receipt limit. Upgrade to continue uploading.'
                  : isNearLimit
                      ? 'You have $remaining receipts remaining this month.'
                      : 'You have $remaining receipts remaining this month.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isAtLimit
                    ? Theme.of(context).colorScheme.error
                    : isNearLimit
                        ? Colors.orange[700]
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  SubscriptionTier _getRequiredTierForFeature(String feature) {
    switch (feature) {
      case 'versionControl':
      case 'customBranding':
        return SubscriptionTier.pro;
      case 'apiAccess':
      case 'unlimitedUsers':
        return SubscriptionTier.max;
      default:
        return SubscriptionTier.pro;
    }
  }
}

/// Upgrade prompt widget
/// Shows a simple upgrade prompt with call-to-action
class UpgradePromptWidget extends ConsumerWidget {
  final String title;
  final String description;
  final String buttonText;
  final bool compact;

  const UpgradePromptWidget({
    super.key,
    required this.title,
    required this.description,
    this.buttonText = 'Upgrade Now',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTier = ref.watch(currentSubscriptionTierProvider);

    // Don't show upgrade prompt if already on max tier
    if (currentTier == SubscriptionTier.max) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: compact ? _buildCompactLayout(context) : _buildFullLayout(context),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.star,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.push('/pricing'),
          child: Text(buttonText),
        ),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.push('/pricing'),
          child: Text(buttonText),
        ),
      ],
    );
  }
}
