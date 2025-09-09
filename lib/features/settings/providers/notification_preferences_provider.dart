import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/notification_preferences_model.dart';
import '../../../shared/services/notification_preferences_service.dart';
import '../../../core/services/app_logger.dart';
import '../../auth/providers/auth_provider.dart';

/// Notification preferences state
class NotificationPreferencesState extends Equatable {
  final NotificationPreferences? preferences;
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final String? updateError;

  const NotificationPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.updateError,
  });

  NotificationPreferencesState copyWith({
    NotificationPreferences? preferences,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    String? updateError,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      updateError: updateError,
    );
  }

  @override
  List<Object?> get props => [
    preferences,
    isLoading,
    isUpdating,
    error,
    updateError,
  ];
}

/// Notification preferences provider
class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  NotificationPreferencesNotifier(this._service, this._authNotifier)
    : super(const NotificationPreferencesState()) {
    // Listen to auth changes and load preferences when user logs in
    _authNotifier.addListener((authState) {
      if (authState.user != null && state.preferences == null) {
        loadPreferences();
      } else if (authState.user == null) {
        // Clear preferences when user logs out
        state = const NotificationPreferencesState();
      }
    });
  }

  final NotificationPreferencesService _service;
  final StateNotifier<AuthState> _authNotifier;

  /// Load notification preferences
  Future<void> loadPreferences() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final preferences = await _service.getUserNotificationPreferences();
      state = state.copyWith(preferences: preferences, isLoading: false);
      AppLogger.info('Notification preferences loaded successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load notification preferences', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    if (state.isUpdating) return;

    state = state.copyWith(isUpdating: true, updateError: null);

    try {
      await _service.updateNotificationPreferences(preferences);
      state = state.copyWith(preferences: preferences, isUpdating: false);
      AppLogger.info('Notification preferences updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update notification preferences',
        e,
        stackTrace,
      );
      state = state.copyWith(isUpdating: false, updateError: e.toString());
    }
  }

  /// Toggle email notifications globally
  Future<void> toggleEmailNotifications(bool enabled) async {
    if (state.preferences == null) return;

    final updatedPreferences = state.preferences!.copyWith(
      emailEnabled: enabled,
    );
    await updatePreferences(updatedPreferences);
  }

  /// Toggle push notifications globally
  Future<void> togglePushNotifications(bool enabled) async {
    if (state.preferences == null) return;

    final updatedPreferences = state.preferences!.copyWith(
      pushEnabled: enabled,
    );
    await updatePreferences(updatedPreferences);
  }

  /// Update email preference for a specific notification type
  Future<void> updateEmailPreference(
    NotificationType type,
    bool enabled,
  ) async {
    if (state.preferences == null) return;

    NotificationPreferences updatedPreferences;

    switch (type) {
      case NotificationType.receiptProcessingStarted:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptProcessingStarted: enabled,
        );
        break;
      case NotificationType.receiptProcessingCompleted:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptProcessingCompleted: enabled,
        );
        break;
      case NotificationType.receiptProcessingFailed:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptProcessingFailed: enabled,
        );
        break;
      case NotificationType.receiptReadyForReview:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptReadyForReview: enabled,
        );
        break;
      case NotificationType.receiptBatchCompleted:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptBatchCompleted: enabled,
        );
        break;
      case NotificationType.receiptBatchFailed:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptBatchFailed: enabled,
        );
        break;
      case NotificationType.receiptShared:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptShared: enabled,
        );
        break;
      case NotificationType.receiptCommentAdded:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptCommentAdded: enabled,
        );
        break;
      case NotificationType.receiptEditedByTeamMember:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptEditedByTeamMember: enabled,
        );
        break;
      case NotificationType.receiptApprovedByTeam:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptApprovedByTeam: enabled,
        );
        break;
      case NotificationType.receiptFlaggedForReview:
        updatedPreferences = state.preferences!.copyWith(
          emailReceiptFlaggedForReview: enabled,
        );
        break;
      case NotificationType.teamInvitationSent:
        updatedPreferences = state.preferences!.copyWith(
          emailTeamInvitationSent: enabled,
        );
        break;
      case NotificationType.teamInvitationAccepted:
        updatedPreferences = state.preferences!.copyWith(
          emailTeamInvitationAccepted: enabled,
        );
        break;
      case NotificationType.teamMemberJoined:
        updatedPreferences = state.preferences!.copyWith(
          emailTeamMemberJoined: enabled,
        );
        break;
      case NotificationType.teamMemberLeft:
        updatedPreferences = state.preferences!.copyWith(
          emailTeamMemberLeft: enabled,
        );
        break;
      case NotificationType.teamMemberRemoved:
        updatedPreferences = state.preferences!.copyWith(
          emailTeamMemberRemoved: enabled,
        );
        break;
      case NotificationType.teamMemberRoleChanged:
        updatedPreferences = state.preferences!.copyWith(
          emailTeamMemberRoleChanged: enabled,
        );
        break;
      case NotificationType.teamSettingsUpdated:
        updatedPreferences = state.preferences!.copyWith(
          emailTeamSettingsUpdated: enabled,
        );
        break;
      case NotificationType.claimSubmitted:
        updatedPreferences = state.preferences!.copyWith(
          emailClaimSubmitted: enabled,
        );
        break;
      case NotificationType.claimApproved:
        updatedPreferences = state.preferences!.copyWith(
          emailClaimApproved: enabled,
        );
        break;
      case NotificationType.claimRejected:
        updatedPreferences = state.preferences!.copyWith(
          emailClaimRejected: enabled,
        );
        break;
      case NotificationType.claimReviewRequested:
        updatedPreferences = state.preferences!.copyWith(
          emailClaimReviewRequested: enabled,
        );
        break;
    }

    await updatePreferences(updatedPreferences);
  }

  /// Update push preference for a specific notification type
  Future<void> updatePushPreference(NotificationType type, bool enabled) async {
    if (state.preferences == null) return;

    NotificationPreferences updatedPreferences;

    switch (type) {
      case NotificationType.receiptProcessingStarted:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptProcessingStarted: enabled,
        );
        break;
      case NotificationType.receiptProcessingCompleted:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptProcessingCompleted: enabled,
        );
        break;
      case NotificationType.receiptProcessingFailed:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptProcessingFailed: enabled,
        );
        break;
      case NotificationType.receiptReadyForReview:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptReadyForReview: enabled,
        );
        break;
      case NotificationType.receiptBatchCompleted:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptBatchCompleted: enabled,
        );
        break;
      case NotificationType.receiptBatchFailed:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptBatchFailed: enabled,
        );
        break;
      case NotificationType.receiptShared:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptShared: enabled,
        );
        break;
      case NotificationType.receiptCommentAdded:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptCommentAdded: enabled,
        );
        break;
      case NotificationType.receiptEditedByTeamMember:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptEditedByTeamMember: enabled,
        );
        break;
      case NotificationType.receiptApprovedByTeam:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptApprovedByTeam: enabled,
        );
        break;
      case NotificationType.receiptFlaggedForReview:
        updatedPreferences = state.preferences!.copyWith(
          pushReceiptFlaggedForReview: enabled,
        );
        break;
      case NotificationType.teamInvitationSent:
        updatedPreferences = state.preferences!.copyWith(
          pushTeamInvitationSent: enabled,
        );
        break;
      case NotificationType.teamInvitationAccepted:
        updatedPreferences = state.preferences!.copyWith(
          pushTeamInvitationAccepted: enabled,
        );
        break;
      case NotificationType.teamMemberJoined:
        updatedPreferences = state.preferences!.copyWith(
          pushTeamMemberJoined: enabled,
        );
        break;
      case NotificationType.teamMemberLeft:
        updatedPreferences = state.preferences!.copyWith(
          pushTeamMemberLeft: enabled,
        );
        break;
      case NotificationType.teamMemberRemoved:
        updatedPreferences = state.preferences!.copyWith(
          pushTeamMemberRemoved: enabled,
        );
        break;
      case NotificationType.teamMemberRoleChanged:
        updatedPreferences = state.preferences!.copyWith(
          pushTeamMemberRoleChanged: enabled,
        );
        break;
      case NotificationType.teamSettingsUpdated:
        updatedPreferences = state.preferences!.copyWith(
          pushTeamSettingsUpdated: enabled,
        );
        break;
      case NotificationType.claimSubmitted:
        updatedPreferences = state.preferences!.copyWith(
          pushClaimSubmitted: enabled,
        );
        break;
      case NotificationType.claimApproved:
        updatedPreferences = state.preferences!.copyWith(
          pushClaimApproved: enabled,
        );
        break;
      case NotificationType.claimRejected:
        updatedPreferences = state.preferences!.copyWith(
          pushClaimRejected: enabled,
        );
        break;
      case NotificationType.claimReviewRequested:
        updatedPreferences = state.preferences!.copyWith(
          pushClaimReviewRequested: enabled,
        );
        break;
    }

    await updatePreferences(updatedPreferences);
  }

  /// Update quiet hours settings
  Future<void> updateQuietHours({
    required bool enabled,
    String? startTime,
    String? endTime,
    String? timezone,
  }) async {
    if (state.preferences == null) return;

    final updatedPreferences = state.preferences!.copyWith(
      quietHoursEnabled: enabled,
      quietHoursStart: startTime ?? state.preferences!.quietHoursStart,
      quietHoursEnd: endTime ?? state.preferences!.quietHoursEnd,
      timezone: timezone ?? state.preferences!.timezone,
    );

    await updatePreferences(updatedPreferences);
  }

  /// Update digest preferences
  Future<void> updateDigestPreferences({
    bool? dailyEnabled,
    bool? weeklyEnabled,
    String? digestTime,
  }) async {
    if (state.preferences == null) return;

    final updatedPreferences = state.preferences!.copyWith(
      dailyDigestEnabled: dailyEnabled ?? state.preferences!.dailyDigestEnabled,
      weeklyDigestEnabled:
          weeklyEnabled ?? state.preferences!.weeklyDigestEnabled,
      digestTime: digestTime ?? state.preferences!.digestTime,
    );

    await updatePreferences(updatedPreferences);
  }

  /// Update browser permission status
  Future<void> updateBrowserPermission({
    required bool granted,
    DateTime? requestedAt,
  }) async {
    if (state.preferences == null) return;

    final updatedPreferences = state.preferences!.copyWith(
      browserPermissionGranted: granted,
      browserPermissionRequestedAt:
          requestedAt ?? state.preferences!.browserPermissionRequestedAt,
    );

    await updatePreferences(updatedPreferences);
  }

  /// Clear error states
  void clearErrors() {
    state = state.copyWith(error: null, updateError: null);
  }

  /// Refresh preferences
  Future<void> refresh() async {
    await loadPreferences();
  }
}

/// Notification preferences service provider
final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
      return NotificationPreferencesService();
    });

/// Notification preferences provider
final notificationPreferencesProvider =
    StateNotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreferencesState
    >((ref) {
      final service = ref.watch(notificationPreferencesServiceProvider);
      final authNotifier = ref.read(authProvider.notifier);
      return NotificationPreferencesNotifier(service, authNotifier);
    });

/// Convenience providers for specific states
final notificationPreferencesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notificationPreferencesProvider).isLoading;
});

final notificationPreferencesUpdatingProvider = Provider<bool>((ref) {
  return ref.watch(notificationPreferencesProvider).isUpdating;
});

final notificationPreferencesErrorProvider = Provider<String?>((ref) {
  return ref.watch(notificationPreferencesProvider).error;
});

final notificationPreferencesUpdateErrorProvider = Provider<String?>((ref) {
  return ref.watch(notificationPreferencesProvider).updateError;
});

final currentNotificationPreferencesProvider =
    Provider<NotificationPreferences?>((ref) {
      return ref.watch(notificationPreferencesProvider).preferences;
    });
