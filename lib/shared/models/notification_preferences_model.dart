import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences_model.g.dart';

/// Notification types enum
enum NotificationType {
  // Receipt processing notifications
  @JsonValue('receipt_processing_started')
  receiptProcessingStarted,
  @JsonValue('receipt_processing_completed')
  receiptProcessingCompleted,
  @JsonValue('receipt_processing_failed')
  receiptProcessingFailed,
  @JsonValue('receipt_ready_for_review')
  receiptReadyForReview,
  @JsonValue('receipt_batch_completed')
  receiptBatchCompleted,
  @JsonValue('receipt_batch_failed')
  receiptBatchFailed,

  // Team receipt collaboration notifications
  @JsonValue('receipt_shared')
  receiptShared,
  @JsonValue('receipt_comment_added')
  receiptCommentAdded,
  @JsonValue('receipt_edited_by_team_member')
  receiptEditedByTeamMember,
  @JsonValue('receipt_approved_by_team')
  receiptApprovedByTeam,
  @JsonValue('receipt_flagged_for_review')
  receiptFlaggedForReview,

  // Team collaboration notifications
  @JsonValue('team_invitation_sent')
  teamInvitationSent,
  @JsonValue('team_invitation_accepted')
  teamInvitationAccepted,
  @JsonValue('team_member_joined')
  teamMemberJoined,
  @JsonValue('team_member_left')
  teamMemberLeft,
  @JsonValue('team_member_removed')
  teamMemberRemoved,
  @JsonValue('team_member_role_changed')
  teamMemberRoleChanged,
  @JsonValue('team_settings_updated')
  teamSettingsUpdated,

  // Claims and billing notifications
  @JsonValue('claim_submitted')
  claimSubmitted,
  @JsonValue('claim_approved')
  claimApproved,
  @JsonValue('claim_rejected')
  claimRejected,
  @JsonValue('claim_review_requested')
  claimReviewRequested,
}

/// Notification categories for UI organization
enum NotificationCategory {
  receiptProcessing,
  teamCollaboration,
  claimsAndBilling,
}

/// Notification category configuration
class NotificationCategoryConfig {
  final String label;
  final String description;
  final List<NotificationType> types;

  const NotificationCategoryConfig({
    required this.label,
    required this.description,
    required this.types,
  });
}

/// Notification categories mapping
const Map<NotificationCategory, NotificationCategoryConfig>
notificationCategories = {
  NotificationCategory.receiptProcessing: NotificationCategoryConfig(
    label: 'Receipt Processing',
    description: 'Notifications about receipt upload and processing status',
    types: [
      NotificationType.receiptProcessingStarted,
      NotificationType.receiptProcessingCompleted,
      NotificationType.receiptProcessingFailed,
      NotificationType.receiptReadyForReview,
      NotificationType.receiptBatchCompleted,
      NotificationType.receiptBatchFailed,
    ],
  ),
  NotificationCategory.teamCollaboration: NotificationCategoryConfig(
    label: 'Team Collaboration',
    description:
        'Notifications about team activities and receipt collaboration',
    types: [
      NotificationType.receiptShared,
      NotificationType.receiptCommentAdded,
      NotificationType.receiptEditedByTeamMember,
      NotificationType.receiptApprovedByTeam,
      NotificationType.receiptFlaggedForReview,
      NotificationType.teamInvitationSent,
      NotificationType.teamInvitationAccepted,
      NotificationType.teamMemberJoined,
      NotificationType.teamMemberLeft,
      NotificationType.teamMemberRemoved,
      NotificationType.teamMemberRoleChanged,
      NotificationType.teamSettingsUpdated,
    ],
  ),
  NotificationCategory.claimsAndBilling: NotificationCategoryConfig(
    label: 'Claims & Billing',
    description: 'Notifications about expense claims and billing updates',
    types: [
      NotificationType.claimSubmitted,
      NotificationType.claimApproved,
      NotificationType.claimRejected,
      NotificationType.claimReviewRequested,
    ],
  ),
};

/// Notification preferences model
@JsonSerializable()
class NotificationPreferences extends Equatable {
  final String? id;
  @JsonKey(name: 'user_id')
  final String userId;

  // Email notification preferences
  @JsonKey(name: 'email_enabled')
  final bool emailEnabled;
  @JsonKey(name: 'email_receipt_processing_started')
  final bool emailReceiptProcessingStarted;
  @JsonKey(name: 'email_receipt_processing_completed')
  final bool emailReceiptProcessingCompleted;
  @JsonKey(name: 'email_receipt_processing_failed')
  final bool emailReceiptProcessingFailed;
  @JsonKey(name: 'email_receipt_ready_for_review')
  final bool emailReceiptReadyForReview;
  @JsonKey(name: 'email_receipt_batch_completed')
  final bool emailReceiptBatchCompleted;
  @JsonKey(name: 'email_receipt_batch_failed')
  final bool emailReceiptBatchFailed;
  @JsonKey(name: 'email_receipt_shared')
  final bool emailReceiptShared;
  @JsonKey(name: 'email_receipt_comment_added')
  final bool emailReceiptCommentAdded;
  @JsonKey(name: 'email_receipt_edited_by_team_member')
  final bool emailReceiptEditedByTeamMember;
  @JsonKey(name: 'email_receipt_approved_by_team')
  final bool emailReceiptApprovedByTeam;
  @JsonKey(name: 'email_receipt_flagged_for_review')
  final bool emailReceiptFlaggedForReview;
  @JsonKey(name: 'email_team_invitation_sent')
  final bool emailTeamInvitationSent;
  @JsonKey(name: 'email_team_invitation_accepted')
  final bool emailTeamInvitationAccepted;
  @JsonKey(name: 'email_team_member_joined')
  final bool emailTeamMemberJoined;
  @JsonKey(name: 'email_team_member_left')
  final bool emailTeamMemberLeft;
  @JsonKey(name: 'email_team_member_removed')
  final bool emailTeamMemberRemoved;
  @JsonKey(name: 'email_team_member_role_changed')
  final bool emailTeamMemberRoleChanged;
  @JsonKey(name: 'email_team_settings_updated')
  final bool emailTeamSettingsUpdated;
  @JsonKey(name: 'email_claim_submitted')
  final bool emailClaimSubmitted;
  @JsonKey(name: 'email_claim_approved')
  final bool emailClaimApproved;
  @JsonKey(name: 'email_claim_rejected')
  final bool emailClaimRejected;
  @JsonKey(name: 'email_claim_review_requested')
  final bool emailClaimReviewRequested;

  // Push notification preferences
  @JsonKey(name: 'push_enabled')
  final bool pushEnabled;
  @JsonKey(name: 'push_receipt_processing_started')
  final bool pushReceiptProcessingStarted;
  @JsonKey(name: 'push_receipt_processing_completed')
  final bool pushReceiptProcessingCompleted;
  @JsonKey(name: 'push_receipt_processing_failed')
  final bool pushReceiptProcessingFailed;
  @JsonKey(name: 'push_receipt_ready_for_review')
  final bool pushReceiptReadyForReview;
  @JsonKey(name: 'push_receipt_batch_completed')
  final bool pushReceiptBatchCompleted;
  @JsonKey(name: 'push_receipt_batch_failed')
  final bool pushReceiptBatchFailed;
  @JsonKey(name: 'push_receipt_shared')
  final bool pushReceiptShared;
  @JsonKey(name: 'push_receipt_comment_added')
  final bool pushReceiptCommentAdded;
  @JsonKey(name: 'push_receipt_edited_by_team_member')
  final bool pushReceiptEditedByTeamMember;
  @JsonKey(name: 'push_receipt_approved_by_team')
  final bool pushReceiptApprovedByTeam;
  @JsonKey(name: 'push_receipt_flagged_for_review')
  final bool pushReceiptFlaggedForReview;
  @JsonKey(name: 'push_team_invitation_sent')
  final bool pushTeamInvitationSent;
  @JsonKey(name: 'push_team_invitation_accepted')
  final bool pushTeamInvitationAccepted;
  @JsonKey(name: 'push_team_member_joined')
  final bool pushTeamMemberJoined;
  @JsonKey(name: 'push_team_member_left')
  final bool pushTeamMemberLeft;
  @JsonKey(name: 'push_team_member_removed')
  final bool pushTeamMemberRemoved;
  @JsonKey(name: 'push_team_member_role_changed')
  final bool pushTeamMemberRoleChanged;
  @JsonKey(name: 'push_team_settings_updated')
  final bool pushTeamSettingsUpdated;
  @JsonKey(name: 'push_claim_submitted')
  final bool pushClaimSubmitted;
  @JsonKey(name: 'push_claim_approved')
  final bool pushClaimApproved;
  @JsonKey(name: 'push_claim_rejected')
  final bool pushClaimRejected;
  @JsonKey(name: 'push_claim_review_requested')
  final bool pushClaimReviewRequested;

  // Browser notification preferences
  @JsonKey(name: 'browser_permission_granted')
  final bool browserPermissionGranted;
  @JsonKey(name: 'browser_permission_requested_at')
  final DateTime? browserPermissionRequestedAt;

  // Notification timing preferences
  @JsonKey(name: 'quiet_hours_enabled')
  final bool quietHoursEnabled;
  @JsonKey(name: 'quiet_hours_start')
  final String? quietHoursStart; // HH:MM format
  @JsonKey(name: 'quiet_hours_end')
  final String? quietHoursEnd; // HH:MM format
  final String timezone;

  // Digest preferences
  @JsonKey(name: 'daily_digest_enabled')
  final bool dailyDigestEnabled;
  @JsonKey(name: 'weekly_digest_enabled')
  final bool weeklyDigestEnabled;
  @JsonKey(name: 'digest_time')
  final String? digestTime; // HH:MM format

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const NotificationPreferences({
    this.id,
    required this.userId,
    required this.emailEnabled,
    required this.emailReceiptProcessingStarted,
    required this.emailReceiptProcessingCompleted,
    required this.emailReceiptProcessingFailed,
    required this.emailReceiptReadyForReview,
    required this.emailReceiptBatchCompleted,
    required this.emailReceiptBatchFailed,
    required this.emailReceiptShared,
    required this.emailReceiptCommentAdded,
    required this.emailReceiptEditedByTeamMember,
    required this.emailReceiptApprovedByTeam,
    required this.emailReceiptFlaggedForReview,
    required this.emailTeamInvitationSent,
    required this.emailTeamInvitationAccepted,
    required this.emailTeamMemberJoined,
    required this.emailTeamMemberLeft,
    required this.emailTeamMemberRemoved,
    required this.emailTeamMemberRoleChanged,
    required this.emailTeamSettingsUpdated,
    required this.emailClaimSubmitted,
    required this.emailClaimApproved,
    required this.emailClaimRejected,
    required this.emailClaimReviewRequested,
    required this.pushEnabled,
    required this.pushReceiptProcessingStarted,
    required this.pushReceiptProcessingCompleted,
    required this.pushReceiptProcessingFailed,
    required this.pushReceiptReadyForReview,
    required this.pushReceiptBatchCompleted,
    required this.pushReceiptBatchFailed,
    required this.pushReceiptShared,
    required this.pushReceiptCommentAdded,
    required this.pushReceiptEditedByTeamMember,
    required this.pushReceiptApprovedByTeam,
    required this.pushReceiptFlaggedForReview,
    required this.pushTeamInvitationSent,
    required this.pushTeamInvitationAccepted,
    required this.pushTeamMemberJoined,
    required this.pushTeamMemberLeft,
    required this.pushTeamMemberRemoved,
    required this.pushTeamMemberRoleChanged,
    required this.pushTeamSettingsUpdated,
    required this.pushClaimSubmitted,
    required this.pushClaimApproved,
    required this.pushClaimRejected,
    required this.pushClaimReviewRequested,
    required this.browserPermissionGranted,
    this.browserPermissionRequestedAt,
    required this.quietHoursEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.timezone,
    required this.dailyDigestEnabled,
    required this.weeklyDigestEnabled,
    this.digestTime,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  /// Create default notification preferences
  factory NotificationPreferences.defaults(String userId) {
    return NotificationPreferences(
      userId: userId,
      emailEnabled: true,
      emailReceiptProcessingStarted: false,
      emailReceiptProcessingCompleted: true,
      emailReceiptProcessingFailed: true,
      emailReceiptReadyForReview: false,
      emailReceiptBatchCompleted: true,
      emailReceiptBatchFailed: true,
      emailReceiptShared: false,
      emailReceiptCommentAdded: false,
      emailReceiptEditedByTeamMember: false,
      emailReceiptApprovedByTeam: false,
      emailReceiptFlaggedForReview: false,
      emailTeamInvitationSent: true,
      emailTeamInvitationAccepted: true,
      emailTeamMemberJoined: false,
      emailTeamMemberLeft: false,
      emailTeamMemberRemoved: true,
      emailTeamMemberRoleChanged: true,
      emailTeamSettingsUpdated: false,
      emailClaimSubmitted: true,
      emailClaimApproved: true,
      emailClaimRejected: true,
      emailClaimReviewRequested: true,
      pushEnabled: true,
      pushReceiptProcessingStarted: true,
      pushReceiptProcessingCompleted: true,
      pushReceiptProcessingFailed: true,
      pushReceiptReadyForReview: true,
      pushReceiptBatchCompleted: true,
      pushReceiptBatchFailed: true,
      pushReceiptShared: true,
      pushReceiptCommentAdded: true,
      pushReceiptEditedByTeamMember: true,
      pushReceiptApprovedByTeam: true,
      pushReceiptFlaggedForReview: true,
      pushTeamInvitationSent: true,
      pushTeamInvitationAccepted: true,
      pushTeamMemberJoined: true,
      pushTeamMemberLeft: false,
      pushTeamMemberRemoved: true,
      pushTeamMemberRoleChanged: true,
      pushTeamSettingsUpdated: false,
      pushClaimSubmitted: true,
      pushClaimApproved: true,
      pushClaimRejected: true,
      pushClaimReviewRequested: true,
      browserPermissionGranted: false,
      quietHoursEnabled: false,
      timezone: 'Asia/Kuala_Lumpur',
      dailyDigestEnabled: false,
      weeklyDigestEnabled: false,
      digestTime: '09:00',
    );
  }

  /// Copy with method for updating preferences
  NotificationPreferences copyWith({
    String? id,
    String? userId,
    bool? emailEnabled,
    bool? emailReceiptProcessingStarted,
    bool? emailReceiptProcessingCompleted,
    bool? emailReceiptProcessingFailed,
    bool? emailReceiptReadyForReview,
    bool? emailReceiptBatchCompleted,
    bool? emailReceiptBatchFailed,
    bool? emailReceiptShared,
    bool? emailReceiptCommentAdded,
    bool? emailReceiptEditedByTeamMember,
    bool? emailReceiptApprovedByTeam,
    bool? emailReceiptFlaggedForReview,
    bool? emailTeamInvitationSent,
    bool? emailTeamInvitationAccepted,
    bool? emailTeamMemberJoined,
    bool? emailTeamMemberLeft,
    bool? emailTeamMemberRemoved,
    bool? emailTeamMemberRoleChanged,
    bool? emailTeamSettingsUpdated,
    bool? emailClaimSubmitted,
    bool? emailClaimApproved,
    bool? emailClaimRejected,
    bool? emailClaimReviewRequested,
    bool? pushEnabled,
    bool? pushReceiptProcessingStarted,
    bool? pushReceiptProcessingCompleted,
    bool? pushReceiptProcessingFailed,
    bool? pushReceiptReadyForReview,
    bool? pushReceiptBatchCompleted,
    bool? pushReceiptBatchFailed,
    bool? pushReceiptShared,
    bool? pushReceiptCommentAdded,
    bool? pushReceiptEditedByTeamMember,
    bool? pushReceiptApprovedByTeam,
    bool? pushReceiptFlaggedForReview,
    bool? pushTeamInvitationSent,
    bool? pushTeamInvitationAccepted,
    bool? pushTeamMemberJoined,
    bool? pushTeamMemberLeft,
    bool? pushTeamMemberRemoved,
    bool? pushTeamMemberRoleChanged,
    bool? pushTeamSettingsUpdated,
    bool? pushClaimSubmitted,
    bool? pushClaimApproved,
    bool? pushClaimRejected,
    bool? pushClaimReviewRequested,
    bool? browserPermissionGranted,
    DateTime? browserPermissionRequestedAt,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
    bool? dailyDigestEnabled,
    bool? weeklyDigestEnabled,
    String? digestTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      emailReceiptProcessingStarted:
          emailReceiptProcessingStarted ?? this.emailReceiptProcessingStarted,
      emailReceiptProcessingCompleted:
          emailReceiptProcessingCompleted ??
          this.emailReceiptProcessingCompleted,
      emailReceiptProcessingFailed:
          emailReceiptProcessingFailed ?? this.emailReceiptProcessingFailed,
      emailReceiptReadyForReview:
          emailReceiptReadyForReview ?? this.emailReceiptReadyForReview,
      emailReceiptBatchCompleted:
          emailReceiptBatchCompleted ?? this.emailReceiptBatchCompleted,
      emailReceiptBatchFailed:
          emailReceiptBatchFailed ?? this.emailReceiptBatchFailed,
      emailReceiptShared: emailReceiptShared ?? this.emailReceiptShared,
      emailReceiptCommentAdded:
          emailReceiptCommentAdded ?? this.emailReceiptCommentAdded,
      emailReceiptEditedByTeamMember:
          emailReceiptEditedByTeamMember ?? this.emailReceiptEditedByTeamMember,
      emailReceiptApprovedByTeam:
          emailReceiptApprovedByTeam ?? this.emailReceiptApprovedByTeam,
      emailReceiptFlaggedForReview:
          emailReceiptFlaggedForReview ?? this.emailReceiptFlaggedForReview,
      emailTeamInvitationSent:
          emailTeamInvitationSent ?? this.emailTeamInvitationSent,
      emailTeamInvitationAccepted:
          emailTeamInvitationAccepted ?? this.emailTeamInvitationAccepted,
      emailTeamMemberJoined:
          emailTeamMemberJoined ?? this.emailTeamMemberJoined,
      emailTeamMemberLeft: emailTeamMemberLeft ?? this.emailTeamMemberLeft,
      emailTeamMemberRemoved:
          emailTeamMemberRemoved ?? this.emailTeamMemberRemoved,
      emailTeamMemberRoleChanged:
          emailTeamMemberRoleChanged ?? this.emailTeamMemberRoleChanged,
      emailTeamSettingsUpdated:
          emailTeamSettingsUpdated ?? this.emailTeamSettingsUpdated,
      emailClaimSubmitted: emailClaimSubmitted ?? this.emailClaimSubmitted,
      emailClaimApproved: emailClaimApproved ?? this.emailClaimApproved,
      emailClaimRejected: emailClaimRejected ?? this.emailClaimRejected,
      emailClaimReviewRequested:
          emailClaimReviewRequested ?? this.emailClaimReviewRequested,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      pushReceiptProcessingStarted:
          pushReceiptProcessingStarted ?? this.pushReceiptProcessingStarted,
      pushReceiptProcessingCompleted:
          pushReceiptProcessingCompleted ?? this.pushReceiptProcessingCompleted,
      pushReceiptProcessingFailed:
          pushReceiptProcessingFailed ?? this.pushReceiptProcessingFailed,
      pushReceiptReadyForReview:
          pushReceiptReadyForReview ?? this.pushReceiptReadyForReview,
      pushReceiptBatchCompleted:
          pushReceiptBatchCompleted ?? this.pushReceiptBatchCompleted,
      pushReceiptBatchFailed:
          pushReceiptBatchFailed ?? this.pushReceiptBatchFailed,
      pushReceiptShared: pushReceiptShared ?? this.pushReceiptShared,
      pushReceiptCommentAdded:
          pushReceiptCommentAdded ?? this.pushReceiptCommentAdded,
      pushReceiptEditedByTeamMember:
          pushReceiptEditedByTeamMember ?? this.pushReceiptEditedByTeamMember,
      pushReceiptApprovedByTeam:
          pushReceiptApprovedByTeam ?? this.pushReceiptApprovedByTeam,
      pushReceiptFlaggedForReview:
          pushReceiptFlaggedForReview ?? this.pushReceiptFlaggedForReview,
      pushTeamInvitationSent:
          pushTeamInvitationSent ?? this.pushTeamInvitationSent,
      pushTeamInvitationAccepted:
          pushTeamInvitationAccepted ?? this.pushTeamInvitationAccepted,
      pushTeamMemberJoined: pushTeamMemberJoined ?? this.pushTeamMemberJoined,
      pushTeamMemberLeft: pushTeamMemberLeft ?? this.pushTeamMemberLeft,
      pushTeamMemberRemoved:
          pushTeamMemberRemoved ?? this.pushTeamMemberRemoved,
      pushTeamMemberRoleChanged:
          pushTeamMemberRoleChanged ?? this.pushTeamMemberRoleChanged,
      pushTeamSettingsUpdated:
          pushTeamSettingsUpdated ?? this.pushTeamSettingsUpdated,
      pushClaimSubmitted: pushClaimSubmitted ?? this.pushClaimSubmitted,
      pushClaimApproved: pushClaimApproved ?? this.pushClaimApproved,
      pushClaimRejected: pushClaimRejected ?? this.pushClaimRejected,
      pushClaimReviewRequested:
          pushClaimReviewRequested ?? this.pushClaimReviewRequested,
      browserPermissionGranted:
          browserPermissionGranted ?? this.browserPermissionGranted,
      browserPermissionRequestedAt:
          browserPermissionRequestedAt ?? this.browserPermissionRequestedAt,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
      digestTime: digestTime ?? this.digestTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    emailEnabled,
    emailReceiptProcessingStarted,
    emailReceiptProcessingCompleted,
    emailReceiptProcessingFailed,
    emailReceiptReadyForReview,
    emailReceiptBatchCompleted,
    emailReceiptBatchFailed,
    emailReceiptShared,
    emailReceiptCommentAdded,
    emailReceiptEditedByTeamMember,
    emailReceiptApprovedByTeam,
    emailReceiptFlaggedForReview,
    emailTeamInvitationSent,
    emailTeamInvitationAccepted,
    emailTeamMemberJoined,
    emailTeamMemberLeft,
    emailTeamMemberRemoved,
    emailTeamMemberRoleChanged,
    emailTeamSettingsUpdated,
    emailClaimSubmitted,
    emailClaimApproved,
    emailClaimRejected,
    emailClaimReviewRequested,
    pushEnabled,
    pushReceiptProcessingStarted,
    pushReceiptProcessingCompleted,
    pushReceiptProcessingFailed,
    pushReceiptReadyForReview,
    pushReceiptBatchCompleted,
    pushReceiptBatchFailed,
    pushReceiptShared,
    pushReceiptCommentAdded,
    pushReceiptEditedByTeamMember,
    pushReceiptApprovedByTeam,
    pushReceiptFlaggedForReview,
    pushTeamInvitationSent,
    pushTeamInvitationAccepted,
    pushTeamMemberJoined,
    pushTeamMemberLeft,
    pushTeamMemberRemoved,
    pushTeamMemberRoleChanged,
    pushTeamSettingsUpdated,
    pushClaimSubmitted,
    pushClaimApproved,
    pushClaimRejected,
    pushClaimReviewRequested,
    browserPermissionGranted,
    browserPermissionRequestedAt,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
    timezone,
    dailyDigestEnabled,
    weeklyDigestEnabled,
    digestTime,
    createdAt,
    updatedAt,
  ];

  /// Get email preference for a notification type
  bool getEmailPreference(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessingStarted:
        return emailReceiptProcessingStarted;
      case NotificationType.receiptProcessingCompleted:
        return emailReceiptProcessingCompleted;
      case NotificationType.receiptProcessingFailed:
        return emailReceiptProcessingFailed;
      case NotificationType.receiptReadyForReview:
        return emailReceiptReadyForReview;
      case NotificationType.receiptBatchCompleted:
        return emailReceiptBatchCompleted;
      case NotificationType.receiptBatchFailed:
        return emailReceiptBatchFailed;
      case NotificationType.receiptShared:
        return emailReceiptShared;
      case NotificationType.receiptCommentAdded:
        return emailReceiptCommentAdded;
      case NotificationType.receiptEditedByTeamMember:
        return emailReceiptEditedByTeamMember;
      case NotificationType.receiptApprovedByTeam:
        return emailReceiptApprovedByTeam;
      case NotificationType.receiptFlaggedForReview:
        return emailReceiptFlaggedForReview;
      case NotificationType.teamInvitationSent:
        return emailTeamInvitationSent;
      case NotificationType.teamInvitationAccepted:
        return emailTeamInvitationAccepted;
      case NotificationType.teamMemberJoined:
        return emailTeamMemberJoined;
      case NotificationType.teamMemberLeft:
        return emailTeamMemberLeft;
      case NotificationType.teamMemberRemoved:
        return emailTeamMemberRemoved;
      case NotificationType.teamMemberRoleChanged:
        return emailTeamMemberRoleChanged;
      case NotificationType.teamSettingsUpdated:
        return emailTeamSettingsUpdated;
      case NotificationType.claimSubmitted:
        return emailClaimSubmitted;
      case NotificationType.claimApproved:
        return emailClaimApproved;
      case NotificationType.claimRejected:
        return emailClaimRejected;
      case NotificationType.claimReviewRequested:
        return emailClaimReviewRequested;
    }
  }

  /// Get push preference for a notification type
  bool getPushPreference(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessingStarted:
        return pushReceiptProcessingStarted;
      case NotificationType.receiptProcessingCompleted:
        return pushReceiptProcessingCompleted;
      case NotificationType.receiptProcessingFailed:
        return pushReceiptProcessingFailed;
      case NotificationType.receiptReadyForReview:
        return pushReceiptReadyForReview;
      case NotificationType.receiptBatchCompleted:
        return pushReceiptBatchCompleted;
      case NotificationType.receiptBatchFailed:
        return pushReceiptBatchFailed;
      case NotificationType.receiptShared:
        return pushReceiptShared;
      case NotificationType.receiptCommentAdded:
        return pushReceiptCommentAdded;
      case NotificationType.receiptEditedByTeamMember:
        return pushReceiptEditedByTeamMember;
      case NotificationType.receiptApprovedByTeam:
        return pushReceiptApprovedByTeam;
      case NotificationType.receiptFlaggedForReview:
        return pushReceiptFlaggedForReview;
      case NotificationType.teamInvitationSent:
        return pushTeamInvitationSent;
      case NotificationType.teamInvitationAccepted:
        return pushTeamInvitationAccepted;
      case NotificationType.teamMemberJoined:
        return pushTeamMemberJoined;
      case NotificationType.teamMemberLeft:
        return pushTeamMemberLeft;
      case NotificationType.teamMemberRemoved:
        return pushTeamMemberRemoved;
      case NotificationType.teamMemberRoleChanged:
        return pushTeamMemberRoleChanged;
      case NotificationType.teamSettingsUpdated:
        return pushTeamSettingsUpdated;
      case NotificationType.claimSubmitted:
        return pushClaimSubmitted;
      case NotificationType.claimApproved:
        return pushClaimApproved;
      case NotificationType.claimRejected:
        return pushClaimRejected;
      case NotificationType.claimReviewRequested:
        return pushClaimReviewRequested;
    }
  }
}
