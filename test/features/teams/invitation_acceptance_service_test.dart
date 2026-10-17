import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/teams/providers/invitation_acceptance_provider.dart';
import 'package:mataresit_app/features/teams/services/invitation_acceptance_service.dart';

import 'invitation_acceptance_fixtures.dart';

void main() {
  group('InvitationAcceptanceService.detectUserInvitationState', () {
    test('maps every backend user_type to its enum value', () async {
      late String rawUserType;
      final rpc = RecordingInvitationRpc(
        (_, _) => detectionPayload(userType: rawUserType),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      const expected = {
        'unregistered': InvitationUserType.unregistered,
        'logged_out': InvitationUserType.loggedOut,
        'logged_in': InvitationUserType.loggedIn,
        'cross_team': InvitationUserType.crossTeam,
      };

      for (final entry in expected.entries) {
        rawUserType = entry.key;

        final result = await service.detectUserInvitationState(token: 'tok');

        expect(result.success, isTrue, reason: 'for ${entry.key}');
        expect(result.userState!.userType, entry.value);
      }

      expect(rpc.countFor(InvitationAcceptanceService.detectFunction), 4);
    });

    test('parses the invitation details returned with the state', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) => detectionPayload(
          userType: 'logged_in',
          teamName: 'Acme Team',
          role: 'admin',
          customMessage: 'Welcome aboard',
        ),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.detectUserInvitationState(token: 'tok');
      final invitation = result.invitation!;

      expect(invitation.teamName, 'Acme Team');
      expect(invitation.email, 'invitee@example.com');
      expect(invitation.role, 'admin');
      expect(invitation.customMessage, 'Welcome aboard');
      expect(invitation.expiresAt, DateTime.parse('2026-12-31T00:00:00.000Z'));
      expect(invitation.invitedBy, 'owner-1');
    });

    test(
      'reports an existing membership for an already-joined member',
      () async {
        final rpc = RecordingInvitationRpc(
          (_, _) => detectionPayload(
            userType: 'logged_in',
            existingMembership: {
              'role': 'member',
              'joined_at': '2026-01-01T00:00:00.000Z',
            },
          ),
        );
        final service = InvitationAcceptanceService(rpc: rpc.call);

        final result = await service.detectUserInvitationState(token: 'tok');
        final membership = result.userState!.existingTeamMembership!;

        expect(membership.role, 'member');
        expect(membership.joinedAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      },
    );

    test('sends the token, the user agent and leaves the IP unset', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) => detectionPayload(userType: 'logged_out'),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      await service.detectUserInvitationState(
        token: 'tok-123',
        userAgent: 'TestAgent/1.0',
      );

      final params = rpc.paramsFor(InvitationAcceptanceService.detectFunction);
      expect(params['p_invitation_token'], 'tok-123');
      expect(params['p_user_agent'], 'TestAgent/1.0');
      expect(params['p_ip_address'], isNull);
      expect(params['p_browser_fingerprint'], isNull);
    });

    test('surfaces the backend error message and code', () async {
      final rpc = RecordingInvitationRpc((_, _) => detectionErrorPayload());
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.detectUserInvitationState(token: 'tok');

      expect(result.success, isFalse);
      expect(result.error, 'Invitation not found or has expired');
      expect(result.errorCode, InvitationErrorCodes.invitationNotFound);
      expect(result.invitation, isNull);
      expect(result.userState, isNull);
    });

    test('reports an unexpected response for an unusable payload', () async {
      final rpc = RecordingInvitationRpc((_, _) => null);
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.detectUserInvitationState(token: 'tok');

      expect(result.success, isFalse);
      expect(result.errorCode, InvitationErrorCodes.unexpectedResponse);
    });

    test('reports USER_STATE_DETECTION_FAILED when the RPC throws', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) => throw Exception('permission denied for function'),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.detectUserInvitationState(token: 'tok');

      expect(result.success, isFalse);
      expect(result.errorCode, InvitationErrorCodes.userStateDetectionFailed);
    });
  });

  group('InvitationAcceptanceService.validateDirectInvitationAcceptance', () {
    test('parses an accept-ready invitation', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) => validationPayload(canAccept: true),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final validation = await service.validateDirectInvitationAcceptance(
        token: 'tok',
        userId: 'user-1',
      );

      expect(validation.canAccept, isTrue);
      expect(validation.emailMatch, isTrue);
      expect(validation.alreadyMember, isFalse);
      expect(validation.invitationValid, isTrue);
      expect(validation.teamName, 'Acme Team');
      expect(validation.role, 'member');
    });

    test(
      'parses a refusal even though the payload has no success key',
      () async {
        final rpc = RecordingInvitationRpc(
          (_, _) => validationPayload(canAccept: false, invitationValid: false),
        );
        final service = InvitationAcceptanceService(rpc: rpc.call);

        final validation = await service.validateDirectInvitationAcceptance(
          token: 'tok',
          userId: 'user-1',
        );

        expect(validation.canAccept, isFalse);
        expect(validation.invitationValid, isFalse);
      },
    );

    test('sends the token and user id as the backend expects', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) => validationPayload(canAccept: true),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      await service.validateDirectInvitationAcceptance(
        token: 'tok-123',
        userId: 'user-9',
      );

      final params = rpc.paramsFor(
        InvitationAcceptanceService.validateFunction,
      );
      expect(params, {'p_invitation_token': 'tok-123', 'p_user_id': 'user-9'});
    });
  });

  group('InvitationAcceptanceService.processPostAuthInvitation', () {
    test('unwraps the nested result envelope on success', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) =>
            acceptancePayload(teamName: 'Acme Team', redirectUrl: '/teams'),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.processPostAuthInvitation(
        token: 'tok',
        userId: 'user-1',
      );

      expect(result.success, isTrue);
      expect(result.invitationAccepted, isTrue);
      expect(result.teamId, 'team-1');
      expect(result.teamName, 'Acme Team');
      expect(result.userRole, 'member');
      expect(result.onboardingRequired, isTrue);
      expect(result.redirectUrl, '/teams');
      expect(result.error, isNull);
      expect(result.errorCode, isNull);
    });

    test('parses the flat error shape', () async {
      final rpc = RecordingInvitationRpc((_, _) => acceptanceErrorPayload());
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.processPostAuthInvitation(
        token: 'tok',
        userId: 'user-1',
      );

      expect(result.success, isFalse);
      expect(result.error, 'Invitation not found or expired');
      expect(result.errorCode, InvitationErrorCodes.invitationNotFound);
      expect(result.invitationAccepted, isFalse);
      expect(result.teamId, isNull);
      expect(result.redirectUrl, isNull);
    });

    test('parses the flat email mismatch error shape', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) => acceptanceErrorPayload(
          error: 'User email does not match invitation',
          errorCode: 'EMAIL_MISMATCH',
        ),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.processPostAuthInvitation(
        token: 'tok',
        userId: 'user-1',
      );

      expect(result.success, isFalse);
      expect(result.errorCode, InvitationErrorCodes.emailMismatch);
      expect(result.error, 'User email does not match invitation');
    });

    test('sends the existing-session authentication method', () async {
      final rpc = RecordingInvitationRpc((_, _) => acceptancePayload());
      final service = InvitationAcceptanceService(rpc: rpc.call);

      await service.processPostAuthInvitation(
        token: 'tok-123',
        userId: 'user-9',
      );

      final params = rpc.paramsFor(InvitationAcceptanceService.processFunction);
      expect(params['p_invitation_token'], 'tok-123');
      expect(params['p_user_id'], 'user-9');
      expect(params['p_authentication_method'], 'existing_session');
      expect(params['p_browser_fingerprint'], isNull);
    });

    test('reports POST_AUTH_PROCESSING_FAILED when the RPC throws', () async {
      final rpc = RecordingInvitationRpc(
        (_, _) => throw Exception('network unavailable'),
      );
      final service = InvitationAcceptanceService(rpc: rpc.call);

      final result = await service.processPostAuthInvitation(
        token: 'tok',
        userId: 'user-1',
      );

      expect(result.success, isFalse);
      expect(result.errorCode, InvitationErrorCodes.postAuthProcessingFailed);
    });

    test(
      'reports an unexpected response when success carries no result',
      () async {
        final rpc = RecordingInvitationRpc((_, _) => {'success': true});
        final service = InvitationAcceptanceService(rpc: rpc.call);

        final result = await service.processPostAuthInvitation(
          token: 'tok',
          userId: 'user-1',
        );

        expect(result.success, isFalse);
        expect(result.errorCode, InvitationErrorCodes.unexpectedResponse);
      },
    );
  });

  group('invitationBlockReasonKey', () {
    test('names an already joined member', () {
      final reason = invitationBlockReasonKey(
        const AcceptanceValidation(
          canAccept: false,
          emailMatch: true,
          alreadyMember: true,
          invitationValid: true,
        ),
      );

      expect(reason, 'invitations.reasons.alreadyMember');
    });

    test('names an email mismatch', () {
      final reason = invitationBlockReasonKey(
        const AcceptanceValidation(
          canAccept: false,
          emailMatch: false,
          alreadyMember: false,
          invitationValid: true,
        ),
      );

      expect(reason, 'invitations.reasons.emailMismatch');
    });

    test('names an expired or missing invitation', () {
      final reason = invitationBlockReasonKey(
        const AcceptanceValidation(
          canAccept: false,
          emailMatch: true,
          alreadyMember: false,
          invitationValid: false,
        ),
      );

      expect(reason, 'invitations.reasons.invalid');
    });

    test('falls back to a generic reason', () {
      final reason = invitationBlockReasonKey(
        const AcceptanceValidation(
          canAccept: true,
          emailMatch: true,
          alreadyMember: false,
          invitationValid: true,
        ),
      );

      expect(reason, 'invitations.reasons.generic');
    });

    test('prefers the already-member reason when several flags are set', () {
      final reason = invitationBlockReasonKey(
        const AcceptanceValidation(
          canAccept: false,
          emailMatch: false,
          alreadyMember: true,
          invitationValid: false,
        ),
      );

      expect(reason, 'invitations.reasons.alreadyMember');
    });
  });
}
