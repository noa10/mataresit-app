import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../models/duplicate_models.dart';
import 'duplicate_receipt_row.dart';

/// One duplicate group: the receipts that share a grouping key.
class DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;

  /// 1-based position of this group in the scan result, for display only.
  final int index;

  /// Already localized label of the fields that matched, e.g. `Merchant + Date`.
  final String criteriaLabel;

  final Set<String> selectedIds;
  final ValueChanged<String> onToggleReceipt;

  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.index,
    required this.criteriaLabel,
    required this.selectedIds,
    required this.onToggleReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.defaultPadding,
              AppConstants.smallPadding,
              AppConstants.defaultPadding,
              AppConstants.smallPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'duplicates.group.title'.tr(namedArgs: {'index': '$index'}),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(criteriaLabel),
                  labelStyle: theme.textTheme.labelSmall,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final receipt in group.receipts)
            DuplicateReceiptRow(
              receipt: receipt,
              isKept: receipt.id == group.keptReceiptId,
              isSelected: selectedIds.contains(receipt.id),
              onChanged: (_) => onToggleReceipt(receipt.id),
            ),
        ],
      ),
    );
  }
}
