import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../shared/utils/date_utils.dart';
import '../models/search_result_model.dart';
import 'search_source_filter.dart';

/// Shows detail information for a search hit that has no in-app detail route.
Future<void> showSearchResultDetailSheet(
  BuildContext context,
  SearchResultItem result,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SearchResultDetailSheet(result: result),
  );
}

/// Detail sheet for non-receipt results.
class SearchResultDetailSheet extends StatelessWidget {
  final SearchResultItem result;

  const SearchResultDetailSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = result.title.isEmpty ? result.sourceType : result.title;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'InstrumentSerif',
                  fontSize: 30,
                  height: 1.05,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                searchSourceLabel(result.sourceType).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: colors.outlineVariant),
              const SizedBox(height: 12),
              _detailRow(
                context,
                'search.detail.source'.tr(),
                result.contentType.isEmpty
                    ? result.sourceType
                    : result.contentType,
              ),
              _detailRow(
                context,
                'search.detail.similarity'.tr(),
                'search.result.similarity'.tr(
                  namedArgs: {'percent': '${result.similarityPercent}'},
                ),
                mono: true,
              ),
              if (result.accessLevel != null)
                _detailRow(
                  context,
                  'search.detail.accessLevel'.tr(),
                  result.accessLevel!,
                ),
              if (result.createdAt != null)
                _detailRow(
                  context,
                  'search.result.created'.tr(),
                  AppDateUtils.formatDate(result.createdAt!),
                  mono: true,
                ),
              if (result.updatedAt != null)
                _detailRow(
                  context,
                  'search.result.updated'.tr(),
                  AppDateUtils.formatDate(result.updatedAt!),
                  mono: true,
                ),
              const SizedBox(height: 4),
              Text(
                result.description.isEmpty
                    ? 'search.result.noDescription'.tr()
                    : result.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: result.description.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                  fontStyle: result.description.isEmpty
                      ? FontStyle.italic
                      : null,
                ),
              ),
              if (result.metadata.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'search.detail.metadata'.tr().toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.metadata.entries.map(
                  (entry) => _detailRow(
                    context,
                    entry.key,
                    entry.value is String ||
                            entry.value is num ||
                            entry.value is bool
                        ? '${entry.value}'
                        : jsonEncode(entry.value),
                    mono: entry.value is num,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('search.detail.close'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool mono = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: colors.onSurface,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
