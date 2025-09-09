import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/subscription_config.dart';
import '../../features/subscription/providers/subscription_provider.dart';

/// Subscription guard for enforcing subscription limits
/// This provides methods to check and enforce subscription limits throughout the app
class SubscriptionGuard {
  /// Check if user can upload receipts
  static Future<bool> canUploadReceipts(WidgetRef ref) async {
    final subscriptionNotifier = ref.read(subscriptionProvider.notifier);
    return await subscriptionNotifier.canUploadReceipts();
  }

  /// Check if user can perform batch upload
  static Future<bool> canBatchUpload(WidgetRef ref, int receiptCount) async {
    final subscriptionState = ref.read(subscriptionProvider);
    final subscription = subscriptionState.subscription;

    if (subscription == null) return false;

    // Check if user has enough remaining receipts
    if (subscription.remainingReceipts < receiptCount &&
        subscription.limits.monthlyReceipts != -1) {
      return false;
    }

    // Check batch upload limit
    return receiptCount <= subscription.limits.batchUploadLimit;
  }

  /// Check if a feature is available
  static Future<bool> isFeatureAvailable(WidgetRef ref, String feature) async {
    final subscriptionNotifier = ref.read(subscriptionProvider.notifier);
    return await subscriptionNotifier.isFeatureAvailable(feature);
  }

  /// Check if user can add team members
  static Future<bool> canAddTeamMembers(WidgetRef ref) async {
    final subscriptionState = ref.read(subscriptionProvider);
    final subscription = subscriptionState.subscription;
    final usage = subscriptionState.usage;

    if (subscription == null || usage == null) return false;

    final maxUsers = subscription.limits.features.maxUsers;
    if (maxUsers == -1) return true; // Unlimited

    return usage.teamMembersCount < maxUsers;
  }

  /// Check if user can access API
  static Future<bool> canAccessAPI(WidgetRef ref) async {
    return await isFeatureAvailable(ref, 'apiAccess');
  }

  /// Check if user can use custom branding
  static Future<bool> canUseCustomBranding(WidgetRef ref) async {
    return await isFeatureAvailable(ref, 'customBranding');
  }

  /// Check if user can use version control
  static Future<bool> canUseVersionControl(WidgetRef ref) async {
    return await isFeatureAvailable(ref, 'versionControl');
  }

  /// Show upgrade dialog if feature is not available
  static Future<bool> showUpgradeDialogIfNeeded(
    BuildContext context,
    WidgetRef ref,
    String feature,
  ) async {
    final isAvailable = await isFeatureAvailable(ref, feature);

    if (!isAvailable && context.mounted) {
      final shouldUpgrade = await showDialog<bool>(
        context: context,
        builder: (context) => UpgradeDialog(feature: feature),
      );

      if (shouldUpgrade == true && context.mounted) {
        context.push('/pricing');
      }

      return false;
    }

    return true;
  }

  /// Show receipt limit dialog if at limit
  static Future<bool> showReceiptLimitDialogIfNeeded(
    BuildContext context,
    WidgetRef ref, {
    int additionalReceipts = 1,
  }) async {
    final subscriptionState = ref.read(subscriptionProvider);
    final subscription = subscriptionState.subscription;

    if (subscription == null) return false;

    final canUpload =
        subscription.remainingReceipts >= additionalReceipts ||
        subscription.limits.monthlyReceipts == -1;

    if (!canUpload) {
      final shouldUpgrade = await showDialog<bool>(
        context: context,
        builder: (context) => ReceiptLimitDialog(
          remainingReceipts: subscription.remainingReceipts,
          requestedReceipts: additionalReceipts,
          currentTier: subscription.tier,
        ),
      );

      if (shouldUpgrade == true && context.mounted) {
        context.push('/pricing');
      }

      return false;
    }

    return true;
  }

  /// Show batch upload limit dialog if exceeds limit
  static Future<bool> showBatchLimitDialogIfNeeded(
    BuildContext context,
    WidgetRef ref,
    int receiptCount,
  ) async {
    final subscriptionState = ref.read(subscriptionProvider);
    final subscription = subscriptionState.subscription;

    if (subscription == null) return false;

    final batchLimit = subscription.limits.batchUploadLimit;

    if (receiptCount > batchLimit) {
      final shouldUpgrade = await showDialog<bool>(
        context: context,
        builder: (context) => BatchLimitDialog(
          requestedCount: receiptCount,
          batchLimit: batchLimit,
          currentTier: subscription.tier,
        ),
      );

      if (shouldUpgrade == true && context.mounted) {
        context.push('/pricing');
      }

      return false;
    }

    return true;
  }

  /// Get required tier for a feature
  static SubscriptionTier getRequiredTierForFeature(String feature) {
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

/// Upgrade dialog widget
class UpgradeDialog extends StatelessWidget {
  final String feature;

  const UpgradeDialog({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final requiredTier = SubscriptionGuard.getRequiredTierForFeature(feature);

    return AlertDialog(
      title: const Text('Feature Not Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This feature requires a ${requiredTier.value.toUpperCase()} subscription or higher.',
          ),
          const SizedBox(height: 16),
          Text(
            'Upgrade now to unlock:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._getFeatureList(requiredTier).map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Upgrade Now'),
        ),
      ],
    );
  }

  List<String> _getFeatureList(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.pro:
        return [
          '500 receipts per month',
          'Version control',
          'Custom branding',
          'Priority support',
        ];
      case SubscriptionTier.max:
        return [
          'Unlimited receipts',
          'API access',
          'Unlimited team members',
          'Advanced integrations',
        ];
      default:
        return [];
    }
  }
}

/// Receipt limit dialog widget
class ReceiptLimitDialog extends StatelessWidget {
  final int remainingReceipts;
  final int requestedReceipts;
  final SubscriptionTier currentTier;

  const ReceiptLimitDialog({
    super.key,
    required this.remainingReceipts,
    required this.requestedReceipts,
    required this.currentTier,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Receipt Limit Reached'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have $remainingReceipts receipts remaining this month, '
            'but you\'re trying to upload $requestedReceipts receipts.',
          ),
          const SizedBox(height: 16),
          Text(
            'Upgrade to continue uploading receipts:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (currentTier == SubscriptionTier.free) ...[
            _buildUpgradeOption(context, 'Pro Plan', '500 receipts/month'),
            _buildUpgradeOption(context, 'Max Plan', 'Unlimited receipts'),
          ] else ...[
            _buildUpgradeOption(context, 'Max Plan', 'Unlimited receipts'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Upgrade Now'),
        ),
      ],
    );
  }

  Widget _buildUpgradeOption(
    BuildContext context,
    String planName,
    String benefit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.arrow_upward,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text('$planName: $benefit'),
        ],
      ),
    );
  }
}

/// Batch limit dialog widget
class BatchLimitDialog extends StatelessWidget {
  final int requestedCount;
  final int batchLimit;
  final SubscriptionTier currentTier;

  const BatchLimitDialog({
    super.key,
    required this.requestedCount,
    required this.batchLimit,
    required this.currentTier,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batch Upload Limit Exceeded'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'re trying to upload $requestedCount receipts, '
            'but your current plan allows up to $batchLimit receipts per batch.',
          ),
          const SizedBox(height: 16),
          Text(
            'Options:',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('• Upload in smaller batches of $batchLimit receipts'),
          Text('• Upgrade for higher batch limits'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Upgrade Now'),
        ),
      ],
    );
  }
}
