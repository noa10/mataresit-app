import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../services/notification_navigation_service.dart';
import '../../core/constants/app_constants.dart';
import '../../app/router/app_router.dart';
import 'notification_list.dart';

/// Notification center widget similar to React app's NotificationCenter
/// Provides a dropdown-style notification panel with badge indicator
class NotificationCenter extends ConsumerStatefulWidget {
  final String? teamId;
  final Widget? child;
  final bool showBadge;

  const NotificationCenter({
    super.key,
    this.teamId,
    this.child,
    this.showBadge = true,
  });

  @override
  ConsumerState<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends ConsumerState<NotificationCenter> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final notificationState = ref.watch(notificationProvider);
          final notifications = widget.teamId != null
              ? notificationState.notifications.where((n) => n.teamId == widget.teamId).toList()
              : notificationState.notifications;

          return Positioned(
            top: offset.dy + size.height + 8,
            right: MediaQuery.of(context).size.width - offset.dx - size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 380,
                height: 500,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: NotificationList(
                        notifications: notifications,
                        onNotificationTap: _handleNotificationTap,
                        onMarkAsRead: _handleMarkAsRead,
                        onArchive: _handleArchive,
                        onDelete: _handleDelete,
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  Widget _buildHeader() {
    return Consumer(
      builder: (context, ref, child) {
        final notificationState = ref.watch(notificationProvider);
        final unreadCount = widget.teamId != null
            ? notificationState.notifications
                .where((n) => n.teamId == widget.teamId && n.isUnread)
                .length
            : notificationState.unreadCount;

        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount unread',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              _buildConnectionIndicator(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _handleRefresh,
                tooltip: 'Refresh notifications',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _closeDropdown,
                tooltip: 'Close',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionIndicator() {
    return Consumer(
      builder: (context, ref, child) {
        final connectionStatus = ref.watch(notificationConnectionStatusProvider);

        Color color;
        IconData icon;
        String tooltip;

        switch (connectionStatus) {
          case 'connected':
            color = Colors.green;
            icon = Icons.wifi;
            tooltip = 'Connected';
            break;
          case 'reconnecting':
            color = Colors.orange;
            icon = Icons.wifi_off;
            tooltip = 'Reconnecting...';
            break;
          default:
            color = Colors.red;
            icon = Icons.wifi_off;
            tooltip = 'Disconnected';
        }

        return Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Consumer(
      builder: (context, ref, child) {
        final notificationState = ref.watch(notificationProvider);
        final unreadCount = widget.teamId != null
            ? notificationState.notifications
                .where((n) => n.teamId == widget.teamId && n.isUnread)
                .length
            : notificationState.unreadCount;

        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: _handleMarkAllAsRead,
                  child: const Text('Mark all as read'),
                ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _closeDropdown();
                  // Navigate to full notifications page using GoRouter
                  context.push(AppRoutes.notifications);
                },
                child: const Text('View all'),
              ),
            ],
          ),
        );
      },
    );
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
      await notifier.markAllAsRead(teamId: widget.teamId);
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
      _closeDropdown();
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _buttonKey,
      onTap: _toggleDropdown,
      child: widget.child ??
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = widget.teamId != null
                  ? ref.watch(teamNotificationsProvider(widget.teamId))
                      .where((n) => n.isUnread)
                      .length
                  : ref.watch(unreadNotificationCountProvider);

              return Stack(
                children: [
                  Icon(
                    Icons.notifications,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  if (widget.showBadge && unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }
}
