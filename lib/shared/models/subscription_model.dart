import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../core/config/subscription_config.dart';

part 'subscription_model.g.dart';

/// Subscription data model matching the React app's SubscriptionData interface
@JsonSerializable()
class SubscriptionModel extends Equatable {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  @JsonKey(name: 'stripe_customer_id')
  final String? stripeCustomerId;
  @JsonKey(name: 'stripe_subscription_id')
  final String? stripeSubscriptionId;
  @JsonKey(name: 'subscription_start_date')
  final DateTime? subscriptionStartDate;
  @JsonKey(name: 'subscription_end_date')
  final DateTime? subscriptionEndDate;
  @JsonKey(name: 'trial_end_date')
  final DateTime? trialEndDate;
  @JsonKey(name: 'receipts_used_this_month')
  final int receiptsUsedThisMonth;
  @JsonKey(name: 'monthly_reset_date')
  final DateTime? monthlyResetDate;
  @JsonKey(name: 'next_billing_date')
  final DateTime? nextBillingDate;
  final bool? simulated;

  const SubscriptionModel({
    required this.tier,
    required this.status,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialEndDate,
    required this.receiptsUsedThisMonth,
    this.monthlyResetDate,
    this.nextBillingDate,
    this.simulated,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  /// Create a free tier subscription
  factory SubscriptionModel.free() {
    return const SubscriptionModel(
      tier: SubscriptionTier.free,
      status: SubscriptionStatus.active,
      receiptsUsedThisMonth: 0,
    );
  }

  /// Check if subscription is active
  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;

  /// Check if subscription is in trial
  bool get isTrialing => status == SubscriptionStatus.trialing;

  /// Check if subscription is past due
  bool get isPastDue => status == SubscriptionStatus.pastDue;

  /// Check if subscription is canceled
  bool get isCanceled => status == SubscriptionStatus.canceled;

  /// Get subscription limits
  SubscriptionLimits get limits => TierConfig.getLimits(tier);

  /// Get remaining receipts for this month
  int get remainingReceipts {
    final monthlyLimit = limits.monthlyReceipts;
    if (monthlyLimit == -1) return -1; // unlimited
    return (monthlyLimit - receiptsUsedThisMonth).clamp(0, monthlyLimit);
  }

  /// Check if user can upload more receipts
  bool get canUploadReceipts {
    if (limits.monthlyReceipts == -1) return true; // unlimited
    return receiptsUsedThisMonth < limits.monthlyReceipts;
  }

  /// Get usage percentage for receipts
  double get receiptUsagePercentage {
    if (limits.monthlyReceipts == -1) return 0.0; // unlimited
    return (receiptsUsedThisMonth / limits.monthlyReceipts).clamp(0.0, 1.0);
  }

  /// Check if a feature is available
  bool isFeatureAvailable(String feature) {
    return TierConfig.isFeatureAvailable(tier, feature);
  }

  /// Get days until trial ends (if in trial)
  int? get daysUntilTrialEnds {
    if (!isTrialing || trialEndDate == null) return null;
    final now = DateTime.now();
    final difference = trialEndDate!.difference(now);
    return difference.inDays.clamp(0, double.infinity).toInt();
  }

  /// Get days until next billing (if active subscription)
  int? get daysUntilNextBilling {
    if (nextBillingDate == null) return null;
    final now = DateTime.now();
    final difference = nextBillingDate!.difference(now);
    return difference.inDays.clamp(0, double.infinity).toInt();
  }

  @override
  List<Object?> get props => [
        tier,
        status,
        stripeCustomerId,
        stripeSubscriptionId,
        subscriptionStartDate,
        subscriptionEndDate,
        trialEndDate,
        receiptsUsedThisMonth,
        monthlyResetDate,
        nextBillingDate,
        simulated,
      ];

  SubscriptionModel copyWith({
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? trialEndDate,
    int? receiptsUsedThisMonth,
    DateTime? monthlyResetDate,
    DateTime? nextBillingDate,
    bool? simulated,
  }) {
    return SubscriptionModel(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      receiptsUsedThisMonth: receiptsUsedThisMonth ?? this.receiptsUsedThisMonth,
      monthlyResetDate: monthlyResetDate ?? this.monthlyResetDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      simulated: simulated ?? this.simulated,
    );
  }
}

/// Subscription usage information
@JsonSerializable()
class SubscriptionUsage extends Equatable {
  @JsonKey(name: 'receipts_used')
  final int receiptsUsed;
  @JsonKey(name: 'storage_used_mb')
  final double storageUsedMB;
  @JsonKey(name: 'team_members_count')
  final int teamMembersCount;
  @JsonKey(name: 'api_requests_this_hour')
  final int apiRequestsThisHour;
  @JsonKey(name: 'last_updated')
  final DateTime lastUpdated;

  const SubscriptionUsage({
    required this.receiptsUsed,
    required this.storageUsedMB,
    required this.teamMembersCount,
    required this.apiRequestsThisHour,
    required this.lastUpdated,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionUsageFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionUsageToJson(this);

  /// Create empty usage
  factory SubscriptionUsage.empty() {
    return SubscriptionUsage(
      receiptsUsed: 0,
      storageUsedMB: 0.0,
      teamMembersCount: 1,
      apiRequestsThisHour: 0,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        receiptsUsed,
        storageUsedMB,
        teamMembersCount,
        apiRequestsThisHour,
        lastUpdated,
      ];

  SubscriptionUsage copyWith({
    int? receiptsUsed,
    double? storageUsedMB,
    int? teamMembersCount,
    int? apiRequestsThisHour,
    DateTime? lastUpdated,
  }) {
    return SubscriptionUsage(
      receiptsUsed: receiptsUsed ?? this.receiptsUsed,
      storageUsedMB: storageUsedMB ?? this.storageUsedMB,
      teamMembersCount: teamMembersCount ?? this.teamMembersCount,
      apiRequestsThisHour: apiRequestsThisHour ?? this.apiRequestsThisHour,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Billing preferences model
@JsonSerializable()
class BillingPreferences extends Equatable {
  @JsonKey(name: 'auto_renewal_enabled')
  final bool autoRenewalEnabled;
  @JsonKey(name: 'auto_renewal_frequency')
  final String autoRenewalFrequency;
  @JsonKey(name: 'billing_email_enabled')
  final bool billingEmailEnabled;
  @JsonKey(name: 'reminder_days_before_renewal')
  final List<int> reminderDaysBeforeRenewal;
  @JsonKey(name: 'payment_failure_notifications')
  final bool paymentFailureNotifications;
  @JsonKey(name: 'grace_period_notifications')
  final bool gracePeriodNotifications;
  @JsonKey(name: 'max_payment_retry_attempts')
  final int maxPaymentRetryAttempts;
  @JsonKey(name: 'retry_interval_hours')
  final int retryIntervalHours;
  @JsonKey(name: 'grace_period_days')
  final int gracePeriodDays;
  @JsonKey(name: 'preferred_language')
  final String preferredLanguage;
  final String timezone;

  const BillingPreferences({
    required this.autoRenewalEnabled,
    required this.autoRenewalFrequency,
    required this.billingEmailEnabled,
    required this.reminderDaysBeforeRenewal,
    required this.paymentFailureNotifications,
    required this.gracePeriodNotifications,
    required this.maxPaymentRetryAttempts,
    required this.retryIntervalHours,
    required this.gracePeriodDays,
    required this.preferredLanguage,
    required this.timezone,
  });

  factory BillingPreferences.fromJson(Map<String, dynamic> json) =>
      _$BillingPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$BillingPreferencesToJson(this);

  /// Create default billing preferences
  factory BillingPreferences.defaults() {
    return const BillingPreferences(
      autoRenewalEnabled: true,
      autoRenewalFrequency: 'monthly',
      billingEmailEnabled: true,
      reminderDaysBeforeRenewal: [7, 3, 1],
      paymentFailureNotifications: true,
      gracePeriodNotifications: true,
      maxPaymentRetryAttempts: 3,
      retryIntervalHours: 24,
      gracePeriodDays: 7,
      preferredLanguage: 'en',
      timezone: 'UTC',
    );
  }

  @override
  List<Object?> get props => [
        autoRenewalEnabled,
        autoRenewalFrequency,
        billingEmailEnabled,
        reminderDaysBeforeRenewal,
        paymentFailureNotifications,
        gracePeriodNotifications,
        maxPaymentRetryAttempts,
        retryIntervalHours,
        gracePeriodDays,
        preferredLanguage,
        timezone,
      ];

  BillingPreferences copyWith({
    bool? autoRenewalEnabled,
    String? autoRenewalFrequency,
    bool? billingEmailEnabled,
    List<int>? reminderDaysBeforeRenewal,
    bool? paymentFailureNotifications,
    bool? gracePeriodNotifications,
    int? maxPaymentRetryAttempts,
    int? retryIntervalHours,
    int? gracePeriodDays,
    String? preferredLanguage,
    String? timezone,
  }) {
    return BillingPreferences(
      autoRenewalEnabled: autoRenewalEnabled ?? this.autoRenewalEnabled,
      autoRenewalFrequency: autoRenewalFrequency ?? this.autoRenewalFrequency,
      billingEmailEnabled: billingEmailEnabled ?? this.billingEmailEnabled,
      reminderDaysBeforeRenewal: reminderDaysBeforeRenewal ?? this.reminderDaysBeforeRenewal,
      paymentFailureNotifications: paymentFailureNotifications ?? this.paymentFailureNotifications,
      gracePeriodNotifications: gracePeriodNotifications ?? this.gracePeriodNotifications,
      maxPaymentRetryAttempts: maxPaymentRetryAttempts ?? this.maxPaymentRetryAttempts,
      retryIntervalHours: retryIntervalHours ?? this.retryIntervalHours,
      gracePeriodDays: gracePeriodDays ?? this.gracePeriodDays,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
    );
  }
}
