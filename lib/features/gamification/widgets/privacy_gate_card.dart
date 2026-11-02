import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shown instead of the leaderboard while the user has not opted in.
///
/// The leaderboard RPC is never issued in that state — see
/// `gamificationLeaderboardProvider` — so this panel explains how to join
/// instead of rendering an empty board.
class PrivacyGateCard extends StatelessWidget {
  const PrivacyGateCard({super.key, required this.onOpenRewards});

  /// Navigates to the Rewards tab, where the opt-in switch lives.
  final VoidCallback onOpenRewards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 22,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'gamification.privacy_gate.title'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'gamification.privacy_gate.message'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onOpenRewards,
                icon: const Icon(Icons.emoji_events_outlined),
                label: Text('gamification.privacy_gate.action'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
