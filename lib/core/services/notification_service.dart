import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Service for managing local notifications
/// This service handles local notifications only, without Firebase/FCM dependencies
class NotificationService {
  static final Logger _logger = Logger();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static final StreamController<NotificationAction> _actionController = StreamController<NotificationAction>.broadcast();

  /// Stream of notification actions
  static Stream<NotificationAction> get actionStream => _actionController.stream;

  /// Initialize notification service (local notifications only)
  static Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      _logger.i('Local Notification Service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Handle notification response
  static void _onNotificationResponse(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.id}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _actionController.add(NotificationAction(
          type: data['type'] ?? 'unknown',
          data: data,
        ));
      } catch (e) {
        _logger.e('Failed to parse notification payload: $e');
      }
    }
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'receipts',
        'Receipt Notifications',
        description: 'Notifications about receipt processing and updates',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'sync',
        'Sync Notifications',
        description: 'Notifications about data synchronization',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'general',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Show local notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'general',
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      _logger.d('Local notification shown: $title');
    } catch (e) {
      _logger.e('Failed to show notification: $e');
    }
  }

  /// Show receipt processing notification
  static Future<void> showReceiptNotification({
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
    );
  }

  /// Show sync notification
  static Future<void> showSyncNotification({
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
      channelId: 'sync',
    );
  }

  /// Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }
    
    // For iOS, assume enabled if we got this far
    return true;
  }

  /// Request notification permissions (iOS)
  static Future<bool> requestPermissions() async {
    final iosImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      return await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    
    return true; // Android permissions are handled at install time
  }

  /// Dispose resources
  static void dispose() {
    _actionController.close();
  }
}

/// Notification action data
class NotificationAction {
  final String type;
  final Map<String, dynamic> data;

  const NotificationAction({
    required this.type,
    required this.data,
  });

  @override
  String toString() => 'NotificationAction(type: $type, data: $data)';
}
