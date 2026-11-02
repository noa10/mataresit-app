import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/mission.dart';
import '../providers/gamification_provider.dart';
import '../widgets/mission_tile.dart';

/// Missions grouped into one-time, weekly and community sections.
class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with SingleTickerProviderStateMixin {
  // Created eagerly: a lazy `late final` here would first run during dispose()
  // on an empty board (no tab bar ever built), creating a ticker on a
  // deactivated widget.
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: MissionType.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missionsState = ref.watch(gamificationMissionsProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          Expanded(
            child: missionsState.when(
              loading: () =>
                  LoadingWidget(message: 'gamification.missions.loading'.tr()),
              error: (error, _) => AppErrorWidget(
                error: error.toString(),
                title: 'gamification.error.title'.tr(),
                onRetry: () =>
                    ref.read(gamificationMissionsProvider.notifier).refresh(),
              ),
              data: (board) =>
                  board.isEmpty ? _buildEmpty() : _buildBoard(board),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back',
            style: IconButton.styleFrom(foregroundColor: colors.onSurface),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REWARDS LEDGER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'gamification.missions.title'.tr(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFamily: 'InstrumentSerif',
                      fontSize: 32,
                      height: 1.05,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track one-time, weekly and community missions tied to '
                    'your rewards progress.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'gamification.actions.refresh'.tr(),
            onPressed: () =>
                ref.read(gamificationMissionsProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return EmptyStateWidget(
      icon: Icons.flag_outlined,
      title: 'gamification.missions.empty_title'.tr(),
      message: 'gamification.missions.empty'.tr(),
    );
  }

  Widget _buildBoard(MissionsBoard board) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: _MissionSummary(summary: board.summary),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _TypeFilterPills(controller: _tabController),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final type in MissionType.values)
                _buildMissionList(board.missionsOf(type)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissionList(List<GamificationMission> missions) {
    if (missions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.flag_outlined,
        title: 'gamification.missions.empty_group_title'.tr(),
        message: 'gamification.missions.empty_group'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(gamificationMissionsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: missions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => MissionTile(mission: missions[index]),
      ),
    );
  }
}

/// Active / completed counters and the XP earned from missions, as ledger
/// metric tiles.
class _MissionSummary extends StatelessWidget {
  const _MissionSummary({required this.summary});

  final MissionSummary summary;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight gives the Row a bounded height, so the stretch tiles
    // stay equal-height instead of receiving an infinite-height constraint.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryTile(
              value: '${summary.activeCount}',
              label: 'gamification.missions.summary.active'.tr(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              value: '${summary.completedCount}',
              label: 'gamification.missions.summary.completed'.tr(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              value: 'gamification.missions.reward_xp'.tr(
                namedArgs: {'xp': '${summary.totalXpEarned}'},
              ),
              label: 'gamification.missions.summary.xp_earned'.tr(),
              accent: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.value, required this.label, this.accent});

  final String value;
  final String label;
  final bool? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isAccent = accent ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccent ? colors.primaryContainer : colors.surface,
        border: Border.all(
          color: isAccent ? colors.primaryContainer : colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w600,
                color: isAccent ? colors.onPrimaryContainer : colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              letterSpacing: 1.2,
              color: isAccent
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-time / weekly / community filter pills driving the tab view.
class _TypeFilterPills extends StatelessWidget {
  const _TypeFilterPills({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < MissionType.values.length; index++)
              _FilterPill(
                label:
                    'gamification.missions.tabs.${MissionType.values[index].wireValue}'
                        .tr(),
                selected: controller.index == index,
                onTap: () => controller.animateTo(index),
              ),
          ],
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.primaryContainer : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                    letterSpacing: 0.4,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
