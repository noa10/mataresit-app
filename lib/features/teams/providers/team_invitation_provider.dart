import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/team_invitation_model.dart';
import '../../../shared/models/team_model.dart';
import '../services/team_invitation_service.dart';
import '../utils/team_invitation_debugger.dart';

/// State for team invitations
class TeamInvitationState {
  final List<TeamInvitationModel> invitations;
  final bool isLoading;
  final String? error;
  final Map<String, int>? stats;

  const TeamInvitationState({
    this.invitations = const [],
    this.isLoading = false,
    this.error,
    this.stats,
  });

  TeamInvitationState copyWith({
    List<TeamInvitationModel>? invitations,
    bool? isLoading,
    String? error,
    Map<String, int>? stats,
  }) {
    return TeamInvitationState(
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }

  /// Get invitations by status
  List<TeamInvitationModel> getInvitationsByStatus(InvitationStatus status) {
    return invitations.where((invitation) => invitation.status == status).toList();
  }

  /// Get pending invitations (excluding expired)
  List<TeamInvitationModel> get pendingInvitations {
    return invitations.where((invitation) => invitation.isPending).toList();
  }

  /// Get expired invitations
  List<TeamInvitationModel> get expiredInvitations {
    return invitations.where((invitation) => invitation.isExpired).toList();
  }

  /// Get accepted invitations
  List<TeamInvitationModel> get acceptedInvitations {
    return invitations.where((invitation) => invitation.isAccepted).toList();
  }

  /// Get cancelled invitations
  List<TeamInvitationModel> get cancelledInvitations {
    return invitations.where((invitation) => invitation.isCancelled).toList();
  }
}

/// Team invitation notifier
class TeamInvitationNotifier extends StateNotifier<TeamInvitationState> {
  final Ref ref;

  TeamInvitationNotifier(this.ref) : super(const TeamInvitationState());

  /// Load team invitations
  Future<void> loadInvitations(String teamId, {bool includeExpired = true}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      AppLogger.debug('🔍 Loading invitations for team: $teamId');

      // Run debug checks in debug mode
      try {
        await TeamInvitationDebugger.runDebugChecks(teamId);
      } catch (debugError) {
        AppLogger.warning('Debug checks failed (non-critical)', debugError);
      }

      final invitations = await TeamInvitationService.getTeamInvitations(
        teamId: teamId,
        includeExpired: includeExpired,
      );

      final stats = await TeamInvitationService.getInvitationStats(teamId);

      state = state.copyWith(
        invitations: invitations,
        stats: stats,
        isLoading: false,
      );

      AppLogger.debug('✅ Loaded ${invitations.length} invitations');
    } catch (error) {
      AppLogger.error('💥 Failed to load invitations', error);
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// Send invitation
  Future<void> sendInvitation({
    required String teamId,
    required String email,
    required TeamRole role,
    String? customMessage,
    Map<String, dynamic>? permissions,
    int expiresInDays = 7,
    bool sendEmail = true,
  }) async {
    try {
      AppLogger.debug('📤 Sending invitation to: $email');

      await TeamInvitationService.sendInvitation(
        teamId: teamId,
        email: email,
        role: role,
        customMessage: customMessage,
        permissions: permissions,
        expiresInDays: expiresInDays,
        sendEmail: sendEmail,
      );

      // Reload invitations to show the new one
      await loadInvitations(teamId);

      AppLogger.debug('✅ Invitation sent successfully');
    } catch (error) {
      AppLogger.error('💥 Failed to send invitation', error);
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  /// Resend invitation
  Future<void> resendInvitation({
    required String teamId,
    required String invitationId,
    String? customMessage,
    bool extendExpiration = true,
    int newExpirationDays = 7,
  }) async {
    try {
      AppLogger.debug('🔄 Resending invitation: $invitationId');

      await TeamInvitationService.resendInvitation(
        invitationId: invitationId,
        customMessage: customMessage,
        extendExpiration: extendExpiration,
        newExpirationDays: newExpirationDays,
      );

      // Reload invitations to show updated data
      await loadInvitations(teamId);

      AppLogger.debug('✅ Invitation resent successfully');
    } catch (error) {
      AppLogger.error('💥 Failed to resend invitation', error);
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  /// Cancel invitation
  Future<void> cancelInvitation({
    required String teamId,
    required String invitationId,
    String? reason,
  }) async {
    try {
      AppLogger.debug('❌ Cancelling invitation: $invitationId');

      await TeamInvitationService.cancelInvitation(
        invitationId: invitationId,
        reason: reason,
      );

      // Reload invitations to show updated data
      await loadInvitations(teamId);

      AppLogger.debug('✅ Invitation cancelled successfully');
    } catch (error) {
      AppLogger.error('💥 Failed to cancel invitation', error);
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  /// Filter invitations by status
  void filterByStatus(InvitationStatus? status) {
    // This could be implemented to filter the current list
    // For now, we'll reload with the filter
    // Implementation depends on UI requirements
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh invitations
  Future<void> refresh(String teamId) async {
    await loadInvitations(teamId);
  }
}

/// Team invitation provider for a specific team
final teamInvitationProvider = StateNotifierProvider.family<TeamInvitationNotifier, TeamInvitationState, String>((ref, teamId) {
  final notifier = TeamInvitationNotifier(ref);
  // Auto-load invitations when provider is created
  Future.microtask(() => notifier.loadInvitations(teamId));
  return notifier;
});

/// Provider for invitation statistics
final invitationStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, teamId) async {
  return await TeamInvitationService.getInvitationStats(teamId);
});

/// Provider for pending invitations count
final pendingInvitationsCountProvider = Provider.family<int, String>((ref, teamId) {
  final invitationState = ref.watch(teamInvitationProvider(teamId));
  return invitationState.pendingInvitations.length;
});
