import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_bar_with_actions.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/utils/date_utils.dart';
import '../providers/claims_provider.dart';
import '../widgets/claim_audit_trail_widget.dart';
import '../widgets/edit_claim_dialog.dart';
import '../widgets/claim_approval_dialog.dart';
import '../widgets/claim_rejection_dialog.dart';

class ClaimDetailScreen extends ConsumerStatefulWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen> {
  bool _showAuditTrail = false;

  @override
  Widget build(BuildContext context) {
    final claimAsync = ref.watch(claimByIdProvider(widget.claimId));

    return Scaffold(
      appBar: AppBarWithActions(
        title: 'Claim Details',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showAuditTrail ? Icons.visibility_off : Icons.history),
            onPressed: () {
              setState(() {
                _showAuditTrail = !_showAuditTrail;
              });
            },
            tooltip: _showAuditTrail ? 'Hide Audit Trail' : 'Show Audit Trail',
          ),
        ],
      ),
      body: claimAsync.when(
        loading: () => const LoadingWidget(message: 'Loading claim details...'),
        error: (error, stack) => AppErrorWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(claimByIdProvider(widget.claimId)),
        ),
        data: (claim) {
          if (claim == null) {
            return const Center(child: Text('Claim not found'));
          }
          return _buildClaimDetails(claim);
        },
      ),
    );
  }

  Widget _buildClaimDetails(ClaimModel claim) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(claim),

                const SizedBox(height: 16),

                // Details Card
                _buildDetailsCard(claim),

                const SizedBox(height: 16),

                // Attachments Card
                if (claim.attachments.isNotEmpty) _buildAttachmentsCard(claim),

                const SizedBox(height: 16),

                // Workflow Card
                _buildWorkflowCard(claim),

                const SizedBox(height: 16),

                // Audit Trail
                if (_showAuditTrail) ClaimAuditTrailWidget(claimId: claim.id),
              ],
            ),
          ),
        ),

        // Action Buttons
        _buildActionButtons(claim),
      ],
    );
  }

  Widget _buildHeaderCard(ClaimModel claim) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    claim.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(claim.status),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyUtils.formatCurrency(claim.amount, claim.currency),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                _buildPriorityBadge(claim.priority),
              ],
            ),

            if (claim.description != null && claim.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                claim.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ClaimModel claim) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.person,
              label: 'Claimant',
              value: claim.claimantName ?? 'Unknown',
            ),

            if (claim.category != null)
              _buildDetailRow(
                icon: Icons.category,
                label: 'Category',
                value: claim.category!,
              ),

            _buildDetailRow(
              icon: Icons.schedule,
              label: 'Created',
              value: AppDateUtils.formatDateTime(claim.createdAt),
            ),

            if (claim.submittedAt != null)
              _buildDetailRow(
                icon: Icons.send,
                label: 'Submitted',
                value: AppDateUtils.formatDateTime(claim.submittedAt!),
              ),

            if (claim.approvedAt != null)
              _buildDetailRow(
                icon: Icons.check_circle,
                label: 'Approved',
                value: AppDateUtils.formatDateTime(claim.approvedAt!),
                subtitle: claim.approverName,
              ),

            if (claim.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rejection Reason',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      claim.rejectionReason!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard(ClaimModel claim) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attachments (${claim.attachments.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...claim.attachments.map((attachment) {
              // Parse attachment if it's a string representation
              return ListTile(
                leading: const Icon(Icons.receipt),
                title: const Text('Receipt'),
                subtitle: const Text('Tap to view'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Open receipt viewer
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowCard(ClaimModel claim) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workflow Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildWorkflowStep(
              title: 'Created',
              isCompleted: true,
              date: claim.createdAt,
            ),
            _buildWorkflowStep(
              title: 'Submitted',
              isCompleted: claim.submittedAt != null,
              date: claim.submittedAt,
            ),
            _buildWorkflowStep(
              title: 'Reviewed',
              isCompleted: claim.reviewedAt != null,
              date: claim.reviewedAt,
            ),
            _buildWorkflowStep(
              title: claim.status == ClaimStatus.approved
                  ? 'Approved'
                  : 'Processed',
              isCompleted:
                  claim.approvedAt != null ||
                  claim.status == ClaimStatus.rejected,
              date: claim.approvedAt,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStep({
    required String title,
    required bool isCompleted,
    DateTime? date,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey.shade600,
                ),
              ),
              if (date != null)
                Text(
                  AppDateUtils.formatDateTime(date),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ClaimStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case ClaimStatus.draft:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.edit;
        break;
      case ClaimStatus.submitted:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.send;
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(ClaimPriority priority) {
    Color color;
    IconData icon;

    switch (priority) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            priority.name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ClaimModel claim) {
    final actions = <Widget>[];

    // Edit button (only for draft claims)
    if (claim.canEdit) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showEditDialog(claim),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ),
      );
    }

    // Submit button (only for draft claims that can be submitted)
    if (claim.canSubmit) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _submitClaim(claim),
            icon: const Icon(Icons.send),
            label: const Text('Submit'),
          ),
        ),
      );
    }

    // Approve button (for pending/under review claims)
    if (claim.canApprove) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showApprovalDialog(claim),
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // Reject button (for pending/under review claims)
    if (claim.canReject) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRejectionDialog(claim),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: actions
            .expand((action) => [action, const SizedBox(width: 8)])
            .take(actions.length * 2 - 1)
            .toList(),
      ),
    );
  }

  void _showEditDialog(ClaimModel claim) {
    showDialog(
      context: context,
      builder: (context) => EditClaimDialog(
        claim: claim,
        onClaimUpdated: () {
          ref.invalidate(claimByIdProvider(widget.claimId));
        },
      ),
    );
  }

  Future<void> _submitClaim(ClaimModel claim) async {
    try {
      await ref.read(claimsProvider.notifier).submitClaim(claim.id);
      ref.invalidate(claimByIdProvider(widget.claimId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim submitted for review'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit claim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showApprovalDialog(ClaimModel claim) {
    showDialog(
      context: context,
      builder: (context) => ClaimApprovalDialog(
        claim: claim,
        onClaimApproved: () {
          ref.invalidate(claimByIdProvider(widget.claimId));
        },
      ),
    );
  }

  void _showRejectionDialog(ClaimModel claim) {
    showDialog(
      context: context,
      builder: (context) => ClaimRejectionDialog(
        claim: claim,
        onClaimRejected: () {
          ref.invalidate(claimByIdProvider(widget.claimId));
        },
      ),
    );
  }
}
