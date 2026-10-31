import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'invitations.title'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'InstrumentSerif',
            fontSize: 24,
            height: 1.05,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InvitationCard(
                  invitation: invitation,
                  notice: notice,
                  errorMessage: errorMessage,
                ),
                const SizedBox(height: 16),
                ...actions,
              ],
            ),
          ),
        ),
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
    final colors = theme.colorScheme;
    final teamName = invitation.teamName;
    final role = _localizedRole(invitation.role);
    final expiresAt = invitation.expiresAt;
    final invitedBy = invitation.invitedBy;
    final customMessage = invitation.customMessage;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonogramTile(initials: _initialsFor(teamName)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEAM INVITATION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teamName ?? 'invitations.unknownTeam'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _RolePill(label: role),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'invitations.forEmail'.tr(
                    namedArgs: {'email': invitation.email},
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (invitedBy != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'invitations.invitedBy'.tr(namedArgs: {'name': invitedBy}),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'invitations.expiresAt'.tr(
                      namedArgs: {'date': _formatDate(expiresAt)},
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                    ),
                  ),
                ],
                if (customMessage != null && customMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'invitations.message'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customMessage,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (notice != null) ...[const SizedBox(height: 16), notice!],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onErrorContainer,
                      ),
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
    final colors = theme.colorScheme;
    final detail = this.detail;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
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
                      color: colors.onSurfaceVariant,
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

class _MonogramTile extends StatelessWidget {
  const _MonogramTile({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.onPrimaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

String _formatDate(DateTime date) {
  return DateFormat('dd MMM').format(date).toUpperCase();
}

String _initialsFor(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return '?';
  final words = trimmed
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words[1][0]}'.toUpperCase();
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
