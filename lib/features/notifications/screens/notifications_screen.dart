import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/services/notification_navigation_service.dart';
import '../../../shared/widgets/notification_list.dart';
import '../../../shared/widgets/notification_status_indicator.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/constants/app_constants.dart';

/// Full-screen notifications view
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  NotificationFilters _filters = const NotificationFilters();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).refreshNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Connection status indicator
          NotificationStatusIndicator(
            showBadge: false,
            onTap: () => _showConnectionDialog(context, notificationState),
          ),
          const SizedBox(width: 8),
          
          // Filter toggle
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Filter notifications',
          ),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh notifications',
          ),
          
          // Mark all as read
          if (notificationState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              onPressed: _handleMarkAllAsRead,
              tooltip: 'Mark all as read',
            ),
          
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          if (_showFilters) _buildFilterSection(),
          
          // Notifications list
          Expanded(child: _buildNotificationsList(notificationState)),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          
          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Unread only'),
                selected: _filters.unreadOnly == true,
                onSelected: (selected) {
                  setState(() {
                    _filters = _filters.copyWith(unreadOnly: selected ? true : null);
                  });
                  _applyFilters();
                },
              ),
              FilterChip(
                label: const Text('High priority'),
                selected: _filters.priority == NotificationPriority.high,
                onSelected: (selected) {
                  setState(() {
                    _filters = _filters.copyWith(
                      priority: selected ? NotificationPriority.high : null,
                    );
                  });
                  _applyFilters();
                },
              ),
              FilterChip(
                label: const Text('Clear filters'),
                selected: false,
                onSelected: (_) {
                  setState(() {
                    _filters = const NotificationFilters();
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: AppErrorWidget(
          error: state.error!,
          onRetry: _handleRefresh,
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: NotificationList(
        notifications: state.notifications,
        onNotificationTap: _handleNotificationTap,
        onMarkAsRead: _handleMarkAsRead,
        onArchive: _handleArchive,
        onDelete: _handleDelete,
        scrollController: _scrollController,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    // TODO: Implement filtering logic
    // For now, just refresh to show all notifications
    _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.refreshNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh notifications: $e')),
        );
      }
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.markAllAsRead();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read if unread
    if (notification.isUnread) {
      await _handleMarkAsRead(notification.id);
    }

    // Use navigation service for proper handling
    if (mounted) {
      await NotificationNavigationService().handleNotificationTap(context, notification);
    }
  }

  Future<void> _handleMarkAsRead(String notificationId) async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.markAsRead(notificationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as read: $e')),
        );
      }
    }
  }

  Future<void> _handleArchive(String notificationId) async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.archiveNotification(notificationId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification archived')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to archive notification: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(String notificationId) async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.deleteNotification(notificationId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e')),
        );
      }
    }
  }

  void _showConnectionDialog(BuildContext context, NotificationState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${state.connectionStatus}'),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text('Error: ${state.error}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (state.connectionStatus != 'connected')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleRefresh();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
