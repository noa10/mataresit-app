import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
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
    final title = result.title.isEmpty ? result.sourceType : result.title;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.defaultPadding,
            0,
            AppConstants.defaultPadding,
            AppConstants.defaultPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                searchSourceLabel(result.sourceType),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
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
                ),
              if (result.updatedAt != null)
                _detailRow(
                  context,
                  'search.result.updated'.tr(),
                  AppDateUtils.formatDate(result.updatedAt!),
                ),
              const SizedBox(height: AppConstants.defaultPadding),
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
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'search.detail.metadata'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                ...result.metadata.entries.map(
                  (entry) => _detailRow(
                    context,
                    entry.key,
                    entry.value is String ||
                            entry.value is num ||
                            entry.value is bool
                        ? '${entry.value}'
                        : jsonEncode(entry.value),
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.largePadding),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
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

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
