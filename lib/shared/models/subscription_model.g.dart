// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) =>
    SubscriptionModel(
      tier: $enumDecode(_$SubscriptionTierEnumMap, json['tier']),
      status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      subscriptionStartDate: json['subscription_start_date'] == null
          ? null
          : DateTime.parse(json['subscription_start_date'] as String),
      subscriptionEndDate: json['subscription_end_date'] == null
          ? null
          : DateTime.parse(json['subscription_end_date'] as String),
      trialEndDate: json['trial_end_date'] == null
          ? null
          : DateTime.parse(json['trial_end_date'] as String),
      receiptsUsedThisMonth: (json['receipts_used_this_month'] as num).toInt(),
      monthlyResetDate: json['monthly_reset_date'] == null
          ? null
          : DateTime.parse(json['monthly_reset_date'] as String),
      nextBillingDate: json['next_billing_date'] == null
          ? null
          : DateTime.parse(json['next_billing_date'] as String),
      simulated: json['simulated'] as bool?,
    );

Map<String, dynamic> _$SubscriptionModelToJson(
  SubscriptionModel instance,
) => <String, dynamic>{
  'tier': _$SubscriptionTierEnumMap[instance.tier]!,
  'status': _$SubscriptionStatusEnumMap[instance.status]!,
  'stripe_customer_id': instance.stripeCustomerId,
  'stripe_subscription_id': instance.stripeSubscriptionId,
  'subscription_start_date': instance.subscriptionStartDate?.toIso8601String(),
  'subscription_end_date': instance.subscriptionEndDate?.toIso8601String(),
  'trial_end_date': instance.trialEndDate?.toIso8601String(),
  'receipts_used_this_month': instance.receiptsUsedThisMonth,
  'monthly_reset_date': instance.monthlyResetDate?.toIso8601String(),
  'next_billing_date': instance.nextBillingDate?.toIso8601String(),
  'simulated': instance.simulated,
};

const _$SubscriptionTierEnumMap = {
  SubscriptionTier.free: 'free',
  SubscriptionTier.pro: 'pro',
  SubscriptionTier.max: 'max',
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.trialing: 'trialing',
  SubscriptionStatus.pastDue: 'pastDue',
  SubscriptionStatus.canceled: 'canceled',
  SubscriptionStatus.incomplete: 'incomplete',
  SubscriptionStatus.incompleteExpired: 'incompleteExpired',
  SubscriptionStatus.unpaid: 'unpaid',
};

SubscriptionUsage _$SubscriptionUsageFromJson(Map<String, dynamic> json) =>
    SubscriptionUsage(
      receiptsUsed: (json['receipts_used'] as num).toInt(),
      storageUsedMB: (json['storage_used_mb'] as num).toDouble(),
      teamMembersCount: (json['team_members_count'] as num).toInt(),
      apiRequestsThisHour: (json['api_requests_this_hour'] as num).toInt(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$SubscriptionUsageToJson(SubscriptionUsage instance) =>
    <String, dynamic>{
      'receipts_used': instance.receiptsUsed,
      'storage_used_mb': instance.storageUsedMB,
      'team_members_count': instance.teamMembersCount,
      'api_requests_this_hour': instance.apiRequestsThisHour,
      'last_updated': instance.lastUpdated.toIso8601String(),
    };

BillingPreferences _$BillingPreferencesFromJson(
  Map<String, dynamic> json,
) => BillingPreferences(
  autoRenewalEnabled: json['auto_renewal_enabled'] as bool,
  autoRenewalFrequency: json['auto_renewal_frequency'] as String,
  billingEmailEnabled: json['billing_email_enabled'] as bool,
  reminderDaysBeforeRenewal:
      (json['reminder_days_before_renewal'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
  paymentFailureNotifications: json['payment_failure_notifications'] as bool,
  gracePeriodNotifications: json['grace_period_notifications'] as bool,
  maxPaymentRetryAttempts: (json['max_payment_retry_attempts'] as num).toInt(),
  retryIntervalHours: (json['retry_interval_hours'] as num).toInt(),
  gracePeriodDays: (json['grace_period_days'] as num).toInt(),
  preferredLanguage: json['preferred_language'] as String,
  timezone: json['timezone'] as String,
);

Map<String, dynamic> _$BillingPreferencesToJson(BillingPreferences instance) =>
    <String, dynamic>{
      'auto_renewal_enabled': instance.autoRenewalEnabled,
      'auto_renewal_frequency': instance.autoRenewalFrequency,
      'billing_email_enabled': instance.billingEmailEnabled,
      'reminder_days_before_renewal': instance.reminderDaysBeforeRenewal,
      'payment_failure_notifications': instance.paymentFailureNotifications,
      'grace_period_notifications': instance.gracePeriodNotifications,
      'max_payment_retry_attempts': instance.maxPaymentRetryAttempts,
      'retry_interval_hours': instance.retryIntervalHours,
      'grace_period_days': instance.gracePeriodDays,
      'preferred_language': instance.preferredLanguage,
      'timezone': instance.timezone,
    };
