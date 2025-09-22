import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/notification_model.dart';
import '../../core/services/app_logger.dart';

/// Service for handling notification navigation and action URLs
class NotificationNavigationService {
  static final NotificationNavigationService _instance = NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  /// Handle notification tap and navigation
  Future<void> handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    try {
      AppLogger.info('Handling notification tap: ${notification.id}');

      // Navigate based on notification type and action URL
      if (notification.actionUrl != null) {
        await _navigateToActionUrl(context, notification.actionUrl!);
      } else {
        await _navigateByNotificationType(context, notification);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle notification tap', e, stackTrace);
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to open notification');
      }
    }
  }

  /// Navigate to action URL using GoRouter
  Future<void> _navigateToActionUrl(BuildContext context, String actionUrl) async {
    try {
      AppLogger.info('Navigating to action URL: $actionUrl');

      // Parse the action URL and navigate accordingly
      final uri = Uri.parse(actionUrl);

      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        // External URL - could open in browser or web view
        _showInfoSnackBar(context, 'External links not supported in app');
        return;
      }

      // Map legacy action URLs to correct GoRouter paths
      String routePath = _mapActionUrlToRoute(actionUrl);

      // Use GoRouter for internal navigation
      if (context.mounted) {
        context.push(routePath);
      }
    } catch (e) {
      AppLogger.error('Failed to navigate to action URL: $actionUrl', e);
      if (context.mounted) {
        _showErrorSnackBar(context, 'Invalid navigation URL');
      }
    }
  }

  /// Map legacy action URLs to correct GoRouter paths
  String _mapActionUrlToRoute(String actionUrl) {
    // Ensure the URL starts with /
    if (!actionUrl.startsWith('/')) {
      actionUrl = '/$actionUrl';
    }

    // Handle specific route mappings
    if (actionUrl.startsWith('/receipt/')) {
      // Map /receipt/:id to /receipts/:id
      return actionUrl.replaceFirst('/receipt/', '/receipts/');
    }

    if (actionUrl.startsWith('/claim/')) {
      // Map /claim/:id to /claims/:id
      return actionUrl.replaceFirst('/claim/', '/claims/');
    }

    if (actionUrl.startsWith('/team/')) {
      // Map /team/:id to /teams/:id (if needed)
      return actionUrl.replaceFirst('/team/', '/teams/');
    }

    // Return the URL as-is for other cases
    return actionUrl;
  }

  /// Navigate based on notification type
  Future<void> _navigateByNotificationType(
    BuildContext context,
    NotificationModel notification,
  ) async {
    try {
      AppLogger.info('Navigating by notification type: ${notification.type}');

      switch (notification.type) {
        // Receipt processing notifications
        case NotificationType.receiptProcessingStarted:
        case NotificationType.receiptProcessingCompleted:
        case NotificationType.receiptProcessingFailed:
        case NotificationType.receiptReadyForReview:
          await _navigateToReceipt(context, notification);
          break;

        case NotificationType.receiptBatchCompleted:
        case NotificationType.receiptBatchFailed:
          await _navigateToReceiptsList(context);
          break;

        // Team collaboration notifications
        case NotificationType.teamInvitationSent:
        case NotificationType.teamInvitationAccepted:
        case NotificationType.teamMemberJoined:
        case NotificationType.teamMemberLeft:
        case NotificationType.teamMemberRemoved:
        case NotificationType.teamMemberRoleChanged:
        case NotificationType.teamSettingsUpdated:
          await _navigateToTeam(context, notification);
          break;

        // Receipt collaboration notifications
        case NotificationType.receiptShared:
        case NotificationType.receiptCommentAdded:
        case NotificationType.receiptEditedByTeamMember:
        case NotificationType.receiptApprovedByTeam:
        case NotificationType.receiptFlaggedForReview:
          await _navigateToReceipt(context, notification);
          break;

        // Claims notifications
        case NotificationType.claimSubmitted:
        case NotificationType.claimApproved:
        case NotificationType.claimRejected:
        case NotificationType.claimReviewRequested:
          await _navigateToClaim(context, notification);
          break;
      }
    } catch (e) {
      AppLogger.error('Failed to navigate by notification type', e);
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to open notification');
      }
    }
  }

  /// Navigate to specific receipt using GoRouter
  Future<void> _navigateToReceipt(BuildContext context, NotificationModel notification) async {
    final receiptId = notification.relatedEntityId;
    if (context.mounted) {
      if (receiptId != null) {
        context.push('/receipts/$receiptId');
      } else {
        context.push('/receipts');
      }
    }
  }

  /// Navigate to receipts list using GoRouter
  Future<void> _navigateToReceiptsList(BuildContext context) async {
    if (context.mounted) {
      context.push('/receipts');
    }
  }

  /// Navigate to team using GoRouter
  Future<void> _navigateToTeam(BuildContext context, NotificationModel notification) async {
    final teamId = notification.teamId;
    if (context.mounted) {
      if (teamId != null) {
        context.push('/teams/$teamId');
      } else {
        context.push('/teams');
      }
    }
  }

  /// Navigate to claim using GoRouter
  Future<void> _navigateToClaim(BuildContext context, NotificationModel notification) async {
    final claimId = notification.relatedEntityId;
    if (context.mounted) {
      if (claimId != null) {
        context.push('/claims/$claimId');
      } else {
        context.push('/claims');
      }
    }
  }

  /// Show error snack bar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Show info snack bar
  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  /// Get navigation route for notification
  String? getNavigationRoute(NotificationModel notification) {
    if (notification.actionUrl != null) {
      return notification.actionUrl;
    }

    switch (notification.type) {
      // Receipt processing notifications
      case NotificationType.receiptProcessingStarted:
      case NotificationType.receiptProcessingCompleted:
      case NotificationType.receiptProcessingFailed:
      case NotificationType.receiptReadyForReview:
      case NotificationType.receiptShared:
      case NotificationType.receiptCommentAdded:
      case NotificationType.receiptEditedByTeamMember:
      case NotificationType.receiptApprovedByTeam:
      case NotificationType.receiptFlaggedForReview:
        final receiptId = notification.relatedEntityId;
        return receiptId != null ? '/receipts/$receiptId' : '/receipts';

      case NotificationType.receiptBatchCompleted:
      case NotificationType.receiptBatchFailed:
        return '/receipts';

      // Team collaboration notifications
      case NotificationType.teamInvitationSent:
      case NotificationType.teamInvitationAccepted:
      case NotificationType.teamMemberJoined:
      case NotificationType.teamMemberLeft:
      case NotificationType.teamMemberRemoved:
      case NotificationType.teamMemberRoleChanged:
      case NotificationType.teamSettingsUpdated:
        final teamId = notification.teamId;
        return teamId != null ? '/teams/$teamId' : '/teams';

      // Claims notifications
      case NotificationType.claimSubmitted:
      case NotificationType.claimApproved:
      case NotificationType.claimRejected:
      case NotificationType.claimReviewRequested:
        final claimId = notification.relatedEntityId;
        return claimId != null ? '/claims/$claimId' : '/claims';
    }
  }

  /// Check if notification has navigation
  bool hasNavigation(NotificationModel notification) {
    return getNavigationRoute(notification) != null;
  }
}

/// Notification action handler
class NotificationActionHandler {
  static final NotificationActionHandler _instance = NotificationActionHandler._internal();
  factory NotificationActionHandler() => _instance;
  NotificationActionHandler._internal();

  /// Handle notification action
  Future<void> handleAction(
    BuildContext context,
    NotificationModel notification,
    String action,
  ) async {
    try {
      AppLogger.info('Handling notification action: $action for ${notification.id}');

      switch (action) {
        case 'view':
          await NotificationNavigationService().handleNotificationTap(context, notification);
          break;
        case 'dismiss':
          // Just dismiss - no action needed
          break;
        case 'mark_read':
          // This would be handled by the notification provider
          break;
        case 'archive':
          // This would be handled by the notification provider
          break;
        case 'delete':
          // This would be handled by the notification provider
          break;
        default:
          AppLogger.warning('Unknown notification action: $action');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle notification action', e, stackTrace);
    }
  }

  /// Get available actions for notification
  List<String> getAvailableActions(NotificationModel notification) {
    final actions = <String>['view', 'dismiss'];

    if (notification.isUnread) {
      actions.add('mark_read');
    }

    if (!notification.isArchived) {
      actions.add('archive');
    }

    actions.add('delete');

    return actions;
  }

  /// Get action display name
  String getActionDisplayName(String action) {
    switch (action) {
      case 'view':
        return 'View';
      case 'dismiss':
        return 'Dismiss';
      case 'mark_read':
        return 'Mark as read';
      case 'archive':
        return 'Archive';
      case 'delete':
        return 'Delete';
      default:
        return action;
    }
  }

  /// Get action icon
  IconData getActionIcon(String action) {
    switch (action) {
      case 'view':
        return Icons.visibility;
      case 'dismiss':
        return Icons.close;
      case 'mark_read':
        return Icons.mark_email_read;
      case 'archive':
        return Icons.archive;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.help;
    }
  }
}
