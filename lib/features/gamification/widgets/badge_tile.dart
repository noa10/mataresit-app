import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/date_utils.dart';
import '../models/badge.dart';

/// One badge in the rewards grid.
///
/// The `equipped` flag is read-only: the backend has no equip RPC and
/// `user_badges` only exposes a SELECT policy, so there is no equip action here.
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge});

  final BadgeWithStatus badge;

  /// Maps the catalogue's `icon_name` onto a Material icon.
  static const Map<String, IconData> _icons = {
    'emoji_events': Icons.emoji_events,
    'workspace_premium': Icons.workspace_premium,
    'military_tech': Icons.military_tech,
    'local_fire_department': Icons.local_fire_department,
    'receipt_long': Icons.receipt_long,
    'receipt': Icons.receipt,
    'star': Icons.star,
    'verified': Icons.verified,
    'bolt': Icons.bolt,
    'flag': Icons.flag,
    'school': Icons.school,
    'group': Icons.group,
    'card_giftcard': Icons.card_giftcard,
    'savings': Icons.savings,
    'trending_up': Icons.trending_up,
    'calendar_month': Icons.calendar_month,
  };

  static const Map<BadgeRarity, Color> _rarityColors = {
    BadgeRarity.common: Color(0xFF6B7280),
    BadgeRarity.rare: Color(0xFF2563EB),
    BadgeRarity.epic: Color(0xFF7C3AED),
    BadgeRarity.legendary: Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = badge.isUnlocked;
    final rarityColor =
        _rarityColors[badge.rarity] ?? _rarityColors[BadgeRarity.common]!;
    final title = badge.name.isEmpty
        ? 'gamification.badges.unknown'.tr()
        : badge.name;
    final unlockedAt = badge.unlockedAt;

    final tile = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: unlocked ? 0.18 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icons[badge.iconName] ?? Icons.emoji_events_outlined,
                size: 24,
                color: unlocked ? rarityColor : theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.rarity.labelKey.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: rarityColor),
            ),
            const SizedBox(height: 2),
            if (!unlocked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      'gamification.badges.locked'.tr(),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              )
            else
              Flexible(
                child: Text(
                  badge.isEquipped
                      ? 'gamification.badges.equipped'.tr()
                      : unlockedAt == null
                      ? 'gamification.badges.unlocked'.tr()
                      : 'gamification.badges.unlocked_on'.tr(
                          namedArgs: {
                            'date': AppDateUtils.formatDisplayDate(unlockedAt),
                          },
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (badge.description.isEmpty) return tile;
    return Tooltip(message: badge.description, child: tile);
  }
}
