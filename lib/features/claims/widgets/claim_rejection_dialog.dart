import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../../../shared/utils/currency_utils.dart';
import '../providers/claims_provider.dart';

class ClaimRejectionDialog extends ConsumerStatefulWidget {
  final ClaimModel claim;
  final VoidCallback? onClaimRejected;

  const ClaimRejectionDialog({
    super.key,
    required this.claim,
    this.onClaimRejected,
  });

  @override
  ConsumerState<ClaimRejectionDialog> createState() =>
      _ClaimRejectionDialogState();
}

class _ClaimRejectionDialogState extends ConsumerState<ClaimRejectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _rejectClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = ClaimRejectionRequest(
        claimId: widget.claim.id,
        rejectionReason: _reasonController.text.trim(),
      );

      await ref.read(claimsProvider.notifier).rejectClaim(request);

      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Claim rejected',
              style: TextStyle(color: colors.onTertiary),
            ),
            backgroundColor: colors.tertiary,
          ),
        );
        widget.onClaimRejected?.call();
      }
    } catch (e) {
      if (mounted) {
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to reject claim: $e',
              style: TextStyle(color: colors.onError),
            ),
            backgroundColor: colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REJECTION',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Reject Claim',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'InstrumentSerif',
                              fontSize: 26,
                              height: 1.05,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.claim.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyUtils.formatCurrency(
                                  widget.claim.amount,
                                  widget.claim.currency,
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.error,
                                  fontFamily: 'IBMPlexMono',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.claim.claimantName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Claimant: ${widget.claim.claimantName}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (widget.claim.description != null &&
                                  widget.claim.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.claim.description!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_outlined,
                                color: colors.onErrorContainer,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This action will reject the claim and cannot be undone. The claimant will be notified with your reason.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onErrorContainer,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Rejection Reason *',
                            hintText:
                                'Please provide a clear reason for rejecting this claim...',
                            prefixIcon: Icon(Icons.comment_outlined),
                            errorMaxLines: 2,
                          ),
                          maxLines: 4,
                          maxLength: 500,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide a reason for rejection';
                            }
                            if (value.trim().length < 10) {
                              return 'Rejection reason must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Common Reasons:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              [
                                    'Insufficient documentation',
                                    'Amount exceeds policy limits',
                                    'Duplicate claim',
                                    'Invalid receipt',
                                    'Missing required information',
                                    'Policy violation',
                                  ]
                                  .map(
                                    (reason) => ActionChip(
                                      label: Text(reason),
                                      labelStyle: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                      backgroundColor: colors.surface,
                                      side: BorderSide(
                                        color: colors.outlineVariant,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      onPressed: () {
                                        _reasonController.text = reason;
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _rejectClaim,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                        disabledBackgroundColor: colors.error,
                        disabledForegroundColor: colors.onError,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onError,
                              ),
                            )
                          : const Text('Reject Claim'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
