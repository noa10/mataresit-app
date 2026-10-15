import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/gamification/models/badge.dart';

Map<String, dynamic> definitionRow({
  required String id,
  String name = 'Badge',
  int sortOrder = 0,
  String rarity = 'common',
  String category = 'onboarding',
  String iconName = 'emoji_events',
  bool isActive = true,
}) {
  return <String, dynamic>{
    'id': id,
    'code': 'code_$id',
    'name': name,
    'description': 'Unlocked for $name',
    'icon_name': iconName,
    'category': category,
    'rarity': rarity,
    'sort_order': sortOrder,
    'criteria': <String, dynamic>{'threshold': 1},
    'is_active': isActive,
  };
}

Map<String, dynamic> unlockRow({
  required String badgeId,
  String id = 'unlock-1',
  bool equipped = false,
  String? unlockedAt = '2026-10-01T10:00:00Z',
}) {
  return <String, dynamic>{
    'id': id,
    'user_id': 'user-1',
    'badge_id': badgeId,
    'source_event_id': null,
    'equipped': equipped,
    'metadata': <String, dynamic>{},
    'unlocked_at': unlockedAt,
  };
}

void main() {
  group('badge parsing', () {
    test('reads the catalogue row', () {
      final badge = GamificationBadge.fromMap(
        definitionRow(
          id: 'b-1',
          name: 'First Scan',
          rarity: 'rare',
          category: 'onboarding',
          sortOrder: 1,
        ),
      );

      expect(badge.id, 'b-1');
      expect(badge.name, 'First Scan');
      expect(badge.rarity, BadgeRarity.rare);
      expect(badge.category, 'onboarding');
      expect(badge.sortOrder, 1);
      expect(badge.isActive, isTrue);
    });

    test('falls back to common for an unknown rarity', () {
      expect(BadgeRarity.fromWire('mythic'), BadgeRarity.common);
      expect(BadgeRarity.fromWire(null), BadgeRarity.common);
      expect(BadgeRarity.fromWire('LEGENDARY'), BadgeRarity.legendary);
    });

    test('reads the unlock row', () {
      final unlock = UserBadge.fromMap(
        unlockRow(badgeId: 'b-1', equipped: true),
      );

      expect(unlock.badgeId, 'b-1');
      expect(unlock.userId, 'user-1');
      expect(unlock.equipped, isTrue);
      expect(unlock.unlockedAt, DateTime.utc(2026, 10, 1, 10));
    });
  });

  group('client-side badge join', () {
    test('joins the catalogue with the user unlocks by badge id', () {
      final joined = BadgeCollection.join(
        definitions: [
          GamificationBadge.fromMap(
            definitionRow(id: 'b-1', name: 'First Scan', sortOrder: 1),
          ),
          GamificationBadge.fromMap(
            definitionRow(id: 'b-2', name: 'Streak Starter', sortOrder: 2),
          ),
        ],
        userBadges: [
          UserBadge.fromMap(
            unlockRow(
              badgeId: 'b-1',
              equipped: true,
              unlockedAt: '2026-10-01T10:00:00Z',
            ),
          ),
        ],
      );

      expect(joined, hasLength(2));
      // Unlocked first, then the locked badge.
      expect(joined.first.id, 'b-1');
      expect(joined.first.isUnlocked, isTrue);
      expect(joined.first.isEquipped, isTrue);
      expect(joined.last.id, 'b-2');
      expect(joined.last.isUnlocked, isFalse);
      expect(joined.last.userBadge, isNull);
      // Equipping is read-only: the flag is only ever read from the row.
      expect(joined.last.isEquipped, isFalse);
    });

    test('keeps an unlock whose badge definition is missing', () {
      final joined = BadgeCollection.join(
        definitions: [
          GamificationBadge.fromMap(definitionRow(id: 'b-1', sortOrder: 1)),
        ],
        userBadges: [
          UserBadge.fromMap(unlockRow(badgeId: 'b-1')),
          UserBadge.fromMap(
            unlockRow(
              id: 'unlock-2',
              badgeId: 'deleted-badge',
              unlockedAt: '2026-10-02T10:00:00Z',
            ),
          ),
        ],
      );

      expect(joined, hasLength(2));

      final orphan = joined.firstWhere((badge) => badge.definition == null);
      expect(orphan.id, 'deleted-badge');
      expect(orphan.isUnlocked, isTrue);
      // Null-safe fallbacks instead of a crash.
      expect(orphan.name, '');
      expect(orphan.description, '');
      expect(orphan.iconName, 'emoji_events');
      expect(orphan.rarity, BadgeRarity.common);
      expect(orphan.category, 'onboarding');

      // The orphan is unlocked, so it sorts with the unlocked badges.
      expect(orphan.unlockedAt, DateTime.utc(2026, 10, 2, 10));
    });

    test(
      'orders unlocked badges by most recent unlock, then catalogue order',
      () {
        final joined = BadgeCollection.join(
          definitions: [
            GamificationBadge.fromMap(definitionRow(id: 'b-1', sortOrder: 1)),
            GamificationBadge.fromMap(definitionRow(id: 'b-2', sortOrder: 2)),
            GamificationBadge.fromMap(definitionRow(id: 'b-3', sortOrder: 3)),
          ],
          userBadges: [
            UserBadge.fromMap(
              unlockRow(
                id: 'unlock-1',
                badgeId: 'b-1',
                unlockedAt: '2026-09-01T10:00:00Z',
              ),
            ),
            UserBadge.fromMap(
              unlockRow(
                id: 'unlock-2',
                badgeId: 'b-3',
                unlockedAt: '2026-10-05T10:00:00Z',
              ),
            ),
          ],
        );

        expect(joined.map((badge) => badge.id), ['b-3', 'b-1', 'b-2']);
      },
    );

    test('an empty join returns nothing', () {
      expect(
        BadgeCollection.join(definitions: const [], userBadges: const []),
        isEmpty,
      );
    });
  });
}
