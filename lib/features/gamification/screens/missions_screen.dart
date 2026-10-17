import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
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
  late final TabController _tabController = TabController(
    length: MissionType.values.length,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missionsState = ref.watch(gamificationMissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('gamification.missions.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'gamification.actions.refresh'.tr(),
            onPressed: () =>
                ref.read(gamificationMissionsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: missionsState.when(
        loading: () =>
            LoadingWidget(message: 'gamification.missions.loading'.tr()),
        error: (error, _) => AppErrorWidget(
          error: error.toString(),
          title: 'gamification.error.title'.tr(),
          onRetry: () =>
              ref.read(gamificationMissionsProvider.notifier).refresh(),
        ),
        data: (board) => board.isEmpty ? _buildEmpty() : _buildBoard(board),
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
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: _MissionSummaryCard(summary: board.summary),
        ),
        TabBar(
          controller: _tabController,
          tabs: [
            for (final type in MissionType.values)
              Tab(text: 'gamification.missions.tabs.${type.wireValue}'.tr()),
          ],
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
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: missions.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppConstants.smallPadding),
        itemBuilder: (context, index) => MissionTile(mission: missions[index]),
      ),
    );
  }
}

/// Active / completed counters and the XP earned from missions.
class _MissionSummaryCard extends StatelessWidget {
  const _MissionSummaryCard({required this.summary});

  final MissionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            _SummaryTile(
              value: '${summary.activeCount}',
              label: 'gamification.missions.summary.active'.tr(),
              icon: Icons.play_circle_outline,
            ),
            _SummaryTile(
              value: '${summary.completedCount}',
              label: 'gamification.missions.summary.completed'.tr(),
              icon: Icons.check_circle_outline,
            ),
            _SummaryTile(
              value: '${summary.totalXpEarned}',
              label: 'gamification.missions.summary.xp_earned'.tr(),
              icon: Icons.bolt,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
