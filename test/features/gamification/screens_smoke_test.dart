import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/auth/providers/auth_provider.dart';
import 'package:mataresit_app/features/gamification/models/gamification_profile.dart';
import 'package:mataresit_app/features/gamification/models/leaderboard_entry.dart';
import 'package:mataresit_app/features/gamification/models/mission.dart';
import 'package:mataresit_app/features/gamification/screens/leaderboard_screen.dart';
import 'package:mataresit_app/features/gamification/screens/missions_screen.dart';
import 'package:mataresit_app/features/gamification/services/gamification_service.dart';
import 'package:mataresit_app/features/gamification/widgets/mission_tile.dart';
import 'package:mataresit_app/features/gamification/widgets/privacy_gate_card.dart';
import 'package:mataresit_app/shared/models/user_model.dart';

import 'fake_gamification_service.dart';

Widget _wrap(FakeGamificationService service, Widget child) {
  return ProviderScope(
    overrides: [
      gamificationServiceProvider.overrideWithValue(service),
      currentUserProvider.overrideWithValue(
        UserModel(
          id: FakeGamificationService.testUserId,
          email: 'reward-tester@example.com',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

/// One mission per type: two in progress, the community one completed.
final List<GamificationMission> _seedMissions = [
  GamificationMission(
    id: 'row-1',
    missionId: 'm-one',
    currentValue: 3,
    targetValue: 5,
    mission: MissionDefinition(
      id: 'm-one',
      code: 'SCAN5',
      title: 'Scan five receipts',
      missionType: MissionType.oneTime,
      targetValue: 5,
      rewardXp: 100,
    ),
  ),
  GamificationMission(
    id: 'row-2',
    missionId: 'm-weekly',
    currentValue: 1,
    targetValue: 7,
    mission: MissionDefinition(
      id: 'm-weekly',
      code: 'LOGIN7',
      title: 'Log in seven days',
      missionType: MissionType.weekly,
      targetValue: 7,
      rewardXp: 150,
    ),
  ),
  GamificationMission(
    id: 'row-3',
    missionId: 'm-comm',
    communityCurrentValue: 1250,
    communityTargetValue: 1000,
    communityCompletedAt: DateTime.utc(2026, 10, 30),
    mission: MissionDefinition(
      id: 'm-comm',
      code: 'DRIVE',
      title: 'Community scan drive',
      missionType: MissionType.community,
      targetValue: 1000,
      rewardXp: 200,
    ),
  ),
];

/// A full board: the podium plus the current user just outside the top three.
const List<LeaderboardEntry> _seedEntries = [
  LeaderboardEntry(
    rank: 1,
    userId: 'u-a',
    displayName: 'Mamak MVP',
    metricValue: 4800,
  ),
  LeaderboardEntry(
    rank: 2,
    userId: 'u-b',
    displayName: 'Receipt Runner',
    metricValue: 3900,
  ),
  LeaderboardEntry(
    rank: 3,
    userId: 'u-c',
    displayName: 'Ledger Legend',
    metricValue: 3100,
  ),
  LeaderboardEntry(
    rank: 4,
    userId: FakeGamificationService.testUserId,
    displayName: 'Reward Tester',
    isCurrentUser: true,
    metricValue: 2450,
  ),
];

/// Layout smoke tests for the rewards screens.
///
/// These pump the real screens so their ledger rows are laid out under widget
/// test constraints — a Row with `CrossAxisAlignment.stretch` placed directly
/// under an unbounded-height parent throws, and only a layout pass catches it.
void main() {
  group('MissionsScreen', () {
    testWidgets('renders summary tiles and the one-time mission list', (
      tester,
    ) async {
      final service = FakeGamificationService(missions: _seedMissions);

      await tester.pumpWidget(_wrap(service, const MissionsScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The one-time tab opens first, so its mission tile is on screen.
      expect(find.byType(MissionTile), findsOneWidget);
      expect(find.text('Scan five receipts'), findsOneWidget);
      // Summary counters: two active missions, one completed.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(service.fetchMissionsCalls, 1);
    });

    testWidgets('shows the empty state when no missions exist', (tester) async {
      final service = FakeGamificationService();

      await tester.pumpWidget(_wrap(service, const MissionsScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MissionTile), findsNothing);
      expect(find.text('gamification.missions.empty_title'), findsOneWidget);
    });
  });

  group('LeaderboardScreen', () {
    testWidgets('renders podium, rank table and your rank when opted in', (
      tester,
    ) async {
      final service = FakeGamificationService(
        profile: const GamificationProfile(
          userId: FakeGamificationService.testUserId,
          currentLevel: 3,
          leaderboardOptIn: true,
        ),
        leaderboardEntries: _seedEntries,
      );

      await tester.pumpWidget(_wrap(service, const LeaderboardScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mamak MVP'), findsOneWidget);
      expect(find.text('Receipt Runner'), findsOneWidget);
      expect(find.text('Ledger Legend'), findsOneWidget);
      // The rank table sits below the fold; scroll it into view.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Reward Tester'), findsOneWidget);
      // The initial board is the Malaysian weekly XP ranking.
      expect(service.fetchLeaderboardCalls, 1);
      expect(service.requestedMetrics.single, LeaderboardMetric.weeklyXp);
      expect(service.requestedCountryCodes.single, 'MY');
    });

    testWidgets(
      'shows the privacy gate and never calls the RPC when opted out',
      (tester) async {
        final service = FakeGamificationService(
          profile: const GamificationProfile(
            userId: FakeGamificationService.testUserId,
            currentLevel: 1,
          ),
          leaderboardEntries: _seedEntries,
        );

        await tester.pumpWidget(_wrap(service, const LeaderboardScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(PrivacyGateCard), findsOneWidget);
        expect(find.text('Mamak MVP'), findsNothing);
        expect(service.fetchLeaderboardCalls, 0);
      },
    );
  });
}
