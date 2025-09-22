import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../services/local_notification_service.dart';
import '../widgets/notification_center.dart';
import '../widgets/notification_list.dart';
import '../widgets/notification_status_indicator.dart';

/// Test screen for notification functionality
class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState
    extends ConsumerState<NotificationTestScreen> {
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _localNotificationService.initialize();
      await _localNotificationService.requestPermissions();
    } catch (e) {
      debugPrint('Failed to initialize notification services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        actions: [
          NotificationStatusIndicator(onTap: () => _showStatusDialog(context)),
          const SizedBox(width: 16),
          NotificationCenter(showBadge: true),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(notificationState),
          _buildStats(notificationState),
          _buildTestButtons(),
          const Divider(),
          Expanded(child: _buildNotificationsList(notificationState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTestNotification(),
        tooltip: 'Create test notification',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConnectionStatus(NotificationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getConnectionColor(
          state.connectionStatus,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getConnectionColor(state.connectionStatus),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getConnectionIcon(state.connectionStatus),
            color: _getConnectionColor(state.connectionStatus),
          ),
          const SizedBox(width: 8),
          Text(
            'Connection: ${state.connectionStatus}',
            style: TextStyle(
              color: _getConnectionColor(state.connectionStatus),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (state.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(NotificationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', state.notifications.length.toString()),
          _buildStatItem('Unread', state.unreadCount.toString()),
          _buildStatItem(
            'High Priority',
            state.highPriorityUnreadCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildTestButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton(
            onPressed: _testReceiptNotification,
            child: const Text('Receipt'),
          ),
          ElevatedButton(
            onPressed: _testTeamNotification,
            child: const Text('Team'),
          ),
          ElevatedButton(
            onPressed: _testClaimsNotification,
            child: const Text('Claims'),
          ),
          ElevatedButton(
            onPressed: _testHighPriorityNotification,
            child: const Text('High Priority'),
          ),
          ElevatedButton(
            onPressed: _refreshNotifications,
            child: const Text('Refresh'),
          ),
          ElevatedButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark All Read'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationState state) {
    if (state.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No notifications'),
          ],
        ),
      );
    }

    return NotificationList(
      notifications: state.notifications,
      onNotificationTap: _handleNotificationTap,
      onMarkAsRead: _handleMarkAsRead,
      onArchive: _handleArchive,
      onDelete: _handleDelete,
    );
  }

  Color _getConnectionColor(String status) {
    switch (status) {
      case 'connected':
        return Colors.green;
      case 'reconnecting':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _getConnectionIcon(String status) {
    switch (status) {
      case 'connected':
        return Icons.wifi;
      case 'reconnecting':
        return Icons.wifi_off;
      default:
        return Icons.wifi_off;
    }
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Status'),
        content: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(notificationProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection: ${state.connectionStatus}'),
                Text('Total notifications: ${state.notifications.length}'),
                Text('Unread: ${state.unreadCount}'),
                Text('Loading: ${state.isLoading}'),
                if (state.error != null) Text('Error: ${state.error}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestNotification() async {
    await _localNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Test Notification',
      body: 'This is a test notification from the Flutter app',
      channelId: 'general',
    );
  }

  Future<void> _testReceiptNotification() async {
    await _localNotificationService.showReceiptNotification(
      title: 'Receipt Processed',
      body: 'Your receipt has been successfully processed',
      data: {'type': 'receipt', 'id': '123'},
    );
  }

  Future<void> _testTeamNotification() async {
    await _localNotificationService.showTeamNotification(
      title: 'Team Invitation',
      body: 'You have been invited to join a team',
      data: {'type': 'team', 'id': '456'},
    );
  }

  Future<void> _testClaimsNotification() async {
    await _localNotificationService.showClaimsNotification(
      title: 'Claim Approved',
      body: 'Your expense claim has been approved',
      data: {'type': 'claim', 'id': '789'},
    );
  }

  Future<void> _testHighPriorityNotification() async {
    await _localNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'High Priority Alert',
      body: 'This is a high priority notification',
      channelId: 'general',
      priority: Priority.high,
    );
  }

  Future<void> _refreshNotifications() async {
    final notifier = ref.read(notificationProvider.notifier);
    await notifier.refreshNotifications();
  }

  Future<void> _markAllAsRead() async {
    final notifier = ref.read(notificationProvider.notifier);
    await notifier.markAllAsRead();
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tapped: ${notification.title}')));
  }

  Future<void> _handleMarkAsRead(String notificationId) async {
    final notifier = ref.read(notificationProvider.notifier);
    await notifier.markAsRead(notificationId);
  }

  Future<void> _handleArchive(String notificationId) async {
    final notifier = ref.read(notificationProvider.notifier);
    await notifier.archiveNotification(notificationId);
  }

  Future<void> _handleDelete(String notificationId) async {
    final notifier = ref.read(notificationProvider.notifier);
    await notifier.deleteNotification(notificationId);
  }
}
