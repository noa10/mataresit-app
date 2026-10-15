import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../gamification/models/gamification_profile.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/screens/leaderboard_screen.dart';
import '../../gamification/screens/missions_screen.dart';
import '../../gamification/widgets/badge_tile.dart';
import '../../gamification/widgets/referral_card.dart';
import '../../gamification/widgets/xp_progress_card.dart';

/// The Rewards tab: XP and level, streaks, missions, badges, referral and the
/// leaderboard privacy controls.
///
/// Owns its scrolling (the other profile tabs are wrapped by the profile screen)
/// so the grid and the pull-to-refresh stay in one place.
class ProfileRewards extends ConsumerWidget {
  const ProfileRewards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(gamificationProfileProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gamificationProfileProvider.notifier).refresh();
        await ref.read(gamificationBadgesProvider.notifier).refresh();
      },
      child: profileState.when(
        loading: () => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: LoadingWidget(message: 'gamification.rewards.loading'.tr()),
        ),
        error: (error, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: AppErrorWidget(
            error: error.toString(),
            title: 'gamification.error.title'.tr(),
            onRetry: () =>
                ref.read(gamificationProfileProvider.notifier).refresh(),
          ),
        ),
        data: (profile) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              XpProgressCard(profile: profile),
              const SizedBox(height: AppConstants.defaultPadding),
              _StreaksCard(profile: profile),
              const SizedBox(height: AppConstants.defaultPadding),
              _DailyGoalCard(profile: profile),
              const SizedBox(height: AppConstants.defaultPadding),
              const _SectionLinks(),
              const SizedBox(height: AppConstants.defaultPadding),
              ReferralCard(profile: profile),
              const SizedBox(height: AppConstants.defaultPadding),
              const _BadgesSection(),
              const SizedBox(height: AppConstants.defaultPadding),
              _PrivacyControls(profile: profile),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entries into the missions and leaderboard screens.
class _SectionLinks extends StatelessWidget {
  const _SectionLinks();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MissionsScreen()),
            ),
            icon: const Icon(Icons.flag_outlined),
            label: Text('gamification.actions.missions'.tr()),
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LeaderboardScreen(),
              ),
            ),
            icon: const Icon(Icons.leaderboard_outlined),
            label: Text('gamification.actions.leaderboard'.tr()),
          ),
        ),
      ],
    );
  }
}

/// Login and scan streaks, current and longest.
class _StreaksCard extends StatelessWidget {
  const _StreaksCard({required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'gamification.streaks.title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _StreakRow(
              icon: Icons.login,
              label: 'gamification.streaks.login'.tr(),
              value: profile.loginStreakDays,
              longestLabel: 'gamification.streaks.longest_login'.tr(),
              longestValue: profile.longestLoginStreakDays,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            _StreakRow(
              icon: Icons.document_scanner_outlined,
              label: 'gamification.streaks.scan'.tr(),
              value: profile.scanStreakDays,
              longestLabel: 'gamification.streaks.longest_scan'.tr(),
              longestValue: profile.longestScanStreakDays,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.longestLabel,
    required this.longestValue,
  });

  final IconData icon;
  final String label;
  final int value;
  final String longestLabel;
  final int longestValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                longestLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'gamification.streaks.days'.tr(namedArgs: {'count': '$value'}),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'gamification.streaks.days'.tr(
                namedArgs: {'count': '$longestValue'},
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Whether the user has scanned a receipt today.
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = profile.isDailyGoalCompleted();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'gamification.daily_goal.title'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completed
                        ? 'gamification.daily_goal.completed'.tr()
                        : 'gamification.daily_goal.pending'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The unlocked/locked badge grid (client-side join of catalogue and unlocks).
class _BadgesSection extends ConsumerWidget {
  const _BadgesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final badgesState = ref.watch(gamificationBadgesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'gamification.badges.title'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'gamification.actions.refresh'.tr(),
              onPressed: () =>
                  ref.read(gamificationBadgesProvider.notifier).refresh(),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        badgesState.when(
          loading: () => const LoadingWidget(),
          error: (error, _) => AppErrorWidget(
            error: error.toString(),
            title: 'gamification.error.title'.tr(),
            onRetry: () =>
                ref.read(gamificationBadgesProvider.notifier).refresh(),
          ),
          data: (badges) => badges.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.emoji_events_outlined,
                  title: 'gamification.badges.empty_title'.tr(),
                  message: 'gamification.badges.empty'.tr(),
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 0.72,
                  mainAxisSpacing: AppConstants.smallPadding,
                  crossAxisSpacing: AppConstants.smallPadding,
                  children: [
                    for (final badge in badges) BadgeTile(badge: badge),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Leaderboard participation switch and the display-mode toggle.
class _PrivacyControls extends ConsumerStatefulWidget {
  const _PrivacyControls({required this.profile});

  final GamificationProfile profile;

  @override
  ConsumerState<_PrivacyControls> createState() => _PrivacyControlsState();
}

class _PrivacyControlsState extends ConsumerState<_PrivacyControls> {
  bool _isSaving = false;

  Future<void> _save({bool? optIn, String? displayMode}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(gamificationProfileProvider.notifier)
          .updateLeaderboardPreferences(optIn: optIn, displayMode: displayMode);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('gamification.privacy.save_failed'.tr())),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optedIn = widget.profile.leaderboardOptIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'gamification.privacy.title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('gamification.privacy.opt_in'.tr()),
              subtitle: Text('gamification.privacy.opt_in_description'.tr()),
              value: optedIn,
              onChanged: _isSaving ? null : (value) => _save(optIn: value),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'gamification.privacy.display_mode'.tr(),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(
                  value: GamificationProfile.displayModeAnonymous,
                  label: Text(
                    'gamification.privacy.display_modes.anonymous'.tr(),
                  ),
                ),
                ButtonSegment<String>(
                  value: GamificationProfile.displayModeName,
                  label: Text('gamification.privacy.display_modes.name'.tr()),
                ),
              ],
              selected: <String>{widget.profile.leaderboardDisplayMode},
              // Disabled while opted out: a display mode has no meaning then.
              onSelectionChanged: optedIn && !_isSaving
                  ? (selection) => _save(displayMode: selection.first)
                  : null,
            ),
            if (!optedIn) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'gamification.privacy.opt_out_hint'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
