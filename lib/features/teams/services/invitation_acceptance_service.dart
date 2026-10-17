import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';

/// Executes a PostgREST RPC call and returns the decoded JSON payload.
///
/// Injected so the acceptance flow can be exercised without a live Supabase
/// client. Production code uses [SupabaseService.rpc].
typedef InvitationRpcExecutor =
    Future<dynamic> Function(String function, Map<String, dynamic> params);

/// Error codes returned by the invitation acceptance RPCs.
class InvitationErrorCodes {
  static const String invitationNotFound = 'INVITATION_NOT_FOUND';
  static const String invitationExpired = 'INVITATION_EXPIRED';
  static const String emailMismatch = 'EMAIL_MISMATCH';
  static const String userStateDetectionFailed = 'USER_STATE_DETECTION_FAILED';
  static const String postAuthProcessingFailed = 'POST_AUTH_PROCESSING_FAILED';
  static const String unexpectedResponse = 'UNEXPECTED_RESPONSE';
}

/// Account state reported by `detect_user_invitation_state` in `user_state.user_type`.
enum InvitationUserType {
  unregistered,
  loggedOut,
  loggedIn,
  crossTeam,

  /// Value the app does not know how to act on (forward compatibility).
  unknown;

  static InvitationUserType fromDatabase(Object? value) {
    switch (value) {
      case 'unregistered':
        return InvitationUserType.unregistered;
      case 'logged_out':
        return InvitationUserType.loggedOut;
      case 'logged_in':
        return InvitationUserType.loggedIn;
      case 'cross_team':
        return InvitationUserType.crossTeam;
      default:
        return InvitationUserType.unknown;
    }
  }
}

/// Invitation summary returned by `detect_user_invitation_state` (no token field).
class InvitationDetails {
  const InvitationDetails({
    required this.email,
    this.id,
    this.role,
    this.teamId,
    this.teamName,
    this.expiresAt,
    this.customMessage,
    this.invitedBy,
  });

  factory InvitationDetails.fromJson(Map<String, dynamic> json) {
    return InvitationDetails(
      id: _asString(json['id']),
      email: _asString(json['email']) ?? '',
      role: _asString(json['role']),
      teamId: _asString(json['team_id']),
      teamName: _asString(json['team_name']),
      expiresAt: _asDateTime(json['expires_at']),
      customMessage: _asString(json['custom_message']),
      invitedBy: _asString(json['invited_by']),
    );
  }

  final String? id;
  final String email;
  final String? role;
  final String? teamId;
  final String? teamName;
  final DateTime? expiresAt;
  final String? customMessage;
  final String? invitedBy;
}

/// Membership the signed-in user already holds on the invited team.
class InvitationExistingMembership {
  const InvitationExistingMembership({this.role, this.joinedAt});

  factory InvitationExistingMembership.fromJson(Map<String, dynamic> json) {
    return InvitationExistingMembership(
      role: _asString(json['role']),
      joinedAt: _asDateTime(json['joined_at']),
    );
  }

  final String? role;
  final DateTime? joinedAt;
}

/// `user_state` block returned by `detect_user_invitation_state`.
class InvitationUserState {
  const InvitationUserState({
    required this.userType,
    this.userExists = false,
    this.userLoggedIn = false,
    this.emailMatch = false,
    this.currentUserId,
    this.currentUserEmail,
    this.existingTeamMembership,
    this.crossTeamMemberships = 0,
  });

  factory InvitationUserState.fromJson(Map<String, dynamic> json) {
    final membership = _asMap(json['existing_team_membership']);
    return InvitationUserState(
      userType: InvitationUserType.fromDatabase(json['user_type']),
      userExists: json['user_exists'] == true,
      userLoggedIn: json['user_logged_in'] == true,
      emailMatch: json['email_match'] == true,
      currentUserId: _asString(json['current_user_id']),
      currentUserEmail: _asString(json['current_user_email']),
      existingTeamMembership: membership == null
          ? null
          : InvitationExistingMembership.fromJson(membership),
      crossTeamMemberships: json['cross_team_memberships'] is int
          ? json['cross_team_memberships'] as int
          : 0,
    );
  }

  final InvitationUserType userType;
  final bool userExists;
  final bool userLoggedIn;
  final bool emailMatch;
  final String? currentUserId;
  final String? currentUserEmail;
  final InvitationExistingMembership? existingTeamMembership;
  final int crossTeamMemberships;
}

/// Result of `detect_user_invitation_state` (RPC A).
class InvitationDetectionResult {
  const InvitationDetectionResult({
    required this.success,
    this.error,
    this.errorCode,
    this.invitation,
    this.userState,
  });

  /// Builds a failure when the call itself could not be completed.
  factory InvitationDetectionResult.failure({
    String? error,
    String? errorCode,
  }) {
    return InvitationDetectionResult(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }

  factory InvitationDetectionResult.fromRpc(Object? raw) {
    final map = _asMap(raw);
    if (map == null) {
      return InvitationDetectionResult.failure(
        errorCode: InvitationErrorCodes.unexpectedResponse,
      );
    }

    if (map['success'] != true) {
      return InvitationDetectionResult.failure(
        error: _asString(map['error']),
        errorCode: _asString(map['error_code']),
      );
    }

    final invitation = _asMap(map['invitation']);
    final userState = _asMap(map['user_state']);
    if (invitation == null || userState == null) {
      return InvitationDetectionResult.failure(
        errorCode: InvitationErrorCodes.unexpectedResponse,
      );
    }

    return InvitationDetectionResult(
      success: true,
      invitation: InvitationDetails.fromJson(invitation),
      userState: InvitationUserState.fromJson(userState),
    );
  }

  final bool success;
  final String? error;
  final String? errorCode;
  final InvitationDetails? invitation;
  final InvitationUserState? userState;
}

/// Result of `validate_direct_invitation_acceptance` (RPC B).
///
/// This payload has no `success` key and no `error_code`: an unknown or expired
/// token comes back as `can_accept: false`.
class AcceptanceValidation {
  const AcceptanceValidation({
    required this.canAccept,
    required this.emailMatch,
    required this.alreadyMember,
    required this.invitationValid,
    this.teamId,
    this.teamName,
    this.role,
  });

  factory AcceptanceValidation.fromRpc(Object? raw) {
    final map = _asMap(raw);
    if (map == null) {
      return const AcceptanceValidation(
        canAccept: false,
        emailMatch: false,
        alreadyMember: false,
        invitationValid: false,
      );
    }

    return AcceptanceValidation(
      canAccept: map['can_accept'] == true,
      emailMatch: map['email_match'] == true,
      alreadyMember: map['already_member'] == true,
      invitationValid: map['invitation_valid'] == true,
      teamId: _asString(map['team_id']),
      teamName: _asString(map['team_name']),
      role: _asString(map['role']),
    );
  }

  final bool canAccept;
  final bool emailMatch;
  final bool alreadyMember;
  final bool invitationValid;
  final String? teamId;
  final String? teamName;
  final String? role;
}

/// Result of `process_post_auth_invitation` (RPC C).
///
/// The success envelope nests the payload under `result`; failures are flat and
/// only carry `error` / `error_code`.
class InvitationAcceptanceResult {
  const InvitationAcceptanceResult({
    required this.success,
    this.error,
    this.errorCode,
    this.invitationAccepted = false,
    this.teamId,
    this.teamName,
    this.userRole,
    this.onboardingRequired = false,
    this.redirectUrl,
  });

  factory InvitationAcceptanceResult.failure({
    String? error,
    String? errorCode,
  }) {
    return InvitationAcceptanceResult(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }

  factory InvitationAcceptanceResult.fromRpc(Object? raw) {
    final map = _asMap(raw);
    if (map == null) {
      return InvitationAcceptanceResult.failure(
        errorCode: InvitationErrorCodes.unexpectedResponse,
      );
    }

    if (map['success'] != true) {
      return InvitationAcceptanceResult.failure(
        error: _asString(map['error']),
        errorCode: _asString(map['error_code']),
      );
    }

    final result = _asMap(map['result']);
    if (result == null) {
      return InvitationAcceptanceResult.failure(
        errorCode: InvitationErrorCodes.unexpectedResponse,
      );
    }

    return InvitationAcceptanceResult(
      success: true,
      invitationAccepted: result['invitation_accepted'] == true,
      teamId: _asString(result['team_id']),
      teamName: _asString(result['team_name']),
      userRole: _asString(result['user_role']),
      onboardingRequired: result['onboarding_required'] == true,
      redirectUrl: _asString(result['redirect_url']),
    );
  }

  final bool success;
  final String? error;
  final String? errorCode;
  final bool invitationAccepted;
  final String? teamId;
  final String? teamName;
  final String? userRole;
  final bool onboardingRequired;
  final String? redirectUrl;
}

/// Wraps the invitation *acceptance* RPCs used by the `/invite/:token` flow.
///
/// The sending side lives in `team_invitation_service.dart`; this service only
/// covers the flow an invitee goes through.
class InvitationAcceptanceService {
  InvitationAcceptanceService({InvitationRpcExecutor? rpc})
    : _rpc = rpc ?? _defaultRpc;

  static const String detectFunction = 'detect_user_invitation_state';
  static const String validateFunction =
      'validate_direct_invitation_acceptance';
  static const String processFunction = 'process_post_auth_invitation';

  /// Stand-in for the web client's `navigator.userAgent`.
  static const String userAgent = 'Mataresit Mobile/${AppConstants.appVersion}';

  final InvitationRpcExecutor _rpc;

  static Future<dynamic> _defaultRpc(
    String function,
    Map<String, dynamic> params,
  ) {
    return SupabaseService.rpc(function, params: params);
  }

  /// RPC A — detects the invitee's account state.
  ///
  /// The backend writes an audit row on **every** call, so this must run once
  /// per screen load (never from `build`).
  Future<InvitationDetectionResult> detectUserInvitationState({
    required String token,
    String? browserFingerprint,
    String? userAgent,
  }) async {
    try {
      AppLogger.debug('🔍 Detecting invitation state');

      final raw = await _rpc(detectFunction, {
        'p_invitation_token': token,
        'p_browser_fingerprint': browserFingerprint,
        'p_ip_address': null,
        'p_user_agent': userAgent,
      });

      final result = InvitationDetectionResult.fromRpc(raw);
      AppLogger.debug(
        '✅ Invitation state detected: ${result.userState?.userType.name}',
      );
      return result;
    } catch (error) {
      AppLogger.error('💥 Failed to detect invitation state', error);
      return InvitationDetectionResult.failure(
        errorCode: InvitationErrorCodes.userStateDetectionFailed,
      );
    }
  }

  /// RPC B — pre-check before accepting. Never throws on a bad token: the
  /// payload simply reports `can_accept: false`.
  Future<AcceptanceValidation> validateDirectInvitationAcceptance({
    required String token,
    required String userId,
  }) async {
    final raw = await _rpc(validateFunction, {
      'p_invitation_token': token,
      'p_user_id': userId,
    });

    return AcceptanceValidation.fromRpc(raw);
  }

  /// RPC C — the actual acceptance.
  Future<InvitationAcceptanceResult> processPostAuthInvitation({
    required String token,
    required String userId,
    String? browserFingerprint,
    String authenticationMethod = 'existing_session',
  }) async {
    try {
      AppLogger.debug('✅ Accepting invitation');

      final raw = await _rpc(processFunction, {
        'p_invitation_token': token,
        'p_user_id': userId,
        'p_authentication_method': authenticationMethod,
        'p_browser_fingerprint': browserFingerprint,
      });

      final result = InvitationAcceptanceResult.fromRpc(raw);
      if (result.success) {
        AppLogger.debug('✅ Invitation accepted for team: ${result.teamName}');
      } else {
        AppLogger.warning(
          '⚠️ Invitation acceptance failed: ${result.errorCode}',
        );
      }
      return result;
    } catch (error) {
      AppLogger.error('💥 Failed to accept invitation', error);
      return InvitationAcceptanceResult.failure(
        errorCode: InvitationErrorCodes.postAuthProcessingFailed,
      );
    }
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

String? _asString(Object? value) {
  if (value == null) return null;
  return value is String ? value : value.toString();
}

DateTime? _asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
