import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/claim_model.dart';
import '../providers/claims_provider.dart';

class ClaimAuditTrailWidget extends ConsumerWidget {
  final String claimId;

  const ClaimAuditTrailWidget({super.key, required this.claimId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditTrailAsync = ref.watch(claimAuditTrailProvider(claimId));
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Text(
                  'Audit Trail',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                auditTrailAsync.maybeWhen(
                  data: (entries) => Text(
                    '${entries.length} ${entries.length == 1 ? 'event' : 'events'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: auditTrailAsync.when(
              loading: () => _buildLoading(context),
              error: (error, stack) => _buildError(context, ref, error),
              data: (auditTrail) {
                if (auditTrail.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No audit trail available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return Column(
                  children: auditTrail.asMap().entries.map((entry) {
                    final isLast = entry.key == auditTrail.length - 1;
                    return _buildAuditItem(context, entry.value, isLast);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Loading audit trail...',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Could not load audit trail',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          error.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => ref.invalidate(claimAuditTrailProvider(claimId)),
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildAuditItem(
    BuildContext context,
    ClaimAuditTrailModel audit,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (toneBackground, toneForeground) = _actionTone(colors, audit.action);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: toneBackground,
              ),
              child: Icon(
                _getActionIcon(audit.action),
                size: 13,
                color: toneForeground,
              ),
            ),
            if (!isLast)
              Container(width: 1, height: 44, color: colors.outlineVariant),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _getActionDisplayName(audit.action),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'dd MMM · HH:mm',
                    ).format(audit.createdAt).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              if (audit.userName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'by ${audit.userName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (audit.oldStatus != null && audit.newStatus != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusChip(context, audit.oldStatus!),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    _buildStatusChip(context, audit.newStatus!),
                  ],
                ),
              ],
              if (audit.comment != null && audit.comment!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Text(
                    audit.comment!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
              if (!isLast) const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, ClaimStatus status) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontFamily: 'IBMPlexMono',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
    );
  }

  static (Color, Color) _actionTone(ColorScheme colors, String action) {
    switch (action.toLowerCase()) {
      case 'created':
      case 'submitted':
      case 'reviewed':
        return (colors.tertiaryContainer, colors.onTertiaryContainer);
      case 'approved':
        return (colors.primaryContainer, colors.onPrimaryContainer);
      case 'rejected':
        return (colors.errorContainer, colors.onErrorContainer);
      case 'updated':
        return (colors.surfaceContainerHighest, colors.onSurfaceVariant);
      default:
        return (colors.surfaceContainerHighest, colors.onSurfaceVariant);
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
        return action
            .split('_')
            .map(
              (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(' ');
    }
  }
}
