import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
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
    final createdAt = result.createdAt;
    final title = result.title.isEmpty ? result.sourceType : result.title;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconFor(result.sourceType),
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (result.description.isNotEmpty) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  result.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: AppConstants.smallPadding,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _SourceBadge(label: searchSourceLabel(result.sourceType)),
                  _SimilarityBadge(percent: result.similarityPercent),
                  if (createdAt != null)
                    Text(
                      AppDateUtils.formatDate(createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
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

class _SourceBadge extends StatelessWidget {
  final String label;

  const _SourceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SimilarityBadge extends StatelessWidget {
  final int percent;

  const _SimilarityBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.percent,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          'search.result.similarity'.tr(namedArgs: {'percent': '$percent'}),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
