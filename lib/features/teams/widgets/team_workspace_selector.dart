import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/team_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/teams_provider.dart';

class TeamWorkspaceSelector extends ConsumerStatefulWidget {
  final bool showCreateButton;
  final VoidCallback? onCreateTeam;

  const TeamWorkspaceSelector({
    super.key,
    this.showCreateButton = true,
    this.onCreateTeam,
  });

  @override
  ConsumerState<TeamWorkspaceSelector> createState() =>
      _TeamWorkspaceSelectorState();
}

class _TeamWorkspaceSelectorState extends ConsumerState<TeamWorkspaceSelector> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentTeamState = ref.watch(currentTeamProvider);
    final currentTeam = currentTeamState.currentTeam;
    final currentRole = currentTeamState.currentRole;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _showWorkspaceSelector(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _WorkspaceMonogram(
                icon: currentTeam == null ? Icons.person_outline : null,
                initials: currentTeam == null
                    ? null
                    : _initialsFor(currentTeam.name),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTeam?.name ?? 'Personal Workspace',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentRole != null) ...[
                      const SizedBox(height: 3),
                      _RolePill(role: currentRole),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.unfold_more, size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkspaceSelector(BuildContext context) {
    final teamsState = ref.read(teamsProvider);
    final currentTeamState = ref.read(currentTeamProvider);
    final currentUser = ref.read(currentUserProvider);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'WORKSPACES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Switch Workspace',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: 'InstrumentSerif',
                    fontSize: 26,
                    height: 1.05,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Personal workspace
                _SheetRow(
                  leading: const _WorkspaceMonogram(icon: Icons.person_outline),
                  title: 'Personal Workspace',
                  trailing: currentTeamState.currentTeam == null
                      ? Icon(Icons.check, size: 18, color: colors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(currentTeamProvider.notifier).switchTeam(null);
                  },
                ),

                // Teams section
                if (teamsState.teams.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Teams',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...teamsState.teams.map((team) {
                    final userRole = team.getUserRole(currentUser?.id ?? '');
                    final isCurrentTeam =
                        currentTeamState.currentTeam?.id == team.id;

                    return _SheetRow(
                      leading: _WorkspaceMonogram(
                        initials: _initialsFor(team.name),
                      ),
                      title: team.name,
                      subtitle:
                          '${team.memberCount} member${team.memberCount != 1 ? 's' : ''}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RolePill(role: userRole),
                          if (isCurrentTeam)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.check,
                                size: 18,
                                color: colors.primary,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ref
                            .read(currentTeamProvider.notifier)
                            .switchTeam(team.id);
                      },
                    );
                  }),
                ],

                // Create team option
                if (widget.showCreateButton) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCreateTeam?.call();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Team'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'IBMPlexMono',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceMonogram extends StatelessWidget {
  const _WorkspaceMonogram({this.icon, this.initials});

  final IconData? icon;
  final String? initials;

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
      child: icon != null
          ? Icon(icon, size: 17, color: colors.onSurfaceVariant)
          : Text(
              initials ?? '',
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
    final background = isPrivileged
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final foreground = isPrivileged
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

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
            role.displayName,
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
