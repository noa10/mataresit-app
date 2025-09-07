import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../providers/claims_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/currency_utils.dart';

/// Dialog for creating a claim from a receipt
/// Matches the functionality of React app's ClaimFromReceiptButton
class ClaimFromReceiptDialog extends ConsumerStatefulWidget {
  final ReceiptModel receipt;
  final VoidCallback? onClaimCreated;

  const ClaimFromReceiptDialog({
    super.key,
    required this.receipt,
    this.onClaimCreated,
  });

  @override
  ConsumerState<ClaimFromReceiptDialog> createState() => _ClaimFromReceiptDialogState();
}

class _ClaimFromReceiptDialogState extends ConsumerState<ClaimFromReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String _currency = 'MYR';
  ClaimPriority _priority = ClaimPriority.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormWithReceiptData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _initializeFormWithReceiptData() {
    final receipt = widget.receipt;
    
    // Pre-fill form with receipt data (matching React app logic)
    _titleController.text = 'Expense - ${receipt.merchantName ?? 'Unknown Merchant'}';
    _descriptionController.text = 'Expense claim for ${receipt.merchantName ?? 'Unknown Merchant'} on ${_formatDate(receipt.transactionDate)}';
    _amountController.text = receipt.totalAmount?.toString() ?? '0.00';
    _currency = CurrencyUtils.normalizeCurrencyCode(receipt.currency);
    _categoryController.text = receipt.category ?? '';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown Date';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _createClaim() async {
    if (!_formKey.currentState!.validate()) return;

    final currentTeam = ref.read(currentTeamModelProvider);
    if (currentTeam == null) {
      _showErrorSnackBar('No team selected');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare attachments with receipt metadata (matching React app structure)
      final attachments = [
        {
          'type': 'receipt',
          'receiptId': widget.receipt.id,
          'url': widget.receipt.imageUrl,
          'metadata': {
            'merchant': widget.receipt.merchantName,
            'date': widget.receipt.transactionDate?.toIso8601String(),
            'total': widget.receipt.totalAmount,
            'currency': widget.receipt.currency,
          }
        }
      ];

      final request = CreateClaimRequest(
        teamId: currentTeam.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: _currency,
        category: _categoryController.text.trim().isEmpty 
            ? null 
            : _categoryController.text.trim(),
        priority: _priority,
        attachments: attachments.map((a) => a.toString()).toList(),
      );

      await ref.read(claimsProvider.notifier).createClaim(request);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onClaimCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create claim: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create Claim from Receipt',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Receipt preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.receipt.merchantName ?? 'Unknown Merchant',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${widget.receipt.currency ?? 'MYR'} ${widget.receipt.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Title must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Amount and Currency row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Amount is required';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _currency,
                              decoration: const InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'MYR', child: Text('MYR')),
                                DropdownMenuItem(value: 'USD', child: Text('USD')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _currency = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category field
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Priority field
                      DropdownButtonFormField<ClaimPriority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: ClaimPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _priority = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createClaim,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Claim'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
