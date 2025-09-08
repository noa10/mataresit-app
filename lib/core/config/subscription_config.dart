/// Subscription Configuration
///
/// This file contains all subscription-related configuration including price IDs,
/// tier mappings, and utility functions. This matches the React app's structure
/// and ensures consistency across platforms.
library;

/// Subscription tier enumeration
enum SubscriptionTier {
  free('free'),
  pro('pro'),
  max('max');

  const SubscriptionTier(this.value);
  final String value;

  static SubscriptionTier fromString(String value) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.value == value,
      orElse: () => SubscriptionTier.free,
    );
  }
}

/// Billing interval enumeration
enum BillingInterval {
  monthly('monthly'),
  annual('annual');

  const BillingInterval(this.value);
  final String value;

  static BillingInterval fromString(String value) {
    return BillingInterval.values.firstWhere(
      (interval) => interval.value == value,
      orElse: () => BillingInterval.monthly,
    );
  }
}

/// Subscription status enumeration
enum SubscriptionStatus {
  active('active'),
  trialing('trialing'),
  pastDue('past_due'),
  canceled('canceled'),
  incomplete('incomplete'),
  incompleteExpired('incomplete_expired'),
  unpaid('unpaid');

  const SubscriptionStatus(this.value);
  final String value;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.canceled,
    );
  }
}

/// Stripe Price ID Configuration
/// These match the exact price IDs from the React app and Stripe dashboard
class StripePriceIds {
  static const Map<String, Map<String, String>> priceIds = {
    'pro': {
      'monthly': 'price_1RSiggPHa6JfBjtMFGNcoKnZ',
      'annual': 'price_1RSiiHPHa6JfBjtMOIItG7RA',
    },
    'max': {
      'monthly': 'price_1RSiixPHa6JfBjtMXI9INFRf',
      'annual': 'price_1RSik1PHa6JfBjtMbYhspNSR',
    },
  };

  /// Reverse mapping: Price ID to Tier
  static final Map<String, SubscriptionTier> priceIdToTierMap = {
    priceIds['pro']!['monthly']!: SubscriptionTier.pro,
    priceIds['pro']!['annual']!: SubscriptionTier.pro,
    priceIds['max']!['monthly']!: SubscriptionTier.max,
    priceIds['max']!['annual']!: SubscriptionTier.max,
  };

  /// Get price ID for a specific tier and billing interval
  static String? getPriceId(SubscriptionTier tier, BillingInterval interval) {
    if (tier == SubscriptionTier.free) return null;
    return priceIds[tier.value]?[interval.value];
  }

  /// Map a Stripe price ID to a subscription tier
  static SubscriptionTier mapPriceIdToTier(String priceId) {
    return priceIdToTierMap[priceId] ?? SubscriptionTier.free;
  }

  /// Get billing interval from price ID
  static BillingInterval? getBillingIntervalFromPriceId(String priceId) {
    for (final tierEntry in priceIds.entries) {
      for (final intervalEntry in tierEntry.value.entries) {
        if (intervalEntry.value == priceId) {
          return BillingInterval.fromString(intervalEntry.key);
        }
      }
    }
    return null;
  }

  /// Check if a price ID is valid
  static bool isValidPriceId(String priceId) {
    return priceIdToTierMap.containsKey(priceId);
  }
}

/// Subscription tier features and limits
class SubscriptionFeatures {
  final bool versionControl;
  final String integrations; // 'none', 'basic', 'advanced'
  final bool customBranding;
  final int maxUsers; // -1 for unlimited
  final String supportLevel; // 'basic', 'standard', 'priority'
  final bool apiAccess;

  const SubscriptionFeatures({
    required this.versionControl,
    required this.integrations,
    required this.customBranding,
    required this.maxUsers,
    required this.supportLevel,
    required this.apiAccess,
  });
}

/// Subscription tier limits
class SubscriptionLimits {
  final int monthlyReceipts; // -1 for unlimited
  final int storageLimitMB; // -1 for unlimited
  final int retentionDays;
  final int batchUploadLimit;
  final SubscriptionFeatures features;

  const SubscriptionLimits({
    required this.monthlyReceipts,
    required this.storageLimitMB,
    required this.retentionDays,
    required this.batchUploadLimit,
    required this.features,
  });
}

/// Tier configuration matching React app structure
class TierConfig {
  static const Map<SubscriptionTier, SubscriptionLimits> tierLimits = {
    SubscriptionTier.free: SubscriptionLimits(
      monthlyReceipts: 50,
      storageLimitMB: 1024, // 1GB
      retentionDays: 7,
      batchUploadLimit: 5,
      features: SubscriptionFeatures(
        versionControl: false,
        integrations: 'none',
        customBranding: false,
        maxUsers: 1,
        supportLevel: 'basic',
        apiAccess: false,
      ),
    ),
    SubscriptionTier.pro: SubscriptionLimits(
      monthlyReceipts: 500,
      storageLimitMB: 10240, // 10GB
      retentionDays: 90,
      batchUploadLimit: 50,
      features: SubscriptionFeatures(
        versionControl: true,
        integrations: 'basic',
        customBranding: true,
        maxUsers: 5,
        supportLevel: 'standard',
        apiAccess: false,
      ),
    ),
    SubscriptionTier.max: SubscriptionLimits(
      monthlyReceipts: -1, // unlimited
      storageLimitMB: -1, // unlimited
      retentionDays: 365,
      batchUploadLimit: 100,
      features: SubscriptionFeatures(
        versionControl: true,
        integrations: 'advanced',
        customBranding: true,
        maxUsers: -1, // unlimited
        supportLevel: 'priority',
        apiAccess: true,
      ),
    ),
  };

  /// Get limits for a specific tier
  static SubscriptionLimits getLimits(SubscriptionTier tier) {
    return tierLimits[tier]!;
  }

  /// Check if a feature is available for a tier
  static bool isFeatureAvailable(SubscriptionTier tier, String feature) {
    final limits = getLimits(tier);
    switch (feature) {
      case 'versionControl':
        return limits.features.versionControl;
      case 'customBranding':
        return limits.features.customBranding;
      case 'apiAccess':
        return limits.features.apiAccess;
      case 'unlimitedUsers':
        return limits.features.maxUsers == -1;
      case 'advancedIntegrations':
        return limits.features.integrations == 'advanced';
      case 'prioritySupport':
        return limits.features.supportLevel == 'priority';
      default:
        return false;
    }
  }
}

/// Pricing information for display
class PricingInfo {
  static const Map<SubscriptionTier, Map<BillingInterval, double>> pricing = {
    SubscriptionTier.free: {
      BillingInterval.monthly: 0.0,
      BillingInterval.annual: 0.0,
    },
    SubscriptionTier.pro: {
      BillingInterval.monthly: 10.0,
      BillingInterval.annual: 108.0, // 10% discount
    },
    SubscriptionTier.max: {
      BillingInterval.monthly: 20.0,
      BillingInterval.annual: 216.0, // 10% discount
    },
  };

  /// Get price for a tier and billing interval
  static double getPrice(SubscriptionTier tier, BillingInterval interval) {
    return pricing[tier]?[interval] ?? 0.0;
  }

  /// Get monthly equivalent price for annual billing
  static double getMonthlyEquivalentPrice(SubscriptionTier tier, BillingInterval interval) {
    final price = getPrice(tier, interval);
    return interval == BillingInterval.annual ? price / 12 : price;
  }

  /// Calculate savings for annual billing
  static double getAnnualSavings(SubscriptionTier tier) {
    final monthlyPrice = getPrice(tier, BillingInterval.monthly);
    final annualPrice = getPrice(tier, BillingInterval.annual);
    return (monthlyPrice * 12) - annualPrice;
  }

  /// Get savings percentage for annual billing
  static double getAnnualSavingsPercentage(SubscriptionTier tier) {
    final monthlyPrice = getPrice(tier, BillingInterval.monthly);
    if (monthlyPrice == 0) return 0.0;
    final savings = getAnnualSavings(tier);
    return (savings / (monthlyPrice * 12)) * 100;
  }
}

/// Stripe public key configuration
class StripeConfig {
  static const String publicKey = 'pk_test_51RShZxPHa6JfBjtMAj3ijFQOzUhyGUwwMRsjfuy7p4lAmW4IoBFhoVLnfU8WxUNfJZN7kxAKHkLX0vYprLVmB9lW00o2s0rYkK';
}
