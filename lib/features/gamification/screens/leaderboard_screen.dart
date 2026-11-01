import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardMetric _metric = LeaderboardMetric.weeklyXp;
  bool _malaysiaOnly = true;

  LeaderboardQuery get _query =>
      LeaderboardQuery(metric: _metric, malaysiaOnly: _malaysiaOnly);

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(gamificationProfileProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          Expanded(
            child: profileState.when(
              loading: () => LoadingWidget(
                message: 'gamification.leaderboard.loading'.tr(),
              ),
              error: (error, _) => AppErrorWidget(
                error: error.toString(),
                title: 'gamification.error.title'.tr(),
                onRetry: () =>
                    ref.read(gamificationProfileProvider.notifier).refresh(),
              ),
              data: (profile) => profile.leaderboardOptIn
                  ? _buildBoard()
                  : PrivacyGateCard(
                      // Opting in is done from the Rewards tab; popping here
                      // would land the user wherever they came from, not on
                      // that switch.
                      onOpenRewards: () => context.push('/profile?tab=rewards'),
                    ),
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
            onPressed: () => context.pop(),
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
                    'gamification.leaderboard.title'.tr(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFamily: 'InstrumentSerif',
                      fontSize: 32,
                      height: 1.05,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Compare your rewards progress across weekly XP, monthly '
                    'receipts and deductible totals.',
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
                ref.invalidate(gamificationLeaderboardProvider(_query)),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    final boardState = ref.watch(gamificationLeaderboardProvider(_query));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metric in LeaderboardMetric.values)
                _LedgerPill(
                  label: metric.labelKey.tr(),
                  selected: _metric == metric,
                  onTap: () => setState(() => _metric = metric),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerPill(
                label: 'gamification.leaderboard.scope.malaysia'.tr(),
                icon: Icons.location_on_outlined,
                selected: _malaysiaOnly,
                onTap: () => setState(() => _malaysiaOnly = true),
              ),
              _LedgerPill(
                label: 'gamification.leaderboard.scope.global'.tr(),
                icon: Icons.public_outlined,
                selected: !_malaysiaOnly,
                onTap: () => setState(() => _malaysiaOnly = false),
              ),
            ],
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
    final remainingRanks = result.remainingRanks;
    final scopeLabel =
        (_malaysiaOnly
                ? 'gamification.leaderboard.scope.malaysia'
                : 'gamification.leaderboard.scope.global')
            .tr();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (currentUserEntry != null) ...[
          _YourRankPanel(entry: currentUserEntry, metric: result.metric),
          const SizedBox(height: 12),
        ],
        if (result.podium.isNotEmpty) ...[
          _Podium(entries: result.podium, metric: result.metric),
          const SizedBox(height: 12),
        ],
        if (remainingRanks.isNotEmpty)
          _RankTable(
            entries: remainingRanks,
            metric: result.metric,
            scopeLabel: scopeLabel,
          ),
      ],
    );
  }
}

/// The signed-in user's own rank, shown above the board.
class _YourRankPanel extends StatelessWidget {
  const _YourRankPanel({required this.entry, required this.metric});

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final insideTopTen = entry.rank <= 10;

    // Mirror of the web position bar: full when inside the top ten, otherwise
    // the value against the value plus the gap still missing.
    final total = entry.metricValue + entry.gapToTopTen;
    final fraction = insideTopTen
        ? 1.0
        : total > 0
        ? (entry.metricValue / total).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'gamification.leaderboard.your_rank'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    metric.labelKey.tr(),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 0.4,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Flexible + FittedBox: the rank text is the row's only
                // non-shrinking child otherwise, and a long localized rank
                // string would push the panel wider than the screen.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'gamification.leaderboard.rank'.tr(
                        namedArgs: {'rank': '${entry.rank}'},
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 5,
                          backgroundColor: colors.outlineVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatMetricValue(metric, entry.metricValue),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 11,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insideTopTen
                            ? 'gamification.leaderboard.in_top_ten'.tr()
                            : 'gamification.leaderboard.gap_to_top_ten'.tr(
                                namedArgs: {
                                  'gap': _formatMetricValue(
                                    metric,
                                    entry.gapToTopTen,
                                  ),
                                },
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ranks 1-3, arranged second-first-third like the web podium cards.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.metric});

  final List<LeaderboardEntry> entries;
  final LeaderboardMetric metric;

  @override
  Widget build(BuildContext context) {
    LeaderboardEntry? entryForRank(int rank) {
      for (final entry in entries) {
        if (entry.rank == rank) return entry;
      }
      return null;
    }

    final ordered = [
      entryForRank(2),
      entryForRank(1),
      entryForRank(3),
    ].whereType<LeaderboardEntry>().toList();

    if (ordered.isEmpty) return const SizedBox.shrink();

    // IntrinsicHeight bounds the Row's height inside the scroll view, so the
    // stretch podium cards stay equal-height instead of crashing on layout.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < ordered.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            Expanded(
              child: _PodiumCard(
                entry: ordered[index],
                metric: metric,
                isFirst: ordered[index].rank == 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.metric,
    required this.isFirst,
  });

  final LeaderboardEntry entry;
  final LeaderboardMetric metric;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final highlighted = isFirst || entry.isCurrentUser;
    final name = _displayName(entry);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: highlighted ? colors.primary : colors.outlineVariant,
          width: highlighted ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '#${entry.rank}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 1.2,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst ? colors.primary : colors.surfaceContainerHigh,
            ),
            child: Text(
              _entryInitials(entry),
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w600,
                color: isFirst ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatMetricValue(metric, entry.metricValue),
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ranks below the podium, rendered as rows of one ledger panel.
class _RankTable extends StatelessWidget {
  const _RankTable({
    required this.entries,
    required this.metric,
    required this.scopeLabel,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardMetric metric;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    metric.labelKey.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    scopeLabel,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 0.4,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          for (var index = 0; index < entries.length; index++) ...[
            _RankRow(entry: entries[index], metric: metric),
            if (index < entries.length - 1)
              Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          ],
        ],
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
    final colors = theme.colorScheme;
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      color: isCurrentUser
          ? colors.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrentUser
                  ? colors.primaryContainer
                  : colors.surfaceContainerHigh,
            ),
            child: Text(
              _entryInitials(entry),
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isCurrentUser
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _displayName(entry),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
          if (entry.isAnonymous) ...[
            const SizedBox(width: 8),
            const _AnonymousBadge(),
          ],
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              _formatMetricValue(metric, entry.metricValue),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnonymousBadge extends StatelessWidget {
  const _AnonymousBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'gamification.leaderboard.anonymous'.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: 'IBMPlexMono',
          fontSize: 9,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LedgerPill extends StatelessWidget {
  const _LedgerPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
                if (icon != null) ...[
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: 6),
                ],
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

/// Masks anonymous entries; falls back to the anonymous label when the server
/// returns no display name.
String _displayName(LeaderboardEntry entry) {
  if (entry.displayName.isNotEmpty) return entry.displayName;
  return 'gamification.leaderboard.anonymous'.tr();
}

/// Two-letter monogram for an entry, with the web's anonymous fallback.
String _entryInitials(LeaderboardEntry entry) {
  if (entry.isAnonymous) return 'AN';
  return _initialsFor(_displayName(entry));
}

/// Grapheme-safe two-letter monogram for a display name.
String _initialsFor(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'AN';
  if (words.length == 1) {
    return words.first.characters.take(2).toString().toUpperCase();
  }
  return '${words.first.characters.first}${words[1].characters.first}'
      .toUpperCase();
}

String _formatMetricValue(LeaderboardMetric metric, double value) {
  if (metric.isCurrency) {
    return CurrencyUtils.formatCurrencySafe(value, 'MYR');
  }
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}
