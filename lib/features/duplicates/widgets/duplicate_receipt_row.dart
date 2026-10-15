import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/utils/date_utils.dart';

/// One receipt inside a duplicate group.
///
/// The kept receipt of a group is badged and its checkbox is disabled so it
/// cannot be part of a delete.
class DuplicateReceiptRow extends StatelessWidget {
  final ReceiptModel receipt;
  final bool isKept;
  final bool isSelected;
  final ValueChanged<bool?>? onChanged;

  const DuplicateReceiptRow({
    super.key,
    required this.receipt,
    required this.isKept,
    required this.isSelected,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = receipt.transactionDate;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
      ),
      leading: Checkbox(
        value: isKept ? false : isSelected,
        onChanged: isKept ? null : onChanged,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              receipt.merchantName?.trim().isNotEmpty == true
                  ? receipt.merchantName!.trim()
                  : 'duplicates.receipt.unknownMerchant'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (isKept) ...[
            const SizedBox(width: AppConstants.smallPadding),
            Chip(
              label: Text('duplicates.kept'.tr()),
              labelStyle: theme.textTheme.labelSmall,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: theme.colorScheme.secondaryContainer,
            ),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (date != null) AppDateUtils.formatDate(date),
          CurrencyUtils.formatCurrencySafe(
            receipt.totalAmount,
            receipt.currency,
          ),
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
