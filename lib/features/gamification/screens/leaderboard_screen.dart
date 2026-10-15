import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/leaderboard_entry.dart';
import '../providers/gamification_provider.dart';
import '../widgets/privacy_gate_card.dart';

/// Leaderboard for the three metrics, in Malaysian or global scope.
///
/// While the user has not opted in this renders [PrivacyGateCard] instead of a
/// board, and the leaderboard RPC is never called.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: LeaderboardMetric.values.length,
    vsync: this,
  );
  LeaderboardMetric _metric = LeaderboardMetric.weeklyXp;
  bool _malaysiaOnly = true;

  LeaderboardQuery get _query =>
      LeaderboardQuery(metric: _metric, malaysiaOnly: _malaysiaOnly);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(gamificationProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('gamification.leaderboard.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'gamification.actions.refresh'.tr(),
            onPressed: () =>
                ref.invalidate(gamificationLeaderboardProvider(_query)),
          ),
        ],
      ),
      body: profileState.when(
        loading: () =>
            LoadingWidget(message: 'gamification.leaderboard.loading'.tr()),
        error: (error, _) => AppErrorWidget(
          error: error.toString(),
          title: 'gamification.error.title'.tr(),
          onRetry: () =>
              ref.read(gamificationProfileProvider.notifier).refresh(),
        ),
        data: (profile) => profile.leaderboardOptIn
            ? _buildBoard()
            : PrivacyGateCard(
                // Opting in is done from the Rewards tab; popping here would
                // land the user wherever they came from, not on that switch.
                onOpenRewards: () => context.push('/profile?tab=rewards'),
              ),
      ),
    );
  }

  Widget _buildBoard() {
    final boardState = ref.watch(gamificationLeaderboardProvider(_query));

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          onTap: (index) =>
              setState(() => _metric = LeaderboardMetric.values[index]),
          tabs: [
            for (final metric in LeaderboardMetric.values)
              Tab(text: metric.labelKey.tr()),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: true,
                label: Text('gamification.leaderboard.scope.malaysia'.tr()),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('gamification.leaderboard.scope.global'.tr()),
              ),
            ],
            selected: <bool>{_malaysiaOnly},
            onSelectionChanged: (selection) =>
                setState(() => _malaysiaOnly = selection.first),
          ),
        ),
        Expanded(
          child: boardState.when(
            loading: () =>
                LoadingWidget(message: 'gamification.leaderboard.loading'.tr()),
            error: (error, _) => AppErrorWidget(
              error: error.toString(),
              title: 'gamification.error.title'.tr(),
              onRetry: () =>
                  ref.invalidate(gamificationLeaderboardProvider(_query)),
            ),
            data: (result) => result.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.leaderboard_outlined,
                    title: 'gamification.leaderboard.empty_title'.tr(),
                    message: 'gamification.leaderboard.empty'.tr(),
                  )
                : _buildEntries(result),
          ),
        ),
      ],
    );
  }

  Widget _buildEntries(LeaderboardResult result) {
    final currentUserEntry = result.currentUserEntry;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        if (currentUserEntry != null) ...[
          _CurrentUserRankCard(entry: currentUserEntry, metric: result.metric),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
        if (result.podium.isNotEmpty) ...[
          _Podium(entries: result.podium, metric: result.metric),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
        for (final entry in result.remainingRanks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
            child: _RankRow(entry: entry, metric: result.metric),
          ),
      ],
    );
  }
}

/// The signed-in user's own rank, shown above the board.
class _CurrentUserRankCard extends StatelessWidget {
  const _CurrentUserRankCard({required this.entry, required this.metric});

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'gamification.leaderboard.your_rank'.tr(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'gamification.leaderboard.rank'.tr(
                    namedArgs: {'rank': '${entry.rank}'},
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMetricValue(metric, entry.metricValue),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.rank <= 10
                        ? 'gamification.leaderboard.in_top_ten'.tr()
                        : 'gamification.leaderboard.gap_to_top_ten'.tr(
                            namedArgs: {
                              'gap': _formatMetricValue(
                                metric,
                                entry.gapToTopTen,
                              ),
                            },
                          ),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
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

/// Ranks 1-3, arranged as a podium.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.metric});

  final List<LeaderboardEntry> entries;
  final LeaderboardMetric metric;

  static const Map<int, Color> _medalColors = {
    1: Color(0xFFD97706),
    2: Color(0xFF64748B),
    3: Color(0xFF92400E),
  };

  LeaderboardEntry? _entryForRank(int rank) {
    for (final entry in entries) {
      if (entry.rank == rank) return entry;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Second, first, third — the classic podium silhouette.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _slot(context, _entryForRank(2), 96)),
        Expanded(child: _slot(context, _entryForRank(1), 120)),
        Expanded(child: _slot(context, _entryForRank(3), 96)),
      ],
    );
  }

  Widget _slot(BuildContext context, LeaderboardEntry? entry, double height) {
    final theme = Theme.of(context);

    if (entry == null) {
      return const SizedBox(height: 96);
    }

    final medalColor = _medalColors[entry.rank] ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        decoration: BoxDecoration(
          color: medalColor.withValues(alpha: 0.12),
          border: Border.all(
            color: entry.isCurrentUser
                ? theme.colorScheme.primary
                : medalColor.withValues(alpha: 0.4),
            width: entry.isCurrentUser ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: medalColor),
            const SizedBox(height: 4),
            Text(
              _displayName(entry),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatMetricValue(metric, entry.metricValue),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the rank list.
class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.metric});

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentUser = entry.isCurrentUser;

    return Card(
      color: isCurrentUser ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${entry.rank}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _displayName(entry),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrentUser
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (entry.isAnonymous) ...[
                    const SizedBox(width: AppConstants.smallPadding),
                    const _AnonymousChip(),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Text(
              _formatMetricValue(metric, entry.metricValue),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnonymousChip extends StatelessWidget {
  const _AnonymousChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'gamification.leaderboard.anonymous'.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Masks anonymous entries; falls back to the anonymous label when the server
/// returns no display name.
String _displayName(LeaderboardEntry entry) {
  if (entry.displayName.isNotEmpty) return entry.displayName;
  return 'gamification.leaderboard.anonymous'.tr();
}

String _formatMetricValue(LeaderboardMetric metric, double value) {
  if (metric.isCurrency) {
    return CurrencyUtils.formatCurrencySafe(value, 'MYR');
  }
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}
