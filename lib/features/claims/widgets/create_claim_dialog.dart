import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/utils/currency_utils.dart';
import '../providers/claims_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../receipts/providers/receipts_provider.dart';

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
        SnackBar(
          content: Text(
            'Please select a team first',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
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
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create claim: $e',
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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
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
                          'Create New Claim',
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
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Claim Title *',
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
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined),
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
                                prefixIcon: Icon(Icons.payments_outlined),
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
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ClaimPriority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
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
                      _buildReceiptsSection(),
                    ],
                  ),
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
                      child: _isLoading
                          ? SizedBox(
                              height: 18,
                              width: 18,
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
    );
  }

  Widget _buildReceiptsSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attached Receipts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No receipts attached\nTap "Add Receipts" to attach receipts to this claim',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < _selectedReceipts.length;
                  index++
                ) ...[
                  if (index > 0)
                    Divider(height: 1, color: colors.outlineVariant),
                  _buildReceiptRow(_selectedReceipts[index]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReceiptRow(ReceiptModel receipt) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final merchant = receipt.merchantName ?? 'Unknown Merchant';
    final meta =
        '${receipt.transactionDate?.day ?? ''}/${receipt.transactionDate?.month ?? ''}/${receipt.transactionDate?.year ?? ''} • ${receipt.currency ?? 'MYR'} ${(receipt.totalAmount ?? 0.0).toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      child: Row(
        children: [
          _ReceiptMonogram(name: merchant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle, color: colors.error, size: 20),
            onPressed: () {
              setState(() {
                _selectedReceipts.remove(receipt);
                _calculateTotalFromReceipts();
              });
            },
          ),
        ],
      ),
    );
  }
}

class _ReceiptMonogram extends StatelessWidget {
  const _ReceiptMonogram({required this.name});

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

// Simple receipt picker dialog (placeholder)
class _ReceiptPickerDialog extends ConsumerStatefulWidget {
  final List<ReceiptModel> selectedReceipts;
  final Function(List<ReceiptModel>) onReceiptsSelected;

  const _ReceiptPickerDialog({
    required this.selectedReceipts,
    required this.onReceiptsSelected,
  });

  @override
  ConsumerState<_ReceiptPickerDialog> createState() =>
      _ReceiptPickerDialogState();
}

class _ReceiptPickerDialogState extends ConsumerState<_ReceiptPickerDialog> {
  late List<ReceiptModel> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<ReceiptModel>.from(widget.selectedReceipts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final receiptsState = ref.watch(receiptsProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Select Receipts',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'InstrumentSerif',
                        fontSize: 26,
                        height: 1.05,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Flexible(
              child: receiptsState.receipts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No receipts available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: receiptsState.receipts.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: colors.outlineVariant),
                      itemBuilder: (context, index) {
                        final receipt = receiptsState.receipts[index];
                        final isSelected = _selected.contains(receipt);

                        return CheckboxListTile(
                          title: Text(
                            receipt.merchantName ?? 'Unknown Merchant',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${receipt.transactionDate?.day ?? ''}/${receipt.transactionDate?.month ?? ''}/${receipt.transactionDate?.year ?? ''} • ${receipt.currency ?? 'MYR'} ${(receipt.totalAmount ?? 0.0).toStringAsFixed(2)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (selected) {
                            final newSelection = List<ReceiptModel>.from(
                              _selected,
                            );
                            if (selected == true) {
                              newSelection.add(receipt);
                            } else {
                              newSelection.remove(receipt);
                            }
                            setState(() {
                              _selected = newSelection;
                            });
                            widget.onReceiptsSelected(newSelection);
                          },
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
