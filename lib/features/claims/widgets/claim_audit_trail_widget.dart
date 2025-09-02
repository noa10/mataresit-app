import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../providers/claims_provider.dart';

class ClaimAuditTrailWidget extends ConsumerWidget {
  final String claimId;

  const ClaimAuditTrailWidget({
    super.key,
    required this.claimId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditTrailAsync = ref.watch(claimAuditTrailProvider(claimId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Audit Trail',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            auditTrailAsync.when(
              loading: () => const LoadingWidget(message: 'Loading audit trail...'),
              error: (error, stack) => AppErrorWidget(
                error: error.toString(),
                onRetry: () => ref.invalidate(claimAuditTrailProvider(claimId)),
              ),
              data: (auditTrail) {
                if (auditTrail.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No audit trail available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: auditTrail.asMap().entries.map((entry) {
                    final index = entry.key;
                    final audit = entry.value;
                    final isLast = index == auditTrail.length - 1;

                    return _buildAuditItem(context, audit, isLast);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItem(BuildContext context, ClaimAuditTrailModel audit, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getActionColor(audit.action),
              ),
              child: Icon(
                _getActionIcon(audit.action),
                size: 14,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action and user
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getActionDisplayName(audit.action),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    AppDateUtils.formatDateTime(audit.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              // User info
              if (audit.userName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'by ${audit.userName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              
              // Status change
              if (audit.oldStatus != null && audit.newStatus != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusChip(context, audit.oldStatus!),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(context, audit.newStatus!),
                  ],
                ),
              ],
              
              // Comment
              if (audit.comment != null && audit.comment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    audit.comment!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, ClaimStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ClaimStatus.draft:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        break;
      case ClaimStatus.submitted:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case ClaimStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case ClaimStatus.underReview:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case ClaimStatus.approved:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case ClaimStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        break;
      case ClaimStatus.paid:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Colors.blue;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'updated':
        return Colors.purple;
      case 'reviewed':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Icons.add_circle;
      case 'submitted':
        return Icons.send;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'updated':
        return Icons.edit;
      case 'reviewed':
        return Icons.visibility;
      default:
        return Icons.circle;
    }
  }

  String _getActionDisplayName(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return 'Claim Created';
      case 'submitted':
        return 'Claim Submitted';
      case 'approved':
        return 'Claim Approved';
      case 'rejected':
        return 'Claim Rejected';
      case 'updated':
        return 'Claim Updated';
      case 'reviewed':
        return 'Claim Reviewed';
      default:
        return action.split('_').map((word) => 
          word[0].toUpperCase() + word.substring(1).toLowerCase()
        ).join(' ');
    }
  }
}
