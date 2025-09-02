import 'package:flutter/material.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/utils/date_utils.dart';

class ClaimListItem extends StatelessWidget {
  final ClaimModel claim;
  final VoidCallback? onTap;
  final Function(ClaimModel)? onEdit;
  final Function(ClaimModel)? onSubmit;
  final Function(ClaimModel)? onApprove;
  final Function(ClaimModel)? onReject;
  final Function(ClaimModel)? onDelete;

  const ClaimListItem({
    super.key,
    required this.claim,
    this.onTap,
    this.onEdit,
    this.onSubmit,
    this.onApprove,
    this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claim.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (claim.category != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            claim.category!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(context),
                ],
              ),

              const SizedBox(height: 12),

              // Amount and priority row
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyUtils.formatCurrency(claim.amount, claim.currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  _buildPriorityBadge(context),
                ],
              ),

              const SizedBox(height: 12),

              // Claimant and date info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      claim.claimantName ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppDateUtils.formatRelativeDate(claim.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Description if available
              if (claim.description != null && claim.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  claim.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Submitted date for non-draft claims
              if (claim.submittedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.send,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted ${AppDateUtils.formatRelativeDate(claim.submittedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],

              // Action buttons
              const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (claim.status) {
      case ClaimStatus.draft:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.edit;
        break;
      case ClaimStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_empty;
        break;
      case ClaimStatus.underReview:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.visibility;
        break;
      case ClaimStatus.approved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case ClaimStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      case ClaimStatus.paid:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        icon = Icons.payment;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            claim.statusDisplayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context) {
    Color color;
    IconData icon;

    switch (claim.priority) {
      case ClaimPriority.low:
        color = Colors.green;
        icon = Icons.keyboard_arrow_down;
        break;
      case ClaimPriority.medium:
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case ClaimPriority.high:
        color = Colors.red;
        icon = Icons.keyboard_arrow_up;
        break;
      case ClaimPriority.urgent:
        color = Colors.red.shade700;
        icon = Icons.priority_high;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            claim.priorityDisplayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final actions = <Widget>[];

    // Edit button (only for draft claims)
    if (claim.canEdit && onEdit != null) {
      actions.add(
        TextButton.icon(
          onPressed: () => onEdit!(claim),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    // Submit button (only for draft claims that can be submitted)
    if (claim.canSubmit && onSubmit != null) {
      actions.add(
        TextButton.icon(
          onPressed: () => onSubmit!(claim),
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Submit'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    // Approve button (for pending/under review claims)
    if (claim.canApprove && onApprove != null) {
      actions.add(
        TextButton.icon(
          onPressed: () => onApprove!(claim),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Approve'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    // Reject button (for pending/under review claims)
    if (claim.canReject && onReject != null) {
      actions.add(
        TextButton.icon(
          onPressed: () => onReject!(claim),
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Reject'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    // Delete button (only for draft claims)
    if (claim.status == ClaimStatus.draft && onDelete != null) {
      actions.add(
        TextButton.icon(
          onPressed: () => onDelete!(claim),
          icon: const Icon(Icons.delete, size: 16),
          label: const Text('Delete'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: actions,
    );
  }
}
