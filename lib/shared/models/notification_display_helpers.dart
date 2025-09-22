import 'package:flutter/material.dart';
import 'notification_model.dart';

/// Notification display helpers matching React app implementation
class NotificationDisplayHelpers {
  /// Icons for different notification types
  static const Map<NotificationType, IconData> notificationTypeIcons = {
    // Team collaboration notifications
    NotificationType.teamInvitationSent: Icons.mail_outline,
    NotificationType.teamInvitationAccepted: Icons.check_circle,
    NotificationType.teamMemberJoined: Icons.person_add,
    NotificationType.teamMemberLeft: Icons.person_remove,
    NotificationType.teamMemberRemoved: Icons.block,
    NotificationType.teamMemberRoleChanged: Icons.swap_horiz,
    NotificationType.claimSubmitted: Icons.description,
    NotificationType.claimApproved: Icons.check_circle,
    NotificationType.claimRejected: Icons.cancel,
    NotificationType.claimReviewRequested: Icons.visibility,
    NotificationType.teamSettingsUpdated: Icons.settings,

    // Receipt processing notifications
    NotificationType.receiptProcessingStarted: Icons.flash_on,
    NotificationType.receiptProcessingCompleted: Icons.check_circle,
    NotificationType.receiptProcessingFailed: Icons.error,
    NotificationType.receiptReadyForReview: Icons.visibility,
    NotificationType.receiptBatchCompleted: Icons.inventory,
    NotificationType.receiptBatchFailed: Icons.warning,

    // Team receipt collaboration notifications
    NotificationType.receiptShared: Icons.share,
    NotificationType.receiptCommentAdded: Icons.comment,
    NotificationType.receiptEditedByTeamMember: Icons.edit,
    NotificationType.receiptApprovedByTeam: Icons.check_circle,
    NotificationType.receiptFlaggedForReview: Icons.flag,
  };

  /// Colors for different notification types
  static const Map<NotificationType, Color> notificationTypeColors = {
    // Team collaboration notifications
    NotificationType.teamInvitationSent: Colors.blue,
    NotificationType.teamInvitationAccepted: Colors.green,
    NotificationType.teamMemberJoined: Colors.green,
    NotificationType.teamMemberLeft: Colors.grey,
    NotificationType.teamMemberRemoved: Colors.red,
    NotificationType.teamMemberRoleChanged: Colors.blue,
    NotificationType.claimSubmitted: Colors.blue,
    NotificationType.claimApproved: Colors.green,
    NotificationType.claimRejected: Colors.red,
    NotificationType.claimReviewRequested: Colors.orange,
    NotificationType.teamSettingsUpdated: Colors.grey,

    // Receipt processing notifications
    NotificationType.receiptProcessingStarted: Colors.blue,
    NotificationType.receiptProcessingCompleted: Colors.green,
    NotificationType.receiptProcessingFailed: Colors.red,
    NotificationType.receiptReadyForReview: Colors.orange,
    NotificationType.receiptBatchCompleted: Colors.green,
    NotificationType.receiptBatchFailed: Colors.red,

    // Team receipt collaboration notifications
    NotificationType.receiptShared: Colors.blue,
    NotificationType.receiptCommentAdded: Colors.purple,
    NotificationType.receiptEditedByTeamMember: Colors.orange,
    NotificationType.receiptApprovedByTeam: Colors.green,
    NotificationType.receiptFlaggedForReview: Colors.red,
  };

  /// Colors for different priority levels
  static const Map<NotificationPriority, Color> priorityColors = {
    NotificationPriority.low: Colors.grey,
    NotificationPriority.medium: Colors.blue,
    NotificationPriority.high: Colors.red,
  };

  /// Display names for notification types
  static const Map<NotificationType, String> notificationTypeDisplayNames = {
    // Team collaboration notifications
    NotificationType.teamInvitationSent: 'Team Invitation Sent',
    NotificationType.teamInvitationAccepted: 'Team Invitation Accepted',
    NotificationType.teamMemberJoined: 'Team Member Joined',
    NotificationType.teamMemberLeft: 'Team Member Left',
    NotificationType.teamMemberRemoved: 'Team Member Removed',
    NotificationType.teamMemberRoleChanged: 'Team Member Role Changed',
    NotificationType.claimSubmitted: 'Claim Submitted',
    NotificationType.claimApproved: 'Claim Approved',
    NotificationType.claimRejected: 'Claim Rejected',
    NotificationType.claimReviewRequested: 'Claim Review Requested',
    NotificationType.teamSettingsUpdated: 'Team Settings Updated',

    // Receipt processing notifications
    NotificationType.receiptProcessingStarted: 'Receipt Processing Started',
    NotificationType.receiptProcessingCompleted: 'Receipt Processing Completed',
    NotificationType.receiptProcessingFailed: 'Receipt Processing Failed',
    NotificationType.receiptReadyForReview: 'Receipt Ready for Review',
    NotificationType.receiptBatchCompleted: 'Batch Processing Completed',
    NotificationType.receiptBatchFailed: 'Batch Processing Failed',

    // Team receipt collaboration notifications
    NotificationType.receiptShared: 'Receipt Shared',
    NotificationType.receiptCommentAdded: 'Receipt Comment Added',
    NotificationType.receiptEditedByTeamMember: 'Receipt Edited by Team Member',
    NotificationType.receiptApprovedByTeam: 'Receipt Approved by Team',
    NotificationType.receiptFlaggedForReview: 'Receipt Flagged for Review',
  };

  /// Notification categories for UI organization
  static const Map<String, NotificationCategory> notificationCategories = {
    'RECEIPT_PROCESSING': NotificationCategory(
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
    'TEAM_COLLABORATION': NotificationCategory(
      label: 'Team Collaboration',
      description: 'Notifications about team activities and collaboration',
      types: [
        NotificationType.teamInvitationSent,
        NotificationType.teamInvitationAccepted,
        NotificationType.teamMemberJoined,
        NotificationType.teamMemberLeft,
        NotificationType.teamMemberRemoved,
        NotificationType.teamMemberRoleChanged,
        NotificationType.teamSettingsUpdated,
        NotificationType.receiptShared,
        NotificationType.receiptCommentAdded,
        NotificationType.receiptEditedByTeamMember,
        NotificationType.receiptApprovedByTeam,
        NotificationType.receiptFlaggedForReview,
      ],
    ),
    'CLAIMS': NotificationCategory(
      label: 'Claims',
      description: 'Notifications about claim submissions and reviews',
      types: [
        NotificationType.claimSubmitted,
        NotificationType.claimApproved,
        NotificationType.claimRejected,
        NotificationType.claimReviewRequested,
      ],
    ),
  };

  /// Get icon for notification type
  static IconData getNotificationIcon(NotificationType type) {
    return notificationTypeIcons[type] ?? Icons.notifications;
  }

  /// Get color for notification type
  static Color getNotificationColor(NotificationType type) {
    return notificationTypeColors[type] ?? Colors.grey;
  }

  /// Get color for priority
  static Color getPriorityColor(NotificationPriority priority) {
    return priorityColors[priority] ?? Colors.grey;
  }

  /// Get display name for notification type
  static String getNotificationDisplayName(NotificationType type) {
    return notificationTypeDisplayNames[type] ?? type.toString();
  }

  /// Format notification time
  static String formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Get notification summary text
  static String getNotificationSummary(NotificationModel notification) {
    final typeName = getNotificationDisplayName(notification.type);
    final timeAgo = formatNotificationTime(notification.createdAt);

    if (notification.teamName != null) {
      return '$typeName • ${notification.teamName} • $timeAgo';
    } else {
      return '$typeName • $timeAgo';
    }
  }
}

/// Notification category for UI organization
class NotificationCategory {
  final String label;
  final String description;
  final List<NotificationType> types;

  const NotificationCategory({
    required this.label,
    required this.description,
    required this.types,
  });
}
