import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/claim_model.dart';
import '../../../shared/utils/currency_utils.dart';
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
    final claim = claimAsync.valueOrNull;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(claim, showAuditToggle: claim != null),
          Expanded(
            child: claimAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
              data: (claim) {
                if (claim == null) {
                  return const Center(child: Text('Claim not found'));
                }
                return _buildClaimDetails(claim);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ClaimModel? claim, {required bool showAuditToggle}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim == null
                      ? 'CLAIM DETAILS'
                      : 'CLAIM · ${_claimRef(claim.id)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  claim?.title ?? 'Claim Details',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: 'InstrumentSerif',
                    fontSize: 32,
                    height: 1.05,
                    color: colors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (claim != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusPill(status: claim.status),
                      _PriorityPill(priority: claim.priority),
                      Text(
                        _formatDate(claim.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (showAuditToggle)
            IconButton(
              icon: Icon(
                _showAuditTrail ? Icons.visibility_off : Icons.history,
              ),
              onPressed: () {
                setState(() {
                  _showAuditTrail = !_showAuditTrail;
                });
              },
              tooltip: _showAuditTrail
                  ? 'Hide Audit Trail'
                  : 'Show Audit Trail',
            ),
        ],
      ),
    );
  }

  Widget _buildClaimDetails(ClaimModel claim) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsPanel(claim),
                if (claim.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAttachmentsPanel(claim),
                ],
                const SizedBox(height: 12),
                _buildWorkflowPanel(claim),
                if (_showAuditTrail) ...[
                  const SizedBox(height: 12),
                  ClaimAuditTrailWidget(claimId: claim.id),
                ],
              ],
            ),
          ),
        ),
        if (claim.canEdit ||
            claim.canSubmit ||
            claim.canApprove ||
            claim.canReject)
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: SafeArea(top: false, child: _buildActionButtons(claim)),
          ),
      ],
    );
  }

  Widget _buildDetailsPanel(ClaimModel claim) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _LedgerPanel(
      title: 'Details',
      meta: claim.statusDisplayName,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Amount',
              child: Text(
                CurrencyUtils.formatCurrency(claim.amount, claim.currency),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _DetailRow(
              label: 'Claimant',
              child: Row(
                children: [
                  _MonogramTile(name: claim.claimantName ?? 'Unknown'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      claim.claimantName ?? 'Unknown',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (claim.category != null)
              _DetailRow(
                label: 'Category',
                child: Text(
                  claim.category!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            _DetailRow(
              label: 'Created',
              child: _dataText(context, _formatDateTime(claim.createdAt)),
            ),
            if (claim.submittedAt != null)
              _DetailRow(
                label: 'Submitted',
                child: _dataText(context, _formatDateTime(claim.submittedAt!)),
              ),
            if (claim.approvedAt != null)
              _DetailRow(
                label: 'Approved',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dataText(context, _formatDateTime(claim.approvedAt!)),
                    if (claim.approverName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        claim.approverName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (claim.description != null && claim.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'DESCRIPTION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                claim.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  height: 1.45,
                ),
              ),
            ],
            if (claim.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          color: colors.onErrorContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rejection Reason',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      claim.rejectionReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer,
                        height: 1.45,
                      ),
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

  Widget _buildAttachmentsPanel(ClaimModel claim) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _LedgerPanel(
      title: 'Attachments (${claim.attachments.length})',
      child: Column(
        children: [
          for (var index = 0; index < claim.attachments.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.outlineVariant),
            InkWell(
              onTap: () {
                // TODO: Open receipt viewer
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.receipt_outlined,
                        size: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receipt',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkflowPanel(ClaimModel claim) {
    return _LedgerPanel(
      title: 'Workflow Status',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final connectorColor = isCompleted ? colors.primary : colors.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                border: isCompleted
                    ? null
                    : Border.all(color: colors.outlineVariant),
              ),
              child: isCompleted
                  ? Icon(Icons.check, size: 12, color: colors.onPrimary)
                  : null,
            ),
            if (!isLast) Container(width: 1, height: 30, color: connectorColor),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ClaimModel claim) {
    final colors = Theme.of(context).colorScheme;
    final actions = <Widget>[];

    // Edit button (only for draft claims)
    if (claim.canEdit) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showEditDialog(claim),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        ),
      );
    }

    // Submit button (only for draft claims that can be submitted)
    if (claim.canSubmit) {
      actions.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _submitClaim(claim),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Submit'),
          ),
        ),
      );
    }

    // Approve button (for pending/under review claims)
    if (claim.canApprove) {
      actions.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _showApprovalDialog(claim),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
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
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: actions
            .expand((action) => [action, const SizedBox(width: 8)])
            .take(actions.length * 2 - 1)
            .toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading claim details...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 36, color: colors.error),
            const SizedBox(height: 12),
            Text(
              'Could not load claim details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(claimByIdProvider(widget.claimId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
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
    final colors = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(claimsProvider.notifier).submitClaim(claim.id);
      ref.invalidate(claimByIdProvider(widget.claimId));
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Claim submitted for review',
              style: TextStyle(color: colors.onPrimary),
            ),
            backgroundColor: colors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit claim: $e',
              style: TextStyle(color: colors.onError),
            ),
            backgroundColor: colors.error,
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

  String _formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy · HH:mm').format(date).toUpperCase();

  String _formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date).toUpperCase();

  Widget _dataText(BuildContext context, String value) => Text(
    value,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'IBMPlexMono',
      fontWeight: FontWeight.w500,
    ),
  );

  static String _claimRef(String id) {
    final compact = id.replaceAll('-', '').toUpperCase();
    return 'CLM-${compact.length <= 5 ? compact : compact.substring(0, 5)}';
  }
}

class _LedgerPanel extends StatelessWidget {
  const _LedgerPanel({required this.title, required this.child, this.meta});

  final String title;
  final String? meta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (meta != null) ...[
                  const Spacer(),
                  Text(
                    meta!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

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

    return _Pill(
      label: _statusLabel(status),
      background: background,
      foreground: foreground,
    );
  }

  static String _statusLabel(ClaimStatus status) {
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

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final ClaimPriority priority;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (priority) {
      ClaimPriority.low => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
      ClaimPriority.medium => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      ClaimPriority.high ||
      ClaimPriority.urgent => (colors.errorContainer, colors.onErrorContainer),
    };

    return _Pill(
      label: priority.displayName,
      background: background,
      foreground: foreground,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
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
            label,
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
}
