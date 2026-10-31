import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/notification_display_helpers.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/services/notification_navigation_service.dart';

/// Full-screen notifications view
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  NotificationFilters _filters = const NotificationFilters();

  bool get _hasFilters =>
      _filters.unreadOnly == true || _filters.priority != null;

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
    final notifications = _applyFilters(notificationState.notifications);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Refresh notifications',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildPageHeader(notificationState),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverToBoxAdapter(child: _buildFilterTabs()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverToBoxAdapter(
                child: _buildNotificationPanel(
                  notificationState,
                  notifications,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(NotificationState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTIFICATION CENTER',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Notifications',
          style: theme.textTheme.displaySmall?.copyWith(
            fontFamily: 'InstrumentSerif',
            fontSize: 32,
            height: 1.05,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Approvals, receipts and team activity in one place.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${state.unreadCount} UNREAD  ·  ${state.notifications.length} TOTAL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                  color: state.unreadCount > 0
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildConnectionChip(state),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionChip(NotificationState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = state.isConnected
        ? colors.primary
        : state.isReconnecting
        ? colors.tertiary
        : colors.error;
    final statusLabel = state.isConnected
        ? 'CONNECTED'
        : state.isReconnecting
        ? 'RECONNECTING'
        : 'OFFLINE';

    return InkWell(
      onTap: () => _showConnectionDialog(context, state),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontSize: 9,
                letterSpacing: 1,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final unreadOnly = _filters.unreadOnly == true;
    final highPriority = _filters.priority == NotificationPriority.high;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: 'All',
            selected: !_hasFilters,
            onTap: () => _setFilters(const NotificationFilters()),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Unread',
            selected: unreadOnly,
            onTap: () => _setFilters(
              unreadOnly
                  ? const NotificationFilters()
                  : const NotificationFilters(unreadOnly: true),
            ),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'High priority',
            selected: highPriority,
            onTap: () => _setFilters(
              highPriority
                  ? const NotificationFilters()
                  : const NotificationFilters(
                      priority: NotificationPriority.high,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _setFilters(NotificationFilters filters) {
    setState(() {
      _filters = filters;
    });
  }

  Widget _buildNotificationPanel(
    NotificationState state,
    List<NotificationModel> notifications,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Text(
                  'Inbox',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${notifications.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (state.unreadCount > 0)
                  TextButton(
                    onPressed: _handleMarkAllAsRead,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 34),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          if (state.isLoading && state.notifications.isEmpty)
            _buildLoadingState()
          else if (state.error != null && state.notifications.isEmpty)
            _buildErrorState(state.error!)
          else if (notifications.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: [
                for (var i = 0; i < notifications.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.outlineVariant,
                    ),
                  _buildNotificationRow(notifications[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(NotificationModel notification) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUnread = notification.isUnread;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isUnread ? colors.primary : null,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              height: 1.3,
                              color: isUnread
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (notification.priority ==
                            NotificationPriority.high) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'HIGH',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 9,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                                color: colors.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          NotificationDisplayHelpers.formatNotificationTime(
                            notification.createdAt,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 0.3,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (notification.teamName != null) ...[
                          Text(
                            '  ·  ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              notification.teamName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildRowMenu(notification),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowMenu(NotificationModel notification) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: colors.onSurfaceVariant),
      tooltip: 'Notification actions',
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (value) {
        switch (value) {
          case 'mark_read':
            _handleMarkAsRead(notification.id);
            break;
          case 'archive':
            _handleArchive(notification.id);
            break;
          case 'delete':
            _handleDelete(notification.id);
            break;
        }
      },
      itemBuilder: (context) => [
        if (notification.isUnread)
          const PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(Icons.mark_email_read_outlined, size: 16),
                SizedBox(width: 8),
                Text('Mark as read'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 16),
              SizedBox(width: 8),
              Text('Archive'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading notifications…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 30, color: colors.error),
          const SizedBox(height: 10),
          Text(
            'Couldn\'t load notifications',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 32,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            _hasFilters
                ? 'No notifications match these filters'
                : 'No notifications',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasFilters
                ? 'Clear the filters to see everything in your inbox.'
                : 'You\'re all caught up!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (_hasFilters) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => _setFilters(const NotificationFilters()),
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  List<NotificationModel> _applyFilters(List<NotificationModel> notifications) {
    var filtered = notifications;

    if (_filters.unreadOnly == true) {
      filtered = filtered.where((item) => item.isUnread).toList();
    }

    if (_filters.priority != null) {
      filtered = filtered
          .where((item) => item.priority == _filters.priority)
          .toList();
    }

    return filtered;
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
      await NotificationNavigationService().handleNotificationTap(
        context,
        notification,
      );
    }
  }

  Future<void> _handleMarkAsRead(String notificationId) async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.markAsRead(notificationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
      }
    }
  }

  Future<void> _handleArchive(String notificationId) async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.archiveNotification(notificationId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification archived')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = StadiumBorder(
      side: BorderSide(
        color: selected ? colors.primaryContainer : colors.outlineVariant,
      ),
    );

    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: selected
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
