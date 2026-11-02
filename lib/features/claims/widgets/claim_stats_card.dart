import 'package:flutter/material.dart';

import '../../../shared/models/claim_requests.dart';
import '../../../shared/utils/currency_utils.dart';

/// Summary metrics for the claims ledger.
class ClaimStatsCard extends StatelessWidget {
  final ClaimStats stats;

  const ClaimStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final tiles = <_StatTileData>[
      _StatTileData(
        label: 'Total Claims',
        value: '${stats.totalClaims}',
        meta: 'Across the team',
      ),
      _StatTileData(
        label: 'Pending',
        value: '${stats.pendingClaims}',
        meta: '${stats.pendingRate.toStringAsFixed(1)}% awaiting review',
        tone: _StatTone.pending,
      ),
      _StatTileData(
        label: 'Approved Amount',
        value: CurrencyUtils.formatCurrency(stats.approvedAmount, 'MYR'),
        meta: 'Settled claims',
        tone: _StatTone.positive,
      ),
      _StatTileData(
        label: 'Avg. Processing',
        value: stats.averageProcessingTime == null
            ? '—'
            : _formatProcessingTime(stats.averageProcessingTime!),
        meta: 'From submit to decision',
      ),
      _StatTileData(
        label: 'Approved',
        value: '${stats.approvedClaims}',
        meta: '${stats.approvalRate.toStringAsFixed(1)}% approval rate',
        tone: _StatTone.positive,
      ),
      _StatTileData(
        label: 'Rejected',
        value: '${stats.rejectedClaims}',
        meta: 'Declined claims',
        tone: _StatTone.negative,
      ),
      _StatTileData(
        label: 'Total Amount',
        value: CurrencyUtils.formatCurrency(stats.totalAmount, 'MYR'),
        meta: 'All submitted values',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        final rows = <Widget>[];
        for (var index = 0; index < tiles.length; index += columns) {
          final rowTiles = tiles.skip(index).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 10),
                    Expanded(
                      child: column < rowTiles.length
                          ? _StatTile(data: rowTiles[column])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
          if (index + columns < tiles.length) {
            rows.add(const SizedBox(height: 10));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  String _formatProcessingTime(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '${minutes}m';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      final days = (hours / 24).round();
      return '${days}d';
    }
  }
}

enum _StatTone { neutral, pending, positive, negative }

class _StatTileData {
  const _StatTileData({
    required this.label,
    required this.value,
    required this.meta,
    this.tone = _StatTone.neutral,
  });

  final String label;
  final String value;
  final String meta;
  final _StatTone tone;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});

  final _StatTileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final valueColor = switch (data.tone) {
      _StatTone.pending => colors.onTertiaryContainer,
      _StatTone.positive => colors.primary,
      _StatTone.negative => colors.error,
      _StatTone.neutral => colors.onSurface,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.meta,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
