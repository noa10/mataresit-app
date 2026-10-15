/// Fixtures shared by the invitation acceptance tests.
///
/// The payload shapes mirror the JSONB returned by the Supabase RPCs
/// (`detect_user_invitation_state`, `validate_direct_invitation_acceptance`,
/// `process_post_auth_invitation`).
library;

/// Records every RPC call so tests can assert how often the backend is hit.
class RecordingInvitationRpc {
  RecordingInvitationRpc(this._responder);

  final Object? Function(String function, Map<String, dynamic> params)
  _responder;

  final List<({String function, Map<String, dynamic> params})> calls = [];

  Future<dynamic> call(String function, Map<String, dynamic> params) async {
    calls.add((function: function, params: params));
    return _responder(function, params);
  }

  int countFor(String function) =>
      calls.where((call) => call.function == function).length;

  Map<String, dynamic> paramsFor(String function) =>
      calls.firstWhere((call) => call.function == function).params;
}

/// RPC A success payload for a given `user_type`.
Map<String, dynamic> detectionPayload({
  required String userType,
  String email = 'invitee@example.com',
  String? currentUserEmail,
  String currentUserId = 'user-1',
  String teamName = 'Acme Team',
  String role = 'member',
  String? customMessage,
  String? expiresAt = '2026-12-31T00:00:00.000Z',
  Map<String, dynamic>? existingMembership,
}) {
  final loggedIn = userType == 'logged_in' || userType == 'cross_team';
  final signedInEmail =
      currentUserEmail ??
      (userType == 'cross_team' ? 'other.user@example.com' : email);

  return {
    'success': true,
    'invitation': {
      'id': 'inv-1',
      'email': email,
      'role': role,
      'team_id': 'team-1',
      'team_name': teamName,
      'expires_at': expiresAt,
      'custom_message': customMessage,
      'invited_by': 'owner-1',
    },
    'user_state': {
      'user_type': userType,
      'user_exists': userType != 'unregistered',
      'user_logged_in': loggedIn,
      'email_match': userType == 'logged_in',
      'current_user_id': loggedIn ? currentUserId : null,
      'current_user_email': loggedIn ? signedInEmail : null,
      'existing_team_membership': existingMembership,
      'cross_team_memberships': loggedIn ? 1 : 0,
    },
  };
}

/// RPC A failure payload.
Map<String, dynamic> detectionErrorPayload({
  String error = 'Invitation not found or has expired',
  String errorCode = 'INVITATION_NOT_FOUND',
}) {
  return {'success': false, 'error': error, 'error_code': errorCode};
}

/// RPC B payload — note there is no `success` key.
Map<String, dynamic> validationPayload({
  required bool canAccept,
  bool emailMatch = true,
  bool alreadyMember = false,
  bool invitationValid = true,
  String? teamName = 'Acme Team',
  String? role = 'member',
}) {
  return {
    'can_accept': canAccept,
    'email_match': emailMatch,
    'already_member': alreadyMember,
    'invitation_valid': invitationValid,
    'team_id': 'team-1',
    'team_name': teamName,
    'role': role,
  };
}

/// RPC C success payload — the payload is nested under `result`.
Map<String, dynamic> acceptancePayload({
  String teamName = 'Acme Team',
  String? redirectUrl = '/teams',
  bool onboardingRequired = true,
}) {
  return {
    'success': true,
    'result': {
      'invitation_accepted': true,
      'team_id': 'team-1',
      'team_name': teamName,
      'user_role': 'member',
      'onboarding_required': onboardingRequired,
      'redirect_url': redirectUrl,
    },
  };
}

/// RPC C failure payload — flat, without a `result` key.
Map<String, dynamic> acceptanceErrorPayload({
  String error = 'Invitation not found or expired',
  String errorCode = 'INVITATION_NOT_FOUND',
}) {
  return {'success': false, 'error': error, 'error_code': errorCode};
}
