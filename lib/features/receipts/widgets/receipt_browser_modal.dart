import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/receipt_model.dart';
import '../services/receipt_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/utils/date_utils.dart';

/// Modal that displays a list of receipts with detailed viewing capabilities
/// Similar to React's DailyReceiptBrowserModal
class ReceiptBrowserModal extends ConsumerStatefulWidget {
  final List<String> receiptIds;
  final String title;
  final VoidCallback? onClose;

  const ReceiptBrowserModal({
    super.key,
    required this.receiptIds,
    required this.title,
    this.onClose,
  });

  @override
  ConsumerState<ReceiptBrowserModal> createState() =>
      _ReceiptBrowserModalState();
}

class _ReceiptBrowserModalState extends ConsumerState<ReceiptBrowserModal> {
  List<ReceiptModel>? _receipts;
  bool _isLoading = true;
  String? _error;
  String? _selectedReceiptId;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    if (widget.receiptIds.isEmpty) {
      setState(() {
        _receipts = [];
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final receipts = await ReceiptService.getReceiptsByIds(widget.receiptIds);
      
      setState(() {
        _receipts = receipts;
        _isLoading = false;
        // Auto-select first receipt if available
        if (receipts.isNotEmpty) {
          _selectedReceiptId = receipts.first.id;
        }
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  ReceiptModel? get _selectedReceipt {
    if (_selectedReceiptId == null || _receipts == null) return null;
    try {
      return _receipts!.firstWhere((r) => r.id == _selectedReceiptId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading receipts...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading receipts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReceipts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_receipts == null || _receipts!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No receipts found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive design based on screen width
        final isWideScreen = constraints.maxWidth > 600;
        final sidebarWidth = isWideScreen ? 350.0 : constraints.maxWidth * 0.4;

        return Row(
          children: [
            // Left sidebar - Receipt list
            SizedBox(
              width: sidebarWidth,
              child: _buildReceiptList(),
            ),

            // Divider
            const VerticalDivider(width: 1),

            // Right side - Receipt details
            Expanded(
              child: _buildReceiptDetails(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            '${_receipts!.length} Receipt${_receipts!.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Receipt list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.smallPadding,
            ),
            itemCount: _receipts!.length,
            itemBuilder: (context, index) {
              final receipt = _receipts![index];
              final isSelected = receipt.id == _selectedReceiptId;
              
              return Card(
                margin: const EdgeInsets.only(
                  bottom: AppConstants.smallPadding,
                ),
                color: isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReceiptId = receipt.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                receipt.merchantName ?? 'Receipt (${receipt.id.substring(0, 6)}...)',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatDate(receipt.transactionDate ?? receipt.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyUtils.formatCurrency(receipt.totalAmount ?? 0, receipt.currency ?? 'MYR'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptDetails() {
    if (_selectedReceipt == null) {
      return const Center(
        child: Text(
          'Select a receipt from the list to view details',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header with actions
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedReceipt!.merchantName ?? 'Unknown Merchant',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatDate(_selectedReceipt!.transactionDate ?? _selectedReceipt!.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to full receipt detail screen
                      context.push('/receipts/${_selectedReceipt!.id}');
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Receipt summary
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: _buildReceiptSummary(),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptSummary() {
    final receipt = _selectedReceipt!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    CurrencyUtils.formatCurrency(
                      receipt.totalAmount ?? 0,
                      receipt.currency ?? 'MYR',
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Receipt details
        if (receipt.receiptNumber != null) ...[
          _buildDetailRow('Receipt Number', receipt.receiptNumber!),
          const SizedBox(height: 8),
        ],
        
        if (receipt.paymentMethod != null) ...[
          _buildDetailRow('Payment Method', receipt.paymentMethod!),
          const SizedBox(height: 8),
        ],
        
        if (receipt.category != null) ...[
          _buildDetailRow('Category', receipt.category!),
          const SizedBox(height: 8),
        ],
        
        if (receipt.description != null && receipt.description!.isNotEmpty) ...[
          _buildDetailRow('Description', receipt.description!),
          const SizedBox(height: 8),
        ],
        
        if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
          _buildDetailRow('Notes', receipt.notes!),
          const SizedBox(height: 8),
        ],
        
        // Line items
        if (receipt.lineItems != null && receipt.lineItems!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Line Items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...receipt.lineItems!.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.description,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyUtils.formatCurrency(
                      item.amount,
                      receipt.currency ?? 'MYR',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive label width based on available space
        final labelWidth = constraints.maxWidth > 300 ? 120.0 : constraints.maxWidth * 0.35;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
