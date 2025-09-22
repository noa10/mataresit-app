import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/notification_display_helpers.dart';
import '../../core/constants/app_constants.dart';

/// Individual notification card widget
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool compact;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkAsRead,
    this.onArchive,
    this.onDelete,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;
    final typeColor = NotificationDisplayHelpers.getNotificationColor(notification.type);
    final icon = NotificationDisplayHelpers.getNotificationIcon(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? AppConstants.smallPadding : AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: isUnread
              ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
              : null,
          border: Border(
            left: BorderSide(
              color: isUnread ? Theme.of(context).primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(context, icon, typeColor),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _buildContent(context),
            ),
            if (showActions && !compact) ...[
              const SizedBox(width: AppConstants.smallPadding),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon, Color color) {
    return Container(
      width: compact ? 32 : 40,
      height: compact ? 32 : 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      child: Icon(
        icon,
        color: color,
        size: compact ? 16 : 20,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (notification.priority == NotificationPriority.high)
              Container(
                margin: const EdgeInsets.only(left: AppConstants.smallPadding),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'HIGH',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          notification.message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.smallPadding),
        _buildMetadata(context),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final summary = NotificationDisplayHelpers.getNotificationSummary(notification);
    
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
        if (notification.isUnread)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).disabledColor,
        size: 16,
      ),
      onSelected: (value) {
        switch (value) {
          case 'mark_read':
            onMarkAsRead?.call();
            break;
          case 'archive':
            onArchive?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (notification.isUnread && onMarkAsRead != null)
          const PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(Icons.mark_email_read, size: 16),
                SizedBox(width: 8),
                Text('Mark as read'),
              ],
            ),
          ),
        if (onArchive != null)
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive, size: 16),
                SizedBox(width: 8),
                Text('Archive'),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact notification card for use in smaller spaces
class CompactNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const CompactNotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationCard(
      notification: notification,
      onTap: onTap,
      compact: true,
      showActions: false,
    );
  }
}

/// Notification card with swipe actions
class SwipeableNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const SwipeableNotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkAsRead,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.mark_email_read,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - mark as read
          if (notification.isUnread && onMarkAsRead != null) {
            onMarkAsRead!();
            return false; // Don't dismiss, just mark as read
          }
          return false;
        } else {
          // Swipe left - delete
          if (onDelete != null) {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete notification'),
                content: const Text('Are you sure you want to delete this notification?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (result == true) {
              onDelete!();
            }
            return result ?? false;
          }
          return false;
        }
      },
      child: NotificationCard(
        notification: notification,
        onTap: onTap,
        showActions: false,
      ),
    );
  }
}
