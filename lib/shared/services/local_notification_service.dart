import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../models/notification_display_helpers.dart';
import '../services/notification_preferences_service.dart';
import '../../core/services/app_logger.dart';

/// Enhanced local notification service that integrates with the notification system
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationAction> _actionController =
      StreamController<NotificationAction>.broadcast();
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();

  bool _isInitialized = false;

  /// Stream of notification actions
  Stream<NotificationAction> get actionStream => _actionController.stream;

  /// Initialize local notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('Initializing local notification service...');
      await _initializeLocalNotifications();
      _isInitialized = true;
      AppLogger.info('Local notification service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize local notification service',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'general',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'receipts',
        'Receipt Notifications',
        description: 'Receipt processing and collaboration notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'teams',
        'Team Notifications',
        description: 'Team collaboration notifications',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'claims',
        'Claims Notifications',
        description: 'Claims and reimbursement notifications',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Handle notification response
  void _onNotificationResponse(NotificationResponse response) {
    try {
      AppLogger.info('Notification tapped: ${response.id}');

      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        _actionController.add(NotificationAction(type: 'tap', data: data));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle notification response', e, stackTrace);
    }
  }

  /// Show local notification for a notification model
  Future<void> showNotificationFromModel(NotificationModel notification) async {
    try {
      // Check if push notifications are enabled for this type
      final preferences = await _preferencesService
          .getUserNotificationPreferences();
      if (!_shouldShowPushNotification(notification.type, preferences)) {
        AppLogger.debug(
          'Push notification disabled for type: ${notification.type}',
        );
        return;
      }

      final channelId = _getChannelIdForNotificationType(notification.type);
      final color = NotificationDisplayHelpers.getNotificationColor(
        notification.type,
      );

      await showNotification(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.message,
        payload: jsonEncode({
          'notification_id': notification.id,
          'type': notification.type.toString(),
          'action_url': notification.actionUrl,
        }),
        channelId: channelId,
        priority: _mapPriorityToAndroid(notification.priority),
        color: color,
      );

      AppLogger.info('Local notification shown for: ${notification.title}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to show local notification', e, stackTrace);
    }
  }

  /// Show local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
    Priority priority = Priority.defaultPriority,
    Color? color,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: _mapPriorityToImportance(priority),
        priority: priority,
        color: color,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const macosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: macosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      AppLogger.debug('Local notification shown: $title');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to show notification', e, stackTrace);
    }
  }

  /// Show receipt processing notification
  Future<void> showReceiptNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = data != null ? jsonEncode(data) : null;

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'receipts',
      priority: Priority.high,
    );
  }

  /// Show team notification
  Future<void> showTeamNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = data != null ? jsonEncode(data) : null;

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'teams',
    );
  }

  /// Show claims notification
  Future<void> showClaimsNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = data != null ? jsonEncode(data) : null;

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: 'claims',
      priority: Priority.high,
    );
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Request notification permissions (iOS/macOS)
  Future<bool> requestPermissions() async {
    final iosImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      return await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macosImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    if (macosImplementation != null) {
      return await macosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true; // Android permissions are handled at install time
  }

  /// Check if should show push notification based on preferences
  bool _shouldShowPushNotification(NotificationType type, dynamic preferences) {
    if (preferences == null) return true;

    // Check if push notifications are enabled globally
    if (preferences.pushEnabled == false) return false;

    // Check specific type preferences
    switch (type) {
      case NotificationType.receiptProcessingStarted:
        return preferences.pushReceiptProcessingStarted ?? true;
      case NotificationType.receiptProcessingCompleted:
        return preferences.pushReceiptProcessingCompleted ?? true;
      case NotificationType.receiptProcessingFailed:
        return preferences.pushReceiptProcessingFailed ?? true;
      case NotificationType.teamInvitationSent:
        return preferences.pushTeamInvitationSent ?? true;
      case NotificationType.teamMemberJoined:
        return preferences.pushTeamMemberJoined ?? true;
      // Add more cases as needed
      default:
        return true;
    }
  }

  /// Get channel ID for notification type
  String _getChannelIdForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessingStarted:
      case NotificationType.receiptProcessingCompleted:
      case NotificationType.receiptProcessingFailed:
      case NotificationType.receiptReadyForReview:
      case NotificationType.receiptBatchCompleted:
      case NotificationType.receiptBatchFailed:
      case NotificationType.receiptShared:
      case NotificationType.receiptCommentAdded:
      case NotificationType.receiptEditedByTeamMember:
      case NotificationType.receiptApprovedByTeam:
      case NotificationType.receiptFlaggedForReview:
        return 'receipts';

      case NotificationType.teamInvitationSent:
      case NotificationType.teamInvitationAccepted:
      case NotificationType.teamMemberJoined:
      case NotificationType.teamMemberLeft:
      case NotificationType.teamMemberRemoved:
      case NotificationType.teamMemberRoleChanged:
      case NotificationType.teamSettingsUpdated:
        return 'teams';

      case NotificationType.claimSubmitted:
      case NotificationType.claimApproved:
      case NotificationType.claimRejected:
      case NotificationType.claimReviewRequested:
        return 'claims';
    }
  }

  /// Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'receipts':
        return 'Receipt Notifications';
      case 'teams':
        return 'Team Notifications';
      case 'claims':
        return 'Claims Notifications';
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'receipts':
        return 'Receipt processing and collaboration notifications';
      case 'teams':
        return 'Team collaboration notifications';
      case 'claims':
        return 'Claims and reimbursement notifications';
      default:
        return 'General app notifications';
    }
  }

  /// Map notification priority to Android priority
  Priority _mapPriorityToAndroid(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
    }
  }

  /// Map priority to importance
  Importance _mapPriorityToImportance(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Importance.low;
      case Priority.defaultPriority:
        return Importance.defaultImportance;
      case Priority.high:
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Dispose resources
  void dispose() {
    _actionController.close();
  }
}

/// Notification action data
class NotificationAction {
  final String type;
  final Map<String, dynamic> data;

  NotificationAction({required this.type, required this.data});
}
