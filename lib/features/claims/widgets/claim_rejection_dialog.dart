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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onClaimRejected?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject claim: $e'),
            backgroundColor: Colors.red,
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red.shade700),
          const SizedBox(width: 8),
          const Text('Reject Claim'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Claim summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.claim.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 20,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          CurrencyUtils.formatCurrency(
                            widget.claim.amount,
                            widget.claim.currency,
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                        ),
                      ],
                    ),
                    if (widget.claim.claimantName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Claimant: ${widget.claim.claimantName}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.red.shade600),
                          ),
                        ],
                      ),
                    ],
                    if (widget.claim.description != null &&
                        widget.claim.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.claim.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Warning message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action will reject the claim and cannot be undone. The claimant will be notified with your reason.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Rejection reason field (required)
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText:
                      'Please provide a clear reason for rejecting this claim...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
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

              const SizedBox(height: 16),

              // Common rejection reasons (quick select)
              Text(
                'Common Reasons:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
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
                            label: Text(
                              reason,
                              style: const TextStyle(fontSize: 12),
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _rejectClaim,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Reject Claim'),
        ),
      ],
    );
  }
}
