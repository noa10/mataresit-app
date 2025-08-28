import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../providers/receipts_provider.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/team_model.dart';

import '../../categories/providers/categories_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../../shared/widgets/category_display.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/grouped_receipts_list.dart';
import '../widgets/pagination_widget.dart';

class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final WidgetRef _ref;

  @override
  void initState() {
    super.initState();
    _ref = ref;
    _scrollController.addListener(_onScroll);
    // Load categories when the screen initializes with team context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTeam = _ref.read(currentTeamModelProvider);
      _ref.read(categoriesProvider.notifier).loadCategories(teamId: currentTeam?.id);
    });
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
      ref.read(receiptsProvider.notifier).loadMore();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        ref.read(receiptsProvider.notifier).refresh();
        break;
      case 'clear_filters':
        ref.read(receiptsProvider.notifier).clearAllFilters();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptsState = ref.watch(receiptsProvider);

    // Listen for team changes and reload categories
    ref.listen<TeamModel?>(currentTeamModelProvider, (previous, next) {
      if (previous?.id != next?.id) {
        // Team changed, reload categories with new team context
        ref.read(categoriesProvider.notifier).loadCategories(teamId: next?.id);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receipts'),
            if (receiptsState.hasActiveFilters)
              Text(
                '${receiptsState.totalCount} receipts • ${receiptsState.totalAmount.toStringAsFixed(2)} MYR',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: Icon(
              receiptsState.isGroupedView ? Icons.view_list : Icons.view_agenda,
            ),
            onPressed: () => ref.read(receiptsProvider.notifier).toggleGroupedView(),
            tooltip: receiptsState.isGroupedView ? 'List view' : 'Grouped view',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear Filters'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter bar
          DateFilterBar(
            onFilterChanged: () {
              // Optional: Add any additional logic when filters change
            },
          ),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(receiptsProvider.notifier).refresh(),
              child: _buildMainContent(receiptsState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ReceiptsState receiptsState) {
    if (receiptsState.receipts.isEmpty && !receiptsState.isLoading) {
      return _buildEmptyState();
    }

    if (receiptsState.isGroupedView) {
      return GroupedReceiptsList(
        groupedReceipts: receiptsState.groupedReceipts,
        scrollController: _scrollController,
        onLoadMore: () => ref.read(receiptsProvider.notifier).loadMore(),
      );
    } else {
      return _buildFlatReceiptsList(receiptsState);
    }
  }

  Widget _buildEmptyState() {
    final receiptsState = ref.watch(receiptsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              receiptsState.hasActiveFilters
                  ? 'No receipts match your filters'
                  : 'No receipts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              receiptsState.hasActiveFilters
                  ? 'Try adjusting your date range or search terms'
                  : 'Start by capturing your first receipt',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (receiptsState.hasActiveFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(receiptsProvider.notifier).clearAllFilters(),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlatReceiptsList(ReceiptsState receiptsState) {
    return Column(
      children: [
        // Pagination info at the top
        const PaginationInfoWidget(),

        // Main list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: receiptsState.receipts.length + 1, // +1 for pagination widget
            itemBuilder: (context, index) {
              if (index >= receiptsState.receipts.length) {
                return PaginationWidget(
                  onLoadMore: () => ref.read(receiptsProvider.notifier).loadMore(),
                  showLoadMoreButton: false, // Use automatic loading
                );
              }

              final receipt = receiptsState.receipts[index];
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
                  // Category - Use real category data with fallback
                  Consumer(
                    builder: (context, ref, child) {
                      final category = receipt.customCategoryId != null
                          ? ref.watch(categoryByIdProvider(receipt.customCategoryId!))
                          : null;



                      return CategoryDisplay(
                        category: category,
                        size: CategoryDisplaySize.small,
                      );
                    },
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  
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
    final receiptsState = ref.read(receiptsProvider);
    _searchController.text = receiptsState.searchQuery;

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
          onSubmitted: (value) {
            Navigator.of(context).pop();
            ref.read(receiptsProvider.notifier).setSearchQuery(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.of(context).pop();
              ref.read(receiptsProvider.notifier).setSearchQuery('');
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(receiptsProvider.notifier).setSearchQuery(_searchController.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }


}
