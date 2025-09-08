import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/subscription_config.dart';
import '../providers/subscription_provider.dart';

/// Subscription status card widget
/// Displays current subscription status, usage, and limits
class SubscriptionStatusCard extends ConsumerWidget {
  final bool showUpgradeButton;
  final bool compact;

  const SubscriptionStatusCard({
    super.key,
    this.showUpgradeButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final subscription = subscriptionState.subscription;
    final usage = subscriptionState.usage;

    if (subscription == null) {
      return _buildLoadingCard(context);
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tier info
            _buildHeader(context, ref, subscription),
            
            if (!compact) ...[
              const SizedBox(height: 16),

              // Usage information
              if (usage != null) _buildUsageSection(context, subscription, usage),

              if (showUpgradeButton) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context, subscription),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading subscription status...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, subscription) {
    final tier = subscription.tier;
    final status = subscription.status;

    return Row(
      children: [
        // Tier icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTierColor(tier).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTierIcon(tier),
            color: _getTierColor(tier),
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),

        // Tier name and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getTierName(tier),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context, status),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(
                  _getTierDescription(tier),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(subscriptionProvider.notifier).refreshSubscriptionData();
          },
          tooltip: 'Refresh status',
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, SubscriptionStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case SubscriptionStatus.active:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        text = 'Active';
        break;
      case SubscriptionStatus.trialing:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        text = 'Trial';
        break;
      case SubscriptionStatus.pastDue:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
        text = 'Past Due';
        break;
      case SubscriptionStatus.canceled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        text = 'Canceled';
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        text = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUsageSection(BuildContext context, subscription, usage) {
    final limits = subscription.limits;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage This Month',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Receipts usage
        _buildUsageItem(
          context,
          'Receipts',
          subscription.receiptsUsedThisMonth,
          limits.monthlyReceipts,
          Icons.receipt,
        ),

        const SizedBox(height: 8),

        // Storage usage
        _buildUsageItem(
          context,
          'Storage',
          usage.storageUsedMB.toInt(),
          limits.storageLimitMB,
          Icons.storage,
          unit: 'MB',
        ),

        const SizedBox(height: 8),

        // Team members
        _buildUsageItem(
          context,
          'Team Members',
          usage.teamMembersCount,
          limits.features.maxUsers,
          Icons.people,
        ),
      ],
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    String label,
    int used,
    int limit,
    IconData icon, {
    String unit = '',
  }) {
    final isUnlimited = limit == -1;
    final percentage = isUnlimited ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final isNearLimit = percentage > 0.8;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    isUnlimited
                        ? '$used$unit'
                        : '$used$unit / ${limit == -1 ? '∞' : '$limit$unit'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isNearLimit ? Colors.orange[700] : null,
                    ),
                  ),
                ],
              ),
              if (!isUnlimited) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isNearLimit ? Colors.orange : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildActionButtons(BuildContext context, subscription) {
    final tier = subscription.tier;
    
    return Row(
      children: [
        if (tier != SubscriptionTier.max) ...[
          Expanded(
            child: FilledButton.icon(
              onPressed: () => context.push('/pricing'),
              icon: const Icon(Icons.upgrade),
              label: Text(tier == SubscriptionTier.free ? 'Upgrade' : 'Upgrade to Max'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (tier != SubscriptionTier.free) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/billing'),
              icon: const Icon(Icons.settings),
              label: const Text('Manage'),
            ),
          ),
        ],
      ],
    );
  }

  String _getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free Plan';
      case SubscriptionTier.pro:
        return 'Pro Plan';
      case SubscriptionTier.max:
        return 'Max Plan';
    }
  }

  String _getTierDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Perfect for getting started';
      case SubscriptionTier.pro:
        return 'Best for small businesses';
      case SubscriptionTier.max:
        return 'For growing enterprises';
    }
  }

  IconData _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.upload;
      case SubscriptionTier.pro:
        return Icons.flash_on;
      case SubscriptionTier.max:
        return Icons.workspace_premium;
    }
  }

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.green;
      case SubscriptionTier.pro:
        return Colors.blue;
      case SubscriptionTier.max:
        return Colors.purple;
    }
  }


}
