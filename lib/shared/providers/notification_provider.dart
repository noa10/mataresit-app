import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';

/// Notification state
class NotificationState {
  final List<NotificationModel> notifications;
  final NotificationStats? stats;
  final String connectionStatus;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.stats,
    this.connectionStatus = 'disconnected',
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    NotificationStats? stats,
    String? connectionStatus,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      stats: stats ?? this.stats,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Get unread notification count
  int get unreadCount => notifications.where((n) => n.isUnread).length;

  /// Get high priority unread count
  int get highPriorityUnreadCount => notifications
      .where((n) => n.isUnread && n.priority == NotificationPriority.high)
      .length;

  /// Check if connected to real-time
  bool get isConnected => connectionStatus == 'connected';

  /// Check if reconnecting
  bool get isReconnecting => connectionStatus == 'reconnecting';
}

/// Notification provider
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService = NotificationService();
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  bool _isInitialized = false;

  NotificationNotifier() : super(const NotificationState()) {
    _initialize();
  }

  /// Initialize the notification provider
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Initialize notification services
      await _notificationService.initialize();
      await _localNotificationService.initialize();

      // Listen to notification streams
      _notificationService.notificationsStream.listen((notifications) {
        state = state.copyWith(
          notifications: notifications,
          isLoading: false,
          error: null,
        );
      });

      _notificationService.connectionStatusStream.listen((status) {
        state = state.copyWith(connectionStatus: status);
      });

      _notificationService.newNotificationStream.listen((notification) {
        // Handle new notification (trigger local notification)
        _handleNewNotification(notification);
      });

      // Fetch initial notifications
      await fetchNotifications();

      _isInitialized = true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch notifications with optional filters
  Future<void> fetchNotifications({
    NotificationFilters? filters,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && state.isLoading) return;

      state = state.copyWith(isLoading: true, error: null);

      final notifications = await _notificationService.fetchNotifications(
        filters: filters,
        limit: limit,
        offset: offset,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch notification statistics
  Future<void> fetchStats({String? teamId, bool forceRefresh = false}) async {
    try {
      final stats = await _notificationService.getNotificationStats(
        teamId: teamId,
        forceRefresh: forceRefresh,
      );

      state = state.copyWith(stats: stats);
    } catch (e) {
      // Don't update error state for stats failure
      // Silently fail for stats
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      // State will be updated via stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({String? teamId}) async {
    try {
      await _notificationService.markAllAsRead(teamId: teamId);
      // State will be updated via stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _notificationService.archiveNotification(notificationId);
      // State will be updated via stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      // State will be updated via stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await fetchNotifications(forceRefresh: true);
  }

  /// Reconnect to real-time
  Future<void> reconnect() async {
    try {
      await _notificationService.reconnect();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Handle new notification
  void _handleNewNotification(NotificationModel notification) {
    // Trigger local notification for new notifications
    _localNotificationService.showNotificationFromModel(notification);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get notifications filtered by team
  List<NotificationModel> getNotificationsForTeam(String? teamId) {
    if (teamId == null) return state.notifications;
    return state.notifications.where((n) => n.teamId == teamId).toList();
  }

  /// Get unread notifications
  List<NotificationModel> get unreadNotifications =>
      state.notifications.where((n) => n.isUnread).toList();

  /// Get high priority notifications
  List<NotificationModel> get highPriorityNotifications =>
      state.notifications.where((n) => n.priority == NotificationPriority.high).toList();

  @override
  void dispose() {
    _notificationService.dispose();
    _localNotificationService.dispose();
    super.dispose();
  }
}

/// Notification provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

/// Unread notification count provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationProvider);
  return state.unreadCount;
});

/// High priority unread notification count provider
final highPriorityUnreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationProvider);
  return state.highPriorityUnreadCount;
});

/// Connection status provider
final notificationConnectionStatusProvider = Provider<String>((ref) {
  final state = ref.watch(notificationProvider);
  return state.connectionStatus;
});

/// Notifications for specific team provider
final teamNotificationsProvider = Provider.family<List<NotificationModel>, String?>((ref, teamId) {
  final notifier = ref.watch(notificationProvider.notifier);
  return notifier.getNotificationsForTeam(teamId);
});

/// Unread notifications provider
final unreadNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notifier = ref.watch(notificationProvider.notifier);
  return notifier.unreadNotifications;
});

/// High priority notifications provider
final highPriorityNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notifier = ref.watch(notificationProvider.notifier);
  return notifier.highPriorityNotifications;
});
