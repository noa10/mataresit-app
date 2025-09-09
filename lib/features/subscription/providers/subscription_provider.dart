import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../shared/models/subscription_model.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/config/subscription_config.dart';

final Logger _logger = Logger();

/// Subscription state
class SubscriptionState {
  final SubscriptionModel? subscription;
  final SubscriptionUsage? usage;
  final BillingPreferences? billingPreferences;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const SubscriptionState({
    this.subscription,
    this.usage,
    this.billingPreferences,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  SubscriptionState copyWith({
    SubscriptionModel? subscription,
    SubscriptionUsage? usage,
    BillingPreferences? billingPreferences,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      usage: usage ?? this.usage,
      billingPreferences: billingPreferences ?? this.billingPreferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get current subscription tier
  SubscriptionTier get currentTier =>
      subscription?.tier ?? SubscriptionTier.free;

  /// Check if subscription is active
  bool get isActive => subscription?.isActive ?? false;

  /// Check if user can upload receipts
  bool get canUploadReceipts => subscription?.canUploadReceipts ?? false;

  /// Get remaining receipts for this month
  int get remainingReceipts => subscription?.remainingReceipts ?? 0;

  /// Get receipt usage percentage
  double get receiptUsagePercentage =>
      subscription?.receiptUsagePercentage ?? 0.0;

  /// Check if a feature is available
  bool isFeatureAvailable(String feature) {
    return subscription?.isFeatureAvailable(feature) ?? false;
  }

  /// Get subscription limits
  SubscriptionLimits get limits =>
      subscription?.limits ?? TierConfig.getLimits(SubscriptionTier.free);
}

/// Subscription provider notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _initialize();
  }

  /// Initialize subscription data
  Future<void> _initialize() async {
    await loadSubscriptionData();

    // Listen to subscription updates
    SubscriptionService.subscriptionStream.listen((subscription) {
      state = state.copyWith(
        subscription: subscription,
        lastUpdated: DateTime.now(),
      );
    });

    // Listen to Stripe loading state
    StripeService.loadingStream.listen((isLoading) {
      state = state.copyWith(isLoading: isLoading);
    });
  }

  /// Load subscription data
  Future<void> loadSubscriptionData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final futures = await Future.wait([
        SubscriptionService.getSubscriptionStatus(),
        SubscriptionService.getSubscriptionUsage(),
        StripeService.getBillingPreferences(),
      ]);

      state = state.copyWith(
        subscription: futures[0] as SubscriptionModel,
        usage: futures[1] as SubscriptionUsage,
        billingPreferences: futures[2] as BillingPreferences,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      _logger.i('Subscription data loaded successfully');
    } catch (e) {
      _logger.e('Error loading subscription data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh subscription data
  Future<void> refreshSubscriptionData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final subscription =
          await SubscriptionService.refreshSubscriptionStatus();
      final usage = await SubscriptionService.getSubscriptionUsage();

      state = state.copyWith(
        subscription: subscription,
        usage: usage,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      _logger.i('Subscription data refreshed successfully');
    } catch (e) {
      _logger.e('Error refreshing subscription data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create checkout session for subscription upgrade
  Future<void> createCheckoutSession(
    SubscriptionTier tier,
    BillingInterval billingInterval,
  ) async {
    try {
      await StripeService.createCheckoutSession(tier, billingInterval);
      _logger.i(
        'Checkout session created for ${tier.value} ${billingInterval.value}',
      );
    } catch (e) {
      _logger.e('Error creating checkout session: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Open Stripe customer portal
  Future<void> openCustomerPortal() async {
    try {
      await StripeService.createPortalSession();
      _logger.i('Customer portal opened');
    } catch (e) {
      _logger.e('Error opening customer portal: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      await StripeService.cancelSubscription();
      await refreshSubscriptionData();
      _logger.i('Subscription canceled');
    } catch (e) {
      _logger.e('Error canceling subscription: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Downgrade subscription
  Future<void> downgradeSubscription(
    SubscriptionTier targetTier, {
    bool immediate = false,
  }) async {
    try {
      await StripeService.downgradeSubscription(
        targetTier,
        immediate: immediate,
      );
      await refreshSubscriptionData();
      _logger.i('Subscription downgraded to ${targetTier.value}');
    } catch (e) {
      _logger.e('Error downgrading subscription: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update billing preferences
  Future<void> updateBillingPreferences(BillingPreferences preferences) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await StripeService.updateBillingPreferences(preferences);

      state = state.copyWith(
        billingPreferences: preferences,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      _logger.i('Billing preferences updated');
    } catch (e) {
      _logger.e('Error updating billing preferences: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Check if user can upload more receipts
  Future<bool> canUploadReceipts() async {
    return await SubscriptionService.canUploadReceipts();
  }

  /// Check if a feature is available
  Future<bool> isFeatureAvailable(String feature) async {
    return await SubscriptionService.isFeatureAvailable(feature);
  }

  /// Get upgrade message
  Future<String?> getUpgradeMessage() async {
    return await SubscriptionService.getUpgradeMessage();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Subscription provider
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier();
    });

/// Current subscription tier provider
final currentSubscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.currentTier;
});

/// Subscription limits provider
final subscriptionLimitsProvider = Provider<SubscriptionLimits>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.limits;
});

/// Can upload receipts provider
final canUploadReceiptsProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.canUploadReceipts;
});

/// Receipt usage percentage provider
final receiptUsagePercentageProvider = Provider<double>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.receiptUsagePercentage;
});

/// Remaining receipts provider
final remainingReceiptsProvider = Provider<int>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.remainingReceipts;
});

/// Feature availability provider
final featureAvailabilityProvider = Provider.family<bool, String>((
  ref,
  feature,
) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isFeatureAvailable(feature);
});

/// Subscription loading provider
final subscriptionLoadingProvider = Provider<bool>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.isLoading;
});

/// Subscription error provider
final subscriptionErrorProvider = Provider<String?>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return subscriptionState.error;
});
