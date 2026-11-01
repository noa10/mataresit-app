import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/team_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/team_invitation_provider.dart';
import '../providers/teams_provider.dart';
import '../widgets/team_workspace_selector.dart';
import 'team_members_screen.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsState = ref.watch(teamsProvider);
    final currentTeamState = ref.watch(currentTeamProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    onRefresh: () => ref.read(teamsProvider.notifier).refresh(),
                  ),
                  const SizedBox(height: 16),
                  TeamWorkspaceSelector(
                    onCreateTeam: () => _showCreateTeamDialog(context, ref),
                  ),
                  const SizedBox(height: 16),
                  _buildBody(context, ref, teamsState, currentTeamState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TeamsState teamsState,
    CurrentTeamState currentTeamState,
  ) {
    final team = currentTeamState.currentTeam;
    if (team != null) {
      return _buildTeamWorkspaceView(
        context,
        ref,
        team,
        currentTeamState.currentRole,
        teamsState,
      );
    }

    if (teamsState.teams.isEmpty &&
        !teamsState.isLoading &&
        teamsState.error == null) {
      return _buildEmptyState(context, ref);
    }

    return _buildTeamsList(context, ref, teamsState);
  }

  Widget _buildTeamWorkspaceView(
    BuildContext context,
    WidgetRef ref,
    TeamModel team,
    TeamRole? role,
    TeamsState teamsState,
  ) {
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    final canManage = role == TeamRole.owner || role == TeamRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkspacePanel(context, team, role),
        const SizedBox(height: 16),
        _buildQuickActionsPanel(context, ref, team, canManage: canManage),
        const SizedBox(height: 16),
        _buildAllTeamsPanel(context, ref, teamsState, currentUserId),
      ],
    );
  }

  Widget _buildWorkspacePanel(
    BuildContext context,
    TeamModel team,
    TeamRole? role,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _Panel(
      title: 'Workspace',
      meta: _StatusPill(status: team.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonogramTile(initials: _initialsFor(team.name)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (team.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          team.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (role != null) ...[
                  const SizedBox(width: 8),
                  _RolePill(role: role),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Total Members',
                    value: '${team.memberCount}',
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colors.outlineVariant,
                ),
                Expanded(
                  child: _Metric(
                    label: 'Your Role',
                    value: role?.displayName ?? '—',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsPanel(
    BuildContext context,
    WidgetRef ref,
    TeamModel team, {
    required bool canManage,
  }) {
    return _Panel(
      title: 'Quick Actions',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TeamMembersScreen(team: team),
                  ),
                );
              },
              icon: const Icon(Icons.people_outline, size: 18),
              label: const Text('Members'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TeamMembersScreen(
                      team: team,
                      initialTabIndex: 2, // Settings tab
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Settings'),
            ),
            if (canManage)
              FilledButton.icon(
                onPressed: () {
                  _showEnhancedInviteMemberDialog(context, ref, team);
                },
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Invite Members'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTeamsPanel(
    BuildContext context,
    WidgetRef ref,
    TeamsState state,
    String currentUserId,
  ) {
    final colors = Theme.of(context).colorScheme;
    final visibleTeams = state.teams.take(3).toList();

    return _Panel(
      title: 'All Teams',
      action: TextButton(
        onPressed: () =>
            ref.read(currentTeamProvider.notifier).switchTeam(null),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('View All'),
      ),
      child: visibleTeams.isEmpty
          ? const _PanelMessage('No teams to switch to yet.')
          : Column(
              children: [
                for (var index = 0; index < visibleTeams.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.outlineVariant,
                    ),
                  _CompactTeamRow(
                    team: visibleTeams[index],
                    role: visibleTeams[index].getUserRole(currentUserId),
                    onTap: () => ref
                        .read(currentTeamProvider.notifier)
                        .switchTeam(visibleTeams[index].id),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 32, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No teams yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create or join a team to collaborate on receipts',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showCreateTeamDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Team'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsList(
    BuildContext context,
    WidgetRef ref,
    TeamsState state,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 18, color: colors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _Panel(
          title: 'Your Teams',
          meta: Text(
            '${state.teams.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
            ),
          ),
          child: state.teams.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < state.teams.length;
                      index++
                    ) ...[
                      if (index > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colors.outlineVariant,
                        ),
                      _TeamRow(
                        team: state.teams[index],
                        role: state.teams[index].getUserRole(currentUserId),
                        onTap: () => ref
                            .read(currentTeamProvider.notifier)
                            .switchTeam(state.teams[index].id),
                      ),
                    ],
                    if (state.isLoading) ...[
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.outlineVariant,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                hintText: 'Enter team name',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter team description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                try {
                  final teamId = await ref
                      .read(teamsProvider.notifier)
                      .createTeam(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );

                  // Switch to the newly created team
                  if (teamId != null) {
                    await ref
                        .read(currentTeamProvider.notifier)
                        .switchTeam(teamId);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Team created successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create team: ${e.toString()}'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEnhancedInviteMemberDialog(
    BuildContext context,
    WidgetRef ref,
    TeamModel team,
  ) {
    final emailController = TextEditingController();
    final customMessageController = TextEditingController();
    TeamRole selectedRole = TeamRole.member;
    int expiresInDays = 7;
    bool sendEmailNotification = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Team Invitation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite a new member to join ${team.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Email Address
                const Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Enter email address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Role
                const Text(
                  'Role',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<TeamRole>(
                  initialValue: selectedRole,
                  items: TeamRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (role) {
                          if (role != null) {
                            setState(() => selectedRole = role);
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Custom Message
                const Text(
                  'Custom Message (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: customMessageController,
                  decoration: const InputDecoration(
                    hintText: 'Add a personal message to the invitation...',
                  ),
                  maxLines: 3,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),

                // Expires In
                const Text(
                  'Expires In (Days)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: expiresInDays,
                  items: [1, 3, 7, 14, 30].map((days) {
                    return DropdownMenuItem(
                      value: days,
                      child: Text('$days Days'),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (days) {
                          if (days != null) {
                            setState(() => expiresInDays = days);
                          }
                        },
                ),
                const SizedBox(height: 12),

                // Send Email Notification
                SwitchListTile(
                  title: const Text('Send email notification'),
                  value: sendEmailNotification,
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() => sendEmailNotification = value);
                        },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: isLoading || emailController.text.trim().isEmpty
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      try {
                        await ref
                            .read(teamInvitationProvider(team.id).notifier)
                            .sendInvitation(
                              teamId: team.id,
                              email: emailController.text.trim(),
                              role: selectedRole,
                              customMessage:
                                  customMessageController.text.trim().isEmpty
                                  ? null
                                  : customMessageController.text.trim(),
                              expiresInDays: expiresInDays,
                              sendEmail: sendEmailNotification,
                            );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invitation sent successfully!'),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to send invitation: $error',
                              ),
                            ),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(isLoading ? 'Sending...' : 'Send Invitation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKSPACE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Teams',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'InstrumentSerif',
                  fontSize: 32,
                  height: 1.05,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Switch workspaces, manage members and invite your team.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh teams',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 20),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.meta,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? meta;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
            padding: EdgeInsets.fromLTRB(16, 10, action == null ? 16 : 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (meta != null) ...[const SizedBox(width: 8), meta!],
                if (action != null) action!,
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          child,
        ],
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTeamRow extends StatelessWidget {
  const _CompactTeamRow({
    required this.team,
    required this.role,
    required this.onTap,
  });

  final TeamModel team;
  final TeamRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              _MonogramTile(initials: _initialsFor(team.name)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${team.memberCount} members',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RolePill(role: role),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.team, required this.role, required this.onTap});

  final TeamModel team;
  final TeamRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MonogramTile(initials: _initialsFor(team.name)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (team.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        team.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${team.memberCount} members',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'IBMPlexMono',
                            fontSize: 11,
                          ),
                        ),
                        _RolePill(role: role),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: team.status),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
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
  const _RolePill({required this.role});

  final TeamRole role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPrivileged = role == TeamRole.owner || role == TeamRole.admin;

    return _Pill(
      label: role.displayName,
      background: isPrivileged
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      foreground: isPrivileged
          ? colors.onPrimaryContainer
          : colors.onSurfaceVariant,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final TeamStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final background = switch (status) {
      TeamStatus.active => colors.primaryContainer,
      TeamStatus.inactive => colors.tertiaryContainer,
      TeamStatus.suspended => colors.errorContainer,
    };
    final foreground = switch (status) {
      TeamStatus.active => colors.onPrimaryContainer,
      TeamStatus.inactive => colors.onTertiaryContainer,
      TeamStatus.suspended => colors.onErrorContainer,
    };

    return _Pill(
      label: status.displayName,
      background: background,
      foreground: foreground,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
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

String _initialsFor(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words[1][0]}'.toUpperCase();
}
