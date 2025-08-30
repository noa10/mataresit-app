import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/team_invitation_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/team_members_provider.dart';
import '../providers/team_invitation_provider.dart';

class TeamMembersScreen extends ConsumerStatefulWidget {
  final TeamModel team;
  final int initialTabIndex;

  const TeamMembersScreen({
    super.key,
    required this.team,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends ConsumerState<TeamMembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userRole = widget.team.getUserRole(currentUser?.id ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team.name} Members'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members', icon: Icon(Icons.people)),
            Tab(text: 'Invitations', icon: Icon(Icons.mail)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          if (userRole == TeamRole.owner || userRole == TeamRole.admin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showInviteMemberDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members by name, email, or role...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildInvitationsTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return Consumer(
      builder: (context, ref, child) {
        final membersAsync = ref.watch(teamMembersForTeamProvider(widget.team.memberIds));

        return membersAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Failed to load team members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  ElevatedButton(
                    onPressed: () => ref.refresh(teamMembersForTeamProvider(widget.team.memberIds)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (members) {
            if (members.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        'No team members found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Filter members by search query
            final filteredMembers = members.where((member) {
              if (_searchQuery.isEmpty) return true;

              final query = _searchQuery.toLowerCase();
              final name = '${member.firstName ?? ''} ${member.lastName ?? ''}'.toLowerCase();
              final email = (member.email ?? '').toLowerCase();
              final role = _getRoleDisplayName(widget.team.memberRoles[member.id] ?? TeamRole.member).toLowerCase();

              return name.contains(query) || email.contains(query) || role.contains(query);
            }).toList();

            if (filteredMembers.isEmpty && _searchQuery.isNotEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: AppConstants.defaultPadding),
                      Text(
                        'No members match your search',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                final memberRole = widget.team.memberRoles[member.id] ?? TeamRole.member;
                return _buildMemberCard(member, memberRole);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMemberCard(UserModel member, TeamRole role) {
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = currentUser?.id == member.id;
    final currentUserRole = widget.team.getUserRole(currentUser?.id ?? '');
    final canManage = (currentUserRole == TeamRole.owner || currentUserRole == TeamRole.admin) && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
              child: member.avatarUrl == null ? Text(
                _getInitials(member),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ) : null,
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            
            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCurrentUser ? 'You' : _getDisplayName(member),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.person, size: 16, color: Colors.blue),
                        ),
                    ],
                  ),
                  if (!isCurrentUser && member.email != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        member.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
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
            ),
            
            // Actions
            if (canManage)
              PopupMenuButton<String>(
                onSelected: (action) => _handleMemberAction(action, member.id, role),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_role',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings),
                        SizedBox(width: 8),
                        Text('Change Role'),
                      ],
                    ),
                  ),
                  if (role != TeamRole.owner)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove Member', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final invitationState = ref.watch(teamInvitationProvider(widget.team.id));

        if (invitationState.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (invitationState.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Failed to load invitations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    invitationState.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  ElevatedButton(
                    onPressed: () => ref.refresh(teamInvitationProvider(widget.team.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final invitations = invitationState.invitations;

        if (invitations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                  SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'No pending invitations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Invite new members to see pending invitations here',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            return _buildInvitationCard(invitation);
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final currentUser = ref.watch(currentUserProvider);
    final userRole = widget.team.getUserRole(currentUser?.id ?? '');
    final canManageSettings = userRole == TeamRole.owner || userRole == TeamRole.admin;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        // Team settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                
                SwitchListTile(
                  title: const Text('Allow member invites'),
                  subtitle: const Text('Let members invite new people to the team'),
                  value: widget.team.settings.allowMemberInvites,
                  onChanged: canManageSettings ? (value) {
                    // TODO: Update team settings
                  } : null,
                ),
                
                SwitchListTile(
                  title: const Text('Require approval for expenses'),
                  subtitle: const Text('All expenses need approval before processing'),
                  value: widget.team.settings.requireApprovalForExpenses,
                  onChanged: canManageSettings ? (value) {
                    // TODO: Update team settings
                  } : null,
                ),
                
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  subtitle: const Text('Send notifications for team activities'),
                  value: widget.team.settings.enableNotifications,
                  onChanged: canManageSettings ? (value) {
                    // TODO: Update team settings
                  } : null,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Danger zone
        if (userRole == TeamRole.owner)
          Card(
            color: Colors.red.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteTeamDialog(context),
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Delete Team', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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

  void _handleMemberAction(String action, String memberId, TeamRole currentRole) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(context, memberId, currentRole);
        break;
      case 'remove':
        _showRemoveMemberDialog(context, memberId);
        break;
    }
  }

  void _showInviteMemberDialog(BuildContext context) {
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
                  'Invite a new member to join ${widget.team.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
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
                  onChanged: isLoading ? null : (role) {
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
                  onChanged: isLoading ? null : (days) {
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
                  onChanged: isLoading ? null : (value) {
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
            Consumer(
              builder: (context, ref, child) => ElevatedButton.icon(
                onPressed: isLoading || emailController.text.trim().isEmpty ? null : () async {
                  setState(() => isLoading = true);

                  try {
                    await ref.read(teamInvitationProvider(widget.team.id).notifier).sendInvitation(
                      teamId: widget.team.id,
                      email: emailController.text.trim(),
                      role: selectedRole,
                      customMessage: customMessageController.text.trim().isEmpty
                          ? null
                          : customMessageController.text.trim(),
                      expiresInDays: expiresInDays,
                      sendEmail: sendEmailNotification,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitation sent successfully!')),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send invitation: $error')),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(TeamInvitationModel invitation) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(invitation.role).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              invitation.role.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRoleColor(invitation.role),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(invitation.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              invitation.statusDisplayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(invitation.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleInvitationAction(action, invitation),
                  itemBuilder: (context) => [
                    if (invitation.isPending) ...[
                      const PopupMenuItem(
                        value: 'resend',
                        child: Row(
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text('Resend'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Cancel', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sent ${_formatTimeAgo(invitation.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (invitation.isExpired)
              Text(
                'Expired ${_formatTimeAgo(invitation.expiresAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              )
            else if (invitation.isPending)
              Text(
                'Expires ${_formatTimeAgo(invitation.expiresAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, String memberId, TeamRole currentRole) {
    // TODO: Implement change role dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change role feature coming soon!')),
    );
  }

  void _showRemoveMemberDialog(BuildContext context, String memberId) {
    // TODO: Implement remove member dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remove member feature coming soon!')),
    );
  }

  void _handleInvitationAction(String action, TeamInvitationModel invitation) {
    switch (action) {
      case 'resend':
        _resendInvitation(invitation);
        break;
      case 'cancel':
        _cancelInvitation(invitation);
        break;
    }
  }

  Future<void> _resendInvitation(TeamInvitationModel invitation) async {
    try {
      await ref.read(teamInvitationProvider(widget.team.id).notifier).resendInvitation(
        teamId: widget.team.id,
        invitationId: invitation.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation resent successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend invitation: $error')),
        );
      }
    }
  }

  Future<void> _cancelInvitation(TeamInvitationModel invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text('Are you sure you want to cancel the invitation to ${invitation.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(teamInvitationProvider(widget.team.id).notifier).cancelInvitation(
          teamId: widget.team.id,
          invitationId: invitation.id,
          reason: 'Cancelled by team admin',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation cancelled successfully!')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel invitation: $error')),
          );
        }
      }
    }
  }

  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.expired:
        return Colors.red;
      case InvitationStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteTeamDialog(BuildContext context) {
    // TODO: Implement delete team dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete team feature coming soon!')),
    );
  }

  String _getInitials(UserModel user) {
    final firstName = user.firstName?.trim() ?? '';
    final lastName = user.lastName?.trim() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    } else if (user.email != null && user.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    } else {
      return 'U';
    }
  }

  String _getDisplayName(UserModel user) {
    final firstName = user.firstName?.trim() ?? '';
    final lastName = user.lastName?.trim() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else if (user.email != null && user.email!.isNotEmpty) {
      return user.email!;
    } else {
      return 'Unknown User';
    }
  }
}
