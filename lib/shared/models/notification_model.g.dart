// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      teamId: json['team_id'] as String?,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      priority: $enumDecode(_$NotificationPriorityEnumMap, json['priority']),
      title: json['title'] as String,
      message: json['message'] as String,
      actionUrl: json['action_url'] as String?,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      teamName: json['team_name'] as String?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipient_id': instance.recipientId,
      'team_id': instance.teamId,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'title': instance.title,
      'message': instance.message,
      'action_url': instance.actionUrl,
      'read_at': instance.readAt?.toIso8601String(),
      'archived_at': instance.archivedAt?.toIso8601String(),
      'related_entity_type': instance.relatedEntityType,
      'related_entity_id': instance.relatedEntityId,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'team_name': instance.teamName,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.teamInvitationSent: 'team_invitation_sent',
  NotificationType.teamInvitationAccepted: 'team_invitation_accepted',
  NotificationType.teamMemberJoined: 'team_member_joined',
  NotificationType.teamMemberLeft: 'team_member_left',
  NotificationType.teamMemberRemoved: 'team_member_removed',
  NotificationType.teamMemberRoleChanged: 'team_member_role_changed',
  NotificationType.claimSubmitted: 'claim_submitted',
  NotificationType.claimApproved: 'claim_approved',
  NotificationType.claimRejected: 'claim_rejected',
  NotificationType.claimReviewRequested: 'claim_review_requested',
  NotificationType.teamSettingsUpdated: 'team_settings_updated',
  NotificationType.receiptProcessingStarted: 'receipt_processing_started',
  NotificationType.receiptProcessingCompleted: 'receipt_processing_completed',
  NotificationType.receiptProcessingFailed: 'receipt_processing_failed',
  NotificationType.receiptReadyForReview: 'receipt_ready_for_review',
  NotificationType.receiptBatchCompleted: 'receipt_batch_completed',
  NotificationType.receiptBatchFailed: 'receipt_batch_failed',
  NotificationType.receiptShared: 'receipt_shared',
  NotificationType.receiptCommentAdded: 'receipt_comment_added',
  NotificationType.receiptEditedByTeamMember: 'receipt_edited_by_team_member',
  NotificationType.receiptApprovedByTeam: 'receipt_approved_by_team',
  NotificationType.receiptFlaggedForReview: 'receipt_flagged_for_review',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.medium: 'medium',
  NotificationPriority.high: 'high',
};

NotificationFilters _$NotificationFiltersFromJson(Map<String, dynamic> json) =>
    NotificationFilters(
      teamId: json['team_id'] as String?,
      type: $enumDecodeNullable(_$NotificationTypeEnumMap, json['type']),
      priority: $enumDecodeNullable(
        _$NotificationPriorityEnumMap,
        json['priority'],
      ),
      unreadOnly: json['unread_only'] as bool?,
      dateFrom: json['date_from'] == null
          ? null
          : DateTime.parse(json['date_from'] as String),
      dateTo: json['date_to'] == null
          ? null
          : DateTime.parse(json['date_to'] as String),
    );

Map<String, dynamic> _$NotificationFiltersToJson(
  NotificationFilters instance,
) => <String, dynamic>{
  'team_id': instance.teamId,
  'type': _$NotificationTypeEnumMap[instance.type],
  'priority': _$NotificationPriorityEnumMap[instance.priority],
  'unread_only': instance.unreadOnly,
  'date_from': instance.dateFrom?.toIso8601String(),
  'date_to': instance.dateTo?.toIso8601String(),
};

NotificationStats _$NotificationStatsFromJson(Map<String, dynamic> json) =>
    NotificationStats(
      totalNotifications: (json['total_notifications'] as num).toInt(),
      unreadNotifications: (json['unread_notifications'] as num).toInt(),
      highPriorityUnread: (json['high_priority_unread'] as num).toInt(),
      notificationsByType:
          (json['notifications_by_type'] as Map<String, dynamic>).map(
            (k, e) => MapEntry(
              $enumDecode(_$NotificationTypeEnumMap, k),
              (e as num).toInt(),
            ),
          ),
    );

Map<String, dynamic> _$NotificationStatsToJson(NotificationStats instance) =>
    <String, dynamic>{
      'total_notifications': instance.totalNotifications,
      'unread_notifications': instance.unreadNotifications,
      'high_priority_unread': instance.highPriorityUnread,
      'notifications_by_type': instance.notificationsByType.map(
        (k, e) => MapEntry(_$NotificationTypeEnumMap[k]!, e),
      ),
    };
