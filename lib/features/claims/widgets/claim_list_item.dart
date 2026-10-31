import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/claim_model.dart';
import '../../../shared/utils/currency_utils.dart';

/// A single claim in the claims ledger.
class ClaimListItem extends StatelessWidget {
  final ClaimModel claim;
  final VoidCallback? onTap;
  final Function(ClaimModel)? onEdit;
  final Function(ClaimModel)? onSubmit;
  final Function(ClaimModel)? onApprove;
  final Function(ClaimModel)? onReject;
  final Function(ClaimModel)? onDelete;
  final bool isFirst;
  final bool isLast;

  const ClaimListItem({
    super.key,
    required this.claim,
    this.onTap,
    this.onEdit,
    this.onSubmit,
    this.onApprove,
    this.onReject,
    this.onDelete,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(9) : Radius.zero,
      bottom: isLast ? const Radius.circular(9) : Radius.zero,
    );

    return Material(
      color: colors.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MonogramTile(name: claim.claimantName ?? claim.title),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claim.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (claim.category != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  claim.category!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 132),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                CurrencyUtils.formatCurrency(
                                  claim.amount,
                                  claim.currency,
                                ),
                                textAlign: TextAlign.end,
                                style: _dataStyle(
                                  theme,
                                  colors,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ClaimStatusPill(status: claim.status),
                        Text(
                          claim.priorityDisplayName.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'dd MMM',
                          ).format(claim.createdAt).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    if (claim.description != null &&
                        claim.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        claim.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (claim.submittedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Submitted ${DateFormat('dd MMM yyyy').format(claim.submittedAt!).toUpperCase()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                    if (_hasActions) ...[
                      const SizedBox(height: 8),
                      _buildActionButtons(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasActions =>
      (claim.canEdit && onEdit != null) ||
      (claim.canSubmit && onSubmit != null) ||
      (claim.canApprove && onApprove != null) ||
      (claim.canReject && onReject != null) ||
      (claim.status == ClaimStatus.draft && onDelete != null);

  TextStyle? _dataStyle(
    ThemeData theme,
    ColorScheme colors, {
    FontWeight? fontWeight,
  }) => theme.textTheme.bodySmall?.copyWith(
    color: colors.onSurface,
    fontFamily: 'IBMPlexMono',
    fontWeight: fontWeight ?? FontWeight.w500,
  );

  Widget _buildActionButtons(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final actions = <Widget>[];

    // Edit button (only for draft claims)
    if (claim.canEdit && onEdit != null) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.edit,
          label: 'Edit',
          onPressed: () => onEdit!(claim),
          color: colors.onSurfaceVariant,
        ),
      );
    }

    // Submit button (only for draft claims that can be submitted)
    if (claim.canSubmit && onSubmit != null) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.send,
          label: 'Submit',
          onPressed: () => onSubmit!(claim),
          color: colors.primary,
        ),
      );
    }

    // Approve button (for pending/under review claims)
    if (claim.canApprove && onApprove != null) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.check,
          label: 'Approve',
          onPressed: () => onApprove!(claim),
          color: colors.primary,
        ),
      );
    }

    // Reject button (for pending/under review claims)
    if (claim.canReject && onReject != null) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.close,
          label: 'Reject',
          onPressed: () => onReject!(claim),
          color: colors.error,
        ),
      );
    }

    // Delete button (only for draft claims)
    if (claim.status == ClaimStatus.draft && onDelete != null) {
      actions.add(
        _actionButton(
          context,
          icon: Icons.delete_outline,
          label: 'Delete',
          onPressed: () => onDelete!(claim),
          color: colors.error,
        ),
      );
    }

    return Wrap(spacing: 4, runSpacing: 2, children: actions);
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MonogramTile extends StatelessWidget {
  const _MonogramTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final words = trimmed.isEmpty
        ? const <String>[]
        : trimmed.split(RegExp(r'\s+'));
    final initials = words.isEmpty
        ? '?'
        : words.length > 1
        ? '${words[0].characters.first}${words[1].characters.first}'
        : words[0].characters.take(2).toString();

    return ExcludeSemantics(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          initials.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _ClaimStatusPill extends StatelessWidget {
  const _ClaimStatusPill({required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ClaimStatus.approved ||
      ClaimStatus.paid => (colors.primaryContainer, colors.onPrimaryContainer),
      ClaimStatus.submitted || ClaimStatus.pending || ClaimStatus.underReview =>
        (colors.tertiaryContainer, colors.onTertiaryContainer),
      ClaimStatus.rejected => (colors.errorContainer, colors.onErrorContainer),
      ClaimStatus.draft => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusLabel(status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  static String statusLabel(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.pending:
        return 'Pending Review';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.paid:
        return 'Paid';
    }
  }
}
