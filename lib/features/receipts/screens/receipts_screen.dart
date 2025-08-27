import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../providers/receipts_provider.dart';
import '../../../shared/models/receipt_model.dart';

class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(receiptsProvider.notifier).loadReceipts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptsState = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(receiptsProvider.notifier).refresh(),
        child: receiptsState.receipts.isEmpty && !receiptsState.isLoading
            ? _buildEmptyState()
            : _buildReceiptsList(receiptsState),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No receipts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            'Tap the camera button to capture your first receipt',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList(ReceiptsState state) {
    return Column(
      children: [
        // Error display
        if (state.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            color: Colors.red.withValues(alpha: 0.1),
            child: Text(
              state.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        
        // Receipts list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: state.receipts.length + (state.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.receipts.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppConstants.defaultPadding),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final receipt = state.receipts[index];
              return _buildReceiptCard(receipt);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard(ReceiptModel receipt) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
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
                  if (receipt.totalAmount != null)
                    Text(
                      '\$${receipt.totalAmount!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: AppConstants.smallPadding),
              
              // Details row
              Row(
                children: [
                  // Category
                  if (receipt.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.smallPadding,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        receipt.category!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                  ],
                  
                  // Processing status
                  _buildStatusChip(receipt.processingStatus),
                  
                  const Spacer(),
                  
                  // Date
                  Text(
                    timeago.format(receipt.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // Description if available
              if (receipt.description != null) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  receipt.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProcessingStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case ProcessingStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ProcessingStatus.processing:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case ProcessingStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case ProcessingStatus.manualReview:
        color = Colors.blue;
        icon = Icons.visibility;
        break;
      case ProcessingStatus.pending:
        color = Colors.grey;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Receipts'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter merchant name, category, or description',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.of(context).pop();
              ref.read(receiptsProvider.notifier).searchReceipts('');
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(receiptsProvider.notifier).searchReceipts(_searchController.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Receipts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Receipts'),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(receiptsProvider.notifier).filterByStatus(null);
              },
            ),
            ListTile(
              title: const Text('Active'),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(receiptsProvider.notifier).filterByStatus(ReceiptStatus.active);
              },
            ),
            ListTile(
              title: const Text('Draft'),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(receiptsProvider.notifier).filterByStatus(ReceiptStatus.draft);
              },
            ),
            ListTile(
              title: const Text('Archived'),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(receiptsProvider.notifier).filterByStatus(ReceiptStatus.archived);
              },
            ),
          ],
        ),
      ),
    );
  }
}
