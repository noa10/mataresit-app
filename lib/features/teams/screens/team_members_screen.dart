import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/team_invitation_model.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/team_invitation_provider.dart';
import '../providers/team_members_provider.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider);
    final userRole = widget.team.getUserRole(currentUser?.id ?? '');
    final canManage = userRole == TeamRole.owner || userRole == TeamRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TEAM WORKSPACE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.team.name} Members',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'InstrumentSerif',
                fontSize: 24,
                height: 1.05,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Invitations'),
            Tab(text: 'Settings'),
          ],
        ),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Invite member',
              icon: const Icon(Icons.person_add_alt_1, size: 20),
              onPressed: () => _showInviteMemberDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEARCH',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search members by name, email, or role...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
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
        final membersAsync = ref.watch(
          teamMembersForTeamProvider(widget.team.memberIds),
        );

        return membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _StatePanel(
            icon: Icons.error_outline,
            title: 'Failed to load team members',
            message: error.toString(),
            action: OutlinedButton(
              onPressed: () => ref.refresh(
                teamMembersForTeamProvider(widget.team.memberIds),
              ),
              child: const Text('Retry'),
            ),
          ),
          data: (members) {
            if (members.isEmpty) {
              return const _StatePanel(
                icon: Icons.people_outline,
                title: 'No team members found',
              );
            }

            // Filter members by search query
            final filteredMembers = members.where((member) {
              if (_searchQuery.isEmpty) return true;

              final query = _searchQuery.toLowerCase();
              final name = '${member.firstName ?? ''} ${member.lastName ?? ''}'
                  .toLowerCase();
              final email = (member.email ?? '').toLowerCase();
              final role =
                  (widget.team.memberRoles[member.id] ?? TeamRole.member)
                      .displayName
                      .toLowerCase();

              return name.contains(query) ||
                  email.contains(query) ||
                  role.contains(query);
            }).toList();

            if (filteredMembers.isEmpty && _searchQuery.isNotEmpty) {
              return const _StatePanel(
                icon: Icons.search_off,
                title: 'No members match your search',
              );
            }

            return _buildMembersList(filteredMembers);
          },
        );
      },
    );
  }

  Widget _buildMembersList(List<UserModel> members) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Members',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${members.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: members.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: colors.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final member = members[index];
                final memberRole =
                    widget.team.memberRoles[member.id] ?? TeamRole.member;
                return _buildMemberRow(member, memberRole);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(UserModel member, TeamRole role) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = currentUser?.id == member.id;
    final currentUserRole = widget.team.getUserRole(currentUser?.id ?? '');
    final canManage =
        (currentUserRole == TeamRole.owner ||
            currentUserRole == TeamRole.admin) &&
        !isCurrentUser;
    final displayName = isCurrentUser ? 'You' : _getDisplayName(member);
    // Members without a name fall back to their email, so don't repeat it.
    final showEmail =
        !isCurrentUser &&
        member.email != null &&
        member.email!.toLowerCase() != displayName.toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          _MemberAvatar(member: member, initials: _getInitials(member)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.person_outline,
                          size: 16,
                          color: colors.primary,
                        ),
                      ),
                  ],
                ),
                if (showEmail) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                _RolePill(role: role),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              onSelected: (action) =>
                  _handleMemberAction(action, member.id, role),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'change_role',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Change Role'),
                    ],
                  ),
                ),
                if (role != TeamRole.owner)
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.remove_circle_outline,
                          size: 18,
                          color: colors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remove Member',
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInvitationsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final invitationState = ref.watch(
          teamInvitationProvider(widget.team.id),
        );

        if (invitationState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (invitationState.error != null) {
          return _StatePanel(
            icon: Icons.error_outline,
            title: 'Failed to load invitations',
            message: invitationState.error!,
            action: OutlinedButton(
              onPressed: () =>
                  ref.refresh(teamInvitationProvider(widget.team.id)),
              child: const Text('Retry'),
            ),
          );
        }

        final invitations = invitationState.invitations;

        if (invitations.isEmpty) {
          return const _StatePanel(
            icon: Icons.mail_outline,
            title: 'No pending invitations',
            message: 'Invite new members to see pending invitations here',
          );
        }

        return _buildInvitationsList(invitations);
      },
    );
  }

  Widget _buildInvitationsList(List<TeamInvitationModel> invitations) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Invitations',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${invitations.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: invitations.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: colors.outlineVariant,
              ),
              itemBuilder: (context, index) =>
                  _buildInvitationRow(invitations[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationRow(TeamInvitationModel invitation) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentUserRole = widget.team.getUserRole(
      ref.watch(currentUserProvider)?.id ?? '',
    );
    final canManage =
        currentUserRole == TeamRole.owner || currentUserRole == TeamRole.admin;
    final showExpired =
        invitation.status == InvitationStatus.expired ||
        (invitation.status == InvitationStatus.pending && invitation.isExpired);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RolePill(role: invitation.role),
                    _InvitationStatusPill(invitation: invitation),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent ${_formatTimeAgo(invitation.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                  ),
                ),
                if (showExpired)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Expired ${_formatTimeAgo(invitation.expiresAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.error,
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                      ),
                    ),
                  )
                else if (invitation.isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Expires in ${_formatTimeUntil(invitation.expiresAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canManage && invitation.isPending)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              onSelected: (action) =>
                  _handleInvitationAction(action, invitation),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'resend',
                  child: Row(
                    children: [
                      Icon(Icons.send_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Resend'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: colors.error,
                      ),
                      const SizedBox(width: 8),
                      Text('Cancel', style: TextStyle(color: colors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final currentUser = ref.watch(currentUserProvider);
    final userRole = widget.team.getUserRole(currentUser?.id ?? '');
    final canManageSettings =
        userRole == TeamRole.owner || userRole == TeamRole.admin;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _Panel(
          title: 'Team Settings',
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Allow member invites'),
                subtitle: const Text(
                  'Let members invite new people to the team',
                ),
                value: widget.team.settings.allowMemberInvites,
                onChanged: canManageSettings
                    ? (value) {
                        // TODO: Update team settings
                      }
                    : null,
              ),
              Divider(height: 1, thickness: 1, color: colors.outlineVariant),
              SwitchListTile(
                title: const Text('Require approval for expenses'),
                subtitle: const Text(
                  'All expenses need approval before processing',
                ),
                value: widget.team.settings.requireApprovalForExpenses,
                onChanged: canManageSettings
                    ? (value) {
                        // TODO: Update team settings
                      }
                    : null,
              ),
              Divider(height: 1, thickness: 1, color: colors.outlineVariant),
              SwitchListTile(
                title: const Text('Enable notifications'),
                subtitle: const Text('Send notifications for team activities'),
                value: widget.team.settings.enableNotifications,
                onChanged: canManageSettings
                    ? (value) {
                        // TODO: Update team settings
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (userRole == TeamRole.owner)
          _Panel(
            title: 'Danger Zone',
            titleColor: colors.error,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteTeamDialog(context),
                  icon: Icon(
                    Icons.delete_forever,
                    size: 18,
                    color: colors.error,
                  ),
                  label: Text(
                    'Delete Team',
                    style: TextStyle(color: colors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.error),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleMemberAction(
    String action,
    String memberId,
    TeamRole currentRole,
  ) {
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
            Consumer(
              builder: (context, ref, child) => FilledButton.icon(
                onPressed: isLoading || emailController.text.trim().isEmpty
                    ? null
                    : () async {
                        setState(() => isLoading = true);

                        try {
                          await ref
                              .read(
                                teamInvitationProvider(widget.team.id).notifier,
                              )
                              .sendInvitation(
                                teamId: widget.team.id,
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
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(
    BuildContext context,
    String memberId,
    TeamRole currentRole,
  ) {
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
      await ref
          .read(teamInvitationProvider(widget.team.id).notifier)
          .resendInvitation(
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
        content: Text(
          'Are you sure you want to cancel the invitation to ${invitation.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(teamInvitationProvider(widget.team.id).notifier)
            .cancelInvitation(
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

  String _formatTimeUntil(DateTime dateTime) {
    final difference = dateTime.difference(DateTime.now());

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    }
    return 'less than a minute';
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

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.initials});

  final UserModel member;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatarUrl = member.avatarUrl;

    Widget fallback() => Center(
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

    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: avatarUrl == null || avatarUrl.isEmpty
          ? fallback()
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback(),
            ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.titleColor});

  final String title;
  final Widget child;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor ?? colors.onSurface,
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          child,
        ],
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

class _InvitationStatusPill extends StatelessWidget {
  const _InvitationStatusPill({required this.invitation});

  final TeamInvitationModel invitation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final showExpired =
        invitation.status == InvitationStatus.expired ||
        (invitation.status == InvitationStatus.pending && invitation.isExpired);

    final background = showExpired
        ? colors.errorContainer
        : switch (invitation.status) {
            InvitationStatus.pending => colors.tertiaryContainer,
            InvitationStatus.accepted => colors.primaryContainer,
            InvitationStatus.expired => colors.errorContainer,
            InvitationStatus.cancelled => colors.surfaceContainerHighest,
          };
    final foreground = showExpired
        ? colors.onErrorContainer
        : switch (invitation.status) {
            InvitationStatus.pending => colors.onTertiaryContainer,
            InvitationStatus.accepted => colors.onPrimaryContainer,
            InvitationStatus.expired => colors.onErrorContainer,
            InvitationStatus.cancelled => colors.onSurfaceVariant,
          };

    return _Pill(
      label: invitation.statusDisplayName,
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
