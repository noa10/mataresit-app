import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/gamification/models/mission.dart';

/// Builds a `get_gamification_missions` row (the envelope is snake_case).
Map<String, dynamic> missionRow({
  required String id,
  required Map<String, dynamic> mission,
  num currentValue = 0,
  num targetValue = 1,
  String? completedAt,
  String? claimedAt,
  num? communityCurrentValue,
  num? communityTargetValue,
  String? communityCompletedAt,
}) {
  return <String, dynamic>{
    'id': 'row-$id',
    'mission_id': id,
    'current_value': currentValue,
    'target_value': targetValue,
    'completed_at': completedAt,
    'claimed_at': claimedAt,
    'mission': mission,
    'community_current_value': communityCurrentValue,
    'community_target_value': communityTargetValue,
    'community_completed_at': communityCompletedAt,
  };
}

/// The `mission` JSONB as the RPC sends it today (camelCase).
Map<String, dynamic> camelMission({
  required String id,
  required String type,
  int rewardXp = 100,
  num targetValue = 5,
}) {
  return <String, dynamic>{
    'id': id,
    'code': 'code_$id',
    'title': 'Mission $id',
    'description': 'Description $id',
    'missionType': type,
    'objectiveType': 'receipt_count',
    'targetValue': targetValue,
    'rewardXp': rewardXp,
    'metadata': <String, dynamic>{'difficulty': 'easy'},
  };
}

void main() {
  group('mission parsing', () {
    test('reads the camelCase mission payload the RPC sends today', () {
      final mission = GamificationMission.fromMap(
        missionRow(
          id: 'm-1',
          mission: camelMission(id: 'm-1', type: 'weekly', rewardXp: 120),
          currentValue: 3,
          targetValue: 5,
        ),
      );

      expect(mission.missionId, 'm-1');
      expect(mission.missionType, MissionType.weekly);
      expect(mission.mission.title, 'Mission m-1');
      expect(mission.mission.objectiveType, 'receipt_count');
      expect(mission.rewardXp, 120);
      expect(mission.progressPercent, 60);
      expect(mission.isCompleted, isFalse);
    });

    test('accepts a mission payload that arrives snake_case', () {
      final mission = GamificationMission.fromMap(
        missionRow(
          id: 'm-2',
          currentValue: 5,
          targetValue: 5,
          completedAt: '2026-10-01T10:00:00Z',
          mission: <String, dynamic>{
            'id': 'm-2',
            'code': 'weekly_scan_five',
            'title': 'Scan five receipts',
            'description': 'Scan five receipts this week',
            'mission_type': 'weekly',
            'objective_type': 'receipt_count',
            'target_value': 5,
            'reward_xp': 150,
            'starts_at': '2026-09-28T00:00:00Z',
            'ends_at': '2026-10-05T00:00:00Z',
            'metadata': <String, dynamic>{'difficulty': 'medium'},
          },
        ),
      );

      expect(mission.missionType, MissionType.weekly);
      expect(mission.mission.title, 'Scan five receipts');
      expect(mission.mission.description, 'Scan five receipts this week');
      expect(mission.mission.objectiveType, 'receipt_count');
      expect(mission.mission.targetValue, 5);
      expect(mission.mission.rewardXp, 150);
      expect(mission.mission.startsAt, isNotNull);
      expect(mission.mission.endsAt, isNotNull);
      expect(mission.mission.metadata['difficulty'], 'medium');
      expect(mission.isCompleted, isTrue);
      expect(mission.progressPercent, 100);
    });

    test('accepts the oneTime spelling and falls back to one-time', () {
      expect(MissionType.fromWire('oneTime'), MissionType.oneTime);
      expect(MissionType.fromWire('one_time'), MissionType.oneTime);
      expect(MissionType.fromWire('ONE-TIME'), MissionType.oneTime);
      expect(MissionType.fromWire('community'), MissionType.community);
      expect(MissionType.fromWire(null), MissionType.oneTime);
      expect(MissionType.fromWire('something_else'), MissionType.oneTime);
    });

    test('community missions report the community counters', () {
      final mission = GamificationMission.fromMap(
        missionRow(
          id: 'm-3',
          currentValue: 1,
          targetValue: 5,
          communityCurrentValue: 40,
          communityTargetValue: 100,
          mission: camelMission(id: 'm-3', type: 'community', targetValue: 100),
        ),
      );

      expect(mission.isCommunity, isTrue);
      expect(mission.effectiveCurrentValue, 40);
      expect(mission.effectiveTargetValue, 100);
      expect(mission.progressPercent, 40);
    });

    test(
      'community completion is recognised through community_completed_at',
      () {
        final mission = GamificationMission.fromMap(
          missionRow(
            id: 'm-4',
            communityCurrentValue: 100,
            communityTargetValue: 100,
            communityCompletedAt: '2026-10-10T10:00:00Z',
            mission: camelMission(
              id: 'm-4',
              type: 'community',
              targetValue: 100,
            ),
          ),
        );

        expect(mission.isCompleted, isTrue);
        expect(mission.completedAt, isNull);
      },
    );

    test('a zero target does not divide by zero', () {
      final mission = GamificationMission.fromMap(
        missionRow(
          id: 'm-5',
          targetValue: 0,
          mission: camelMission(id: 'm-5', type: 'one_time', targetValue: 0),
        ),
      );

      expect(mission.progressPercent, 0);
    });
  });

  group('mission grouping', () {
    test('groups by mission.missionType', () {
      final board = MissionsBoard.fromMissions([
        GamificationMission.fromMap(
          missionRow(
            id: 'a',
            mission: camelMission(id: 'a', type: 'one_time'),
          ),
        ),
        GamificationMission.fromMap(
          missionRow(
            id: 'b',
            mission: camelMission(id: 'b', type: 'weekly'),
          ),
        ),
        GamificationMission.fromMap(
          missionRow(
            id: 'c',
            mission: camelMission(id: 'c', type: 'community'),
          ),
        ),
        GamificationMission.fromMap(
          missionRow(
            id: 'd',
            mission: <String, dynamic>{
              'id': 'd',
              'title': 'Snake case one-time',
              'mission_type': 'one_time',
              'target_value': 1,
              'reward_xp': 50,
            },
          ),
        ),
      ]);

      expect(board.missionsOf(MissionType.oneTime), hasLength(2));
      expect(board.missionsOf(MissionType.weekly), hasLength(1));
      expect(board.missionsOf(MissionType.community), hasLength(1));
      expect(board.isEmpty, isFalse);
    });

    test('every mission type has a bucket even when empty', () {
      final grouped = GamificationMission.groupByType(const []);

      expect(grouped.keys, containsAll(MissionType.values));
      expect(grouped[MissionType.weekly], isEmpty);
    });

    test('an empty board reports itself as empty', () {
      final board = MissionsBoard.fromMissions(const []);

      expect(board.isEmpty, isTrue);
      expect(board.summary.activeCount, 0);
      expect(board.summary.completedCount, 0);
      expect(board.summary.totalXpEarned, 0);
    });

    test('summarises active, completed and reward XP', () {
      final board = MissionsBoard.fromMissions([
        GamificationMission.fromMap(
          missionRow(
            id: 'a',
            completedAt: '2026-10-01T10:00:00Z',
            claimedAt: '2026-10-01T10:05:00Z',
            mission: camelMission(id: 'a', type: 'one_time', rewardXp: 100),
          ),
        ),
        GamificationMission.fromMap(
          missionRow(
            id: 'b',
            completedAt: '2026-10-02T10:00:00Z',
            mission: camelMission(id: 'b', type: 'weekly', rewardXp: 250),
          ),
        ),
        GamificationMission.fromMap(
          missionRow(
            id: 'c',
            mission: camelMission(id: 'c', type: 'weekly', rewardXp: 300),
          ),
        ),
      ]);

      expect(board.summary.completedCount, 2);
      expect(board.summary.activeCount, 1);
      expect(board.summary.totalXpEarned, 350);
    });

    test('claimed_at is surfaced but never set by the client', () {
      final mission = GamificationMission.fromMap(
        missionRow(
          id: 'a',
          completedAt: '2026-10-01T10:00:00Z',
          claimedAt: '2026-10-01T10:05:00Z',
          mission: camelMission(id: 'a', type: 'one_time'),
        ),
      );

      expect(mission.isCompleted, isTrue);
      expect(mission.isClaimed, isTrue);
    });
  });
}
