import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../shared/utils/date_utils.dart';
import '../models/search_result_model.dart';
import 'search_source_filter.dart';

/// Card for a single unified search hit.
class SearchResultCard extends StatelessWidget {
  final SearchResultItem result;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final createdAt = result.createdAt;
    final title = result.title.isEmpty ? result.sourceType : result.title;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SourceTile(icon: _iconFor(result.sourceType)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              color: colors.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SimilarityPill(percent: result.similarityPercent),
                      ],
                    ),
                    if (result.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        result.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          searchSourceLabel(result.sourceType).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            AppDateUtils.formatDate(createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                              letterSpacing: 0.4,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String sourceType) {
    switch (sourceType) {
      case SearchSources.receipt:
        return Icons.receipt_long;
      case SearchSources.claim:
        return Icons.description_outlined;
      case SearchSources.teamMember:
        return Icons.group_outlined;
      case SearchSources.customCategory:
        return Icons.sell_outlined;
      case SearchSources.businessDirectory:
        return Icons.storefront_outlined;
      case SearchSources.conversation:
        return Icons.forum_outlined;
      default:
        return Icons.search;
    }
  }
}

/// Outlined icon tile matching the ledger monogram tiles.
class _SourceTile extends StatelessWidget {
  final IconData icon;

  const _SourceTile({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: colors.onSurfaceVariant),
    );
  }
}

/// Match score as a small mono pill in the accent container colour.
class _SimilarityPill extends StatelessWidget {
  final int percent;

  const _SimilarityPill({required this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'search.result.similarity'.tr(namedArgs: {'percent': '$percent'}),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onPrimaryContainer,
          fontFamily: 'IBMPlexMono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
