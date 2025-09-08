import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/subscription_config.dart';
import '../../../core/services/stripe_service.dart';
import '../../../shared/widgets/app_bar_with_actions.dart';
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
      appBar: AppBarWithActions(
        title: 'Pricing Plans',
        actions: [
          if (_showComparison)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _showComparison = false),
              tooltip: 'Close comparison',
            )
          else
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: () => setState(() => _showComparison = true),
              tooltip: 'Compare features',
            ),
        ],
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
              // Header section
              _buildHeader(),
              const SizedBox(height: 24),

              // Billing interval toggle
              Center(
                child: BillingIntervalToggle(
                  selectedInterval: _selectedInterval,
                  onChanged: (interval) {
                    setState(() => _selectedInterval = interval);
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Show either pricing cards or feature comparison
              if (_showComparison)
                FeatureComparisonTable(
                  currentTier: currentTier,
                  billingInterval: _selectedInterval,
                )
              else
                _buildPricingCards(currentTier),

              const SizedBox(height: 32),

              // FAQ section
              _buildFAQSection(),

              const SizedBox(height: 32),

              // Contact section
              _buildContactSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the perfect plan for your receipt management needs. Upgrade or downgrade anytime.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
        const SizedBox(height: 16),

        // Pro tier card
        PricingTierCard(
          tier: SubscriptionTier.pro,
          billingInterval: _selectedInterval,
          isCurrentTier: currentTier == SubscriptionTier.pro,
          isPopular: true,
          onSelectTier: _handleTierSelection,
        ),
        const SizedBox(height: 16),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Need Help Choosing?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our team is here to help you find the perfect plan for your needs.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.email),
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
          await subscriptionNotifier.createCheckoutSession(tier, _selectedInterval);
        } else if (StripeService.isDowngrade(currentTier, tier)) {
          // This is a downgrade - show confirmation
          final confirmed = await _showDowngradeConfirmation(tier);
          if (confirmed) {
            await subscriptionNotifier.downgradeSubscription(tier);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully downgraded to ${tier.value.toUpperCase()} plan'),
                ),
              );
            }
          }
        } else {
          // Same tier - show message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You are already on the ${tier.value.toUpperCase()} plan'),
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
    ) ?? false;
  }

  void _contactSupport() {
    // TODO: Implement contact support functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact support feature coming soon!'),
      ),
    );
  }
}
