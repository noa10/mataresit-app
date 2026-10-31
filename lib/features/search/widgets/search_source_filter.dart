import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'search.sources.label'.tr().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final source in SearchSources.freeTier)
              _SourcePill(
                label: searchSourceLabel(source),
                selected: selectedSources.contains(source),
                onTap: () => onToggle(source),
              ),
          ],
        ),
      ],
    );
  }
}

/// Ledger pill for one source: neutral surface with a hairline border, or the
/// accent container when selected.
class _SourcePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SourcePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? colors.primaryContainer : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? colors.onPrimaryContainer : colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
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
