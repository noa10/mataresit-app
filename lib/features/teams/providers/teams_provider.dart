import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Teams state
class TeamsState {
  final List<TeamModel> teams;
  final bool isLoading;
  final String? error;

  const TeamsState({
    this.teams = const [],
    this.isLoading = false,
    this.error,
  });

  TeamsState copyWith({
    List<TeamModel>? teams,
    bool? isLoading,
    String? error,
  }) {
    return TeamsState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Teams notifier
class TeamsNotifier extends StateNotifier<TeamsState> {
  final Ref ref;

  TeamsNotifier(this.ref) : super(const TeamsState()) {
    loadTeams();
  }

  /// Load teams for the current user
  Future<void> loadTeams() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Try to load from database
      List<TeamModel> teams = [];
      try {
        // First get teams where user is owner
        final ownedTeamsResponse = await SupabaseService.client
            .from('teams')
            .select()
            .eq('owner_id', user.id)
            .order('created_at', ascending: false);

        // Then get teams where user is a member
        final memberTeamsResponse = await SupabaseService.client
            .from('teams')
            .select('''
              *,
              team_members!inner(user_id)
            ''')
            .eq('team_members.user_id', user.id)
            .order('created_at', ascending: false);

        // Combine and deduplicate teams
        final allTeamsMap = <String, dynamic>{};

        // Add owned teams
        for (final team in ownedTeamsResponse as List) {
          allTeamsMap[team['id']] = team;
        }

        // Add member teams (avoiding duplicates)
        for (final team in memberTeamsResponse as List) {
          allTeamsMap[team['id']] = team;
        }

        // Log the raw team data to understand the structure
        AppLogger.debug('Raw team data from database: ${allTeamsMap.values.first}');

        // Convert to TeamModel with proper field mapping
        teams = allTeamsMap.values
            .map((json) => _mapDatabaseTeamToModel(json))
            .toList();

        // Sort by created_at descending
        teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        AppLogger.warning('Failed to load teams from database', e);
        // Create mock teams for demonstration
        teams = _createMockTeams(user.id);
      }

      state = state.copyWith(
        teams: teams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Maps database team data to TeamModel format
  TeamModel _mapDatabaseTeamToModel(Map<String, dynamic> json) {
    // Extract member IDs from team_members array
    final List<String> memberIds = [];
    final Map<String, TeamRole> memberRoles = {};

    if (json['team_members'] is List) {
      for (final member in json['team_members'] as List) {
        if (member is Map<String, dynamic> && member['user_id'] is String) {
          final userId = member['user_id'] as String;
          memberIds.add(userId);

          // Determine role: owner gets owner role, others get member role
          final isOwner = userId == json['owner_id'];
          memberRoles[userId] = isOwner ? TeamRole.owner : TeamRole.member;
        }
      }
    }

    // Ensure owner is always included
    final ownerId = json['owner_id'] as String;
    if (!memberIds.contains(ownerId)) {
      memberIds.add(ownerId);
      memberRoles[ownerId] = TeamRole.owner;
    }

    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: ownerId,
      status: _parseTeamStatus(json['status'] as String?),
      memberIds: memberIds,
      memberRoles: memberRoles,
      settings: _parseTeamSettings(json['settings']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  TeamStatus _parseTeamStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return TeamStatus.active;
      case 'inactive':
        return TeamStatus.inactive;
      case 'suspended':
        return TeamStatus.suspended;
      default:
        return TeamStatus.active;
    }
  }

  TeamSettings _parseTeamSettings(dynamic settings) {
    if (settings is Map<String, dynamic>) {
      return TeamSettings(
        allowMemberInvites: settings['allowMemberInvites'] as bool? ?? false,
        requireApprovalForExpenses: settings['requireApprovalForExpenses'] as bool? ?? false,
        expenseApprovalLimit: settings['expenseApprovalLimit'] as double?,
        enableNotifications: settings['enableNotifications'] as bool? ?? true,
        allowedCategories: (settings['allowedCategories'] as List?)?.cast<String>() ?? [],
      );
    }
    return const TeamSettings(
      allowMemberInvites: false,
      requireApprovalForExpenses: false,
      enableNotifications: true,
      allowedCategories: [],
    );
  }

  /// Create mock teams for demonstration
  List<TeamModel> _createMockTeams(String userId) {
    final now = DateTime.now();
    return [
      TeamModel(
        id: 'team-1',
        name: 'Marketing Team',
        description: 'Marketing department expense tracking',
        ownerId: userId,
        status: TeamStatus.active,
        memberIds: [userId, 'user-2', 'user-3'],
        memberRoles: {
          userId: TeamRole.owner,
          'user-2': TeamRole.admin,
          'user-3': TeamRole.member,
        },
        settings: const TeamSettings(
          allowMemberInvites: true,
          requireApprovalForExpenses: true,
          expenseApprovalLimit: 500.0,
          enableNotifications: true,
        ),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      TeamModel(
        id: 'team-2',
        name: 'Sales Team',
        description: 'Sales team travel and entertainment expenses',
        ownerId: 'other-user',
        status: TeamStatus.active,
        memberIds: [userId, 'other-user', 'user-4'],
        memberRoles: {
          userId: TeamRole.member,
          'other-user': TeamRole.owner,
          'user-4': TeamRole.member,
        },
        settings: const TeamSettings(
          allowMemberInvites: false,
          requireApprovalForExpenses: false,
          enableNotifications: true,
        ),
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Create a new team
  Future<void> createTeam({
    required String name,
    String? description,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final teamId = const Uuid().v4();
      final now = DateTime.now();

      final team = TeamModel(
        id: teamId,
        name: name,
        description: description,
        ownerId: user.id,
        status: TeamStatus.active,
        memberIds: [user.id],
        memberRoles: {user.id: TeamRole.owner},
        settings: const TeamSettings(),
        createdAt: now,
        updatedAt: now,
      );

      // Try to save to database
      try {
        await _saveTeamToDatabase(team);
      } catch (e) {
        AppLogger.warning('Failed to save team to database', e);
        // Continue anyway - add to local state
      }

      // Add to local state
      state = state.copyWith(
        teams: [team, ...state.teams],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Save team to database
  Future<void> _saveTeamToDatabase(TeamModel team) async {
    final teamData = {
      'id': team.id,
      'name': team.name,
      'description': team.description,
      'avatar_url': team.avatarUrl,
      'owner_id': team.ownerId,
      'status': team.status.name,
      'member_ids': team.memberIds,
      'member_roles': team.memberRoles.map((k, v) => MapEntry(k, v.name)),
      'settings': team.settings.toJson(),
      'created_at': team.createdAt.toIso8601String(),
      'updated_at': team.updatedAt.toIso8601String(),
    };

    await SupabaseService.client
        .from('teams')
        .insert(teamData);
  }

  /// Join a team
  Future<void> joinTeam(String teamId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Find the team
      final teamIndex = state.teams.indexWhere((t) => t.id == teamId);
      if (teamIndex == -1) {
        throw Exception('Team not found');
      }

      final team = state.teams[teamIndex];
      if (team.isMember(user.id)) {
        throw Exception('Already a member of this team');
      }

      // Update team with new member
      final updatedTeam = team.copyWith(
        memberIds: [...team.memberIds, user.id],
        memberRoles: {
          ...team.memberRoles,
          user.id: TeamRole.member,
        },
        updatedAt: DateTime.now(),
      );

      // Try to update in database
      try {
        await _saveTeamToDatabase(updatedTeam);
      } catch (e) {
        AppLogger.warning('Failed to update team in database', e);
      }

      // Update local state
      final updatedTeams = [...state.teams];
      updatedTeams[teamIndex] = updatedTeam;

      state = state.copyWith(
        teams: updatedTeams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Leave a team
  Future<void> leaveTeam(String teamId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Find the team
      final teamIndex = state.teams.indexWhere((t) => t.id == teamId);
      if (teamIndex == -1) {
        throw Exception('Team not found');
      }

      final team = state.teams[teamIndex];
      if (team.isOwner(user.id)) {
        throw Exception('Team owner cannot leave the team');
      }

      // Update team by removing member
      final updatedMemberIds = team.memberIds.where((id) => id != user.id).toList();
      final updatedMemberRoles = Map<String, TeamRole>.from(team.memberRoles)
        ..remove(user.id);

      final updatedTeam = team.copyWith(
        memberIds: updatedMemberIds,
        memberRoles: updatedMemberRoles,
        updatedAt: DateTime.now(),
      );

      // Try to update in database
      try {
        await _saveTeamToDatabase(updatedTeam);
      } catch (e) {
        AppLogger.warning('Failed to update team in database', e);
      }

      // Update local state
      final updatedTeams = [...state.teams];
      updatedTeams[teamIndex] = updatedTeam;

      state = state.copyWith(
        teams: updatedTeams,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh teams
  Future<void> refresh() async {
    await loadTeams();
  }
}

/// Teams provider
final teamsProvider = StateNotifierProvider<TeamsNotifier, TeamsState>((ref) {
  return TeamsNotifier(ref);
});

/// Individual team provider
final teamProvider = Provider.family<TeamModel?, String>((ref, teamId) {
  final teams = ref.watch(teamsProvider).teams;
  try {
    return teams.firstWhere((team) => team.id == teamId);
  } catch (e) {
    return null;
  }
});

/// Current team state
class CurrentTeamState {
  final TeamModel? currentTeam;
  final TeamRole? currentRole;
  final bool isLoading;
  final String? error;

  const CurrentTeamState({
    this.currentTeam,
    this.currentRole,
    this.isLoading = false,
    this.error,
  });

  CurrentTeamState copyWith({
    TeamModel? currentTeam,
    TeamRole? currentRole,
    bool? isLoading,
    String? error,
  }) {
    return CurrentTeamState(
      currentTeam: currentTeam ?? this.currentTeam,
      currentRole: currentRole ?? this.currentRole,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Current team notifier
class CurrentTeamNotifier extends StateNotifier<CurrentTeamState> {
  final Ref ref;

  CurrentTeamNotifier(this.ref) : super(const CurrentTeamState()) {
    // Listen for authentication changes
    ref.listen<UserModel?>(currentUserProvider, (previous, next) {
      if (previous == null && next != null) {
        // User just authenticated, initialize current team
        _deferredInitializeCurrentTeam();
      } else if (previous != null && next == null) {
        // User logged out, clear current team
        state = const CurrentTeamState();
      }
    });

    // If user is already authenticated, initialize after the current build cycle
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _deferredInitializeCurrentTeam();
    }
  }

  /// Deferred initialization to avoid circular dependencies during widget builds
  void _deferredInitializeCurrentTeam() {
    // Use Future.microtask to defer execution until after the current build cycle
    Future.microtask(() {
      _initializeCurrentTeam();
    });
  }

  /// Initialize current team from stored preferences or first available team
  Future<void> _initializeCurrentTeam() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Ensure teams are loaded first
      await ref.read(teamsProvider.notifier).loadTeams();

      final teamsState = ref.read(teamsProvider);
      final teams = teamsState.teams;

      AppLogger.debug('🏢 Teams loaded for current team initialization: ${teams.length} teams');
      for (final team in teams) {
        AppLogger.debug('🏢 Team: ${team.id} - ${team.name} (Owner: ${team.ownerId}, Members: ${team.memberIds.length})');
        AppLogger.debug('🏢 Member roles: ${team.memberRoles}');
      }

      if (teams.isEmpty) {
        AppLogger.info('🏢 No teams found for user');
        state = state.copyWith(isLoading: false);
        return;
      }

      // For now, select the first team
      // TODO: Add shared preferences to store last selected team
      final firstTeam = teams.first;
      AppLogger.debug('🏢 Attempting to switch to first team: ${firstTeam.id} - ${firstTeam.name}');
      await switchTeam(firstTeam.id);
    } catch (e) {
      AppLogger.error('Error initializing current team', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Switch to a different team
  Future<void> switchTeam(String? teamId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (teamId == null) {
        state = state.copyWith(
          currentTeam: null,
          currentRole: null,
          isLoading: false,
        );
        return;
      }

      final teams = ref.read(teamsProvider).teams;
      TeamModel? team;
      try {
        team = teams.firstWhere((t) => t.id == teamId);
      } catch (e) {
        team = null;
      }

      if (team == null) {
        throw Exception('Team not found');
      }

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final role = team.getUserRole(user.id);

      state = state.copyWith(
        currentTeam: team,
        currentRole: role,
        isLoading: false,
      );

      AppLogger.info('🏢 Switched to team: ${team.name} (${role.name})');
    } catch (e) {
      AppLogger.error('Error switching team', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Current team provider
final currentTeamProvider = StateNotifierProvider<CurrentTeamNotifier, CurrentTeamState>((ref) {
  return CurrentTeamNotifier(ref);
});

/// Provider for current team model
final currentTeamModelProvider = Provider<TeamModel?>((ref) {
  return ref.watch(currentTeamProvider).currentTeam;
});

/// Provider for current team role
final currentTeamRoleProvider = Provider<TeamRole?>((ref) {
  return ref.watch(currentTeamProvider).currentRole;
});
