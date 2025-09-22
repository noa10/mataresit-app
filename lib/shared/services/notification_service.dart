import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_client.dart';
import '../../core/services/app_logger.dart';
import '../models/notification_model.dart';

/// Comprehensive notification service with Supabase integration
/// Handles CRUD operations, real-time subscriptions, and connection management
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Real-time subscription management
  final Map<String, RealtimeChannel> _activeChannels = {};
  final StreamController<List<NotificationModel>> _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();
  final StreamController<NotificationModel> _newNotificationController =
      StreamController<NotificationModel>.broadcast();
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  // Connection state
  String _connectionStatus = 'disconnected';
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _reconnectDelay = 1000; // milliseconds

  // Cache
  List<NotificationModel> _cachedNotifications = [];
  NotificationStats? _cachedStats;
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Get notifications stream
  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsController.stream;

  /// Get new notification stream
  Stream<NotificationModel> get newNotificationStream =>
      _newNotificationController.stream;

  /// Get connection status stream
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  /// Get current connection status
  String get connectionStatus => _connectionStatus;

  /// Get cached notifications
  List<NotificationModel> get cachedNotifications => _cachedNotifications;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing notification service...');
      await _setupRealtimeSubscription();
      AppLogger.info('Notification service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize notification service',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Fetch notifications with optional filters
  Future<List<NotificationModel>> fetchNotifications({
    NotificationFilters? filters,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh && _isCacheValid() && filters == null) {
        AppLogger.debug('Returning cached notifications');
        return _cachedNotifications;
      }

      AppLogger.info('Fetching notifications from server');

      final supabase = SupabaseService.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Build query
      // For now, use a simple query without complex filtering to get it working
      // TODO: Add proper filtering once the notification table is set up
      final query = supabase
          .from('notifications')
          .select('''
            id,
            recipient_id,
            team_id,
            type,
            priority,
            title,
            message,
            action_url,
            read_at,
            archived_at,
            related_entity_type,
            related_entity_id,
            metadata,
            created_at,
            expires_at
          ''')
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final response = await query;
      final notifications = (response as List)
          .map((json) => _parseNotificationFromJson(json))
          .toList();

      // Update cache if no filters
      if (filters == null) {
        _cachedNotifications = notifications;
        _lastFetch = DateTime.now();
      }

      // Emit to stream
      _notificationsController.add(notifications);

      AppLogger.info('Fetched ${notifications.length} notifications');
      return notifications;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch notifications', e, stackTrace);
      rethrow;
    }
  }

  /// Get notification statistics
  Future<NotificationStats> getNotificationStats({
    String? teamId,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      if (!forceRefresh && _cachedStats != null && _isCacheValid()) {
        return _cachedStats!;
      }

      AppLogger.info('Fetching notification statistics');

      final supabase = SupabaseService.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use RPC function for efficient stats calculation
      final response = await supabase.rpc(
        'get_notification_stats',
        params: {'user_id': userId, 'team_id': teamId},
      );

      final stats = NotificationStats.fromJson(response);
      _cachedStats = stats;

      AppLogger.info('Fetched notification statistics');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch notification statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      AppLogger.info('Marking notification as read: $notificationId');

      final supabase = SupabaseService.client;
      await supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

      // Update cache
      _updateNotificationInCache(notificationId, (notification) {
        return notification.copyWith(readAt: DateTime.now());
      });

      AppLogger.info('Notification marked as read');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to mark notification as read', e, stackTrace);
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({String? teamId}) async {
    try {
      AppLogger.info('Marking all notifications as read');

      final supabase = SupabaseService.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var query = supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('recipient_id', userId)
          .isFilter('read_at', null);

      if (teamId != null) {
        query = query.eq('team_id', teamId);
      }

      await query;

      // Update cache
      final now = DateTime.now();
      _cachedNotifications = _cachedNotifications.map((notification) {
        if (notification.readAt == null &&
            (teamId == null || notification.teamId == teamId)) {
          return notification.copyWith(readAt: now);
        }
        return notification;
      }).toList();

      // Emit updated notifications
      _notificationsController.add(_cachedNotifications);

      AppLogger.info('All notifications marked as read');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to mark all notifications as read',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      AppLogger.info('Archiving notification: $notificationId');

      final supabase = SupabaseService.client;
      await supabase
          .from('notifications')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);

      // Update cache
      _updateNotificationInCache(notificationId, (notification) {
        return notification.copyWith(archivedAt: DateTime.now());
      });

      AppLogger.info('Notification archived');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to archive notification', e, stackTrace);
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      AppLogger.info('Deleting notification: $notificationId');

      final supabase = SupabaseService.client;
      await supabase.from('notifications').delete().eq('id', notificationId);

      // Remove from cache
      _cachedNotifications.removeWhere((n) => n.id == notificationId);
      _notificationsController.add(_cachedNotifications);

      AppLogger.info('Notification deleted');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete notification', e, stackTrace);
      rethrow;
    }
  }

  /// Create a new notification (for testing purposes)
  Future<String> createNotification({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String message,
    String? teamId,
    NotificationPriority priority = NotificationPriority.medium,
    String? actionUrl,
    String? relatedEntityType,
    String? relatedEntityId,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
  }) async {
    try {
      AppLogger.info('Creating notification: $title');

      final supabase = SupabaseService.client;
      final response = await supabase
          .from('notifications')
          .insert({
            'recipient_id': recipientId,
            'team_id': teamId,
            'type': _notificationTypeToString(type),
            'priority': _priorityToString(priority),
            'title': title,
            'message': message,
            'action_url': actionUrl,
            'related_entity_type': relatedEntityType,
            'related_entity_id': relatedEntityId,
            'metadata': metadata ?? {},
            'expires_at': expiresAt?.toIso8601String(),
          })
          .select('id')
          .single();

      final notificationId = response['id'] as String;
      AppLogger.info('Notification created: $notificationId');
      return notificationId;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create notification', e, stackTrace);
      rethrow;
    }
  }

  /// Setup real-time subscription for notifications
  Future<void> _setupRealtimeSubscription() async {
    try {
      final supabase = SupabaseService.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        AppLogger.warning(
          'Cannot setup real-time subscription: user not authenticated',
        );
        return;
      }

      // Clean up existing subscriptions
      await _cleanupSubscriptions();

      AppLogger.info(
        'Setting up real-time notification subscription for user: $userId',
      );

      final channelName = 'notifications-$userId';
      final channel = supabase.channel(channelName);

      // Listen for new notifications
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: userId,
        ),
        callback: _handleNewNotification,
      );

      // Listen for notification updates
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: userId,
        ),
        callback: _handleNotificationUpdate,
      );

      // Listen for notification deletions
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_id',
          value: userId,
        ),
        callback: _handleNotificationDelete,
      );

      // Subscribe to the channel
      channel.subscribe((status, error) {
        _handleSubscriptionStatus(channelName, status, error);
      });

      _activeChannels[channelName] = channel;
      AppLogger.info('Real-time notification subscription established');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to setup real-time subscription', e, stackTrace);
      _updateConnectionStatus('disconnected');
      _scheduleReconnect();
    }
  }

  /// Handle new notification from real-time subscription
  void _handleNewNotification(PostgresChangePayload payload) {
    try {
      AppLogger.debug('Received new notification via real-time');
      final notification = _parseNotificationFromJson(payload.newRecord);

      // Add to cache
      _cachedNotifications.insert(0, notification);

      // Emit to streams
      _newNotificationController.add(notification);
      _notificationsController.add(_cachedNotifications);

      AppLogger.info('New notification processed: ${notification.title}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle new notification', e, stackTrace);
    }
  }

  /// Handle notification update from real-time subscription
  void _handleNotificationUpdate(PostgresChangePayload payload) {
    try {
      AppLogger.debug('Received notification update via real-time');
      final updatedNotification = _parseNotificationFromJson(payload.newRecord);

      // Update in cache
      final index = _cachedNotifications.indexWhere(
        (n) => n.id == updatedNotification.id,
      );
      if (index != -1) {
        _cachedNotifications[index] = updatedNotification;
        _notificationsController.add(_cachedNotifications);
      }

      AppLogger.debug('Notification updated: ${updatedNotification.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle notification update', e, stackTrace);
    }
  }

  /// Handle notification deletion from real-time subscription
  void _handleNotificationDelete(PostgresChangePayload payload) {
    try {
      AppLogger.debug('Received notification deletion via real-time');
      final deletedId = payload.oldRecord['id'] as String;

      // Remove from cache
      _cachedNotifications.removeWhere((n) => n.id == deletedId);
      _notificationsController.add(_cachedNotifications);

      AppLogger.debug('Notification deleted: $deletedId');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to handle notification deletion', e, stackTrace);
    }
  }

  /// Handle subscription status changes
  void _handleSubscriptionStatus(
    String channelName,
    RealtimeSubscribeStatus status, [
    Object? error,
  ]) {
    AppLogger.info('Subscription status for $channelName: $status');

    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _updateConnectionStatus('connected');
        _reconnectAttempts = 0;
        break;
      case RealtimeSubscribeStatus.channelError:
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.closed:
        _updateConnectionStatus('disconnected');
        if (error != null) {
          AppLogger.error('Subscription error for $channelName', error);
        }
        _scheduleReconnect();
        break;
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(String status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      _connectionStatusController.add(status);
      AppLogger.info('Connection status changed to: $status');
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.warning('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;

    AppLogger.info(
      'Scheduling reconnection attempt $_reconnectAttempts in ${delay}ms',
    );

    Timer(Duration(milliseconds: delay), () {
      _updateConnectionStatus('reconnecting');
      _setupRealtimeSubscription();
    });
  }

  /// Reconnect to real-time subscriptions
  Future<void> reconnect() async {
    AppLogger.info('Manual reconnection requested');
    _reconnectAttempts = 0;
    await _setupRealtimeSubscription();
  }

  /// Refresh notifications from server
  Future<void> refreshNotifications() async {
    AppLogger.info('Refreshing notifications');
    await fetchNotifications(forceRefresh: true);
  }

  /// Clean up existing subscriptions
  Future<void> _cleanupSubscriptions() async {
    try {
      for (final channel in _activeChannels.values) {
        await SupabaseService.unsubscribe(channel);
      }
      _activeChannels.clear();
      AppLogger.debug('Cleaned up existing subscriptions');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup subscriptions', e, stackTrace);
    }
  }

  /// Parse notification from JSON response
  NotificationModel _parseNotificationFromJson(Map<String, dynamic> json) {
    try {
      // Handle team name from joined data
      String? teamName;
      if (json['teams'] != null) {
        if (json['teams'] is List && (json['teams'] as List).isNotEmpty) {
          teamName = json['teams'][0]['name'];
        } else if (json['teams'] is Map) {
          teamName = json['teams']['name'];
        }
      }

      return NotificationModel(
        id: json['id'],
        recipientId: json['recipient_id'],
        teamId: json['team_id'],
        type: _stringToNotificationType(json['type']),
        priority: _stringToPriority(json['priority']),
        title: json['title'],
        message: json['message'],
        actionUrl: json['action_url'],
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'])
            : null,
        archivedAt: json['archived_at'] != null
            ? DateTime.parse(json['archived_at'])
            : null,
        relatedEntityType: json['related_entity_type'],
        relatedEntityId: json['related_entity_id'],
        metadata: json['metadata'] ?? {},
        createdAt: DateTime.parse(json['created_at']),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'])
            : null,
        teamName: teamName,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse notification from JSON', e, stackTrace);
      rethrow;
    }
  }

  /// Update notification in cache
  void _updateNotificationInCache(
    String notificationId,
    NotificationModel Function(NotificationModel) updater,
  ) {
    final index = _cachedNotifications.indexWhere(
      (n) => n.id == notificationId,
    );
    if (index != -1) {
      _cachedNotifications[index] = updater(_cachedNotifications[index]);
      _notificationsController.add(_cachedNotifications);
    }
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    return _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheExpiry;
  }

  /// Convert notification type to string
  String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.teamInvitationSent:
        return 'team_invitation_sent';
      case NotificationType.teamInvitationAccepted:
        return 'team_invitation_accepted';
      case NotificationType.teamMemberJoined:
        return 'team_member_joined';
      case NotificationType.teamMemberLeft:
        return 'team_member_left';
      case NotificationType.teamMemberRemoved:
        return 'team_member_removed';
      case NotificationType.teamMemberRoleChanged:
        return 'team_member_role_changed';
      case NotificationType.claimSubmitted:
        return 'claim_submitted';
      case NotificationType.claimApproved:
        return 'claim_approved';
      case NotificationType.claimRejected:
        return 'claim_rejected';
      case NotificationType.claimReviewRequested:
        return 'claim_review_requested';
      case NotificationType.teamSettingsUpdated:
        return 'team_settings_updated';
      case NotificationType.receiptProcessingStarted:
        return 'receipt_processing_started';
      case NotificationType.receiptProcessingCompleted:
        return 'receipt_processing_completed';
      case NotificationType.receiptProcessingFailed:
        return 'receipt_processing_failed';
      case NotificationType.receiptReadyForReview:
        return 'receipt_ready_for_review';
      case NotificationType.receiptBatchCompleted:
        return 'receipt_batch_completed';
      case NotificationType.receiptBatchFailed:
        return 'receipt_batch_failed';
      case NotificationType.receiptShared:
        return 'receipt_shared';
      case NotificationType.receiptCommentAdded:
        return 'receipt_comment_added';
      case NotificationType.receiptEditedByTeamMember:
        return 'receipt_edited_by_team_member';
      case NotificationType.receiptApprovedByTeam:
        return 'receipt_approved_by_team';
      case NotificationType.receiptFlaggedForReview:
        return 'receipt_flagged_for_review';
    }
  }

  /// Convert string to notification type
  NotificationType _stringToNotificationType(String type) {
    switch (type) {
      case 'team_invitation_sent':
        return NotificationType.teamInvitationSent;
      case 'team_invitation_accepted':
        return NotificationType.teamInvitationAccepted;
      case 'team_member_joined':
        return NotificationType.teamMemberJoined;
      case 'team_member_left':
        return NotificationType.teamMemberLeft;
      case 'team_member_removed':
        return NotificationType.teamMemberRemoved;
      case 'team_member_role_changed':
        return NotificationType.teamMemberRoleChanged;
      case 'claim_submitted':
        return NotificationType.claimSubmitted;
      case 'claim_approved':
        return NotificationType.claimApproved;
      case 'claim_rejected':
        return NotificationType.claimRejected;
      case 'claim_review_requested':
        return NotificationType.claimReviewRequested;
      case 'team_settings_updated':
        return NotificationType.teamSettingsUpdated;
      case 'receipt_processing_started':
        return NotificationType.receiptProcessingStarted;
      case 'receipt_processing_completed':
        return NotificationType.receiptProcessingCompleted;
      case 'receipt_processing_failed':
        return NotificationType.receiptProcessingFailed;
      case 'receipt_ready_for_review':
        return NotificationType.receiptReadyForReview;
      case 'receipt_batch_completed':
        return NotificationType.receiptBatchCompleted;
      case 'receipt_batch_failed':
        return NotificationType.receiptBatchFailed;
      case 'receipt_shared':
        return NotificationType.receiptShared;
      case 'receipt_comment_added':
        return NotificationType.receiptCommentAdded;
      case 'receipt_edited_by_team_member':
        return NotificationType.receiptEditedByTeamMember;
      case 'receipt_approved_by_team':
        return NotificationType.receiptApprovedByTeam;
      case 'receipt_flagged_for_review':
        return NotificationType.receiptFlaggedForReview;
      default:
        throw ArgumentError('Unknown notification type: $type');
    }
  }

  /// Convert priority to string
  String _priorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.medium:
        return 'medium';
      case NotificationPriority.high:
        return 'high';
    }
  }

  /// Convert string to priority
  NotificationPriority _stringToPriority(String priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      default:
        return NotificationPriority.medium;
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupSubscriptions();
    _notificationsController.close();
    _newNotificationController.close();
    _connectionStatusController.close();
  }
}
