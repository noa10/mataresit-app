import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

/// Notification types matching the React app implementation
enum NotificationType {
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
  @JsonValue('claim_submitted')
  claimSubmitted,
  @JsonValue('claim_approved')
  claimApproved,
  @JsonValue('claim_rejected')
  claimRejected,
  @JsonValue('claim_review_requested')
  claimReviewRequested,
  @JsonValue('team_settings_updated')
  teamSettingsUpdated,

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
}

/// Notification priority levels
enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
}

/// Main notification model matching React app structure
@JsonSerializable()
class NotificationModel extends Equatable {
  final String id;
  @JsonKey(name: 'recipient_id')
  final String recipientId;
  @JsonKey(name: 'team_id')
  final String? teamId;
  final NotificationType type;
  final NotificationPriority priority;

  // Content
  final String title;
  final String message;
  @JsonKey(name: 'action_url')
  final String? actionUrl;

  // Status
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  @JsonKey(name: 'archived_at')
  final DateTime? archivedAt;

  // Related entities
  @JsonKey(name: 'related_entity_type')
  final String? relatedEntityType;
  @JsonKey(name: 'related_entity_id')
  final String? relatedEntityId;

  // Metadata
  final Map<String, dynamic> metadata;

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  // Joined data
  @JsonKey(name: 'team_name')
  final String? teamName;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    this.teamId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.actionUrl,
    this.readAt,
    this.archivedAt,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.metadata,
    required this.createdAt,
    this.expiresAt,
    this.teamName,
  });

  /// Check if notification is unread
  bool get isUnread => readAt == null;

  /// Check if notification is archived
  bool get isArchived => archivedAt != null;

  /// Check if notification is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Get notification age in minutes
  int get ageInMinutes => DateTime.now().difference(createdAt).inMinutes;

  /// Get notification age in hours
  int get ageInHours => DateTime.now().difference(createdAt).inHours;

  /// Get notification age in days
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Create copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? teamId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    String? actionUrl,
    DateTime? readAt,
    DateTime? archivedAt,
    String? relatedEntityType,
    String? relatedEntityId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? teamName,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      teamId: teamId ?? this.teamId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      teamName: teamName ?? this.teamName,
    );
  }

  /// Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    recipientId,
    teamId,
    type,
    priority,
    title,
    message,
    actionUrl,
    readAt,
    archivedAt,
    relatedEntityType,
    relatedEntityId,
    metadata,
    createdAt,
    expiresAt,
    teamName,
  ];
}

/// Notification filters for querying
@JsonSerializable()
class NotificationFilters extends Equatable {
  @JsonKey(name: 'team_id')
  final String? teamId;
  final NotificationType? type;
  final NotificationPriority? priority;
  @JsonKey(name: 'unread_only')
  final bool? unreadOnly;
  @JsonKey(name: 'date_from')
  final DateTime? dateFrom;
  @JsonKey(name: 'date_to')
  final DateTime? dateTo;

  const NotificationFilters({
    this.teamId,
    this.type,
    this.priority,
    this.unreadOnly,
    this.dateFrom,
    this.dateTo,
  });

  /// Create from JSON
  factory NotificationFilters.fromJson(Map<String, dynamic> json) =>
      _$NotificationFiltersFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$NotificationFiltersToJson(this);

  /// Create a copy with updated values
  NotificationFilters copyWith({
    String? teamId,
    NotificationType? type,
    NotificationPriority? priority,
    bool? unreadOnly,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return NotificationFilters(
      teamId: teamId ?? this.teamId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }

  @override
  List<Object?> get props => [
    teamId,
    type,
    priority,
    unreadOnly,
    dateFrom,
    dateTo,
  ];
}

/// Notification statistics
@JsonSerializable()
class NotificationStats extends Equatable {
  @JsonKey(name: 'total_notifications')
  final int totalNotifications;
  @JsonKey(name: 'unread_notifications')
  final int unreadNotifications;
  @JsonKey(name: 'high_priority_unread')
  final int highPriorityUnread;
  @JsonKey(name: 'notifications_by_type')
  final Map<NotificationType, int> notificationsByType;

  const NotificationStats({
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.highPriorityUnread,
    required this.notificationsByType,
  });

  /// Create from JSON
  factory NotificationStats.fromJson(Map<String, dynamic> json) =>
      _$NotificationStatsFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$NotificationStatsToJson(this);

  @override
  List<Object?> get props => [
    totalNotifications,
    unreadNotifications,
    highPriorityUnread,
    notificationsByType,
  ];
}
