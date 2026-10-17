import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/gamification/models/gamification_profile.dart';
import 'package:mataresit_app/features/gamification/models/leaderboard_entry.dart';
import 'package:mataresit_app/features/gamification/providers/gamification_provider.dart';

import 'fake_gamification_service.dart';

Map<String, dynamic> leaderboardRow({
  required int rank,
  required String userId,
  required num metricValue,
  String displayName = 'Receipt Ruler',
  bool isCurrentUser = false,
  bool isAnonymous = false,
  num gapToTopTen = 0,
}) {
  return <String, dynamic>{
    'rank': rank,
    'user_id': userId,
    'display_name': displayName,
    'is_current_user': isCurrentUser,
    'is_anonymous': isAnonymous,
    'metric_value': metricValue,
    'gap_to_top_ten': gapToTopTen,
  };
}

void main() {
  const malaysiaQuery = LeaderboardQuery(metric: LeaderboardMetric.weeklyXp);

  group('leaderboard privacy gate', () {
    test('does not issue the RPC when the user has not opted in', () async {
      final service = FakeGamificationService(
        profile: const GamificationProfile(
          userId: FakeGamificationService.testUserId,
          totalXp: 1200,
          currentLevel: 3,
          leaderboardOptIn: false,
        ),
        leaderboardEntries: [
          LeaderboardEntry.fromMap(
            leaderboardRow(rank: 1, userId: 'other', metricValue: 900),
          ),
        ],
      );
      final container = createGamificationContainer(service: service);

      final result = await container.read(
        gamificationLeaderboardProvider(malaysiaQuery).future,
      );

      // The web version fires this query regardless of the opt-in flag; the
      // mobile provider must not.
      expect(service.fetchLeaderboardCalls, 0);
      expect(service.requestedMetrics, isEmpty);
      expect(result.optedOut, isTrue);
      expect(result.entries, isEmpty);
    });

    test('issues the RPC once when the user has opted in', () async {
      final service = FakeGamificationService(
        profile: const GamificationProfile(
          userId: FakeGamificationService.testUserId,
          totalXp: 1200,
          currentLevel: 3,
          leaderboardOptIn: true,
        ),
        leaderboardEntries: [
          LeaderboardEntry.fromMap(
            leaderboardRow(rank: 1, userId: 'other', metricValue: 900),
          ),
          LeaderboardEntry.fromMap(
            leaderboardRow(
              rank: 4,
              userId: FakeGamificationService.testUserId,
              isCurrentUser: true,
              metricValue: 640,
            ),
          ),
        ],
      );
      final container = createGamificationContainer(service: service);

      final result = await container.read(
        gamificationLeaderboardProvider(malaysiaQuery).future,
      );

      expect(service.fetchLeaderboardCalls, 1);
      expect(service.requestedMetrics, [LeaderboardMetric.weeklyXp]);
      expect(result.optedOut, isFalse);
      expect(result.entries, hasLength(2));
      expect(result.currentUserEntry?.rank, 4);
    });

    test('scopes the query to Malaysia or the global board', () async {
      final service = FakeGamificationService(
        profile: const GamificationProfile(
          userId: FakeGamificationService.testUserId,
          currentLevel: 3,
          leaderboardOptIn: true,
        ),
      );
      final container = createGamificationContainer(service: service);

      await container.read(
        gamificationLeaderboardProvider(malaysiaQuery).future,
      );
      await container.read(
        gamificationLeaderboardProvider(
          const LeaderboardQuery(
            metric: LeaderboardMetric.deductibleTotal,
            malaysiaOnly: false,
          ),
        ).future,
      );

      expect(service.fetchLeaderboardCalls, 2);
      expect(service.requestedCountryCodes, ['MY', null]);
      expect(service.requestedMetrics.last, LeaderboardMetric.deductibleTotal);
    });

    test('opting in through the privacy write unlocks the board', () async {
      final service = FakeGamificationService(
        profile: const GamificationProfile(
          userId: FakeGamificationService.testUserId,
          currentLevel: 2,
          leaderboardOptIn: false,
        ),
      );
      final container = createGamificationContainer(service: service);

      await container.read(
        gamificationLeaderboardProvider(malaysiaQuery).future,
      );
      expect(service.fetchLeaderboardCalls, 0);

      await container
          .read(gamificationProfileProvider.notifier)
          .updateLeaderboardPreferences(optIn: true);

      await container.read(
        gamificationLeaderboardProvider(malaysiaQuery).future,
      );

      expect(service.fetchLeaderboardCalls, 1);
      expect(service.preferenceWrites.single['leaderboard_opt_in'], isTrue);
      expect(service.preferenceWrites.single['user_id'], 'user-1');
    });

    test('opting out keeps the RPC silent after a previous read', () async {
      final service = FakeGamificationService(
        profile: const GamificationProfile(
          userId: FakeGamificationService.testUserId,
          currentLevel: 2,
          leaderboardOptIn: true,
        ),
      );
      final container = createGamificationContainer(service: service);

      await container.read(
        gamificationLeaderboardProvider(malaysiaQuery).future,
      );
      expect(service.fetchLeaderboardCalls, 1);

      await container
          .read(gamificationProfileProvider.notifier)
          .updateLeaderboardPreferences(optIn: false);

      final result = await container.read(
        gamificationLeaderboardProvider(malaysiaQuery).future,
      );

      expect(service.fetchLeaderboardCalls, 1);
      expect(result.optedOut, isTrue);
    });
  });

  group('leaderboard rows', () {
    test('finds the current user when it sits outside the top ranks', () {
      final result = LeaderboardResult.fromRows(
        metric: LeaderboardMetric.weeklyXp,
        rows: [
          leaderboardRow(rank: 1, userId: 'a', metricValue: 900),
          leaderboardRow(rank: 2, userId: 'b', metricValue: 800),
          leaderboardRow(rank: 3, userId: 'c', metricValue: 700),
          leaderboardRow(rank: 4, userId: 'd', metricValue: 600),
          leaderboardRow(
            rank: 57,
            userId: 'me',
            displayName: 'You',
            isCurrentUser: true,
            metricValue: 120,
            gapToTopTen: 480,
          ),
        ],
      );

      expect(result.podium.map((entry) => entry.rank), [1, 2, 3]);
      expect(result.remainingRanks.map((entry) => entry.rank), [4, 57]);
      expect(result.currentUserEntry?.rank, 57);
      expect(result.currentUserEntry?.userId, 'me');
      expect(result.currentUserEntry?.gapToTopTen, 480);
    });

    test('finds the current user when only that row is returned', () {
      final result = LeaderboardResult.fromRows(
        metric: LeaderboardMetric.monthlyReceipts,
        rows: [
          leaderboardRow(
            rank: 312,
            userId: 'me',
            isCurrentUser: true,
            metricValue: 2,
            gapToTopTen: 18,
          ),
        ],
      );

      expect(result.podium, isEmpty);
      expect(result.remainingRanks, hasLength(1));
      expect(result.currentUserEntry?.rank, 312);
    });

    test('marks anonymous rows and keeps the current-user flag', () {
      final result = LeaderboardResult.fromRows(
        metric: LeaderboardMetric.deductibleTotal,
        rows: [
          leaderboardRow(
            rank: 2,
            userId: 'ghost',
            displayName: 'Anonymous',
            isAnonymous: true,
            metricValue: 1500.75,
          ),
          leaderboardRow(
            rank: 1,
            userId: 'me',
            isCurrentUser: true,
            metricValue: 2000.5,
          ),
        ],
      );

      expect(result.entries.first.isAnonymous, isTrue);
      expect(result.entries.first.metricValue, 1500.75);
      expect(result.entries.last.isCurrentUser, isTrue);
      expect(result.podium.map((entry) => entry.rank), [1, 2]);
      expect(result.remainingRanks, isEmpty);
    });

    test('coerces numeric strings and missing keys', () {
      final result = LeaderboardResult.fromRows(
        metric: LeaderboardMetric.weeklyXp,
        rows: [
          <String, dynamic>{
            'rank': '5',
            'user_id': 'x',
            'metric_value': '42',
            'gap_to_top_ten': null,
          },
        ],
      );

      expect(result.entries.single.rank, 5);
      expect(result.entries.single.metricValue, 42);
      expect(result.entries.single.gapToTopTen, 0);
      expect(result.entries.single.displayName, '');
      expect(result.entries.single.isAnonymous, isFalse);
    });

    test('metric rpc values and currency flags', () {
      expect(LeaderboardMetric.weeklyXp.rpcValue, 'weekly_xp');
      expect(LeaderboardMetric.monthlyReceipts.rpcValue, 'monthly_receipts');
      expect(LeaderboardMetric.deductibleTotal.rpcValue, 'deductible_total');
      expect(LeaderboardMetric.deductibleTotal.isCurrency, isTrue);
      expect(LeaderboardMetric.weeklyXp.isCurrency, isFalse);
    });

    test('the Malaysia board sends MY and the global board sends null', () {
      expect(
        const LeaderboardQuery(metric: LeaderboardMetric.weeklyXp).countryCode,
        'MY',
      );
      expect(
        const LeaderboardQuery(
          metric: LeaderboardMetric.weeklyXp,
          malaysiaOnly: false,
        ).countryCode,
        isNull,
      );
      expect(
        const LeaderboardQuery(metric: LeaderboardMetric.weeklyXp),
        const LeaderboardQuery(metric: LeaderboardMetric.weeklyXp),
      );
    });
  });
}
