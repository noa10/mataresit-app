import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/currency_display_widget.dart';
import '../providers/claims_provider.dart';
import '../../teams/providers/teams_provider.dart';

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
  ConsumerState<ClaimFromReceiptDialog> createState() =>
      _ClaimFromReceiptDialogState();
}

class _ClaimFromReceiptDialogState
    extends ConsumerState<ClaimFromReceiptDialog> {
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
    _titleController.text =
        'Expense - ${receipt.merchantName ?? 'Unknown Merchant'}';
    _descriptionController.text =
        'Expense claim for ${receipt.merchantName ?? 'Unknown Merchant'} on ${_formatDate(receipt.transactionDate)}';
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
          },
        },
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
        final colors = Theme.of(context).colorScheme;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Claim created successfully',
              style: TextStyle(color: colors.onPrimary),
            ),
            backgroundColor: colors.primary,
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
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colors.onError)),
        backgroundColor: colors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
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
                            'NEW CLAIM',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Create Claim from Receipt',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.receipt_outlined,
                                color: colors.onSurfaceVariant,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.receipt.merchantName ??
                                        'Unknown Merchant',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  CompactCurrencyDisplay(
                                    amount: widget.receipt.totalAmount ?? 0.0,
                                    currencyCode:
                                        widget.receipt.currency ?? 'MYR',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                      fontFamily: 'IBMPlexMono',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title *',
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
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _amountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount *',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                    ),
                                    items:
                                        CurrencyConfigs.getSelectableCurrencyCodes(
                                              selectedCurrency: _currency,
                                            )
                                            .map(
                                              (currency) => DropdownMenuItem(
                                                value: currency,
                                                child: Text(currency),
                                              ),
                                            )
                                            .toList(),
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
                            TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ClaimPriority>(
                              initialValue: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
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
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _createClaim,
                        style: FilledButton.styleFrom(
                          disabledBackgroundColor: colors.primary,
                          disabledForegroundColor: colors.onPrimary,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Text('Create Claim'),
                      ),
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
