import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/team_model.dart';
import '../providers/teams_provider.dart';
import '../providers/team_invitation_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/team_workspace_selector.dart';
import 'team_members_screen.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsState = ref.watch(teamsProvider);
    final currentTeamState = ref.watch(currentTeamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Teams'),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: TeamWorkspaceSelector(
                onCreateTeam: () => _showCreateTeamDialog(context, ref),
              ),
            ),
          ],
        ),
        titleSpacing: AppConstants.defaultPadding,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(teamsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teamsProvider.notifier).refresh(),
        child: _buildBody(context, ref, teamsState, currentTeamState),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TeamsState teamsState,
    CurrentTeamState currentTeamState,
  ) {
    if (currentTeamState.currentTeam != null) {
      // Show current team workspace view
      return _buildTeamWorkspaceView(
        context,
        ref,
        currentTeamState.currentTeam!,
        currentTeamState.currentRole,
      );
    } else {
      // Show teams list or empty state
      return teamsState.teams.isEmpty && !teamsState.isLoading
          ? _buildEmptyState()
          : _buildTeamsList(context, ref, teamsState);
    }
  }

  Widget _buildTeamWorkspaceView(
    BuildContext context,
    WidgetRef ref,
    TeamModel team,
    TeamRole? role,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team header
          _buildTeamHeader(context, team, role),
          const SizedBox(height: AppConstants.defaultPadding * 2),

          // Team stats
          _buildTeamStats(context, ref, team),
          const SizedBox(height: AppConstants.defaultPadding * 2),

          // Quick actions
          _buildQuickActions(context, ref, team, role),
          const SizedBox(height: AppConstants.defaultPadding * 2),

          // All teams section
          _buildAllTeamsSection(context, ref, ref.watch(teamsProvider)),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(
    BuildContext context,
    TeamModel team,
    TeamRole? role,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                team.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          team.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (role != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRoleDisplayName(role),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getRoleColor(role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (team.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        team.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
          SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No teams yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            'Create or join a team to collaborate on receipts',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStats(BuildContext context, WidgetRef ref, TeamModel team) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Members',
            '${team.memberCount}',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: _buildStatCard(
            context,
            'Your Role',
            _getRoleDisplayName(
              team.getUserRole(ref.read(currentUserProvider)?.id ?? ''),
            ),
            Icons.admin_panel_settings,
            _getRoleColor(
              team.getUserRole(ref.read(currentUserProvider)?.id ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    TeamModel team,
    TeamRole? role,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TeamMembersScreen(team: team),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Members'),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
              ],
            ),
            if (role == TeamRole.owner || role == TeamRole.admin) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showEnhancedInviteMemberDialog(context, ref, team);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite Members'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllTeamsSection(
    BuildContext context,
    WidgetRef ref,
    TeamsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Teams',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () =>
                  ref.read(currentTeamProvider.notifier).switchTeam(null),
              icon: const Icon(Icons.view_list),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...state.teams
            .take(3)
            .map(
              (team) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppConstants.defaultPadding,
                ),
                child: _buildCompactTeamCard(context, ref, team),
              ),
            ),
      ],
    );
  }

  Widget _buildCompactTeamCard(
    BuildContext context,
    WidgetRef ref,
    TeamModel team,
  ) {
    final currentUser = ref.read(currentUserProvider);
    final userRole = team.getUserRole(currentUser?.id ?? '');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            team.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(team.name),
        subtitle: Text('${team.memberCount} members'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => ref.read(currentTeamProvider.notifier).switchTeam(team.id),
      ),
    );
  }

  Widget _buildTeamsList(
    BuildContext context,
    WidgetRef ref,
    TeamsState state,
  ) {
    return Column(
      children: [
        // Error display
        if (state.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            color: Colors.red.withValues(alpha: 0.1),
            child: Text(
              state.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),

        // Teams list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: state.teams.length + (state.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.teams.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppConstants.defaultPadding),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final team = state.teams[index];
              return _buildTeamCard(context, ref, team);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(BuildContext context, WidgetRef ref, TeamModel team) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Team avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    team.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),

                // Team info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (team.description != null)
                        Text(
                          team.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Status badge
                _buildStatusBadge(team.status),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Team details
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${team.memberCount} members',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(width: AppConstants.defaultPadding),

                Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  team.isOwner(ref.read(currentUserProvider)?.id ?? '')
                      ? 'Owner'
                      : 'Member',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TeamStatus status) {
    Color color;
    switch (status) {
      case TeamStatus.active:
        color = Colors.green;
        break;
      case TeamStatus.inactive:
        color = Colors.orange;
        break;
      case TeamStatus.suspended:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
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
            const SizedBox(height: AppConstants.defaultPadding),
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
          TextButton(
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
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create team: ${e.toString()}'),
                        backgroundColor: Colors.red,
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Email Address
                const Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Enter email address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Role
                const Text(
                  'Role',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                DropdownButtonFormField<TeamRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: AppConstants.defaultPadding),

                // Custom Message
                const Text(
                  'Custom Message (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: customMessageController,
                  decoration: const InputDecoration(
                    hintText: 'Add a personal message to the invitation...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Expires In
                const Text(
                  'Expires In (Days)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                DropdownButtonFormField<int>(
                  initialValue: expiresInDays,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: AppConstants.defaultPadding),

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
            ElevatedButton.icon(
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
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(isLoading ? 'Sending...' : 'Send Invitation'),
            ),
          ],
        ),
      ),
    );
  }
}
