import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    mission.mission.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.smallPadding,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'gamification.missions.reward_xp'.tr(
                      namedArgs: {'xp': '${mission.rewardXp}'},
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (mission.mission.description.isNotEmpty) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                mission.mission.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.defaultPadding),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: LinearProgressIndicator(
                value: mission.progressPercent / 100,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (isCompleted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _completedLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
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
