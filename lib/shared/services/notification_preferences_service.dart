import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_preferences_model.dart';
import '../../core/services/app_logger.dart';

/// Service for managing notification preferences
class NotificationPreferencesService {
  static final _instance = NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  final _supabase = Supabase.instance.client;

  /// Get user notification preferences
  Future<NotificationPreferences> getUserNotificationPreferences([String? userId]) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Fetching notification preferences for user: $targetUserId');

      final response = await _supabase.rpc(
        'get_user_notification_preferences',
        params: {'_user_id': targetUserId},
      );

      if (response == null || (response as List).isEmpty) {
        AppLogger.info('No preferences found, returning defaults');
        return NotificationPreferences.defaults(targetUserId);
      }

      final data = (response as List).first as Map<String, dynamic>;
      final preferences = NotificationPreferences.fromJson(data);
      
      AppLogger.info('Successfully fetched notification preferences');
      return preferences;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching notification preferences', e, stackTrace);
      
      // Return defaults if user is authenticated but there's an error
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        return NotificationPreferences.defaults(userId);
      }
      
      rethrow;
    }
  }

  /// Update user notification preferences
  Future<String> updateNotificationPreferences(NotificationPreferences preferences) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Updating notification preferences for user: $userId');

      // Convert preferences to JSON for the RPC call
      final preferencesJson = preferences.toJson();
      
      // Remove fields that shouldn't be updated via this method
      preferencesJson.remove('id');
      preferencesJson.remove('user_id');
      preferencesJson.remove('created_at');
      preferencesJson.remove('updated_at');

      final response = await _supabase.rpc(
        'upsert_notification_preferences',
        params: {
          '_user_id': userId,
          '_preferences': preferencesJson,
        },
      );

      AppLogger.info('Successfully updated notification preferences');
      return response as String;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating notification preferences', e, stackTrace);
      rethrow;
    }
  }

  /// Update a specific notification preference
  Future<String> updateSpecificPreference({
    required String preferenceKey,
    required dynamic value,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Updating specific preference: $preferenceKey = $value');

      final response = await _supabase.rpc(
        'upsert_notification_preferences',
        params: {
          '_user_id': userId,
          '_preferences': {preferenceKey: value},
        },
      );

      AppLogger.info('Successfully updated specific preference');
      return response as String;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating specific preference', e, stackTrace);
      rethrow;
    }
  }

  /// Enable/disable email notifications globally
  Future<String> toggleEmailNotifications(bool enabled) async {
    return updateSpecificPreference(
      preferenceKey: 'email_enabled',
      value: enabled,
    );
  }

  /// Enable/disable push notifications globally
  Future<String> togglePushNotifications(bool enabled) async {
    return updateSpecificPreference(
      preferenceKey: 'push_enabled',
      value: enabled,
    );
  }

  /// Update quiet hours settings
  Future<String> updateQuietHours({
    required bool enabled,
    String? startTime,
    String? endTime,
    String? timezone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Updating quiet hours settings');

      final preferences = <String, dynamic>{
        'quiet_hours_enabled': enabled,
      };

      if (startTime != null) {
        preferences['quiet_hours_start'] = startTime;
      }
      
      if (endTime != null) {
        preferences['quiet_hours_end'] = endTime;
      }
      
      if (timezone != null) {
        preferences['timezone'] = timezone;
      }

      final response = await _supabase.rpc(
        'upsert_notification_preferences',
        params: {
          '_user_id': userId,
          '_preferences': preferences,
        },
      );

      AppLogger.info('Successfully updated quiet hours settings');
      return response as String;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating quiet hours settings', e, stackTrace);
      rethrow;
    }
  }

  /// Update digest preferences
  Future<String> updateDigestPreferences({
    bool? dailyEnabled,
    bool? weeklyEnabled,
    String? digestTime,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Updating digest preferences');

      final preferences = <String, dynamic>{};

      if (dailyEnabled != null) {
        preferences['daily_digest_enabled'] = dailyEnabled;
      }
      
      if (weeklyEnabled != null) {
        preferences['weekly_digest_enabled'] = weeklyEnabled;
      }
      
      if (digestTime != null) {
        preferences['digest_time'] = digestTime;
      }

      final response = await _supabase.rpc(
        'upsert_notification_preferences',
        params: {
          '_user_id': userId,
          '_preferences': preferences,
        },
      );

      AppLogger.info('Successfully updated digest preferences');
      return response as String;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating digest preferences', e, stackTrace);
      rethrow;
    }
  }

  /// Update browser permission status
  Future<String> updateBrowserPermission({
    required bool granted,
    DateTime? requestedAt,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Updating browser permission status: $granted');

      final preferences = <String, dynamic>{
        'browser_permission_granted': granted,
      };

      if (requestedAt != null) {
        preferences['browser_permission_requested_at'] = requestedAt.toIso8601String();
      }

      final response = await _supabase.rpc(
        'upsert_notification_preferences',
        params: {
          '_user_id': userId,
          '_preferences': preferences,
        },
      );

      AppLogger.info('Successfully updated browser permission status');
      return response as String;
    } catch (e, stackTrace) {
      AppLogger.error('Error updating browser permission status', e, stackTrace);
      rethrow;
    }
  }

  /// Get default notification preferences for a user
  NotificationPreferences getDefaultPreferences(String userId) {
    return NotificationPreferences.defaults(userId);
  }

  /// Check if notifications should be shown based on quiet hours
  bool shouldShowNotification(NotificationPreferences preferences) {
    if (!preferences.quietHoursEnabled) {
      return true;
    }

    final now = DateTime.now();
    final startTime = preferences.quietHoursStart;
    final endTime = preferences.quietHoursEnd;

    if (startTime == null || endTime == null) {
      return true;
    }

    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final currentMinutes = now.hour * 60 + now.minute;
      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;

      // Handle overnight quiet hours (e.g., 22:00 to 06:00)
      if (startMinutes > endMinutes) {
        return !(currentMinutes >= startMinutes || currentMinutes <= endMinutes);
      } else {
        return !(currentMinutes >= startMinutes && currentMinutes <= endMinutes);
      }
    } catch (e) {
      AppLogger.error('Error parsing quiet hours', e);
      return true; // Default to showing notifications if parsing fails
    }
  }
}
