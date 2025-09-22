import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../../../core/guards/subscription_guard.dart';
import '../../../app/router/app_router.dart';
import '../providers/receipts_provider.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/category_model.dart';

import '../../categories/providers/categories_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/utils/confidence_utils.dart';
import '../../../shared/widgets/category_display.dart';
import '../../../shared/widgets/confidence_indicator.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/active_filters_widget.dart';
import '../widgets/grouped_receipts_list.dart';
import '../widgets/pagination_widget.dart';
import '../widgets/selection_mode_bar.dart';
import '../widgets/bulk_actions_bar.dart';

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
      _ref
          .read(categoriesProvider.notifier)
          .loadCategories(teamId: currentTeam?.id);
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

  Future<void> _handleCaptureReceipt(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Check subscription limits before allowing receipt capture
    final canUpload = await SubscriptionGuard.showReceiptLimitDialogIfNeeded(
      context,
      ref,
      additionalReceipts: 1,
    );

    if (canUpload && context.mounted) {
      context.push(AppRoutes.receiptCapture);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_receipt':
        context.push('/receipts/capture');
        break;
      case 'batch_upload':
        context.push('/receipts/batch-upload');
        break;
      case 'refresh':
        // Show a snackbar to indicate refresh is happening
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing receipts...'),
            duration: Duration(seconds: 2),
          ),
        );
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
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _handleCaptureReceipt(context, ref),
            tooltip: 'Capture Receipt',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_receipt',
                child: ListTile(
                  leading: Icon(Icons.add_a_photo),
                  title: Text('Add Receipt'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'batch_upload',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Batch Upload'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
          // Selection mode bar
          const AdaptiveSelectionModeBar(),

          // Date filter bar (only show when not in selection mode)
          Consumer(
            builder: (context, ref, child) {
              final receiptsState = ref.watch(receiptsProvider);
              if (receiptsState.isSelectionMode) {
                return const SizedBox.shrink();
              }
              return DateFilterBar(
                onFilterChanged: () {
                  // Optional: Add any additional logic when filters change
                },
              );
            },
          ),

          // Active filters indicator
          Consumer(
            builder: (context, ref, child) {
              final receiptsState = ref.watch(receiptsProvider);
              if (receiptsState.isSelectionMode ||
                  !receiptsState.hasActiveFilters) {
                return const SizedBox.shrink();
              }
              return ActiveFiltersWidget(
                onFilterChanged: () {
                  // Optional: Add any additional logic when filters change
                },
              );
            },
          ),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(receiptsProvider.notifier).refresh(),
              child: _buildMainContent(receiptsState),
            ),
          ),

          // Bulk actions bar (only show when items are selected)
          const BulkActionsBar(),
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
                onPressed: () =>
                    ref.read(receiptsProvider.notifier).clearAllFilters(),
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
            itemCount:
                receiptsState.receipts.length + 1, // +1 for pagination widget
            itemBuilder: (context, index) {
              if (index >= receiptsState.receipts.length) {
                return PaginationWidget(
                  onLoadMore: () =>
                      ref.read(receiptsProvider.notifier).loadMore(),
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
    final receiptsState = ref.watch(receiptsProvider);
    final receiptsNotifier = ref.read(receiptsProvider.notifier);
    final isSelected = receiptsNotifier.isReceiptSelected(receipt.id);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      elevation: isSelected ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: InkWell(
          onTap: receiptsState.isSelectionMode
              ? () => receiptsNotifier.toggleReceiptSelection(receipt.id)
              : () => context.push('/receipts/${receipt.id}'),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Selection checkbox (only show in selection mode)
                    if (receiptsState.isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) =>
                            receiptsNotifier.toggleReceiptSelection(receipt.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Merchant name or placeholder
                    Expanded(
                      child: Text(
                        receipt.merchantName ?? 'Unknown Merchant',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Amount with standardized currency formatting
                    if (receipt.totalAmount != null)
                      Text(
                        CurrencyUtils.formatCurrencySafe(
                          receipt.totalAmount,
                          receipt.currency,
                          fallbackCurrency: 'MYR',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Second row with confidence score (matching React web version layout)
                Row(
                  children: [
                    // Store icon and merchant name (smaller version)
                    Icon(
                      Icons.store,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        receipt.merchantName ?? 'Unknown Merchant',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Confidence score indicator (match React web aggregate + ai_suggestions fallback)
                    Builder(
                      builder: (context) {
                        final hasConfidence =
                            (receipt.aiSuggestions != null &&
                                receipt.aiSuggestions!.containsKey(
                                  'confidence',
                                )) ||
                            (receipt.confidenceScores != null &&
                                receipt.confidenceScores!.isNotEmpty);
                        return CompactConfidenceIndicator(
                          score: hasConfidence
                              ? ConfidenceUtils.calculateAggregateConfidence(
                                  receipt,
                                )
                              : null,
                          loading:
                              !hasConfidence &&
                              receipt.processingStatus ==
                                  ProcessingStatus.processing,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.smallPadding),

                // Details row
                Row(
                  children: [
                    // Category - Use real category data with fallback - wrapped in Flexible
                    Flexible(
                      flex: 2,
                      child: Consumer(
                        builder: (context, ref, child) {
                          // Watch the categories state to ensure they're loaded
                          final categoriesState = ref.watch(categoriesProvider);

                          // Find the category from display categories (includes both team and personal)
                          CategoryModel? category;
                          if (receipt.customCategoryId != null) {
                            category = categoriesState.displayCategories
                                .where(
                                  (cat) => cat.id == receipt.customCategoryId,
                                )
                                .firstOrNull;

                            // Debug logging for category lookup removed

                            // If category not found, try to create a fallback based on category field
                            if (category == null && receipt.category != null) {
                              // Look for a category with matching name (case-insensitive)
                              category = categoriesState.displayCategories
                                  .where(
                                    (cat) =>
                                        cat.name.toLowerCase() ==
                                        receipt.category!.toLowerCase(),
                                  )
                                  .firstOrNull;
                            }
                          }

                          return CategoryDisplay(
                            category: category,
                            size: CategoryDisplaySize.small,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),

                    // Processing status
                    _buildStatusChip(receipt.processingStatus),

                    const Spacer(),

                    // Date - wrapped in Flexible to prevent overflow
                    Flexible(
                      child: Text(
                        timeago.format(receipt.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
          Icon(icon, size: 12, color: color),
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
              ref
                  .read(receiptsProvider.notifier)
                  .setSearchQuery(_searchController.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
