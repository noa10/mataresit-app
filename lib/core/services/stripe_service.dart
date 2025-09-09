import 'dart:async';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/models/subscription_model.dart';
import '../config/subscription_config.dart';
import '../network/supabase_client.dart';
import 'subscription_service.dart';

/// Service for handling Stripe payment operations
/// This mirrors the React app's StripeContext functionality
class StripeService {
  static final Logger _logger = Logger();
  static final SupabaseClient _client = SupabaseService.client;

  /// Stream controller for loading state
  static final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();

  /// Stream for loading state
  static Stream<bool> get loadingStream => _loadingController.stream;

  /// Current loading state
  static bool _isLoading = false;
  static bool get isLoading => _isLoading;

  /// Set loading state
  static void _setLoading(bool loading) {
    _isLoading = loading;
    _loadingController.add(loading);
  }

  /// Create Stripe checkout session
  static Future<void> createCheckoutSession(
    SubscriptionTier tier,
    BillingInterval billingInterval,
  ) async {
    if (tier == SubscriptionTier.free) {
      throw Exception('Cannot create checkout session for free tier');
    }

    try {
      _setLoading(true);
      _logger.i(
        'Creating checkout session for ${tier.value} ${billingInterval.value}',
      );

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get price ID for the tier and billing interval
      final priceId = StripePriceIds.getPriceId(tier, billingInterval);
      if (priceId == null) {
        throw Exception(
          'No price ID found for ${tier.value} ${billingInterval.value}',
        );
      }

      _logger.d('Using price ID: $priceId');

      // Call the create-checkout-session edge function
      final response = await _client.functions.invoke(
        'create-checkout-session',
        body: {'priceId': priceId, 'billingInterval': billingInterval.value},
      );

      final data = response.data as Map<String, dynamic>;
      final checkoutUrl = data['url'] as String?;

      if (checkoutUrl == null) {
        throw Exception('No checkout URL returned from server');
      }

      _logger.i('Checkout session created, redirecting to: $checkoutUrl');

      // Launch the checkout URL
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } catch (e) {
      _logger.e('Error creating checkout session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Create Stripe customer portal session
  static Future<void> createPortalSession() async {
    try {
      _setLoading(true);
      _logger.i('Creating customer portal session');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Call the manage-subscription edge function
      final response = await _client.functions.invoke(
        'manage-subscription',
        body: {'action': 'create_portal_session'},
      );

      final data = response.data as Map<String, dynamic>;
      final portalUrl = data['url'] as String?;

      if (portalUrl == null) {
        throw Exception('No portal URL returned from server');
      }

      _logger.i('Portal session created, redirecting to: $portalUrl');

      // Launch the portal URL
      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch portal URL');
      }
    } catch (e) {
      _logger.e('Error creating portal session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription
  static Future<void> cancelSubscription() async {
    try {
      _setLoading(true);
      _logger.i('Canceling subscription');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Call the manage-subscription edge function
      await _client.functions.invoke(
        'manage-subscription',
        body: {'action': 'cancel_subscription'},
      );

      _logger.i('Subscription canceled successfully');

      // Refresh subscription status
      await SubscriptionService.refreshSubscriptionStatus();
    } catch (e) {
      _logger.e('Error canceling subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Downgrade subscription to a lower tier
  static Future<void> downgradeSubscription(
    SubscriptionTier targetTier, {
    bool immediate = false,
  }) async {
    try {
      _setLoading(true);
      _logger.i('Downgrading subscription to ${targetTier.value}');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Call the manage-subscription edge function
      await _client.functions.invoke(
        'manage-subscription',
        body: {
          'action': 'downgrade_subscription',
          'targetTier': targetTier.value,
          'immediate': immediate,
        },
      );

      _logger.i('Subscription downgraded successfully');

      // Refresh subscription status
      await SubscriptionService.refreshSubscriptionStatus();
    } catch (e) {
      _logger.e('Error downgrading subscription: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get billing preferences
  static Future<BillingPreferences> getBillingPreferences() async {
    try {
      _logger.i('Fetching billing preferences');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get basic profile data (billing preference columns don't exist yet)
      await _client.from('profiles').select('id').eq('id', user.id).single();

      _logger.d('Profile exists, returning default billing preferences');

      // Return default billing preferences since columns don't exist in database
      return BillingPreferences.defaults();
    } catch (e) {
      _logger.e('Error fetching billing preferences: $e');
      return BillingPreferences.defaults();
    }
  }

  /// Update billing preferences
  static Future<void> updateBillingPreferences(
    BillingPreferences preferences,
  ) async {
    try {
      _setLoading(true);
      _logger.i('Updating billing preferences');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Update billing preferences in user profile
      await _client
          .from('profiles')
          .update({
            'auto_renewal_enabled': preferences.autoRenewalEnabled,
            'auto_renewal_frequency': preferences.autoRenewalFrequency,
            'billing_email_enabled': preferences.billingEmailEnabled,
            'payment_retry_attempts': preferences.maxPaymentRetryAttempts,
            'preferred_language': preferences.preferredLanguage,
          })
          .eq('id', user.id);

      _logger.i('Billing preferences updated successfully');
    } catch (e) {
      _logger.e('Error updating billing preferences: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user has valid payment method
  static Future<bool> hasValidPaymentMethod() async {
    try {
      final subscription = await SubscriptionService.getSubscriptionStatus();

      // If user has an active paid subscription, they likely have a valid payment method
      return subscription.tier != SubscriptionTier.free &&
          subscription.isActive &&
          subscription.stripeCustomerId != null;
    } catch (e) {
      _logger.e('Error checking payment method: $e');
      return false;
    }
  }

  /// Get subscription tier hierarchy for comparison
  static int getTierHierarchy(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 1;
      case SubscriptionTier.max:
        return 2;
    }
  }

  /// Check if target tier is an upgrade
  static bool isUpgrade(
    SubscriptionTier currentTier,
    SubscriptionTier targetTier,
  ) {
    return getTierHierarchy(targetTier) > getTierHierarchy(currentTier);
  }

  /// Check if target tier is a downgrade
  static bool isDowngrade(
    SubscriptionTier currentTier,
    SubscriptionTier targetTier,
  ) {
    return getTierHierarchy(targetTier) < getTierHierarchy(currentTier);
  }

  /// Dispose resources
  static void dispose() {
    _loadingController.close();
  }
}
