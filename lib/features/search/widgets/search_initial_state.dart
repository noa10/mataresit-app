import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';

/// Pre-search prompt shown before the first query is submitted.
class SearchInitialState extends StatelessWidget {
  /// Example queries, in the current language, ready to submit as-is.
  final List<String> examples;
  final ValueChanged<String> onExampleSelected;

  const SearchInitialState({
    super.key,
    required this.examples,
    required this.onExampleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_search,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'search.initial.title'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'search.initial.message'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'search.examples.title'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppConstants.smallPadding,
            runSpacing: AppConstants.smallPadding,
            children: examples
                .map(
                  (example) => ActionChip(
                    avatar: const Icon(Icons.search, size: 16),
                    label: Text(example),
                    onPressed: () => onExampleSelected(example),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
