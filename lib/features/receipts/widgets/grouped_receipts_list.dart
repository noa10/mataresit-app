import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/grouped_receipts.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../core/constants/app_constants.dart';

import '../../categories/providers/categories_provider.dart';
import '../providers/receipts_provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/utils/confidence_utils.dart';
import '../../../shared/widgets/category_display.dart';
import '../../../shared/widgets/confidence_indicator.dart';
import 'pagination_widget.dart';

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
    if (widget.groupedReceipts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Pagination info at the top
        const PaginationInfoWidget(),

        // Main list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: widget.groupedReceipts.length + 1, // +1 for pagination widget
            itemBuilder: (context, index) {
              if (index >= widget.groupedReceipts.length) {
                return PaginationWidget(
                  onLoadMore: widget.onLoadMore,
                  showLoadMoreButton: false, // Use automatic loading
                );
              }

              final group = widget.groupedReceipts[index];
              return _buildDateGroup(group);
            },
          ),
        ),
      ],
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final receiptsState = ref.watch(receiptsProvider);
    final receiptsNotifier = ref.read(receiptsProvider.notifier);
    final isSelected = receiptsNotifier.isReceiptSelected(receipt.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        onChanged: (value) => receiptsNotifier.toggleReceiptSelection(receipt.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Merchant name or placeholder
                    Expanded(
                      child: Text(
                        receipt.merchantName ?? 'Unknown Merchant',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Amount with standardized currency formatting
                    Text(
                      CurrencyUtils.formatCurrencySafe(
                        receipt.totalAmount,
                        receipt.currency,
                        fallbackCurrency: 'MYR',
                      ),
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
                  // Category - Use real category data with fallback
                  Consumer(
                    builder: (context, ref, child) {
                      // Watch the categories state to ensure they're loaded
                      final categoriesState = ref.watch(categoriesProvider);

                      // Find the category from display categories (includes both team and personal)
                      CategoryModel? category;
                      if (receipt.customCategoryId != null) {
                        category = categoriesState.displayCategories
                            .where((cat) => cat.id == receipt.customCategoryId)
                            .firstOrNull;

                        // If category not found by ID, try to find by name (case-insensitive)
                        if (category == null && receipt.category != null) {
                          category = categoriesState.displayCategories
                              .where((cat) => cat.name.toLowerCase() == receipt.category!.toLowerCase())
                              .firstOrNull;
                        }

                        // If still not found, try partial name matching for common variations
                        if (category == null && receipt.category != null) {
                          final categoryName = receipt.category!.toLowerCase();

                          // Handle common category name mappings
                          if (categoryName.contains('grocer') || categoryName.contains('food')) {
                            category = categoriesState.displayCategories
                                .where((cat) => cat.name.toLowerCase().contains('food') ||
                                              cat.name.toLowerCase().contains('dining') ||
                                              cat.name.toLowerCase().contains('grocer'))
                                .firstOrNull;
                          } else if (categoryName.contains('shop')) {
                            category = categoriesState.displayCategories
                                .where((cat) => cat.name.toLowerCase().contains('shop'))
                                .firstOrNull;
                          }
                        }
                      }

                      return CategoryDisplay(
                        category: category,
                        size: CategoryDisplaySize.small,
                      );
                    },
                  ),
                  const SizedBox(width: 8),

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

                  // Confidence score indicator (match React web aggregate + ai_suggestions fallback)
                  Builder(
                    builder: (context) {
                      final hasConfidence =
                          (receipt.aiSuggestions != null && receipt.aiSuggestions!.containsKey('confidence')) ||
                          (receipt.confidenceScores != null && receipt.confidenceScores!.isNotEmpty);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CompactConfidenceIndicator(
                            score: hasConfidence ? ConfidenceUtils.calculateAggregateConfidence(receipt) : null,
                            loading: !hasConfidence && receipt.processingStatus == ProcessingStatus.processing,
                          ),
                          const SizedBox(width: 8),
                        ],
                      );
                    },
                  ),

                  // Status indicator
                  _buildStatusIndicator(receipt.status),
                ],
              ),

              // Review status badge
              const SizedBox(height: 4),
              _buildReviewStatusBadge(receipt.status),
            ],
          ),
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

  Widget _buildReviewStatusBadge(ReceiptStatus status) {
    String text;
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ReceiptStatus.active: // This maps to "reviewed"
        text = 'Reviewed';
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue.shade700;
        break;
      case ReceiptStatus.draft: // This maps to "unreviewed"
        text = 'Unreviewed';
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        break;
      case ReceiptStatus.archived:
        text = 'Archived';
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey.shade700;
        break;
      case ReceiptStatus.deleted:
        text = 'Deleted';
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
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
