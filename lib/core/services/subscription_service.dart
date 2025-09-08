import 'dart:async';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/subscription_model.dart';
import '../config/subscription_config.dart';
import '../network/supabase_client.dart';

/// Service for managing subscription operations
/// This mirrors the React app's useSubscription hook and StripeContext functionality
class SubscriptionService {
  static final Logger _logger = Logger();
  static final SupabaseClient _client = SupabaseService.client;

  /// Stream controller for subscription updates
  static final StreamController<SubscriptionModel> _subscriptionController =
      StreamController<SubscriptionModel>.broadcast();

  /// Stream for subscription updates
  static Stream<SubscriptionModel> get subscriptionStream =>
      _subscriptionController.stream;

  /// Get current subscription status from user profile
  static Future<SubscriptionModel> getSubscriptionStatus() async {
    try {
      _logger.i('Fetching subscription status...');

      final user = _client.auth.currentUser;
      if (user == null) {
        _logger.w('No authenticated user found');
        return SubscriptionModel.free();
      }

      // Get user profile with subscription data
      final response = await _client
          .from('profiles')
          .select('''
            subscription_tier,
            subscription_status,
            stripe_customer_id,
            stripe_subscription_id,
            subscription_start_date,
            subscription_end_date,
            trial_end_date,
            receipts_used_this_month,
            monthly_reset_date
          ''')
          .eq('id', user.id)
          .single();

      _logger.d('Profile response: $response');
      _logger.d('User ID: ${user.id}');
      _logger.d('User email: ${user.email}');
      _logger.d('Raw subscription_tier: ${response['subscription_tier']}');
      _logger.d('Raw subscription_status: ${response['subscription_status']}');

      // Convert to subscription model
      final subscription = SubscriptionModel(
        tier: SubscriptionTier.fromString(response['subscription_tier'] ?? 'free'),
        status: SubscriptionStatus.fromString(response['subscription_status'] ?? 'active'),
        stripeCustomerId: response['stripe_customer_id'],
        stripeSubscriptionId: response['stripe_subscription_id'],
        subscriptionStartDate: response['subscription_start_date'] != null
            ? DateTime.parse(response['subscription_start_date'])
            : null,
        subscriptionEndDate: response['subscription_end_date'] != null
            ? DateTime.parse(response['subscription_end_date'])
            : null,
        trialEndDate: response['trial_end_date'] != null
            ? DateTime.parse(response['trial_end_date'])
            : null,
        receiptsUsedThisMonth: response['receipts_used_this_month'] ?? 0,
        monthlyResetDate: response['monthly_reset_date'] != null
            ? DateTime.parse(response['monthly_reset_date'])
            : null,
        nextBillingDate: null, // Column doesn't exist in database
      );

      _logger.i('Subscription status retrieved: ${subscription.tier.value} - ${subscription.status.value}');
      
      // Emit to stream
      _subscriptionController.add(subscription);
      
      return subscription;
    } catch (e) {
      _logger.e('Error fetching subscription status: $e');
      
      // Return free tier as fallback
      final freeSubscription = SubscriptionModel.free();
      _subscriptionController.add(freeSubscription);
      return freeSubscription;
    }
  }

  /// Refresh subscription status (force refresh from server)
  static Future<SubscriptionModel> refreshSubscriptionStatus() async {
    try {
      _logger.i('Force refreshing subscription status...');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Call the initialize-user-subscription edge function to sync with Stripe
      final response = await _client.functions.invoke('initialize-user-subscription');
      _logger.d('Subscription refresh response: ${response.data}');

      // Get updated subscription status
      return await getSubscriptionStatus();
    } catch (e) {
      _logger.e('Error refreshing subscription status: $e');
      rethrow;
    }
  }

  /// Get subscription usage information
  static Future<SubscriptionUsage> getSubscriptionUsage() async {
    try {
      _logger.i('Fetching subscription usage...');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get usage data from multiple sources
      final futures = await Future.wait([
        _getReceiptUsage(),
        _getStorageUsage(),
        _getTeamMembersCount(),
        _getApiUsage(),
      ]);

      final usage = SubscriptionUsage(
        receiptsUsed: futures[0] as int,
        storageUsedMB: futures[1] as double,
        teamMembersCount: futures[2] as int,
        apiRequestsThisHour: futures[3] as int,
        lastUpdated: DateTime.now(),
      );

      _logger.i('Usage retrieved: ${usage.receiptsUsed} receipts, ${usage.storageUsedMB}MB storage');
      return usage;
    } catch (e) {
      _logger.e('Error fetching subscription usage: $e');
      return SubscriptionUsage.empty();
    }
  }

  /// Check if user can upload more receipts
  static Future<bool> canUploadReceipts() async {
    try {
      final subscription = await getSubscriptionStatus();
      return subscription.canUploadReceipts;
    } catch (e) {
      _logger.e('Error checking upload permission: $e');
      return false;
    }
  }

  /// Check if a feature is available for current subscription
  static Future<bool> isFeatureAvailable(String feature) async {
    try {
      final subscription = await getSubscriptionStatus();
      return subscription.isFeatureAvailable(feature);
    } catch (e) {
      _logger.e('Error checking feature availability: $e');
      return false;
    }
  }

  /// Get upgrade message for current tier
  static Future<String?> getUpgradeMessage() async {
    try {
      final subscription = await getSubscriptionStatus();
      
      switch (subscription.tier) {
        case SubscriptionTier.free:
          return 'Upgrade to Pro for 500 receipts/month and advanced features';
        case SubscriptionTier.pro:
          return 'Upgrade to Max for unlimited receipts and API access';
        case SubscriptionTier.max:
          return null; // Already on highest tier
      }
    } catch (e) {
      _logger.e('Error getting upgrade message: $e');
      return null;
    }
  }

  /// Initialize subscription for new user
  static Future<void> initializeUserSubscription() async {
    try {
      _logger.i('Initializing user subscription...');

      await _client.functions.invoke('initialize-user-subscription');
      _logger.i('User subscription initialized successfully');
    } catch (e) {
      _logger.e('Error initializing user subscription: $e');
      rethrow;
    }
  }

  /// Debug method to check raw database values
  static Future<void> debugUserSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _logger.w('No authenticated user found for debug');
        return;
      }

      _logger.i('=== DEBUG: Raw database query for user ${user.email} ===');

      // Query the database directly
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      _logger.i('Full profile data: $response');

      // Also check if there are any subscription records in other tables
      try {
        final subscriptionResponse = await _client
            .from('subscription_limits')
            .select('*');
        _logger.i('Available subscription limits: $subscriptionResponse');
      } catch (e) {
        _logger.w('Could not fetch subscription limits: $e');
      }

    } catch (e) {
      _logger.e('Error in debug query: $e');
    }
  }

  /// Private helper methods

  static Future<int> _getReceiptUsage() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      // Get current month's receipt count
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final response = await _client
          .from('receipts')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', startOfMonth.toIso8601String())
          .count();

      return response.count;
    } catch (e) {
      _logger.e('Error getting receipt usage: $e');
      return 0;
    }
  }

  static Future<double> _getStorageUsage() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0.0;

      // This would need to be implemented based on your storage tracking
      // For now, return 0 as placeholder
      return 0.0;
    } catch (e) {
      _logger.e('Error getting storage usage: $e');
      return 0.0;
    }
  }

  static Future<int> _getTeamMembersCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 1;

      // Get team members count
      final response = await _client
          .from('team_members')
          .select('id')
          .eq('user_id', user.id)
          .count();

      return response.count + 1; // +1 for the user themselves
    } catch (e) {
      _logger.e('Error getting team members count: $e');
      return 1;
    }
  }

  static Future<int> _getApiUsage() async {
    try {
      // This would need to be implemented based on your API usage tracking
      // For now, return 0 as placeholder
      return 0;
    } catch (e) {
      _logger.e('Error getting API usage: $e');
      return 0;
    }
  }

  /// Dispose resources
  static void dispose() {
    _subscriptionController.close();
  }
}
