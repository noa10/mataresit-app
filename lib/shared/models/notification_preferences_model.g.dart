// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreferences _$NotificationPreferencesFromJson(
  Map<String, dynamic> json,
) => NotificationPreferences(
  id: json['id'] as String?,
  userId: json['user_id'] as String,
  emailEnabled: json['email_enabled'] as bool,
  emailReceiptProcessingStarted:
      json['email_receipt_processing_started'] as bool,
  emailReceiptProcessingCompleted:
      json['email_receipt_processing_completed'] as bool,
  emailReceiptProcessingFailed: json['email_receipt_processing_failed'] as bool,
  emailReceiptReadyForReview: json['email_receipt_ready_for_review'] as bool,
  emailReceiptBatchCompleted: json['email_receipt_batch_completed'] as bool,
  emailReceiptBatchFailed: json['email_receipt_batch_failed'] as bool,
  emailReceiptShared: json['email_receipt_shared'] as bool,
  emailReceiptCommentAdded: json['email_receipt_comment_added'] as bool,
  emailReceiptEditedByTeamMember:
      json['email_receipt_edited_by_team_member'] as bool,
  emailReceiptApprovedByTeam: json['email_receipt_approved_by_team'] as bool,
  emailReceiptFlaggedForReview:
      json['email_receipt_flagged_for_review'] as bool,
  emailTeamInvitationSent: json['email_team_invitation_sent'] as bool,
  emailTeamInvitationAccepted: json['email_team_invitation_accepted'] as bool,
  emailTeamMemberJoined: json['email_team_member_joined'] as bool,
  emailTeamMemberLeft: json['email_team_member_left'] as bool,
  emailTeamMemberRemoved: json['email_team_member_removed'] as bool,
  emailTeamMemberRoleChanged: json['email_team_member_role_changed'] as bool,
  emailTeamSettingsUpdated: json['email_team_settings_updated'] as bool,
  emailClaimSubmitted: json['email_claim_submitted'] as bool,
  emailClaimApproved: json['email_claim_approved'] as bool,
  emailClaimRejected: json['email_claim_rejected'] as bool,
  emailClaimReviewRequested: json['email_claim_review_requested'] as bool,
  pushEnabled: json['push_enabled'] as bool,
  pushReceiptProcessingStarted: json['push_receipt_processing_started'] as bool,
  pushReceiptProcessingCompleted:
      json['push_receipt_processing_completed'] as bool,
  pushReceiptProcessingFailed: json['push_receipt_processing_failed'] as bool,
  pushReceiptReadyForReview: json['push_receipt_ready_for_review'] as bool,
  pushReceiptBatchCompleted: json['push_receipt_batch_completed'] as bool,
  pushReceiptBatchFailed: json['push_receipt_batch_failed'] as bool,
  pushReceiptShared: json['push_receipt_shared'] as bool,
  pushReceiptCommentAdded: json['push_receipt_comment_added'] as bool,
  pushReceiptEditedByTeamMember:
      json['push_receipt_edited_by_team_member'] as bool,
  pushReceiptApprovedByTeam: json['push_receipt_approved_by_team'] as bool,
  pushReceiptFlaggedForReview: json['push_receipt_flagged_for_review'] as bool,
  pushTeamInvitationSent: json['push_team_invitation_sent'] as bool,
  pushTeamInvitationAccepted: json['push_team_invitation_accepted'] as bool,
  pushTeamMemberJoined: json['push_team_member_joined'] as bool,
  pushTeamMemberLeft: json['push_team_member_left'] as bool,
  pushTeamMemberRemoved: json['push_team_member_removed'] as bool,
  pushTeamMemberRoleChanged: json['push_team_member_role_changed'] as bool,
  pushTeamSettingsUpdated: json['push_team_settings_updated'] as bool,
  pushClaimSubmitted: json['push_claim_submitted'] as bool,
  pushClaimApproved: json['push_claim_approved'] as bool,
  pushClaimRejected: json['push_claim_rejected'] as bool,
  pushClaimReviewRequested: json['push_claim_review_requested'] as bool,
  browserPermissionGranted: json['browser_permission_granted'] as bool,
  browserPermissionRequestedAt: json['browser_permission_requested_at'] == null
      ? null
      : DateTime.parse(json['browser_permission_requested_at'] as String),
  quietHoursEnabled: json['quiet_hours_enabled'] as bool,
  quietHoursStart: json['quiet_hours_start'] as String?,
  quietHoursEnd: json['quiet_hours_end'] as String?,
  timezone: json['timezone'] as String,
  dailyDigestEnabled: json['daily_digest_enabled'] as bool,
  weeklyDigestEnabled: json['weekly_digest_enabled'] as bool,
  digestTime: json['digest_time'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$NotificationPreferencesToJson(
  NotificationPreferences instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'email_enabled': instance.emailEnabled,
  'email_receipt_processing_started': instance.emailReceiptProcessingStarted,
  'email_receipt_processing_completed':
      instance.emailReceiptProcessingCompleted,
  'email_receipt_processing_failed': instance.emailReceiptProcessingFailed,
  'email_receipt_ready_for_review': instance.emailReceiptReadyForReview,
  'email_receipt_batch_completed': instance.emailReceiptBatchCompleted,
  'email_receipt_batch_failed': instance.emailReceiptBatchFailed,
  'email_receipt_shared': instance.emailReceiptShared,
  'email_receipt_comment_added': instance.emailReceiptCommentAdded,
  'email_receipt_edited_by_team_member':
      instance.emailReceiptEditedByTeamMember,
  'email_receipt_approved_by_team': instance.emailReceiptApprovedByTeam,
  'email_receipt_flagged_for_review': instance.emailReceiptFlaggedForReview,
  'email_team_invitation_sent': instance.emailTeamInvitationSent,
  'email_team_invitation_accepted': instance.emailTeamInvitationAccepted,
  'email_team_member_joined': instance.emailTeamMemberJoined,
  'email_team_member_left': instance.emailTeamMemberLeft,
  'email_team_member_removed': instance.emailTeamMemberRemoved,
  'email_team_member_role_changed': instance.emailTeamMemberRoleChanged,
  'email_team_settings_updated': instance.emailTeamSettingsUpdated,
  'email_claim_submitted': instance.emailClaimSubmitted,
  'email_claim_approved': instance.emailClaimApproved,
  'email_claim_rejected': instance.emailClaimRejected,
  'email_claim_review_requested': instance.emailClaimReviewRequested,
  'push_enabled': instance.pushEnabled,
  'push_receipt_processing_started': instance.pushReceiptProcessingStarted,
  'push_receipt_processing_completed': instance.pushReceiptProcessingCompleted,
  'push_receipt_processing_failed': instance.pushReceiptProcessingFailed,
  'push_receipt_ready_for_review': instance.pushReceiptReadyForReview,
  'push_receipt_batch_completed': instance.pushReceiptBatchCompleted,
  'push_receipt_batch_failed': instance.pushReceiptBatchFailed,
  'push_receipt_shared': instance.pushReceiptShared,
  'push_receipt_comment_added': instance.pushReceiptCommentAdded,
  'push_receipt_edited_by_team_member': instance.pushReceiptEditedByTeamMember,
  'push_receipt_approved_by_team': instance.pushReceiptApprovedByTeam,
  'push_receipt_flagged_for_review': instance.pushReceiptFlaggedForReview,
  'push_team_invitation_sent': instance.pushTeamInvitationSent,
  'push_team_invitation_accepted': instance.pushTeamInvitationAccepted,
  'push_team_member_joined': instance.pushTeamMemberJoined,
  'push_team_member_left': instance.pushTeamMemberLeft,
  'push_team_member_removed': instance.pushTeamMemberRemoved,
  'push_team_member_role_changed': instance.pushTeamMemberRoleChanged,
  'push_team_settings_updated': instance.pushTeamSettingsUpdated,
  'push_claim_submitted': instance.pushClaimSubmitted,
  'push_claim_approved': instance.pushClaimApproved,
  'push_claim_rejected': instance.pushClaimRejected,
  'push_claim_review_requested': instance.pushClaimReviewRequested,
  'browser_permission_granted': instance.browserPermissionGranted,
  'browser_permission_requested_at': instance.browserPermissionRequestedAt
      ?.toIso8601String(),
  'quiet_hours_enabled': instance.quietHoursEnabled,
  'quiet_hours_start': instance.quietHoursStart,
  'quiet_hours_end': instance.quietHoursEnd,
  'timezone': instance.timezone,
  'daily_digest_enabled': instance.dailyDigestEnabled,
  'weekly_digest_enabled': instance.weeklyDigestEnabled,
  'digest_time': instance.digestTime,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
