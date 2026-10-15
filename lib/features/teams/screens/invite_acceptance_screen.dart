import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/invitation_acceptance_provider.dart';
import '../services/invitation_acceptance_service.dart';

/// Screen for the `/invite/:token` route: lets an invitee accept a pending
/// team invitation.
///
/// Detection runs once per mount because `detect_user_invitation_state` writes
/// an audit row on every call.
class InviteAcceptanceScreen extends ConsumerStatefulWidget {
  const InviteAcceptanceScreen({super.key, required this.token});

  /// Invitation token taken from the route path.
  final String token;

  @override
  ConsumerState<InviteAcceptanceScreen> createState() =>
      _InviteAcceptanceScreenState();
}

class _InviteAcceptanceScreenState
    extends ConsumerState<InviteAcceptanceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_detect);
  }

  void _detect() {
    if (!mounted) return;
    ref.read(invitationAcceptanceProvider(widget.token).notifier).detect();
  }

  @override
  Widget build(BuildContext context) {
    // Picks the flow back up after the invitee signs in or creates an account
    // on another screen, without requiring a manual refresh.
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null && next.id != previous?.id) {
        _detect();
      }
    });

    final state = ref.watch(invitationAcceptanceProvider(widget.token));

    return Scaffold(
      appBar: AppBar(title: Text('invitations.title'.tr())),
      body: SafeArea(child: _buildBody(state)),
    );
  }

  Widget _buildBody(InvitationAcceptanceState state) {
    final detection = state.detection;

    if (detection == null) {
      return LoadingWidget(message: 'invitations.loading'.tr());
    }

    if (!detection.success) {
      return AppErrorWidget(
        title: _detectionErrorTitle(detection),
        error: _detectionErrorMessage(detection),
        onRetry: _detect,
      );
    }

    final invitation = detection.invitation;
    final userState = detection.userState;
    if (invitation == null || userState == null) {
      return AppErrorWidget(
        title: 'invitations.errors.title'.tr(),
        error: 'invitations.errors.generic'.tr(),
        onRetry: _detect,
      );
    }

    switch (userState.userType) {
      case InvitationUserType.loggedIn:
        return _buildLoggedIn(state, invitation, userState);
      case InvitationUserType.crossTeam:
        return _buildCrossTeam(invitation, userState);
      case InvitationUserType.loggedOut:
        return _buildLoggedOut(invitation);
      case InvitationUserType.unregistered:
        return _buildUnregistered(invitation);
      case InvitationUserType.unknown:
        return EmptyStateWidget(
          icon: Icons.help_outline,
          title: 'invitations.unknownState.title'.tr(),
          message: 'invitations.unknownState.message'.tr(),
          actionLabel: 'invitations.retry'.tr(),
          onAction: _detect,
        );
    }
  }

  Widget _buildLoggedIn(
    InvitationAcceptanceState state,
    InvitationDetails invitation,
    InvitationUserState userState,
  ) {
    // Already a member: nothing to accept, so no Accept button is offered.
    if (userState.existingTeamMembership != null) {
      return _buildFlow(
        invitation: invitation,
        notice: const _Notice(
          icon: Icons.check_circle_outline,
          messageKey: 'invitations.alreadyMember',
        ),
        actions: [
          _PrimaryAction(
            labelKey: 'invitations.goToTeams',
            onPressed: () => context.go(_teamsRoute),
          ),
        ],
      );
    }

    return _buildFlow(
      invitation: invitation,
      errorMessage: _acceptErrorMessage(state),
      actions: [
        SizedBox(
          width: double.infinity,
          child: LoadingButton(
            onPressed: _accept,
            text: 'invitations.accept'.tr(),
            isLoading: state.isAccepting,
          ),
        ),
      ],
    );
  }

  Widget _buildCrossTeam(
    InvitationDetails invitation,
    InvitationUserState userState,
  ) {
    final currentEmail = userState.currentUserEmail;

    return _buildFlow(
      invitation: invitation,
      notice: _Notice(
        icon: Icons.switch_account_outlined,
        messageKey: 'invitations.crossTeam.message',
        messageArgs: {'email': invitation.email},
        detail: currentEmail == null
            ? null
            : 'invitations.signedInAs'.tr(namedArgs: {'email': currentEmail}),
      ),
      actions: [
        _PrimaryAction(
          labelKey: 'invitations.signInWithDifferentAccount',
          onPressed: _signInWithDifferentAccount,
        ),
      ],
    );
  }

  Widget _buildLoggedOut(InvitationDetails invitation) {
    return _buildFlow(
      invitation: invitation,
      notice: const _Notice(
        icon: Icons.login_outlined,
        messageKey: 'invitations.loggedOut.message',
      ),
      actions: [
        // Pushed (not replaced) so this screen stays mounted and re-detects
        // once the invitee is authenticated.
        _PrimaryAction(
          labelKey: 'invitations.signInToAccept',
          onPressed: () => context.push(_loginRoute),
        ),
      ],
    );
  }

  Widget _buildUnregistered(InvitationDetails invitation) {
    return _buildFlow(
      invitation: invitation,
      notice: _Notice(
        icon: Icons.person_add_alt_outlined,
        messageKey: 'invitations.unregistered.message',
        messageArgs: {'email': invitation.email},
      ),
      actions: [
        _PrimaryAction(
          labelKey: 'invitations.createAccountToAccept',
          onPressed: () => context.push(_registerRoute),
        ),
      ],
    );
  }

  Widget _buildFlow({
    required InvitationDetails invitation,
    required List<Widget> actions,
    Widget? notice,
    String? errorMessage,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        _InvitationCard(
          invitation: invitation,
          notice: notice,
          errorMessage: errorMessage,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...actions,
      ],
    );
  }

  Future<void> _accept() async {
    final accepted = await ref
        .read(invitationAcceptanceProvider(widget.token).notifier)
        .accept();
    if (!mounted || accepted == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'invitations.accepted'.tr(
            namedArgs: {
              'teamName': accepted.teamName ?? 'invitations.unknownTeam'.tr(),
            },
          ),
        ),
      ),
    );

    context.go(_resolveRedirectTarget(accepted.redirectUrl));
  }

  Future<void> _signInWithDifferentAccount() async {
    try {
      await SupabaseService.signOut();
    } catch (error) {
      // The invitee asked to switch accounts; showing the login screen is still
      // the right outcome even if the local session could not be cleared.
      AppLogger.warning('Failed to sign out before switching accounts', error);
    }

    if (!mounted) return;
    context.go(_loginRoute);
  }

  String? _acceptErrorMessage(InvitationAcceptanceState state) {
    final blockReasonKey = state.blockReasonKey;
    if (blockReasonKey != null) return blockReasonKey.tr();
    return state.acceptanceError;
  }

  String _detectionErrorMessage(InvitationDetectionResult detection) {
    final error = detection.error;
    if (error != null && error.isNotEmpty) return error;

    switch (detection.errorCode) {
      case InvitationErrorCodes.invitationExpired:
        return 'invitations.errors.expired'.tr();
      case InvitationErrorCodes.invitationNotFound:
        return 'invitations.errors.notFound'.tr();
      default:
        return 'invitations.errors.generic'.tr();
    }
  }

  String _detectionErrorTitle(InvitationDetectionResult detection) {
    switch (detection.errorCode) {
      case InvitationErrorCodes.invitationExpired:
        return 'invitations.errors.expiredTitle'.tr();
      case InvitationErrorCodes.invitationNotFound:
        return 'invitations.errors.notFoundTitle'.tr();
      default:
        return 'invitations.errors.title'.tr();
    }
  }
}

/// Invitation summary shared by every branch of the flow.
class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    this.notice,
    this.errorMessage,
  });

  final InvitationDetails invitation;
  final Widget? notice;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamName = invitation.teamName;
    final role = _localizedRole(invitation.role);
    final expiresAt = invitation.expiresAt;
    final invitedBy = invitation.invitedBy;
    final customMessage = invitation.customMessage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: AppConstants.smallPadding),
                if (teamName != null)
                  Expanded(
                    child: Text(
                      teamName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'invitations.forEmail'.tr(namedArgs: {'email': invitation.email}),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (role.isNotEmpty) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (invitedBy != null) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'invitations.invitedBy'.tr(namedArgs: {'name': invitedBy}),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'invitations.expiresAt'.tr(
                  namedArgs: {'date': AppDateUtils.formatDate(expiresAt)},
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (customMessage != null && customMessage.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'invitations.message'.tr(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(customMessage, style: theme.textTheme.bodyMedium),
            ],
            if (notice != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              notice!,
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Text(
                  errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Short contextual message shown inside [_InvitationCard].
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.messageKey,
    this.messageArgs,
    this.detail,
  });

  final IconData icon;
  final String messageKey;
  final Map<String, String>? messageArgs;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = this.detail;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.smallPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageKey.tr(namedArgs: messageArgs),
                  style: theme.textTheme.bodyMedium,
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full width primary action used by every branch.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.labelKey, required this.onPressed});

  final String labelKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: Text(labelKey.tr())),
    );
  }
}

/// Roles the backend can put on an invitation.
String _localizedRole(String? role) {
  switch (role) {
    case 'owner':
      return 'invitations.roles.owner'.tr();
    case 'admin':
      return 'invitations.roles.admin'.tr();
    case 'member':
      return 'invitations.roles.member'.tr();
    case 'viewer':
      return 'invitations.roles.viewer'.tr();
    default:
      return role ?? '';
  }
}

/// Route paths this screen hands off to. They mirror `AppRoutes` but are kept
/// local so the feature does not depend on the whole app router.
const String _teamsRoute = '/teams';
const String _loginRoute = '/login';
const String _registerRoute = '/register';

/// `redirect_url` values the app actually routes; anything else falls back to
/// the teams screen.
const Set<String> _knownRedirectTargets = {'/teams', '/dashboard', '/receipts'};

String _resolveRedirectTarget(String? redirectUrl) {
  if (redirectUrl != null && _knownRedirectTargets.contains(redirectUrl)) {
    return redirectUrl;
  }
  return _teamsRoute;
}
