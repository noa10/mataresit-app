import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Shown instead of the leaderboard while the user has not opted in.
///
/// The leaderboard RPC is never issued in that state — see
/// `gamificationLeaderboardProvider` — so this card explains how to join instead
/// of rendering an empty board.
class PrivacyGateCard extends StatelessWidget {
  const PrivacyGateCard({super.key, required this.onOpenRewards});

  /// Navigates to the Rewards tab, where the opt-in switch lives.
  final VoidCallback onOpenRewards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'gamification.privacy_gate.title'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'gamification.privacy_gate.message'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConstants.largePadding),
                FilledButton.icon(
                  onPressed: onOpenRewards,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: Text('gamification.privacy_gate.action'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
