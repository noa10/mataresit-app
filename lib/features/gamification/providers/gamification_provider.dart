import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/badge.dart';
import '../models/gamification_profile.dart';
import '../models/leaderboard_entry.dart';
import '../models/mission.dart';
import '../services/gamification_service.dart';

/// Records today's login, at most once per app session.
///
/// `record_daily_login` is idempotent per local day but still mutates server
/// state, so it is issued from a non-autoDispose provider: the result is cached
/// for the lifetime of the app's `ProviderScope` (one session) instead of being
/// re-fired on every rebuild. Returns `null` when nobody is signed in.
final dailyLoginProvider = FutureProvider<GamificationProfile?>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return ref.watch(gamificationServiceProvider).recordDailyLogin();
});

/// The signed-in user's gamification profile, kept fresh over realtime.
class GamificationProfileNotifier extends AsyncNotifier<GamificationProfile> {
  final Logger _logger = Logger();
  GamificationRealtimeSubscription? _subscription;
  Timer? _realtimeDebounce;

  @override
  Future<GamificationProfile> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    final service = ref.watch(gamificationServiceProvider);
    if (userId == null) {
      throw const GamificationException('Not signed in.');
    }

    _subscribeToRealtime(userId, service);
    ref.onDispose(() {
      _realtimeDebounce?.cancel();
      _realtimeDebounce = null;
      final subscription = _subscription;
      _subscription = null;
      if (subscription != null) unawaited(subscription.cancel());
    });

    // `record_daily_login` answers with the stats row, so it doubles as the
    // profile read while keeping the "once per session" contract.
    try {
      final profile = await ref.watch(dailyLoginProvider.future);
      if (profile != null) return profile;
    } catch (e) {
      _logger.w('record_daily_login failed, reading the profile directly: $e');
    }
    return service.fetchProfile(userId);
  }

  /// Re-reads the profile from the server.
  Future<void> refresh() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    // Keep the current content visible while the refresh is in flight.
    state = const AsyncLoading<GamificationProfile>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(gamificationServiceProvider).fetchProfile(userId),
    );
  }

  /// Persists the leaderboard preferences.
  ///
  /// Only `leaderboard_opt_in` and `leaderboard_display_mode` are written, and
  /// they are written for the signed-in user only. Errors propagate so the UI
  /// can report them; the state keeps the previous profile.
  Future<void> updateLeaderboardPreferences({
    bool? optIn,
    String? displayMode,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final current = state.valueOrNull;
    final updated = await ref
        .read(gamificationServiceProvider)
        .updateLeaderboardPreferences(
          userId: userId,
          leaderboardOptIn: optIn ?? current?.leaderboardOptIn ?? false,
          leaderboardDisplayMode:
              displayMode ??
              current?.leaderboardDisplayMode ??
              GamificationProfile.displayModeAnonymous,
        );
    state = AsyncValue.data(updated);
  }

  /// Redeems an invite code.
  ///
  /// Resolves to `false` when the server rejects the code; the caller reports
  /// that as a plain message rather than an exception.
  Future<bool> redeemReferralCode(String referralCode) async {
    final redeemed = await ref
        .read(gamificationServiceProvider)
        .redeemReferralCode(referralCode.trim());
    if (redeemed) await _refreshQuietly();
    return redeemed;
  }

  /// Re-reads the profile without flashing a loading state over the rewards UI.
  Future<void> _refreshQuietly() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    try {
      final profile = await ref
          .read(gamificationServiceProvider)
          .fetchProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e) {
      _logger.w('Gamification profile refresh failed: $e');
    }
  }

  void _subscribeToRealtime(String userId, GamificationService service) {
    final previous = _subscription;
    if (previous != null) unawaited(previous.cancel());
    _subscription = service.subscribeToChanges(
      userId: userId,
      onChange: _handleRealtimeChange,
    );
  }

  /// One action can emit an XP event, a stats update and a badge unlock in quick
  /// succession, so the refresh is debounced.
  ///
  /// Missions are deliberately not refetched here: that RPC mutates state (it
  /// can award XP), so it stays a user-initiated refresh.
  void _handleRealtimeChange() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(gamificationBadgesProvider);
      unawaited(_refreshQuietly());
    });
  }
}

/// The user's missions, grouped by `mission.missionType` with summary counters.
class GamificationMissionsNotifier extends AsyncNotifier<MissionsBoard> {
  @override
  Future<MissionsBoard> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const MissionsBoard.empty();
    final missions = await ref
        .watch(gamificationServiceProvider)
        .fetchMissions();
    return MissionsBoard.fromMissions(missions);
  }

  /// Re-reads the missions (this RPC can award XP, so it is user-initiated).
  Future<void> refresh() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    // Keep the current content visible while the refresh is in flight.
    state = const AsyncLoading<MissionsBoard>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final missions = await ref
          .read(gamificationServiceProvider)
          .fetchMissions();
      return MissionsBoard.fromMissions(missions);
    });
  }
}

/// The badge catalogue joined with the user's unlock rows.
class GamificationBadgesNotifier extends AsyncNotifier<List<BadgeWithStatus>> {
  @override
  Future<List<BadgeWithStatus>> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const <BadgeWithStatus>[];
    return ref.watch(gamificationServiceProvider).fetchBadges(userId);
  }

  Future<void> refresh() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    // Keep the current content visible while the refresh is in flight.
    state = const AsyncLoading<List<BadgeWithStatus>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(gamificationServiceProvider).fetchBadges(userId),
    );
  }
}

/// Profile, streaks, XP and leaderboard preferences.
final gamificationProfileProvider =
    AsyncNotifierProvider<GamificationProfileNotifier, GamificationProfile>(
      GamificationProfileNotifier.new,
    );

/// Missions grouped by type.
final gamificationMissionsProvider =
    AsyncNotifierProvider<GamificationMissionsNotifier, MissionsBoard>(
      GamificationMissionsNotifier.new,
    );

/// Badges for the rewards grid.
final gamificationBadgesProvider =
    AsyncNotifierProvider<GamificationBadgesNotifier, List<BadgeWithStatus>>(
      GamificationBadgesNotifier.new,
    );

/// One leaderboard board (metric + scope).
///
/// PRIVACY: the leaderboard RPC is only issued when the user has
/// `leaderboard_opt_in = true`. The web app fires the query regardless
/// (`LeaderboardPage.tsx:82-85` — `enabled` never consults `leaderboardOptIn`),
/// which leaks participation; the gate lives here so no screen can bypass it.
/// While opted out the result is [LeaderboardResult.optedOut] and no request is
/// made.
final gamificationLeaderboardProvider =
    FutureProvider.family<LeaderboardResult, LeaderboardQuery>((
      ref,
      query,
    ) async {
      final profile = await ref.watch(gamificationProfileProvider.future);
      if (!profile.leaderboardOptIn) {
        return LeaderboardResult.optedOut(query.metric);
      }

      final entries = await ref
          .watch(gamificationServiceProvider)
          .fetchLeaderboard(
            metric: query.metric,
            countryCode: query.countryCode,
          );
      return LeaderboardResult(metric: query.metric, entries: entries);
    });
