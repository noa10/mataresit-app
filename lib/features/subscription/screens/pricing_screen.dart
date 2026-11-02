import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/subscription_config.dart';
import '../../../core/services/stripe_service.dart';
import '../providers/subscription_provider.dart';
import '../widgets/pricing_tier_card.dart';
import '../widgets/billing_interval_toggle.dart';
import '../widgets/feature_comparison_table.dart';

/// Pricing screen for subscription plans
/// This mirrors the React app's PricingPage component
class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  BillingInterval _selectedInterval = BillingInterval.monthly;
  bool _showComparison = false;

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final currentTier = subscriptionState.currentTier;

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

                    // Billing interval toggle
                    Center(
                      child: BillingIntervalToggle(
                        selectedInterval: _selectedInterval,
                        onChanged: (interval) {
                          setState(() => _selectedInterval = interval);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Show either pricing cards or feature comparison
                    if (_showComparison)
                      FeatureComparisonTable(
                        currentTier: currentTier,
                        billingInterval: _selectedInterval,
                      )
                    else
                      _buildPricingCards(currentTier),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Prices in MYR, billed securely through Stripe.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          letterSpacing: 0.2,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // FAQ section
                    _buildFAQSection(),

                    const SizedBox(height: 24),

                    // Contact section
                    _buildContactSection(),
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
                'Plans',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'InstrumentSerif',
                  fontSize: 32,
                  height: 1.05,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the plan that fits your workflow. Upgrade or downgrade anytime.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _showComparison = !_showComparison),
          icon: Icon(
            _showComparison ? Icons.close : Icons.compare_arrows,
            size: 20,
          ),
          tooltip: _showComparison ? 'Close comparison' : 'Compare features',
        ),
      ],
    );
  }

  Widget _buildPricingCards(SubscriptionTier currentTier) {
    return Column(
      children: [
        // Free tier card
        PricingTierCard(
          tier: SubscriptionTier.free,
          billingInterval: _selectedInterval,
          isCurrentTier: currentTier == SubscriptionTier.free,
          onSelectTier: _handleTierSelection,
        ),
        const SizedBox(height: 12),

        // Pro tier card
        PricingTierCard(
          tier: SubscriptionTier.pro,
          billingInterval: _selectedInterval,
          isCurrentTier: currentTier == SubscriptionTier.pro,
          isPopular: true,
          onSelectTier: _handleTierSelection,
        ),
        const SizedBox(height: 12),

        // Max tier card
        PricingTierCard(
          tier: SubscriptionTier.max,
          billingInterval: _selectedInterval,
          isCurrentTier: currentTier == SubscriptionTier.max,
          onSelectTier: _handleTierSelection,
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAQ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Questions',
          style: theme.textTheme.displaySmall?.copyWith(
            fontFamily: 'InstrumentSerif',
            fontSize: 30,
            height: 1.05,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Billing, plans and payments.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Column(
            children: [
              _buildFAQItem(
                'Can I change my plan anytime?',
                'Yes, you can upgrade or downgrade your plan at any time. Changes take effect immediately for upgrades, or at the end of your billing cycle for downgrades.',
              ),
              _buildFAQItem(
                'What happens to my data if I downgrade?',
                'Your data is always safe. If you exceed the limits of a lower tier, you\'ll have read-only access until you upgrade or reduce your usage.',
              ),
              _buildFAQItem(
                'Do you offer refunds?',
                'We offer a 30-day money-back guarantee for all paid plans. Contact support for assistance with refunds.',
              ),
              _buildFAQItem(
                'Is my payment information secure?',
                'Yes, all payments are processed securely through Stripe. We never store your payment information on our servers.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          childrenPadding: const EdgeInsets.fromLTRB(4, 0, 16, 14),
          iconColor: colors.primary,
          collapsedIconColor: colors.onSurfaceVariant,
          title: Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.support_agent,
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
                      'Need Help Choosing?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Our team is here to help you find the perfect plan for your needs.',
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
          FilledButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.mail_outline, size: 18),
            label: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTierSelection(SubscriptionTier tier) async {
    final subscriptionNotifier = ref.read(subscriptionProvider.notifier);
    final currentTier = ref.read(currentSubscriptionTierProvider);

    try {
      if (tier == SubscriptionTier.free) {
        // Handle free tier selection (downgrade)
        if (currentTier != SubscriptionTier.free) {
          final confirmed = await _showDowngradeConfirmation(tier);
          if (confirmed) {
            await subscriptionNotifier.downgradeSubscription(tier);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Successfully downgraded to Free plan'),
                ),
              );
            }
          }
        }
      } else {
        // Handle paid tier selection (upgrade or change)
        if (StripeService.isUpgrade(currentTier, tier)) {
          // This is an upgrade - create checkout session
          await subscriptionNotifier.createCheckoutSession(
            tier,
            _selectedInterval,
          );
        } else if (StripeService.isDowngrade(currentTier, tier)) {
          // This is a downgrade - show confirmation
          final confirmed = await _showDowngradeConfirmation(tier);
          if (confirmed) {
            await subscriptionNotifier.downgradeSubscription(tier);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Successfully downgraded to ${tier.value.toUpperCase()} plan',
                  ),
                ),
              );
            }
          }
        } else {
          // Same tier - show message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You are already on the ${tier.value.toUpperCase()} plan',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _showDowngradeConfirmation(SubscriptionTier targetTier) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Downgrade'),
            content: Text(
              'Are you sure you want to downgrade to the ${targetTier.value.toUpperCase()} plan? '
              'This change will take effect at the end of your current billing cycle.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _contactSupport() {
    // TODO: Implement contact support functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support feature coming soon!')),
    );
  }
}
