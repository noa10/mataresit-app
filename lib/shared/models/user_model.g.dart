// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  googleAvatarUrl: json['google_avatar_url'] as String?,
  avatarUpdatedAt: json['avatar_updated_at'] == null
      ? null
      : DateTime.parse(json['avatar_updated_at'] as String),
  subscriptionTier: json['subscription_tier'] as String?,
  subscriptionStatus: json['subscription_status'] as String?,
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
  receiptsUsedThisMonth: (json['receipts_used_this_month'] as num?)?.toInt(),
  monthlyResetDate: json['monthly_reset_date'] == null
      ? null
      : DateTime.parse(json['monthly_reset_date'] as String),
  preferredLanguage: json['preferred_language'] as String?,
  autoRenewalEnabled: json['auto_renewal_enabled'] as bool?,
  autoRenewalFrequency: json['auto_renewal_frequency'] as String?,
  billingEmailEnabled: json['billing_email_enabled'] as bool?,
  paymentRetryAttempts: (json['payment_retry_attempts'] as num?)?.toInt(),
  gracePeriodEndDate: json['grace_period_end_date'] == null
      ? null
      : DateTime.parse(json['grace_period_end_date'] as String),
  lastPaymentAttempt: json['last_payment_attempt'] == null
      ? null
      : DateTime.parse(json['last_payment_attempt'] as String),
  nextBillingDate: json['next_billing_date'] == null
      ? null
      : DateTime.parse(json['next_billing_date'] as String),
  billingAddress: json['billing_address'] as Map<String, dynamic>?,
  paymentMethodLastFour: json['payment_method_last_four'] as String?,
  paymentMethodBrand: json['payment_method_brand'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'avatar_url': instance.avatarUrl,
  'google_avatar_url': instance.googleAvatarUrl,
  'avatar_updated_at': instance.avatarUpdatedAt?.toIso8601String(),
  'subscription_tier': instance.subscriptionTier,
  'subscription_status': instance.subscriptionStatus,
  'stripe_customer_id': instance.stripeCustomerId,
  'stripe_subscription_id': instance.stripeSubscriptionId,
  'subscription_start_date': instance.subscriptionStartDate?.toIso8601String(),
  'subscription_end_date': instance.subscriptionEndDate?.toIso8601String(),
  'trial_end_date': instance.trialEndDate?.toIso8601String(),
  'receipts_used_this_month': instance.receiptsUsedThisMonth,
  'monthly_reset_date': instance.monthlyResetDate?.toIso8601String(),
  'preferred_language': instance.preferredLanguage,
  'auto_renewal_enabled': instance.autoRenewalEnabled,
  'auto_renewal_frequency': instance.autoRenewalFrequency,
  'billing_email_enabled': instance.billingEmailEnabled,
  'payment_retry_attempts': instance.paymentRetryAttempts,
  'grace_period_end_date': instance.gracePeriodEndDate?.toIso8601String(),
  'last_payment_attempt': instance.lastPaymentAttempt?.toIso8601String(),
  'next_billing_date': instance.nextBillingDate?.toIso8601String(),
  'billing_address': instance.billingAddress,
  'payment_method_last_four': instance.paymentMethodLastFour,
  'payment_method_brand': instance.paymentMethodBrand,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
