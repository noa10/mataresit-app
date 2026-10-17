import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
import '../models/search_result_model.dart';

/// Source filter limited to the free-tier targets the server allows.
///
/// The app cannot read the user's subscription tier at this point, so it
/// deliberately does not offer the pro/max-only sources.
class SearchSourceFilter extends StatelessWidget {
  final Set<String> selectedSources;
  final ValueChanged<String> onToggle;

  const SearchSourceFilter({
    super.key,
    required this.selectedSources,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.sources.label'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Wrap(
          spacing: AppConstants.smallPadding,
          runSpacing: AppConstants.smallPadding,
          children: SearchSources.freeTier.map((source) {
            return FilterChip(
              label: Text(searchSourceLabel(source)),
              selected: selectedSources.contains(source),
              onSelected: (_) => onToggle(source),
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Display label for a wire-level source name.
///
/// The server also emits source types outside the documented set (`line_item`,
/// `financial_analysis`, raw database `source_type` values), so unknown names
/// are humanised from the raw value rather than rendered as a missing key.
String searchSourceLabel(String sourceType) {
  switch (sourceType) {
    case SearchSources.receipt:
      return 'search.sources.receipt'.tr();
    case SearchSources.claim:
      return 'search.sources.claim'.tr();
    case SearchSources.teamMember:
      return 'search.sources.team_member'.tr();
    case SearchSources.customCategory:
      return 'search.sources.custom_category'.tr();
    case SearchSources.businessDirectory:
      return 'search.sources.business_directory'.tr();
    case SearchSources.conversation:
      return 'search.sources.conversation'.tr();
  }

  final words = sourceType.replaceAll('_', ' ').trim();
  if (words.isEmpty) return '';
  return words[0].toUpperCase() + words.substring(1);
}
