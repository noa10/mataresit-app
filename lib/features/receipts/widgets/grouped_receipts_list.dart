import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/grouped_receipts.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/receipts_provider.dart';

/// Widget that displays receipts grouped by date
class GroupedReceiptsList extends ConsumerStatefulWidget {
  final List<GroupedReceipts> groupedReceipts;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;

  const GroupedReceiptsList({
    super.key,
    required this.groupedReceipts,
    this.scrollController,
    this.onLoadMore,
  });

  @override
  ConsumerState<GroupedReceiptsList> createState() => _GroupedReceiptsListState();
}

class _GroupedReceiptsListState extends ConsumerState<GroupedReceiptsList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptsState = ref.watch(receiptsProvider);

    if (widget.groupedReceipts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: widget.groupedReceipts.length + (receiptsState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.groupedReceipts.length) {
          return _buildLoadingIndicator();
        }

        final group = widget.groupedReceipts[index];
        return _buildDateGroup(group);
      },
    );
  }

  Widget _buildDateGroup(GroupedReceipts group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        _buildDateHeader(group),
        
        const SizedBox(height: 12),
        
        // Receipts for this date
        ...group.receipts.map((receipt) => _buildReceiptCard(receipt)),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDateHeader(GroupedReceipts group) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            group.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${group.count}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            group.getFormattedTotal(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(ReceiptModel receipt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/receipts/${receipt.id}'),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Merchant name or placeholder
                  Expanded(
                    child: Text(
                      receipt.merchantName ?? 'Unknown Merchant',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Amount
                  Text(
                    '${receipt.currency ?? 'MYR'} ${receipt.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Details row
              Row(
                children: [
                  // Category
                  if (receipt.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        receipt.category!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Payment method
                  if (receipt.paymentMethod != null) ...[
                    Icon(
                      _getPaymentMethodIcon(receipt.paymentMethod!),
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      receipt.paymentMethod!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  const Spacer(),
                  
                  // Status indicator
                  _buildStatusIndicator(receipt.status),
                ],
              ),
              
              // Time if available
              if (receipt.transactionDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTime(receipt.transactionDate!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ReceiptStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case ReceiptStatus.active:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ReceiptStatus.draft:
        color = Colors.orange;
        icon = Icons.edit;
        break;
      case ReceiptStatus.archived:
        color = Colors.grey;
        icon = Icons.archive;
        break;
      case ReceiptStatus.deleted:
        color = Colors.red;
        icon = Icons.delete;
        break;
    }
    
    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  IconData _getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
      case 'credit card':
      case 'debit card':
        return Icons.credit_card;
      case 'digital wallet':
      case 'e-wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No receipts found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or add some receipts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
