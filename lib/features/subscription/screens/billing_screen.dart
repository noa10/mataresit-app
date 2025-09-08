import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_bar_with_actions.dart';
import '../providers/subscription_provider.dart';
import '../widgets/subscription_status_card.dart';

/// Billing management screen
/// Allows users to manage their billing preferences and payment methods
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final subscription = subscriptionState.subscription;
    final billingPreferences = subscriptionState.billingPreferences;

    return Scaffold(
      appBar: const AppBarWithActions(
        title: 'Billing & Payments',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(subscriptionProvider.notifier).refreshSubscriptionData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current subscription status
              const SubscriptionStatusCard(showUpgradeButton: false),
              const SizedBox(height: 24),

              // Billing information section
              if (subscription != null && subscription.tier.value != 'free')
                _buildBillingInfoSection(context, subscription),

              const SizedBox(height: 24),

              // Payment method section
              if (subscription != null && subscription.tier.value != 'free')
                _buildPaymentMethodSection(context),

              const SizedBox(height: 24),

              // Billing preferences section
              if (billingPreferences != null)
                _buildBillingPreferencesSection(context, billingPreferences),

              const SizedBox(height: 24),

              // Billing history section
              if (subscription != null && subscription.tier.value != 'free')
                _buildBillingHistorySection(context),

              const SizedBox(height: 24),

              // Danger zone
              if (subscription != null && subscription.tier.value != 'free')
                _buildDangerZoneSection(context, subscription),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingInfoSection(BuildContext context, subscription) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              context,
              'Current Plan',
              '${subscription.tier.value.toUpperCase()} Plan',
              Icons.workspace_premium,
            ),

            if (subscription.nextBillingDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Next Billing Date',
                _formatDate(subscription.nextBillingDate!),
                Icons.calendar_today,
              ),
            ],

            if (subscription.subscriptionEndDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Subscription End Date',
                _formatDate(subscription.subscriptionEndDate!),
                Icons.event_busy,
              ),
            ],

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openCustomerPortal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Manage in Stripe Portal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment method on file',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Manage your payment methods in the Stripe portal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _openCustomerPortal,
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingPreferencesSection(BuildContext context, billingPreferences) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Billing Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Auto-renewal'),
              subtitle: const Text('Automatically renew subscription'),
              value: billingPreferences.autoRenewalEnabled,
              onChanged: (value) {
                _updateBillingPreference('autoRenewalEnabled', value);
              },
            ),

            SwitchListTile(
              title: const Text('Billing emails'),
              subtitle: const Text('Receive billing notifications via email'),
              value: billingPreferences.billingEmailEnabled,
              onChanged: (value) {
                _updateBillingPreference('billingEmailEnabled', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingHistorySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Billing History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _openCustomerPortal,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Placeholder for billing history
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View billing history in Stripe portal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _openCustomerPortal,
                    child: const Text('Open Portal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context, subscription) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Cancel your subscription',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your subscription will remain active until the end of your billing period.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _showCancelConfirmation,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Subscription'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _openCustomerPortal() async {
    try {
      await ref.read(subscriptionProvider.notifier).openCustomerPortal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening portal: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _updateBillingPreference(String key, bool value) {
    // TODO: Implement billing preference updates
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Billing preferences update coming soon!'),
      ),
    );
  }

  Future<void> _showCancelConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? '
          'You will continue to have access until the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Subscription'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(subscriptionProvider.notifier).cancelSubscription();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription canceled successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error canceling subscription: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
