import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/grouped_receipts.dart';
import '../providers/receipts_provider.dart';
import 'pagination_widget.dart';
import 'receipt_ledger_row.dart';

/// Displays the receipt ledger grouped by transaction date.
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
  ConsumerState<GroupedReceiptsList> createState() =>
      _GroupedReceiptsListState();
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
  void didUpdateWidget(covariant GroupedReceiptsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _scrollController.removeListener(_onScroll);
      if (oldWidget.scrollController == null) _scrollController.dispose();
      _scrollController = widget.scrollController ?? ScrollController();
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) _scrollController.dispose();
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
    final colors = Theme.of(context).colorScheme;
    final loading = ref.watch(receiptsProvider).isLoading;
    if (widget.groupedReceipts.isEmpty && !loading) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        const ReceiptLedgerInfo(),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              for (final group in widget.groupedReceipts)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  sliver: DecoratedSliver(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildDateHeader(context, group),
                        ),
                        SliverList.separated(
                          itemCount: group.receipts.length,
                          itemBuilder: (context, index) => ReceiptLedgerRow(
                            receipt: group.receipts[index],
                            showConvertedAmount: true,
                            showDate: false,
                            isLast: index == group.receipts.length - 1,
                          ),
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 1,
                            color: colors.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: PaginationWidget(
                  onLoadMore: widget.onLoadMore,
                  showLoadMoreButton: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context, GroupedReceipts group) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              group.displayName.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${group.count} • ${group.getFormattedTotal()}',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No receipts found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters or add some receipts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
