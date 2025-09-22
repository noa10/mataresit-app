import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/notification_display_helpers.dart';
import '../../core/constants/app_constants.dart';
import 'notification_card.dart';

/// Notification list widget that displays a scrollable list of notifications
class NotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(NotificationModel) onNotificationTap;
  final Function(String) onMarkAsRead;
  final Function(String) onArchive;
  final Function(String) onDelete;
  final bool showActions;
  final ScrollController? scrollController;

  const NotificationList({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAsRead,
    required this.onArchive,
    required this.onDelete,
    this.showActions = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () => onNotificationTap(notification),
          onMarkAsRead: showActions ? () => onMarkAsRead(notification.id) : null,
          onArchive: showActions ? () => onArchive(notification.id) : null,
          onDelete: showActions ? () => onDelete(notification.id) : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'You\'re all caught up! New notifications will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped notification list that organizes notifications by category or date
class GroupedNotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(NotificationModel) onNotificationTap;
  final Function(String) onMarkAsRead;
  final Function(String) onArchive;
  final Function(String) onDelete;
  final bool groupByDate;
  final bool showActions;
  final ScrollController? scrollController;

  const GroupedNotificationList({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAsRead,
    required this.onArchive,
    required this.onDelete,
    this.groupByDate = true,
    this.showActions = true,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return NotificationList(
        notifications: notifications,
        onNotificationTap: onNotificationTap,
        onMarkAsRead: onMarkAsRead,
        onArchive: onArchive,
        onDelete: onDelete,
        showActions: showActions,
        scrollController: scrollController,
      );
    }

    final groupedNotifications = groupByDate
        ? _groupNotificationsByDate()
        : _groupNotificationsByCategory();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      itemCount: groupedNotifications.length,
      itemBuilder: (context, index) {
        final group = groupedNotifications[index];
        return _buildNotificationGroup(context, group);
      },
    );
  }

  List<NotificationGroup> _groupNotificationsByDate() {
    final groups = <String, List<NotificationModel>>{};
    
    for (final notification in notifications) {
      final dateKey = _getDateGroupKey(notification.createdAt);
      groups.putIfAbsent(dateKey, () => []).add(notification);
    }

    return groups.entries
        .map((entry) => NotificationGroup(
              title: entry.key,
              notifications: entry.value,
            ))
        .toList();
  }

  List<NotificationGroup> _groupNotificationsByCategory() {
    final groups = <String, List<NotificationModel>>{};
    
    for (final notification in notifications) {
      final category = _getCategoryForNotificationType(notification.type);
      groups.putIfAbsent(category, () => []).add(notification);
    }

    return groups.entries
        .map((entry) => NotificationGroup(
              title: entry.key,
              notifications: entry.value,
            ))
        .toList();
  }

  String _getDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return 'This week';
    } else if (now.difference(date).inDays < 30) {
      return 'This month';
    } else {
      return 'Older';
    }
  }

  String _getCategoryForNotificationType(NotificationType type) {
    for (final category in NotificationDisplayHelpers.notificationCategories.values) {
      if (category.types.contains(type)) {
        return category.label;
      }
    }
    return 'Other';
  }

  Widget _buildNotificationGroup(BuildContext context, NotificationGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          child: Text(
            group.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ...group.notifications.map((notification) => Column(
              children: [
                NotificationCard(
                  notification: notification,
                  onTap: () => onNotificationTap(notification),
                  onMarkAsRead: showActions ? () => onMarkAsRead(notification.id) : null,
                  onArchive: showActions ? () => onArchive(notification.id) : null,
                  onDelete: showActions ? () => onDelete(notification.id) : null,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ],
            )),
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }
}

/// Data class for notification groups
class NotificationGroup {
  final String title;
  final List<NotificationModel> notifications;

  const NotificationGroup({
    required this.title,
    required this.notifications,
  });
}
