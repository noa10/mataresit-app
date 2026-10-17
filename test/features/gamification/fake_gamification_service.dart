import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/auth/providers/auth_provider.dart';
import 'package:mataresit_app/features/gamification/models/badge.dart';
import 'package:mataresit_app/features/gamification/models/gamification_profile.dart';
import 'package:mataresit_app/features/gamification/models/leaderboard_entry.dart';
import 'package:mataresit_app/features/gamification/models/mission.dart';
import 'package:mataresit_app/features/gamification/services/gamification_service.dart';
import 'package:mataresit_app/shared/models/user_model.dart';

/// In-memory [GamificationService] that records every call it receives.
///
/// The gamification providers talk to the backend only through
/// [gamificationServiceProvider], so overriding that provider with this fake is
/// enough to assert *which* RPCs the app issues — the point of the leaderboard
/// privacy gate test.
class FakeGamificationService implements GamificationService {
  FakeGamificationService({
    GamificationProfile? profile,
    this.missions = const <GamificationMission>[],
    this.leaderboardEntries = const <LeaderboardEntry>[],
    this.badges = const <BadgeWithStatus>[],
  }) : profile =
           profile ??
           const GamificationProfile(userId: testUserId, currentLevel: 1);

  static const String testUserId = 'user-1';

  GamificationProfile profile;
  List<GamificationMission> missions;
  List<LeaderboardEntry> leaderboardEntries;
  List<BadgeWithStatus> badges;

  int fetchProfileCalls = 0;
  int recordDailyLoginCalls = 0;
  int fetchMissionsCalls = 0;
  int fetchLeaderboardCalls = 0;
  int fetchBadgesCalls = 0;
  int updatePreferencesCalls = 0;
  int redeemReferralCalls = 0;

  final List<LeaderboardMetric> requestedMetrics = <LeaderboardMetric>[];
  final List<String?> requestedCountryCodes = <String?>[];
  final List<Map<String, dynamic>> preferenceWrites = <Map<String, dynamic>>[];
  final List<void Function()> changeCallbacks = <void Function()>[];

  bool redeemResult = false;

  @override
  Future<GamificationProfile> fetchProfile(String userId) async {
    fetchProfileCalls++;
    return profile;
  }

  @override
  Future<GamificationProfile> recordDailyLogin() async {
    recordDailyLoginCalls++;
    return profile;
  }

  @override
  Future<List<GamificationMission>> fetchMissions() async {
    fetchMissionsCalls++;
    return missions;
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardMetric metric,
    String? countryCode,
  }) async {
    fetchLeaderboardCalls++;
    requestedMetrics.add(metric);
    requestedCountryCodes.add(countryCode);
    return leaderboardEntries;
  }

  @override
  Future<List<BadgeWithStatus>> fetchBadges(String userId) async {
    fetchBadgesCalls++;
    return badges;
  }

  @override
  Future<GamificationProfile> updateLeaderboardPreferences({
    required String userId,
    required bool leaderboardOptIn,
    required String leaderboardDisplayMode,
    String? countryCode,
  }) async {
    updatePreferencesCalls++;
    preferenceWrites.add(<String, dynamic>{
      'user_id': userId,
      'leaderboard_opt_in': leaderboardOptIn,
      'leaderboard_display_mode': leaderboardDisplayMode,
      'country_code': countryCode,
    });
    profile = profile.copyWith(
      leaderboardOptIn: leaderboardOptIn,
      leaderboardDisplayMode: leaderboardDisplayMode,
    );
    return profile;
  }

  @override
  Future<bool> redeemReferralCode(String referralCode) async {
    redeemReferralCalls++;
    return redeemResult;
  }

  @override
  GamificationRealtimeSubscription subscribeToChanges({
    required String userId,
    required void Function() onChange,
  }) {
    changeCallbacks.add(onChange);
    return FakeRealtimeSubscription();
  }
}

class FakeRealtimeSubscription implements GamificationRealtimeSubscription {
  bool cancelled = false;

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}

/// A container wired to [service], with an authenticated test user.
ProviderContainer createGamificationContainer({
  required FakeGamificationService service,
  String userId = FakeGamificationService.testUserId,
}) {
  final container = ProviderContainer(
    overrides: [
      gamificationServiceProvider.overrideWithValue(service),
      currentUserProvider.overrideWithValue(
        UserModel(
          id: userId,
          email: 'reward-tester@example.com',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
