import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String? email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'google_avatar_url')
  final String? googleAvatarUrl;
  @JsonKey(name: 'avatar_updated_at')
  final DateTime? avatarUpdatedAt;
  @JsonKey(name: 'subscription_tier')
  final String? subscriptionTier;
  @JsonKey(name: 'subscription_status')
  final String? subscriptionStatus;
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
  final int? receiptsUsedThisMonth;
  @JsonKey(name: 'monthly_reset_date')
  final DateTime? monthlyResetDate;
  @JsonKey(name: 'preferred_language')
  final String? preferredLanguage;
  @JsonKey(name: 'auto_renewal_enabled')
  final bool? autoRenewalEnabled;
  @JsonKey(name: 'auto_renewal_frequency')
  final String? autoRenewalFrequency;
  @JsonKey(name: 'billing_email_enabled')
  final bool? billingEmailEnabled;
  @JsonKey(name: 'payment_retry_attempts')
  final int? paymentRetryAttempts;
  @JsonKey(name: 'grace_period_end_date')
  final DateTime? gracePeriodEndDate;
  @JsonKey(name: 'last_payment_attempt')
  final DateTime? lastPaymentAttempt;
  @JsonKey(name: 'next_billing_date')
  final DateTime? nextBillingDate;
  @JsonKey(name: 'billing_address')
  final Map<String, dynamic>? billingAddress;
  @JsonKey(name: 'payment_method_last_four')
  final String? paymentMethodLastFour;
  @JsonKey(name: 'payment_method_brand')
  final String? paymentMethodBrand;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Computed properties for backward compatibility
  String? get fullName {
    if (firstName != null && lastName != null) {
      return '${firstName!} ${lastName!}'.trim();
    }
    return firstName ?? lastName;
  }

  bool get emailVerified => email != null;
  bool get phoneVerified => false; // Not implemented in profiles table
  UserRole get role => UserRole.user; // Default role
  UserStatus get status => UserStatus.active; // Default status

  const UserModel({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.googleAvatarUrl,
    this.avatarUpdatedAt,
    this.subscriptionTier,
    this.subscriptionStatus,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialEndDate,
    this.receiptsUsedThisMonth,
    this.monthlyResetDate,
    this.preferredLanguage,
    this.autoRenewalEnabled,
    this.autoRenewalFrequency,
    this.billingEmailEnabled,
    this.paymentRetryAttempts,
    this.gracePeriodEndDate,
    this.lastPaymentAttempt,
    this.nextBillingDate,
    this.billingAddress,
    this.paymentMethodLastFour,
    this.paymentMethodBrand,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? googleAvatarUrl,
    DateTime? avatarUpdatedAt,
    String? subscriptionTier,
    String? subscriptionStatus,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? trialEndDate,
    int? receiptsUsedThisMonth,
    DateTime? monthlyResetDate,
    String? preferredLanguage,
    bool? autoRenewalEnabled,
    String? autoRenewalFrequency,
    bool? billingEmailEnabled,
    int? paymentRetryAttempts,
    DateTime? gracePeriodEndDate,
    DateTime? lastPaymentAttempt,
    DateTime? nextBillingDate,
    Map<String, dynamic>? billingAddress,
    String? paymentMethodLastFour,
    String? paymentMethodBrand,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      googleAvatarUrl: googleAvatarUrl ?? this.googleAvatarUrl,
      avatarUpdatedAt: avatarUpdatedAt ?? this.avatarUpdatedAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      receiptsUsedThisMonth:
          receiptsUsedThisMonth ?? this.receiptsUsedThisMonth,
      monthlyResetDate: monthlyResetDate ?? this.monthlyResetDate,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      autoRenewalEnabled: autoRenewalEnabled ?? this.autoRenewalEnabled,
      autoRenewalFrequency: autoRenewalFrequency ?? this.autoRenewalFrequency,
      billingEmailEnabled: billingEmailEnabled ?? this.billingEmailEnabled,
      paymentRetryAttempts: paymentRetryAttempts ?? this.paymentRetryAttempts,
      gracePeriodEndDate: gracePeriodEndDate ?? this.gracePeriodEndDate,
      lastPaymentAttempt: lastPaymentAttempt ?? this.lastPaymentAttempt,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      billingAddress: billingAddress ?? this.billingAddress,
      paymentMethodLastFour:
          paymentMethodLastFour ?? this.paymentMethodLastFour,
      paymentMethodBrand: paymentMethodBrand ?? this.paymentMethodBrand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    avatarUrl,
    googleAvatarUrl,
    avatarUpdatedAt,
    subscriptionTier,
    subscriptionStatus,
    stripeCustomerId,
    stripeSubscriptionId,
    subscriptionStartDate,
    subscriptionEndDate,
    trialEndDate,
    receiptsUsedThisMonth,
    monthlyResetDate,
    preferredLanguage,
    autoRenewalEnabled,
    autoRenewalFrequency,
    billingEmailEnabled,
    paymentRetryAttempts,
    gracePeriodEndDate,
    lastPaymentAttempt,
    nextBillingDate,
    billingAddress,
    paymentMethodLastFour,
    paymentMethodBrand,
    createdAt,
    updatedAt,
  ];
}

@JsonEnum()
enum UserRole {
  @JsonValue('user')
  user,
  @JsonValue('admin')
  admin,
  @JsonValue('super_admin')
  superAdmin,
}

@JsonEnum()
enum UserStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('suspended')
  suspended,
  @JsonValue('pending')
  pending,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;
  bool get isSuperAdmin => this == UserRole.superAdmin;
}

extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.pending:
        return 'Pending';
    }
  }

  bool get isActive => this == UserStatus.active;
  bool get canLogin => this == UserStatus.active;
}
