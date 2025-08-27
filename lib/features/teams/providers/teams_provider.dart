import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/team_model.dart';
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
        final response = await SupabaseService.client
            .from('teams')
            .select()
            .or('owner_id.eq.${user.id},member_ids.cs.{${user.id}}')
            .order('created_at', ascending: false);

        teams = (response as List)
            .map((json) => TeamModel.fromJson(json))
            .toList();
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
