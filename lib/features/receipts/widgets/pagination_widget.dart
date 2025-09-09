import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/receipts_provider.dart';

/// Widget that displays pagination controls and loading states
class PaginationWidget extends ConsumerWidget {
  final VoidCallback? onLoadMore;
  final bool showLoadMoreButton;

  const PaginationWidget({
    super.key,
    this.onLoadMore,
    this.showLoadMoreButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);

    if (receiptsState.isLoading) {
      return _buildLoadingIndicator(context);
    }

    if (!receiptsState.hasMore) {
      return _buildEndOfListIndicator(context, receiptsState);
    }

    if (showLoadMoreButton) {
      return _buildLoadMoreButton(context, ref);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Loading receipts...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfListIndicator(BuildContext context, ReceiptsState state) {
    if (state.receipts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'All receipts loaded',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${state.totalCount} total receipts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            onLoadMore?.call();
            ref.read(receiptsProvider.notifier).loadMore();
          },
          icon: const Icon(Icons.expand_more),
          label: const Text('Load More'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }
}

/// Widget that shows pagination info at the top of the list
class PaginationInfoWidget extends ConsumerWidget {
  const PaginationInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);

    if (receiptsState.receipts.isEmpty && !receiptsState.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            _buildInfoText(receiptsState),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (receiptsState.hasActiveFilters) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Filtered',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildInfoText(ReceiptsState state) {
    final totalCount = state.totalCount;
    final totalAmount = state.totalAmount;

    if (totalCount == 0) {
      return 'No receipts';
    }

    final countText = totalCount == 1 ? '1 receipt' : '$totalCount receipts';
    final amountText = 'MYR ${totalAmount.toStringAsFixed(2)}';

    if (state.hasMore) {
      return '$countText loaded • $amountText';
    } else {
      return '$countText • $amountText';
    }
  }
}

/// Widget that provides pull-to-refresh functionality
class RefreshableReceiptsList extends ConsumerWidget {
  final Widget child;
  final ScrollController? scrollController;

  const RefreshableReceiptsList({
    super.key,
    required this.child,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(receiptsProvider.notifier).refresh();
      },
      child: child,
    );
  }
}

/// Mixin for handling scroll-based pagination
mixin ScrollPaginationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final receiptsNotifier = ref.read(receiptsProvider.notifier);

    if (receiptsNotifier.shouldLoadMore(
      scrollController.position.pixels,
      scrollController.position.maxScrollExtent,
    )) {
      receiptsNotifier.loadMore();
    }
  }
}

/// Widget that handles infinite scroll loading
class InfiniteScrollWrapper extends ConsumerStatefulWidget {
  final Widget Function(ScrollController controller) builder;
  final VoidCallback? onLoadMore;

  const InfiniteScrollWrapper({
    super.key,
    required this.builder,
    this.onLoadMore,
  });

  @override
  ConsumerState<InfiniteScrollWrapper> createState() =>
      _InfiniteScrollWrapperState();
}

class _InfiniteScrollWrapperState extends ConsumerState<InfiniteScrollWrapper>
    with ScrollPaginationMixin {
  @override
  Widget build(BuildContext context) {
    return widget.builder(scrollController);
  }

  @override
  void _onScroll() {
    super._onScroll();
    widget.onLoadMore?.call();
  }
}
