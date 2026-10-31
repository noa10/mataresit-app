import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/guards/subscription_guard.dart';
import '../../../app/router/app_router.dart';
import '../providers/receipts_provider.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/utils/date_utils.dart';

import '../../categories/providers/categories_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../widgets/date_filter_bar.dart';
import '../widgets/grouped_receipts_list.dart';
import '../widgets/receipt_ledger_row.dart';
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
  final FocusNode _searchFocus = FocusNode();
  late final WidgetRef _ref;

  @override
  void initState() {
    super.initState();
    _ref = ref;
    _searchController.text = _ref.read(receiptsProvider).searchQuery;
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
    _searchFocus.dispose();
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
      case 'search_all':
        // The AppBar search icon filters this list in place; this opens the
        // unified search surface, which queries receipts, categories and the
        // business directory together.
        context.push(AppRoutes.search);
        break;
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

    ref.listen<ReceiptsState>(receiptsProvider, (previous, next) {
      if (previous?.searchQuery != next.searchQuery &&
          _searchController.text != next.searchQuery) {
        _searchController.value = TextEditingValue(
          text: next.searchQuery,
          selection: TextSelection.collapsed(offset: next.searchQuery.length),
        );
      }
    });

    // Listen for team changes and reload categories
    ref.listen<TeamModel?>(currentTeamModelProvider, (previous, next) {
      if (previous?.id != next?.id) {
        // Team changed, reload categories with new team context
        ref.read(categoriesProvider.notifier).loadCategories(teamId: next?.id);
      }
    });

    return Scaffold(
      body: Column(
        children: [
          _buildPageHeader(receiptsState),
          if (!receiptsState.isSelectionMode) _buildFilterPanel(receiptsState),

          // Selection mode bar
          const AdaptiveSelectionModeBar(),

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

  Widget _buildPageHeader(ReceiptsState receiptsState) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INBOX',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Receipts',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFamily: 'InstrumentSerif',
                        fontSize: 32,
                        height: 1.05,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (!receiptsState.isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  tooltip: 'Search receipts',
                  onPressed: () => _searchFocus.requestFocus(),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  onPressed: () => _handleCaptureReceipt(context, ref),
                  tooltip: 'Capture Receipt',
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'search_all',
                      child: ListTile(
                        leading: const Icon(Icons.manage_search),
                        title: Text('search.title'.tr()),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
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
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'Search, filter and open any receipt.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(ReceiptsState receiptsState) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildSearchField(),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          DateFilterBar(
            onFilterChanged: () {
              // Optional: Add any additional logic when filters change
            },
          ),
          if (receiptsState.hasActiveFilters) ...[
            Divider(height: 1, thickness: 1, color: colors.outlineVariant),
            _buildActiveFilters(receiptsState),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilters(ReceiptsState receiptsState) {
    final categoriesState = ref.watch(categoriesProvider);
    final chips = <Widget>[];

    if (receiptsState.dateFilter.option != DateFilterOption.all) {
      chips.add(
        _buildActiveFilterChip(
          label: AppDateUtils.getFilterOptionDisplayName(
            receiptsState.dateFilter.option,
          ),
          onDeleted: () => ref
              .read(receiptsProvider.notifier)
              .setDateFilter(const DateRange(option: DateFilterOption.all)),
        ),
      );
    }

    if (receiptsState.searchQuery.isNotEmpty) {
      chips.add(
        _buildActiveFilterChip(
          label: 'Search: "${receiptsState.searchQuery}"',
          onDeleted: () =>
              ref.read(receiptsProvider.notifier).setSearchQuery(''),
        ),
      );
    }

    if (receiptsState.statusFilter != null) {
      chips.add(
        _buildActiveFilterChip(
          label: 'Status: ${receiptsState.statusFilter!.displayName}',
          onDeleted: () =>
              ref.read(receiptsProvider.notifier).setStatusFilter(null),
        ),
      );
    }

    for (final categoryId in receiptsState.categoryFilters) {
      final category = categoriesState.categories
          .where((item) => item.id == categoryId)
          .firstOrNull;
      if (category == null) continue;
      chips.add(
        _buildActiveFilterChip(
          label: category.name,
          onDeleted: () => ref
              .read(receiptsProvider.notifier)
              .removeCategoryFilter(categoryId),
        ),
      );
    }

    if (receiptsState.reviewedStatusFilter != ReviewedStatusFilter.all) {
      chips.add(
        _buildActiveFilterChip(
          label: receiptsState.reviewedStatusFilter.displayName,
          onDeleted: () => ref
              .read(receiptsProvider.notifier)
              .setReviewedStatusFilter(ReviewedStatusFilter.all),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          TextButton(
            onPressed: () =>
                ref.read(receiptsProvider.notifier).clearAllFilters(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: InputChip(
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall,
        ),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 14),
        deleteIconColor: colors.onSurfaceVariant,
        backgroundColor: colors.surfaceContainerHighest,
        side: BorderSide(color: colors.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildMainContent(ReceiptsState receiptsState) {
    if (receiptsState.receipts.isEmpty && receiptsState.error != null) {
      return _buildErrorState(receiptsState.error!);
    }

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

  Widget _buildErrorState(String error) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 40, color: colors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Couldn\'t load receipts',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(receiptsProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final receiptsState = ref.watch(receiptsProvider);
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
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
                    receiptsState.hasActiveFilters
                        ? 'No receipts match your filters'
                        : 'No receipts yet',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    receiptsState.hasActiveFilters
                        ? 'Try adjusting your date range or search terms'
                        : 'Start by capturing your first receipt',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (receiptsState.hasActiveFilters)
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(receiptsProvider.notifier).clearAllFilters(),
                      child: const Text('Clear Filters'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _handleCaptureReceipt(context, ref),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Capture Receipt'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlatReceiptsList(ReceiptsState receiptsState) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        const ReceiptLedgerInfo(),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (receiptsState.receipts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  sliver: DecoratedSliver(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    sliver: SliverList.separated(
                      itemCount: receiptsState.receipts.length,
                      itemBuilder: (context, index) => ReceiptLedgerRow(
                        receipt: receiptsState.receipts[index],
                        isFirst: index == 0,
                        isLast: index == receiptsState.receipts.length - 1,
                      ),
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.outlineVariant,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: PaginationWidget(
                  onLoadMore: () =>
                      ref.read(receiptsProvider.notifier).loadMore(),
                  showLoadMoreButton: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEARCH',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              ref.read(receiptsProvider.notifier).setSearchQuery(value);
              _searchFocus.unfocus();
            },
            decoration: InputDecoration(
              hintText: 'Search merchant, category or description',
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(receiptsProvider.notifier).setSearchQuery('');
                    },
                  );
                },
              ),
              filled: true,
              fillColor: colors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: colors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
