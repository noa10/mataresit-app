import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/user_model.dart';

/// State for team members
class TeamMembersState {
  final List<UserModel> members;
  final bool isLoading;
  final String? error;

  const TeamMembersState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  TeamMembersState copyWith({
    List<UserModel>? members,
    bool? isLoading,
    String? error,
  }) {
    return TeamMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for team members
class TeamMembersNotifier extends StateNotifier<TeamMembersState> {
  final Ref ref;

  TeamMembersNotifier(this.ref) : super(const TeamMembersState());

  /// Load team members by their IDs
  Future<void> loadTeamMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) {
      state = state.copyWith(members: [], isLoading: false);
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      AppLogger.debug('🔍 Loading team members for IDs: $memberIds');

      // Fetch user data from Supabase profiles table
      final response = await SupabaseService.client
          .from('profiles')
          .select('''
            id,
            email,
            first_name,
            last_name,
            avatar_url,
            google_avatar_url,
            avatar_updated_at,
            subscription_tier,
            subscription_status,
            stripe_customer_id,
            stripe_subscription_id,
            receipts_used_this_month,
            created_at,
            updated_at
          ''')
          .inFilter('id', memberIds);

      AppLogger.debug('📊 Raw team members response: $response');

      final List<UserModel> members = [];

      for (final userData in response) {
        try {
          final user = UserModel.fromJson(userData);
          members.add(user);
          AppLogger.debug('✅ Loaded member: ${user.email} (${user.id})');
        } catch (e) {
          AppLogger.warning('Failed to parse user data: $userData, error: $e');
        }
      }

      // Sort members by name
      members.sort((a, b) {
        final aName = '${a.firstName ?? ''} ${a.lastName ?? ''}'.trim();
        final bName = '${b.firstName ?? ''} ${b.lastName ?? ''}'.trim();
        if (aName.isEmpty && bName.isEmpty) {
          return (a.email ?? '').compareTo(b.email ?? '');
        }
        if (aName.isEmpty) return 1;
        if (bName.isEmpty) return -1;
        return aName.compareTo(bName);
      });

      state = state.copyWith(members: members, isLoading: false);

      AppLogger.info('✅ Loaded ${members.length} team members');
    } catch (e) {
      AppLogger.error('Error loading team members', e);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Get member by ID
  UserModel? getMemberById(String memberId) {
    try {
      return state.members.firstWhere((member) => member.id == memberId);
    } catch (e) {
      return null;
    }
  }

  /// Clear members
  void clearMembers() {
    state = const TeamMembersState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Team members provider
final teamMembersProvider =
    StateNotifierProvider.family<
      TeamMembersNotifier,
      TeamMembersState,
      List<String>
    >((ref, memberIds) {
      final notifier = TeamMembersNotifier(ref);
      // Auto-load members when provider is created
      Future.microtask(() => notifier.loadTeamMembers(memberIds));
      return notifier;
    });

/// Provider for a specific team's members
final teamMembersForTeamProvider =
    Provider.family<AsyncValue<List<UserModel>>, List<String>>((
      ref,
      memberIds,
    ) {
      if (memberIds.isEmpty) {
        return const AsyncValue.data([]);
      }

      final membersState = ref.watch(teamMembersProvider(memberIds));

      if (membersState.isLoading) {
        return const AsyncValue.loading();
      }

      if (membersState.error != null) {
        return AsyncValue.error(membersState.error!, StackTrace.current);
      }

      return AsyncValue.data(membersState.members);
    });
