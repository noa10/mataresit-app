import 'gamification_json.dart';

/// `mission.missionType` — how the mission is scheduled.
enum MissionType {
  oneTime('one_time'),
  weekly('weekly'),
  community('community');

  const MissionType(this.wireValue);

  /// The value used by the server (`one_time` / `weekly` / `community`).
  final String wireValue;

  /// Tolerant parser: accepts `one_time`, `oneTime` and `one-time`.
  static MissionType fromWire(dynamic raw) {
    switch (raw?.toString().trim().toLowerCase()) {
      case 'weekly':
        return MissionType.weekly;
      case 'community':
        return MissionType.community;
      case 'one_time':
      case 'one-time':
      case 'onetime':
      default:
        return MissionType.oneTime;
    }
  }
}

/// The `mission` JSONB payload of a mission row.
///
/// That payload is camelCase today, but the row wrapping it is snake_case, so
/// every field is read through [GamificationJson.pick] to survive either shape.
class MissionDefinition {
  const MissionDefinition({
    this.id = '',
    this.code = '',
    this.title = '',
    this.description = '',
    this.missionType = MissionType.oneTime,
    this.objectiveType = '',
    this.targetValue = 0,
    this.rewardXp = 0,
    this.startsAt,
    this.endsAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final MissionType missionType;
  final String objectiveType;
  final double targetValue;
  final int rewardXp;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final Map<String, dynamic> metadata;

  factory MissionDefinition.fromMap(Map<String, dynamic> map) {
    return MissionDefinition(
      id: GamificationJson.stringOr(GamificationJson.pick(map, 'id')),
      code: GamificationJson.stringOr(GamificationJson.pick(map, 'code')),
      // Older payloads used `name` instead of `title`.
      title: GamificationJson.stringOr(
        GamificationJson.pick(map, 'title') ??
            GamificationJson.pick(map, 'name'),
      ),
      description: GamificationJson.stringOr(
        GamificationJson.pick(map, 'description'),
      ),
      missionType: MissionType.fromWire(
        GamificationJson.pick(map, 'missionType') ??
            GamificationJson.pick(map, 'type'),
      ),
      objectiveType: GamificationJson.stringOr(
        GamificationJson.pick(map, 'objectiveType'),
      ),
      targetValue: GamificationJson.asDouble(
        GamificationJson.pick(map, 'targetValue'),
      ),
      rewardXp: GamificationJson.asInt(GamificationJson.pick(map, 'rewardXp')),
      startsAt: GamificationJson.asDateTime(
        GamificationJson.pick(map, 'startsAt'),
      ),
      endsAt: GamificationJson.asDateTime(GamificationJson.pick(map, 'endsAt')),
      metadata: GamificationJson.asMap(GamificationJson.pick(map, 'metadata')),
    );
  }
}

/// One row of `get_gamification_missions`: the user's progress plus the mission
/// definition it belongs to.
///
/// There is no claim action in the client — `claimed_at` is set server-side when
/// the mission reward is granted.
class GamificationMission {
  const GamificationMission({
    required this.id,
    required this.missionId,
    this.currentValue = 0,
    this.targetValue = 0,
    this.completedAt,
    this.claimedAt,
    this.mission = const MissionDefinition(),
    this.communityCurrentValue,
    this.communityTargetValue,
    this.communityCompletedAt,
  });

  final String id;
  final String missionId;
  final double currentValue;
  final double targetValue;
  final DateTime? completedAt;
  final DateTime? claimedAt;
  final MissionDefinition mission;
  final double? communityCurrentValue;
  final double? communityTargetValue;
  final DateTime? communityCompletedAt;

  /// Progress value shown for this mission: the community total for community
  /// missions, the personal value otherwise.
  double get effectiveCurrentValue =>
      isCommunity ? (communityCurrentValue ?? currentValue) : currentValue;

  /// Target shown for this mission.
  double get effectiveTargetValue =>
      isCommunity ? (communityTargetValue ?? targetValue) : targetValue;

  bool get isCommunity => mission.missionType == MissionType.community;

  bool get isCompleted =>
      completedAt != null || (isCommunity && communityCompletedAt != null);

  bool get isClaimed => claimedAt != null;

  int get rewardXp => mission.rewardXp;

  MissionType get missionType => mission.missionType;

  double get progressPercent {
    final target = effectiveTargetValue;
    if (target <= 0) return 0;
    return (effectiveCurrentValue / target * 100).clamp(0, 100).toDouble();
  }

  factory GamificationMission.fromMap(Map<String, dynamic> map) {
    return GamificationMission(
      id: GamificationJson.stringOr(GamificationJson.pick(map, 'id')),
      missionId: GamificationJson.stringOr(
        GamificationJson.pick(map, 'mission_id'),
      ),
      currentValue: GamificationJson.asDouble(
        GamificationJson.pick(map, 'current_value'),
      ),
      targetValue: GamificationJson.asDouble(
        GamificationJson.pick(map, 'target_value'),
      ),
      completedAt: GamificationJson.asDateTime(
        GamificationJson.pick(map, 'completed_at'),
      ),
      claimedAt: GamificationJson.asDateTime(
        GamificationJson.pick(map, 'claimed_at'),
      ),
      mission: MissionDefinition.fromMap(
        GamificationJson.asMap(GamificationJson.pick(map, 'mission')),
      ),
      communityCurrentValue: _optionalDouble(
        GamificationJson.pick(map, 'community_current_value'),
      ),
      communityTargetValue: _optionalDouble(
        GamificationJson.pick(map, 'community_target_value'),
      ),
      communityCompletedAt: GamificationJson.asDateTime(
        GamificationJson.pick(map, 'community_completed_at'),
      ),
    );
  }

  static double? _optionalDouble(dynamic value) =>
      value == null ? null : GamificationJson.asDouble(value);

  /// Groups missions by `mission.missionType`, preserving the incoming order
  /// inside each bucket. Every [MissionType] gets an entry, empty when unused, so
  /// the UI can render a fixed set of sections.
  static Map<MissionType, List<GamificationMission>> groupByType(
    Iterable<GamificationMission> missions,
  ) {
    final grouped = <MissionType, List<GamificationMission>>{
      for (final type in MissionType.values) type: <GamificationMission>[],
    };
    for (final mission in missions) {
      grouped[mission.missionType]!.add(mission);
    }
    return grouped;
  }

  static List<GamificationMission> ofType(
    Iterable<GamificationMission> missions,
    MissionType type,
  ) => missions.where((mission) => mission.missionType == type).toList();
}

/// The counters shown above the mission list.
class MissionSummary {
  const MissionSummary({
    this.activeCount = 0,
    this.completedCount = 0,
    this.totalXpEarned = 0,
  });

  final int activeCount;
  final int completedCount;

  /// Reward XP of every mission that has been completed. The reward is granted
  /// server-side on completion, so completed missions are already paid out.
  final int totalXpEarned;

  factory MissionSummary.fromMissions(Iterable<GamificationMission> missions) {
    var active = 0;
    var completed = 0;
    var xp = 0;
    for (final mission in missions) {
      if (mission.isCompleted) {
        completed++;
        xp += mission.rewardXp;
      } else {
        active++;
      }
    }
    return MissionSummary(
      activeCount: active,
      completedCount: completed,
      totalXpEarned: xp,
    );
  }
}

/// Missions grouped by type plus the summary counters for the whole board.
class MissionsBoard {
  const MissionsBoard({required this.grouped, required this.summary});

  const MissionsBoard.empty()
    : grouped = const <MissionType, List<GamificationMission>>{},
      summary = const MissionSummary();

  final Map<MissionType, List<GamificationMission>> grouped;
  final MissionSummary summary;

  factory MissionsBoard.fromMissions(List<GamificationMission> missions) {
    return MissionsBoard(
      grouped: GamificationMission.groupByType(missions),
      summary: MissionSummary.fromMissions(missions),
    );
  }

  List<GamificationMission> missionsOf(MissionType type) =>
      grouped[type] ?? const <GamificationMission>[];

  bool get isEmpty => grouped.values.every((missions) => missions.isEmpty);
}
