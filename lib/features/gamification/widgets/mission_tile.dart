import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/utils/date_utils.dart';
import '../models/mission.dart';

/// A single mission with its progress bar.
///
/// There is no claim action: the reward is granted and `claimed_at` is stamped
/// server-side, so the tile only reports status.
class MissionTile extends StatelessWidget {
  const MissionTile({super.key, required this.mission});

  final GamificationMission mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = mission.isCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  mission.isCommunity
                      ? Icons.groups_outlined
                      : Icons.flag_outlined,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.mission.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (mission.mission.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mission.mission.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'gamification.missions.reward_xp'.tr(
                    namedArgs: {'xp': '${mission.rewardXp}'},
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: mission.progressPercent / 100,
              minHeight: 5,
              backgroundColor: colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.isCommunity
                      ? 'gamification.missions.community_progress'.tr(
                          namedArgs: {
                            'current': _formatValue(
                              mission.effectiveCurrentValue,
                            ),
                            'target': _formatValue(
                              mission.effectiveTargetValue,
                            ),
                          },
                        )
                      : 'gamification.missions.progress'.tr(
                          namedArgs: {
                            'current': _formatValue(mission.currentValue),
                            'target': _formatValue(mission.targetValue),
                          },
                        ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 14, color: colorScheme.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _completedLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _completedLabel() {
    final completedAt = mission.completedAt ?? mission.communityCompletedAt;
    if (completedAt == null) {
      return 'gamification.missions.completed'.tr();
    }
    return 'gamification.missions.completed_on'.tr(
      namedArgs: {'date': AppDateUtils.formatDisplayDate(completedAt)},
    );
  }

  /// Mission values are numeric; show whole numbers without a trailing `.0`.
  static String _formatValue(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}
