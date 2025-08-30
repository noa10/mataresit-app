import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/team_model.dart';
import '../providers/teams_provider.dart';
import '../../auth/providers/auth_provider.dart';

class TeamWorkspaceSelector extends ConsumerStatefulWidget {
  final bool showCreateButton;
  final VoidCallback? onCreateTeam;

  const TeamWorkspaceSelector({
    super.key,
    this.showCreateButton = true,
    this.onCreateTeam,
  });

  @override
  ConsumerState<TeamWorkspaceSelector> createState() => _TeamWorkspaceSelectorState();
}

class _TeamWorkspaceSelectorState extends ConsumerState<TeamWorkspaceSelector> {
  final bool _isDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    final currentTeamState = ref.watch(currentTeamProvider);

    return GestureDetector(
      onTap: () => _showWorkspaceSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentTeamState.currentTeam != null 
                ? Icons.business 
                : Icons.person,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentTeamState.currentTeam?.name ?? 'Personal Workspace',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentTeamState.currentRole != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(currentTeamState.currentRole!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getRoleDisplayName(currentTeamState.currentRole!),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getRoleColor(currentTeamState.currentRole!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Icon(
              _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),

    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.purple;
      case TeamRole.admin:
        return Colors.blue;
      case TeamRole.member:
        return Colors.green;
      case TeamRole.viewer:
        return Colors.orange;
    }
  }

  String _getRoleDisplayName(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return 'Owner';
      case TeamRole.admin:
        return 'Admin';
      case TeamRole.member:
        return 'Member';
      case TeamRole.viewer:
        return 'Viewer';
    }
  }

  void _showWorkspaceSelector(BuildContext context) {
    final teamsState = ref.read(teamsProvider);
    final currentTeamState = ref.read(currentTeamProvider);
    final currentUser = ref.read(currentUserProvider);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Switch Workspace',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Personal workspace
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Personal Workspace'),
                trailing: currentTeamState.currentTeam == null
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(currentTeamProvider.notifier).switchTeam(null);
                },
              ),

              // Teams section
              if (teamsState.teams.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Teams',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                ...teamsState.teams.map((team) {
                  final userRole = team.getUserRole(currentUser?.id ?? '');
                  final isCurrentTeam = currentTeamState.currentTeam?.id == team.id;

                  return ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(team.name),
                    subtitle: Text('${team.memberCount} member${team.memberCount != 1 ? 's' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(userRole).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getRoleDisplayName(userRole),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getRoleColor(userRole),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isCurrentTeam)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, color: Colors.green),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(currentTeamProvider.notifier).switchTeam(team.id);
                    },
                  );
                }),
              ],

              // Create team option
              if (widget.showCreateButton) ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.add, color: Theme.of(context).primaryColor),
                  title: Text(
                    'Create Team',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onCreateTeam?.call();
                  },
                ),
              ],

              const SizedBox(height: AppConstants.defaultPadding),
            ],
          ),
        );
      },
    );
  }
}
