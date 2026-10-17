import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../services/invitation_acceptance_service.dart';
import 'teams_provider.dart';

/// Reason key explaining why `validate_direct_invitation_acceptance` refused the
/// acceptance, so the UI can name the specific problem.
///
/// `already_member` is checked first: a returning member can act on that state
/// (go to the team) while the other flags are dead ends.
String invitationBlockReasonKey(AcceptanceValidation validation) {
  if (validation.alreadyMember) return 'invitations.reasons.alreadyMember';
  if (!validation.emailMatch) return 'invitations.reasons.emailMismatch';
  if (!validation.invitationValid) return 'invitations.reasons.invalid';
  return 'invitations.reasons.generic';
}

/// State of the `/invite/:token` acceptance flow.
class InvitationAcceptanceState {
  const InvitationAcceptanceState({
    this.isDetecting = false,
    this.detection,
    this.isAccepting = false,
    this.blockReasonKey,
    this.acceptanceError,
    this.accepted,
  });

  /// RPC A in flight. `detection` is null while the first call runs.
  final bool isDetecting;
  final InvitationDetectionResult? detection;

  final bool isAccepting;

  /// i18n key for a blocked acceptance (RPC B) or a missing failure detail.
  final String? blockReasonKey;

  /// Raw message returned by RPC C when the acceptance fails.
  final String? acceptanceError;

  /// Set once the invitation has been accepted.
  final InvitationAcceptanceResult? accepted;

  InvitationDetails? get invitation => detection?.invitation;

  InvitationUserState? get userState => detection?.userState;

  InvitationAcceptanceState copyWith({
    bool? isDetecting,
    InvitationDetectionResult? detection,
    bool? isAccepting,
    String? blockReasonKey,
    String? acceptanceError,
    InvitationAcceptanceResult? accepted,
  }) {
    return InvitationAcceptanceState(
      isDetecting: isDetecting ?? this.isDetecting,
      detection: detection ?? this.detection,
      isAccepting: isAccepting ?? this.isAccepting,
      blockReasonKey: blockReasonKey,
      acceptanceError: acceptanceError,
      accepted: accepted ?? this.accepted,
    );
  }
}

/// Drives detection (RPC A), validation (RPC B) and acceptance (RPC C).
class InvitationAcceptanceNotifier
    extends StateNotifier<InvitationAcceptanceState> {
  InvitationAcceptanceNotifier(this._ref, this._service, this._token)
    : super(const InvitationAcceptanceState());

  final Ref _ref;
  final InvitationAcceptanceService _service;
  final String _token;

  /// Re-runs RPC A. Call once per screen load — the backend audits every call.
  Future<void> detect() async {
    state = const InvitationAcceptanceState(isDetecting: true);

    try {
      final result = await _service.detectUserInvitationState(
        token: _token,
        userAgent: InvitationAcceptanceService.userAgent,
      );
      if (!mounted) return;
      state = state.copyWith(isDetecting: false, detection: result);
    } catch (error) {
      AppLogger.error('💥 Invitation detection failed', error);
      if (!mounted) return;
      state = state.copyWith(
        isDetecting: false,
        detection: InvitationDetectionResult.failure(
          errorCode: InvitationErrorCodes.userStateDetectionFailed,
        ),
      );
    }
  }

  /// Validates (RPC B) and, when allowed, accepts (RPC C).
  ///
  /// Returns the acceptance payload on success, or null when the invitation
  /// could not be accepted — the reason is then exposed on [state].
  Future<InvitationAcceptanceResult?> accept() async {
    final userId = state.userState?.currentUserId;
    if (userId == null) {
      AppLogger.warning('⚠️ Cannot accept invitation without a signed-in user');
      state = state.copyWith(blockReasonKey: 'invitations.reasons.generic');
      return null;
    }

    state = state.copyWith(
      isAccepting: true,
      blockReasonKey: null,
      acceptanceError: null,
    );

    try {
      final validation = await _service.validateDirectInvitationAcceptance(
        token: _token,
        userId: userId,
      );
      if (!mounted) return null;

      if (!validation.canAccept) {
        state = state.copyWith(
          isAccepting: false,
          blockReasonKey: invitationBlockReasonKey(validation),
        );
        return null;
      }

      final result = await _service.processPostAuthInvitation(
        token: _token,
        userId: userId,
      );
      if (!mounted) return null;

      if (!result.success) {
        state = state.copyWith(
          isAccepting: false,
          acceptanceError: result.error,
          blockReasonKey: result.error == null
              ? 'invitations.reasons.generic'
              : null,
        );
        return null;
      }

      state = state.copyWith(isAccepting: false, accepted: result);
      await _refreshTeams();
      return result;
    } catch (error) {
      AppLogger.error('💥 Invitation acceptance failed', error);
      if (!mounted) return null;
      state = state.copyWith(
        isAccepting: false,
        blockReasonKey: 'invitations.reasons.generic',
      );
      return null;
    }
  }

  /// Makes the freshly joined team appear without an app restart.
  Future<void> _refreshTeams() async {
    try {
      await _ref.read(teamsProvider.notifier).refresh();
    } catch (error) {
      AppLogger.warning('Failed to refresh teams after accepting', error);
    }
  }
}

/// Service backing the acceptance flow; overridden in tests.
final invitationAcceptanceServiceProvider =
    Provider<InvitationAcceptanceService>(
      (ref) => InvitationAcceptanceService(),
    );

/// Acceptance state for a single invitation token.
///
/// Detection is deliberately *not* triggered here: the caller (the screen)
/// decides when RPC A runs so it is called exactly once per screen load.
final invitationAcceptanceProvider =
    StateNotifierProvider.family<
      InvitationAcceptanceNotifier,
      InvitationAcceptanceState,
      String
    >(
      (ref, token) => InvitationAcceptanceNotifier(
        ref,
        ref.watch(invitationAcceptanceServiceProvider),
        token,
      ),
    );
