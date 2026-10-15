import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mataresit_app/features/auth/providers/auth_provider.dart';
import 'package:mataresit_app/features/teams/providers/invitation_acceptance_provider.dart';
import 'package:mataresit_app/features/teams/providers/teams_provider.dart';
import 'package:mataresit_app/features/teams/screens/invite_acceptance_screen.dart';
import 'package:mataresit_app/features/teams/services/invitation_acceptance_service.dart';
import 'package:mataresit_app/shared/models/user_model.dart';
import 'package:mataresit_app/shared/widgets/loading_widget.dart';

import 'invitation_acceptance_fixtures.dart';

/// Stand-in for the signed-in user; the real provider needs a Supabase session.
final _signedInUser = StateProvider<UserModel?>((ref) => null);

final _testUser = UserModel(
  id: 'user-1',
  email: 'invitee@example.com',
  createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
  updatedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
);

/// Teams notifier that never touches Supabase and counts refreshes.
class _FakeTeamsNotifier extends TeamsNotifier {
  _FakeTeamsNotifier(super.ref);

  int refreshCount = 0;

  @override
  Future<void> loadTeams() async {
    // Intentionally does nothing: no Supabase client in widget tests.
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
    await loadTeams();
  }
}

/// Loads the fragment this feature ships instead of a bundled asset file.
class _InvitationFragmentAssetLoader extends AssetLoader {
  const _InvitationFragmentAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final file = File('$path/invitations.${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

class _Harness {
  _Harness({
    required this.container,
    required this.rpc,
    required this.rebuildTick,
  });

  final ProviderContainer container;
  final RecordingInvitationRpc rpc;
  final ValueNotifier<int> rebuildTick;

  _FakeTeamsNotifier get teams =>
      container.read(teamsProvider.notifier) as _FakeTeamsNotifier;

  int get detectCalls =>
      rpc.countFor(InvitationAcceptanceService.detectFunction);

  int get validateCalls =>
      rpc.countFor(InvitationAcceptanceService.validateFunction);

  int get acceptCalls =>
      rpc.countFor(InvitationAcceptanceService.processFunction);

  void signIn() {
    container.read(_signedInUser.notifier).state = _testUser;
  }
}

GoRouter _router(String token, ValueNotifier<int> rebuildTick) {
  return GoRouter(
    initialLocation: '/invite/$token',
    routes: [
      GoRoute(
        path: '/invite/:token',
        builder: (context, state) {
          final routeToken = state.pathParameters['token']!;
          return ValueListenableBuilder<int>(
            valueListenable: rebuildTick,
            builder: (context, _, _) =>
                InviteAcceptanceScreen(token: routeToken),
          );
        },
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => const Text('teams-stub'),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Text('login-stub'),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Text('register-stub'),
      ),
    ],
  );
}

ProviderContainer _container(RecordingInvitationRpc rpc) {
  return ProviderContainer(
    overrides: [
      invitationAcceptanceServiceProvider.overrideWithValue(
        InvitationAcceptanceService(rpc: rpc.call),
      ),
      teamsProvider.overrideWith((ref) => _FakeTeamsNotifier(ref)),
      currentUserProvider.overrideWith((ref) => ref.watch(_signedInUser)),
    ],
  );
}

/// Mirrors the EasyLocalization wiring of `lib/main.dart`, pointed at the
/// fragment this feature ships.
Widget _app(ProviderContainer container, GoRouter router) {
  return UncontrolledProviderScope(
    container: container,
    child: EasyLocalization(
      supportedLocales: const [Locale('en')],
      startLocale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      path: '.omc/i18n',
      saveLocale: false,
      assetLoader: const _InvitationFragmentAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        ),
      ),
    ),
  );
}

Future<_Harness> _pumpInviteScreen(
  WidgetTester tester, {
  required Object? Function(String function, Map<String, dynamic> params)
  responder,
  String token = 'tok-123',
}) async {
  final rpc = RecordingInvitationRpc(responder);
  final rebuildTick = ValueNotifier<int>(0);
  final container = _container(rpc);
  final router = _router(token, rebuildTick);
  addTearDown(rebuildTick.dispose);
  addTearDown(container.dispose);

  await tester.pumpWidget(_app(container, router));
  await tester.pump(); // flush the initState microtask that starts RPC A
  await tester.pumpAndSettle();
  // Translations resolve asynchronously and `'key'.tr()` does not depend on the
  // Localizations widget, so rebuild once to render the resolved strings.
  await tester.pumpWidget(_app(container, router));
  await tester.pumpAndSettle();

  return _Harness(container: container, rpc: rpc, rebuildTick: rebuildTick);
}

void main() {
  group('InviteAcceptanceScreen branch selection', () {
    testWidgets('renders the matching flow for every user_type', (
      tester,
    ) async {
      const branches = {
        'logged_in': 'Accept Invitation',
        'cross_team': 'Sign in with a different account',
        'logged_out': 'Sign in to accept',
        'unregistered': 'Create an account to accept',
      };

      for (final branch in branches.entries) {
        final harness = await _pumpInviteScreen(
          tester,
          responder: (_, _) => detectionPayload(userType: branch.key),
        );

        expect(
          find.text('Acme Team'),
          findsOneWidget,
          reason: 'invitation card for ${branch.key}',
        );
        expect(
          find.text('Invitation for invitee@example.com'),
          findsOneWidget,
          reason: 'invitation email for ${branch.key}',
        );
        expect(
          find.text(branch.value),
          findsOneWidget,
          reason: 'action for ${branch.key}',
        );
        expect(harness.detectCalls, 1, reason: 'detection for ${branch.key}');

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('shows a loading state until RPC A answers', (tester) async {
      final pendingDetection = Completer<Object?>();
      final rpc = RecordingInvitationRpc((_, _) => pendingDetection.future);
      final rebuildTick = ValueNotifier<int>(0);
      final container = _container(rpc);
      addTearDown(rebuildTick.dispose);
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, _router('tok-123', rebuildTick)));
      // Not pumpAndSettle: the spinner would never let the tree settle while
      // RPC A is still in flight.
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('Acme Team'), findsNothing);

      pendingDetection.complete(detectionPayload(userType: 'logged_in'));
      await tester.pumpAndSettle();

      expect(find.byType(LoadingWidget), findsNothing);
      expect(find.text('Acme Team'), findsOneWidget);
    });

    testWidgets('shows the invitation details and custom message', (
      tester,
    ) async {
      await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(
          userType: 'logged_in',
          role: 'admin',
          customMessage: 'Welcome aboard',
        ),
      );

      expect(find.text('Acme Team'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Invited by owner-1'), findsOneWidget);
      expect(find.text('Welcome aboard'), findsOneWidget);
    });
  });

  group('InviteAcceptanceScreen detection', () {
    testWidgets('calls RPC A once per mount, never on rebuild', (tester) async {
      final harness = await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(userType: 'logged_in'),
      );

      expect(harness.detectCalls, 1);

      harness.rebuildTick.value++;
      await tester.pump();
      harness.rebuildTick.value++;
      await tester.pump();

      expect(harness.detectCalls, 1);
    });

    testWidgets('re-detects and continues once the invitee signs in', (
      tester,
    ) async {
      var userType = 'logged_out';
      final harness = await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(userType: userType),
      );

      expect(find.text('Sign in to accept'), findsOneWidget);
      expect(harness.detectCalls, 1);

      userType = 'logged_in';
      harness.signIn();
      await tester.pumpAndSettle();

      expect(harness.detectCalls, 2);
      expect(find.text('Accept Invitation'), findsOneWidget);
      expect(find.text('Sign in to accept'), findsNothing);
    });

    testWidgets('renders the backend message and retries on failure', (
      tester,
    ) async {
      var fail = true;
      final harness = await _pumpInviteScreen(
        tester,
        responder: (_, _) => fail
            ? detectionErrorPayload()
            : detectionPayload(userType: 'logged_in'),
      );

      expect(find.text('Invitation not found'), findsOneWidget);
      expect(find.text('Invitation not found or has expired'), findsOneWidget);
      expect(harness.detectCalls, 1);

      fail = false;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(harness.detectCalls, 2);
      expect(find.text('Accept Invitation'), findsOneWidget);
    });

    testWidgets('offers a retry for an unknown account state', (tester) async {
      final harness = await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(userType: 'something_new'),
      );

      expect(find.text('This invitation cannot be processed'), findsOneWidget);
      expect(find.text('Accept Invitation'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(harness.detectCalls, 2);
    });
  });

  group('InviteAcceptanceScreen signed-out flows', () {
    testWidgets('sends a logged out invitee to the login screen', (
      tester,
    ) async {
      await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(userType: 'logged_out'),
      );

      await tester.tap(find.text('Sign in to accept'));
      await tester.pumpAndSettle();

      expect(find.text('login-stub'), findsOneWidget);
    });

    testWidgets('sends an unregistered invitee to the register screen', (
      tester,
    ) async {
      await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(userType: 'unregistered'),
      );

      await tester.tap(find.text('Create an account to accept'));
      await tester.pumpAndSettle();

      expect(find.text('register-stub'), findsOneWidget);
    });

    testWidgets('never offers Accept to a cross-team account', (tester) async {
      await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(userType: 'cross_team'),
      );

      expect(find.text('Invitation for invitee@example.com'), findsOneWidget);
      expect(
        find.text(
          'This invitation was sent to invitee@example.com. '
          'Sign in with that account to accept it.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('You are signed in as other.user@example.com'),
        findsOneWidget,
      );
      expect(find.text('Accept Invitation'), findsNothing);

      await tester.tap(find.text('Sign in with a different account'));
      await tester.pumpAndSettle();

      expect(find.text('login-stub'), findsOneWidget);
    });
  });

  group('InviteAcceptanceScreen acceptance', () {
    testWidgets('accepts, refreshes teams and lands on /teams', (tester) async {
      final harness = await _pumpInviteScreen(
        tester,
        responder: (function, _) => switch (function) {
          InvitationAcceptanceService.detectFunction => detectionPayload(
            userType: 'logged_in',
          ),
          InvitationAcceptanceService.validateFunction => validationPayload(
            canAccept: true,
          ),
          InvitationAcceptanceService.processFunction => acceptancePayload(),
          _ => null,
        },
      );

      await tester.tap(find.text('Accept Invitation'));
      await tester.pumpAndSettle();

      expect(harness.validateCalls, 1);
      expect(harness.acceptCalls, 1);
      expect(harness.teams.refreshCount, 1);
      expect(find.text('teams-stub'), findsOneWidget);

      final acceptParams = harness.rpc.paramsFor(
        InvitationAcceptanceService.processFunction,
      );
      expect(acceptParams['p_user_id'], 'user-1');
      expect(acceptParams['p_invitation_token'], 'tok-123');
    });

    testWidgets('ignores an unknown redirect_url and falls back to /teams', (
      tester,
    ) async {
      await _pumpInviteScreen(
        tester,
        responder: (function, _) => switch (function) {
          InvitationAcceptanceService.detectFunction => detectionPayload(
            userType: 'logged_in',
          ),
          InvitationAcceptanceService.validateFunction => validationPayload(
            canAccept: true,
          ),
          InvitationAcceptanceService.processFunction => acceptancePayload(
            redirectUrl: '/teams/acme-slug',
          ),
          _ => null,
        },
      );

      await tester.tap(find.text('Accept Invitation'));
      await tester.pumpAndSettle();

      expect(find.text('teams-stub'), findsOneWidget);
    });

    testWidgets('names the reason when RPC B refuses the acceptance', (
      tester,
    ) async {
      final scenarios = {
        'already member': (
          validation: validationPayload(canAccept: false, alreadyMember: true),
          message: 'You are already a member of this team.',
        ),
        'email mismatch': (
          validation: validationPayload(canAccept: false, emailMatch: false),
          message:
              'This invitation was sent to a different email address. '
              'Sign in with the invited account to accept it.',
        ),
        'invalid invitation': (
          validation: validationPayload(
            canAccept: false,
            invitationValid: false,
          ),
          message:
              'This invitation is no longer valid. '
              'It may have expired or been cancelled.',
        ),
      };

      for (final scenario in scenarios.entries) {
        final harness = await _pumpInviteScreen(
          tester,
          responder: (function, _) => switch (function) {
            InvitationAcceptanceService.detectFunction => detectionPayload(
              userType: 'logged_in',
            ),
            InvitationAcceptanceService.validateFunction =>
              scenario.value.validation,
            _ => null,
          },
        );

        await tester.tap(find.text('Accept Invitation'));
        await tester.pumpAndSettle();

        expect(
          find.text(scenario.value.message),
          findsOneWidget,
          reason: 'reason for ${scenario.key}',
        );
        expect(
          harness.acceptCalls,
          0,
          reason: 'must not accept when ${scenario.key}',
        );
        expect(find.text('teams-stub'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('shows the RPC C error message', (tester) async {
      await _pumpInviteScreen(
        tester,
        responder: (function, _) => switch (function) {
          InvitationAcceptanceService.detectFunction => detectionPayload(
            userType: 'logged_in',
          ),
          InvitationAcceptanceService.validateFunction => validationPayload(
            canAccept: true,
          ),
          InvitationAcceptanceService.processFunction => acceptanceErrorPayload(
            error: 'User email does not match invitation',
            errorCode: 'EMAIL_MISMATCH',
          ),
          _ => null,
        },
      );

      await tester.tap(find.text('Accept Invitation'));
      await tester.pumpAndSettle();

      expect(find.text('User email does not match invitation'), findsOneWidget);
      expect(find.text('teams-stub'), findsNothing);
    });

    testWidgets('reports an existing membership instead of an Accept button', (
      tester,
    ) async {
      await _pumpInviteScreen(
        tester,
        responder: (_, _) => detectionPayload(
          userType: 'logged_in',
          existingMembership: {
            'role': 'member',
            'joined_at': '2026-01-01T00:00:00.000Z',
          },
        ),
      );

      expect(find.text('Accept Invitation'), findsNothing);
      expect(
        find.text('You are already a member of this team.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Go to Teams'));
      await tester.pumpAndSettle();

      expect(find.text('teams-stub'), findsOneWidget);
    });
  });
}
