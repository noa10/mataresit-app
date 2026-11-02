import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/subscription_config.dart';
import '../../../shared/models/subscription_model.dart';
import '../providers/subscription_provider.dart';

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(subscriptionProvider.notifier)
                .refreshSubscriptionData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),

                    // Current subscription status
                    _buildCurrentPlanPanel(subscriptionState),

                    // Billing information and payment method
                    if (subscription != null &&
                        subscription.tier != SubscriptionTier.free) ...[
                      const SizedBox(height: 16),
                      _buildBillingInfoSection(context, subscription),
                      const SizedBox(height: 16),
                      _buildPaymentMethodSection(context),
                    ],

                    // Billing preferences
                    if (billingPreferences != null) ...[
                      const SizedBox(height: 16),
                      _buildBillingPreferencesSection(
                        context,
                        billingPreferences,
                      ),
                    ],

                    // Billing history and danger zone
                    if (subscription != null &&
                        subscription.tier != SubscriptionTier.free) ...[
                      const SizedBox(height: 16),
                      _buildBillingHistorySection(context),
                      const SizedBox(height: 16),
                      _buildDangerZoneSection(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back, size: 22),
          tooltip: 'Back',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUBSCRIPTION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Billing',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'InstrumentSerif',
                  fontSize: 32,
                  height: 1.05,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your plan, payment method and billing preferences.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ref.read(subscriptionProvider.notifier).refreshSubscriptionData();
          },
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh status',
        ),
      ],
    );
  }

  Widget _buildCurrentPlanPanel(SubscriptionState subscriptionState) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subscription = subscriptionState.subscription;
    final usage = subscriptionState.usage;

    if (subscriptionState.error != null && subscription == null) {
      return _LedgerPanel(
        title: 'Current plan',
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 18, color: colors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not load subscription status. ${subscriptionState.error}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => ref
                    .read(subscriptionProvider.notifier)
                    .refreshSubscriptionData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (subscription == null) {
      return _LedgerPanel(
        title: 'Current plan',
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Loading subscription status...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final limits = subscription.limits;

    return _LedgerPanel(
      title: 'Current plan',
      meta: subscription.tier.value.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tierName(subscription.tier),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: 'InstrumentSerif',
                          fontSize: 28,
                          height: 1.05,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(status: subscription.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _tierDescription(subscription.tier),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (usage != null) ...[
            Divider(height: 1, thickness: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'USAGE THIS MONTH',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  letterSpacing: 1,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            _UsageRow(
              label: 'Receipts',
              used: subscription.receiptsUsedThisMonth,
              limit: limits.monthlyReceipts,
            ),
            const _UsageDivider(),
            _UsageRow(
              label: 'Storage',
              used: usage.storageUsedMB.toInt(),
              limit: limits.storageLimitMB,
              unit: 'MB',
            ),
            const _UsageDivider(),
            _UsageRow(
              label: 'Team Members',
              used: usage.teamMembersCount,
              limit: limits.features.maxUsers,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingInfoSection(
    BuildContext context,
    SubscriptionModel subscription,
  ) {
    final colors = Theme.of(context).colorScheme;
    final rows = <Widget>[];

    void addRow(String label, String value) {
      if (rows.isNotEmpty) {
        rows.add(
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
        );
      }
      rows.add(_InfoRow(label: label, value: value));
    }

    addRow('Current Plan', '${subscription.tier.value.toUpperCase()} Plan');
    if (subscription.nextBillingDate != null) {
      addRow('Next Billing Date', _formatDate(subscription.nextBillingDate!));
    }
    if (subscription.subscriptionEndDate != null) {
      addRow(
        'Subscription End Date',
        _formatDate(subscription.subscriptionEndDate!),
      );
    }

    return _LedgerPanel(
      title: 'Billing Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows,
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openCustomerPortal,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Manage in Stripe Portal'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _LedgerPanel(
      title: 'Payment Method',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.credit_card,
                size: 20,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment method on file',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your payment methods in the Stripe portal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _openCustomerPortal,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingPreferencesSection(
    BuildContext context,
    BillingPreferences billingPreferences,
  ) {
    final colors = Theme.of(context).colorScheme;

    return _LedgerPanel(
      title: 'Billing Preferences',
      child: Column(
        children: [
          _PreferenceRow(
            title: 'Auto-renewal',
            subtitle: 'Automatically renew subscription',
            value: billingPreferences.autoRenewalEnabled,
            onChanged: (value) {
              _updateBillingPreference('autoRenewalEnabled', value);
            },
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          _PreferenceRow(
            title: 'Billing emails',
            subtitle: 'Receive billing notifications via email',
            value: billingPreferences.billingEmailEnabled,
            onChanged: (value) {
              _updateBillingPreference('billingEmailEnabled', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillingHistorySection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _LedgerPanel(
      title: 'Billing History',
      action: TextButton(
        onPressed: _openCustomerPortal,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('View All'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 22,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View billing history in Stripe portal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invoices, receipts and payment history are managed securely by Stripe.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _openCustomerPortal,
              child: const Text('Open Portal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.error),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: colors.error),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cancel your subscription',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your subscription will remain active until the end of your billing period.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _showCancelConfirmation,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel Subscription'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _tierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.max:
        return 'Max';
    }
  }

  String _tierDescription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Perfect for getting started';
      case SubscriptionTier.pro:
        return 'Best for small businesses';
      case SubscriptionTier.max:
        return 'For growing enterprises';
    }
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
      const SnackBar(content: Text('Billing preferences update coming soon!')),
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
            const SnackBar(content: Text('Subscription canceled successfully')),
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

/// Shared ledger panel: surface fill, hairline border, header and divider.
class _LedgerPanel extends StatelessWidget {
  const _LedgerPanel({
    required this.title,
    required this.child,
    this.meta,
    this.action,
  });

  final String title;
  final String? meta;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: EdgeInsets.fromLTRB(16, 11, action != null ? 8 : 16, 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    meta!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      letterSpacing: 0.8,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(width: 4), action!],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          child,
        ],
      ),
    );
  }
}

/// Label/value row used inside billing information panels.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Usage meter row matching the ledger metric styling.
class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.used,
    required this.limit,
    this.unit = '',
  });

  final String label;
  final int used;
  final int limit;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUnlimited = limit == -1;
    final percentage = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final isNearLimit = percentage > 0.8;
    final valueColor = isNearLimit ? colors.tertiary : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isUnlimited
                    ? '$used$unit'
                    : '$used$unit / ${limit == -1 ? '∞' : '$limit$unit'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
          if (!isUnlimited) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 4,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isNearLimit ? colors.tertiary : colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageDivider extends StatelessWidget {
  const _UsageDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Label/switch row for billing preferences.
class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Small uppercase mono pill used for subscription status.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Color background = colors.primaryContainer;
    Color foreground = colors.onPrimaryContainer;
    String label = 'ACTIVE';

    switch (status) {
      case SubscriptionStatus.active:
        background = colors.primaryContainer;
        foreground = colors.onPrimaryContainer;
        label = 'ACTIVE';
        break;
      case SubscriptionStatus.trialing:
        background = colors.tertiaryContainer;
        foreground = colors.onTertiaryContainer;
        label = 'TRIAL';
        break;
      case SubscriptionStatus.pastDue:
        background = colors.tertiaryContainer;
        foreground = colors.onTertiaryContainer;
        label = 'PAST DUE';
        break;
      case SubscriptionStatus.canceled:
        background = colors.errorContainer;
        foreground = colors.onErrorContainer;
        label = 'CANCELED';
        break;
      case SubscriptionStatus.incomplete:
        background = colors.errorContainer;
        foreground = colors.onErrorContainer;
        label = 'INCOMPLETE';
        break;
      case SubscriptionStatus.incompleteExpired:
        background = colors.errorContainer;
        foreground = colors.onErrorContainer;
        label = 'EXPIRED';
        break;
      case SubscriptionStatus.unpaid:
        background = colors.errorContainer;
        foreground = colors.onErrorContainer;
        label = 'UNPAID';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
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
