import 'gamification_json.dart';

/// `gamification_badges.rarity`.
enum BadgeRarity {
  common('common'),
  rare('rare'),
  epic('epic'),
  legendary('legendary');

  const BadgeRarity(this.wireValue);

  final String wireValue;

  String get labelKey => 'gamification.badges.rarity.$wireValue';

  static BadgeRarity fromWire(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase();
    for (final rarity in BadgeRarity.values) {
      if (rarity.wireValue == value) return rarity;
    }
    return BadgeRarity.common;
  }
}

/// A row of the `gamification_badges` catalogue.
class GamificationBadge {
  const GamificationBadge({
    required this.id,
    this.code = '',
    this.name = '',
    this.description = '',
    this.iconName = 'emoji_events',
    this.category = 'onboarding',
    this.rarity = BadgeRarity.common,
    this.sortOrder = 0,
    this.criteria = const <String, dynamic>{},
    this.isActive = true,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String iconName;
  final String category;
  final BadgeRarity rarity;
  final int sortOrder;
  final Map<String, dynamic> criteria;
  final bool isActive;

  factory GamificationBadge.fromMap(Map<String, dynamic> map) {
    return GamificationBadge(
      id: GamificationJson.stringOr(GamificationJson.pick(map, 'id')),
      code: GamificationJson.stringOr(GamificationJson.pick(map, 'code')),
      name: GamificationJson.stringOr(GamificationJson.pick(map, 'name')),
      description: GamificationJson.stringOr(
        GamificationJson.pick(map, 'description'),
      ),
      iconName: GamificationJson.stringOr(
        GamificationJson.pick(map, 'icon_name'),
        'emoji_events',
      ),
      category: GamificationJson.stringOr(
        GamificationJson.pick(map, 'category'),
        'onboarding',
      ),
      rarity: BadgeRarity.fromWire(GamificationJson.pick(map, 'rarity')),
      sortOrder: GamificationJson.asInt(
        GamificationJson.pick(map, 'sort_order'),
      ),
      criteria: GamificationJson.asMap(GamificationJson.pick(map, 'criteria')),
      isActive: GamificationJson.asBool(
        GamificationJson.pick(map, 'is_active'),
        fallback: true,
      ),
    );
  }
}

/// A row of `user_badges` — an unlocked badge for one user.
///
/// `equipped` is read-only here: the backend has no equip RPC and `user_badges`
/// only exposes a SELECT policy, so clients cannot change it.
class UserBadge {
  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    this.sourceEventId,
    this.equipped = false,
    this.metadata = const <String, dynamic>{},
    this.unlockedAt,
  });

  final String id;
  final String userId;
  final String badgeId;
  final String? sourceEventId;
  final bool equipped;
  final Map<String, dynamic> metadata;
  final DateTime? unlockedAt;

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      id: GamificationJson.stringOr(GamificationJson.pick(map, 'id')),
      userId: GamificationJson.stringOr(GamificationJson.pick(map, 'user_id')),
      badgeId: GamificationJson.stringOr(
        GamificationJson.pick(map, 'badge_id'),
      ),
      sourceEventId: GamificationJson.asString(
        GamificationJson.pick(map, 'source_event_id'),
      ),
      equipped: GamificationJson.asBool(GamificationJson.pick(map, 'equipped')),
      metadata: GamificationJson.asMap(GamificationJson.pick(map, 'metadata')),
      unlockedAt: GamificationJson.asDateTime(
        GamificationJson.pick(map, 'unlocked_at'),
      ),
    );
  }
}

/// A catalogue badge joined with the user's unlock row.
class BadgeWithStatus {
  const BadgeWithStatus({this.definition, this.userBadge});

  /// `null` when the unlock row references a badge definition that is missing
  /// (deactivated or deleted) — the tile then falls back to a generic look.
  final GamificationBadge? definition;
  final UserBadge? userBadge;

  bool get isUnlocked => userBadge != null;

  /// Read-only: equipping has no backend support.
  bool get isEquipped => userBadge?.equipped ?? false;

  String get id => definition?.id ?? userBadge?.badgeId ?? '';
  String get name => definition?.name ?? '';
  String get description => definition?.description ?? '';
  String get iconName => definition?.iconName ?? 'emoji_events';
  String get category => definition?.category ?? 'onboarding';
  BadgeRarity get rarity => definition?.rarity ?? BadgeRarity.common;

  DateTime? get unlockedAt => userBadge?.unlockedAt;
}

/// Joins the badge catalogue with the user's unlock rows, client-side.
///
/// There is no joined view and no RPC for badges: `gamification_badges` (active
/// only) and `user_badges` are read separately and merged here by badge id.
///
/// Ordering: unlocked badges first (most recently unlocked first), then locked
/// badges by catalogue `sort_order`, then unlock rows whose definition is
/// missing — kept so an orphaned row is visible instead of crashing the grid.
class BadgeCollection {
  const BadgeCollection._();

  static List<BadgeWithStatus> join({
    required List<GamificationBadge> definitions,
    required List<UserBadge> userBadges,
  }) {
    final unlocksByBadgeId = <String, UserBadge>{};
    for (final userBadge in userBadges) {
      unlocksByBadgeId[userBadge.badgeId] = userBadge;
    }

    final knownIds = definitions.map((definition) => definition.id).toSet();

    final joined = <BadgeWithStatus>[];
    for (final definition in definitions) {
      joined.add(
        BadgeWithStatus(
          definition: definition,
          userBadge: unlocksByBadgeId[definition.id],
        ),
      );
    }

    final unlocked = joined.where((badge) => badge.isUnlocked).toList()
      ..sort((a, b) => _compareUnlockedAt(a.unlockedAt, b.unlockedAt));
    final locked = joined.where((badge) => !badge.isUnlocked).toList()
      ..sort(
        (a, b) => (a.definition?.sortOrder ?? 0).compareTo(
          b.definition?.sortOrder ?? 0,
        ),
      );

    final orphans =
        userBadges
            .where((userBadge) => !knownIds.contains(userBadge.badgeId))
            .map((userBadge) => BadgeWithStatus(userBadge: userBadge))
            .toList()
          ..sort((a, b) => _compareUnlockedAt(a.unlockedAt, b.unlockedAt));

    return <BadgeWithStatus>[...unlocked, ...locked, ...orphans];
  }

  /// Most recent first; a missing timestamp sorts last.
  static int _compareUnlockedAt(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
