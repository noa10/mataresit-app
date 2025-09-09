import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../../../shared/models/receipt_model.dart';
import '../providers/claims_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../receipts/providers/receipts_provider.dart';
import '../../../shared/utils/currency_utils.dart';

class CreateClaimDialog extends ConsumerStatefulWidget {
  final VoidCallback? onClaimCreated;
  final List<ReceiptModel>? preSelectedReceipts;

  const CreateClaimDialog({
    super.key,
    this.onClaimCreated,
    this.preSelectedReceipts,
  });

  @override
  ConsumerState<CreateClaimDialog> createState() => _CreateClaimDialogState();
}

class _CreateClaimDialogState extends ConsumerState<CreateClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();

  String _currency = 'MYR';
  ClaimPriority _priority = ClaimPriority.medium;
  List<ReceiptModel> _selectedReceipts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedReceipts != null) {
      _selectedReceipts = List.from(widget.preSelectedReceipts!);
      _calculateTotalFromReceipts();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _calculateTotalFromReceipts() {
    if (_selectedReceipts.isNotEmpty) {
      final total = _selectedReceipts.fold<double>(
        0.0,
        (sum, receipt) => sum + (receipt.totalAmount ?? 0.0),
      );
      _amountController.text = total.toStringAsFixed(2);

      // Set currency from first receipt if available
      if (_selectedReceipts.first.currency != null &&
          _selectedReceipts.first.currency!.isNotEmpty) {
        _currency = CurrencyUtils.normalizeCurrencyCode(
          _selectedReceipts.first.currency!,
        );
      }
    }
  }

  void _showReceiptPicker() {
    showDialog(
      context: context,
      builder: (context) => _ReceiptPickerDialog(
        selectedReceipts: _selectedReceipts,
        onReceiptsSelected: (receipts) {
          setState(() {
            _selectedReceipts = receipts;
            _calculateTotalFromReceipts();
          });
        },
      ),
    );
  }

  Future<void> _createClaim() async {
    if (!_formKey.currentState!.validate()) return;

    final currentTeamState = ref.read(currentTeamProvider);
    if (currentTeamState.currentTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a team first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare attachments from selected receipts
      final attachments = _selectedReceipts
          .map((receipt) {
            return {
              'type': 'receipt',
              'receiptId': receipt.id,
              'url': receipt.imageUrl,
              'metadata': {
                'merchant': receipt.merchantName,
                'date': receipt.transactionDate?.toIso8601String(),
                'total': receipt.totalAmount,
                'currency': receipt.currency,
              },
            };
          })
          .map((attachment) => attachment.toString())
          .toList();

      final request = CreateClaimRequest(
        teamId: currentTeamState.currentTeam!.id,
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
        attachments: attachments.isEmpty ? null : attachments,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create claim: $e'),
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create New Claim',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Claim Title *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a claim title';
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
                          prefixIcon: Icon(Icons.description),
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
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
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
                              items:
                                  [
                                        'MYR',
                                        'USD',
                                        'EUR',
                                        'GBP',
                                        'CAD',
                                        'AUD',
                                        'JPY',
                                        'SGD',
                                      ]
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
                                    _currency =
                                        CurrencyUtils.normalizeCurrencyCode(
                                          value,
                                        );
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
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Priority dropdown
                      DropdownButtonFormField<ClaimPriority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: ClaimPriority.values
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _priority = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Receipts section
                      _buildReceiptsSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
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
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createClaim,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }

  Widget _buildReceiptsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attached Receipts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showReceiptPicker,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Receipts'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedReceipts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No receipts attached\nTap "Add Receipts" to attach receipts to this claim',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(_selectedReceipts.map(
            (receipt) => Card(
              child: ListTile(
                leading: const Icon(Icons.receipt),
                title: Text(receipt.merchantName ?? 'Unknown Merchant'),
                subtitle: Text(
                  '${receipt.transactionDate?.day ?? ''}/${receipt.transactionDate?.month ?? ''}/${receipt.transactionDate?.year ?? ''} • ${receipt.currency ?? 'USD'} ${(receipt.totalAmount ?? 0.0).toStringAsFixed(2)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedReceipts.remove(receipt);
                      _calculateTotalFromReceipts();
                    });
                  },
                ),
              ),
            ),
          )),
      ],
    );
  }
}

// Simple receipt picker dialog (placeholder)
class _ReceiptPickerDialog extends ConsumerWidget {
  final List<ReceiptModel> selectedReceipts;
  final Function(List<ReceiptModel>) onReceiptsSelected;

  const _ReceiptPickerDialog({
    required this.selectedReceipts,
    required this.onReceiptsSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);

    return AlertDialog(
      title: const Text('Select Receipts'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: receiptsState.receipts.isEmpty
            ? const Center(child: Text('No receipts available'))
            : ListView.builder(
                itemCount: receiptsState.receipts.length,
                itemBuilder: (context, index) {
                  final receipt = receiptsState.receipts[index];
                  final isSelected = selectedReceipts.contains(receipt);

                  return CheckboxListTile(
                    title: Text(receipt.merchantName ?? 'Unknown Merchant'),
                    subtitle: Text(
                      '${receipt.transactionDate?.day ?? ''}/${receipt.transactionDate?.month ?? ''}/${receipt.transactionDate?.year ?? ''} • ${receipt.currency ?? 'USD'} ${(receipt.totalAmount ?? 0.0).toStringAsFixed(2)}',
                    ),
                    value: isSelected,
                    onChanged: (selected) {
                      final newSelection = List<ReceiptModel>.from(
                        selectedReceipts,
                      );
                      if (selected == true) {
                        newSelection.add(receipt);
                      } else {
                        newSelection.remove(receipt);
                      }
                      onReceiptsSelected(newSelection);
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
