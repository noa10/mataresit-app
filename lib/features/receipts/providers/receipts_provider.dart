import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/line_item_model.dart';
import '../../../shared/models/grouped_receipts.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../services/receipt_service.dart';

/// Receipts state
class ReceiptsState {
  final List<ReceiptModel> receipts;
  final List<GroupedReceipts> groupedReceipts;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final DateRange dateFilter;
  final String searchQuery;
  final ReceiptStatus? statusFilter;
  final List<String> categoryFilters;
  final ReviewedStatusFilter reviewedStatusFilter;
  final bool isGroupedView;

  // Selection mode properties
  final bool isSelectionMode;
  final Set<String> selectedReceiptIds;
  final bool isPerformingBulkOperation;

  const ReceiptsState({
    this.receipts = const [],
    this.groupedReceipts = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
    DateRange? dateFilter,
    this.searchQuery = '',
    this.statusFilter,
    this.categoryFilters = const [],
    this.reviewedStatusFilter = ReviewedStatusFilter.all,
    this.isGroupedView = true,
    this.isSelectionMode = false,
    this.selectedReceiptIds = const {},
    this.isPerformingBulkOperation = false,
  }) : dateFilter = dateFilter ?? const DateRange(option: DateFilterOption.all);

  ReceiptsState copyWith({
    List<ReceiptModel>? receipts,
    List<GroupedReceipts>? groupedReceipts,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    DateRange? dateFilter,
    String? searchQuery,
    ReceiptStatus? statusFilter,
    List<String>? categoryFilters,
    ReviewedStatusFilter? reviewedStatusFilter,
    bool? isGroupedView,
    bool? isSelectionMode,
    Set<String>? selectedReceiptIds,
    bool? isPerformingBulkOperation,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) {
    return ReceiptsState(
      receipts: receipts ?? this.receipts,
      groupedReceipts: groupedReceipts ?? this.groupedReceipts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      categoryFilters: categoryFilters ?? this.categoryFilters,
      reviewedStatusFilter: reviewedStatusFilter ?? this.reviewedStatusFilter,
      isGroupedView: isGroupedView ?? this.isGroupedView,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedReceiptIds: selectedReceiptIds ?? this.selectedReceiptIds,
      isPerformingBulkOperation:
          isPerformingBulkOperation ?? this.isPerformingBulkOperation,
    );
  }

  /// Get total receipts count
  int get totalCount => receipts.length;

  /// Get total amount for current receipts
  double get totalAmount => receipts.fold<double>(
    0.0,
    (sum, receipt) => sum + (receipt.totalAmount ?? 0.0),
  );

  /// Check if any filters are active
  bool get hasActiveFilters =>
      dateFilter.option != DateFilterOption.all ||
      searchQuery.isNotEmpty ||
      statusFilter != null ||
      categoryFilters.isNotEmpty ||
      reviewedStatusFilter != ReviewedStatusFilter.all;
}

/// Receipts notifier
class ReceiptsNotifier extends StateNotifier<ReceiptsState> {
  final Ref ref;

  ReceiptsNotifier(this.ref) : super(const ReceiptsState()) {
    // Listen to workspace changes and refresh receipts when workspace switches
    ref.listen<CurrentTeamState>(currentTeamProvider, (previous, next) {
      // Only refresh if the current team actually changed
      if (previous?.currentTeam?.id != next.currentTeam?.id) {
        AppLogger.info(
          '🔄 Workspace changed from ${previous?.currentTeam?.name ?? "Personal"} to ${next.currentTeam?.name ?? "Personal"}, refreshing receipts',
        );
        // Pass the new team state to ensure we use the updated context
        loadReceipts(refresh: true, teamContext: next);
      }
    });

    loadReceipts();
  }

  /// Load receipts for the current user
  Future<void> loadReceipts({
    bool refresh = false,
    CurrentTeamState? teamContext,
  }) async {
    try {
      if (refresh) {
        state = state.copyWith(
          receipts: [],
          groupedReceipts: [],
          currentPage: 0,
          hasMore: true,
          clearError: true,
        );
      }

      if (state.isLoading || !state.hasMore) return;

      state = state.copyWith(isLoading: true, clearError: true);

      final user = ref.read(currentUserProvider);
      if (user == null) {
        AppLogger.warning('⚠️ No authenticated user found');
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Enhanced authentication check - verify session is still valid
      final currentUser = SupabaseService.client.auth.currentUser;
      final session = SupabaseService.client.auth.currentSession;

      AppLogger.info(
        '🔐 Enhanced auth check: user: ${user.id} (${user.email}), currentUser: ${currentUser?.id}, hasSession: ${session != null}',
      );

      if (currentUser == null || session == null) {
        AppLogger.error('❌ Session invalid or expired');
        state = state.copyWith(
          isLoading: false,
          error: 'Session expired. Please login again.',
        );
        return;
      }

      // Try to load from database
      List<ReceiptModel> newReceipts = [];
      try {
        // Get current workspace context - use provided context if available
        final currentTeamState = teamContext ?? ref.read(currentTeamProvider);
        final currentTeam = currentTeamState?.currentTeam;

        AppLogger.info(
          '🔍 Fetching receipts for user: ${user.id} in workspace: ${currentTeam?.name ?? "Personal"}',
        );

        // Build query with date filtering - Fix duplicate foreign key relationship issue
        var query = SupabaseService.client.from('receipts').select('''
              *,
              custom_categories (
                id,
                name,
                color,
                icon
              ),
              line_items!line_items_receipt_id_fkey (
                id,
                receipt_id,
                description,
                amount,
                created_at,
                updated_at
              )
            ''');

        // Apply workspace-based filtering
        if (currentTeam?.id != null) {
          // When in team context, fetch team receipts using RLS policies
          AppLogger.info(
            '🧾 Fetching team receipts for team: ${currentTeam!.id} (${currentTeam.name})',
          );
          query = query.eq('team_id', currentTeam.id);
        } else {
          // When in personal workspace, fetch personal receipts (team_id is null)
          AppLogger.info(
            '🧾 Fetching personal receipts for user: ${user.email}',
          );
          query = query.eq('user_id', user.id).isFilter('team_id', null);
        }

        // Apply date filtering
        if (state.dateFilter.hasDateRange) {
          if (state.dateFilter.startDate != null) {
            query = query.gte(
              'date',
              state.dateFilter.startDate!.toIso8601String().split('T')[0],
            );
          }
          if (state.dateFilter.endDate != null) {
            query = query.lte(
              'date',
              state.dateFilter.endDate!.toIso8601String().split('T')[0],
            );
          }
        }

        // Apply status filtering
        if (state.statusFilter != null) {
          query = query.eq('status', state.statusFilter!.name);
        }

        // Apply reviewed status filtering
        if (state.reviewedStatusFilter != ReviewedStatusFilter.all) {
          final statusValue = state.reviewedStatusFilter.receiptStatus?.name;
          if (statusValue != null) {
            query = query.eq('status', statusValue);
          }
        }

        // Apply category filtering
        if (state.categoryFilters.isNotEmpty) {
          // Use 'in' filter for multiple categories
          query = query.inFilter('custom_category_id', state.categoryFilters);
        }

        // Apply search filtering (server-side text search)
        if (state.searchQuery.isNotEmpty) {
          query = query.or(
            'merchant.ilike.%${state.searchQuery}%,predicted_category.ilike.%${state.searchQuery}%,fullText.ilike.%${state.searchQuery}%',
          );
        }

        final response = await query
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .range(state.currentPage * 20, (state.currentPage + 1) * 20 - 1);

        AppLogger.info('🔍 Raw database response: ${response.toString()}');

        AppLogger.info(
          '📊 Loaded ${(response as List).length} receipts from database for ${currentTeam?.name ?? "Personal"} workspace',
        );

        newReceipts = (response as List)
            .map((json) => _mapDatabaseToModel(json))
            .toList();

        // Debug: Log filtering results
        AppLogger.info('🔍 Workspace filtering results:');
        AppLogger.info(
          '  - Current workspace: ${currentTeam?.name ?? "Personal"}',
        );
        AppLogger.info(
          '  - Team ID filter: ${currentTeam?.id ?? "null (personal)"}',
        );
        AppLogger.info('  - Receipts found: ${newReceipts.length}');
        if (newReceipts.isNotEmpty) {
          final teamReceipts = newReceipts
              .where((r) => r.teamId != null)
              .length;
          final personalReceipts = newReceipts
              .where((r) => r.teamId == null)
              .length;
          AppLogger.info(
            '  - Team receipts: $teamReceipts, Personal receipts: $personalReceipts',
          );
        }

        // Debug: Log category information
        final receiptsWithCategories = newReceipts
            .where((r) => r.customCategoryId != null)
            .length;
        AppLogger.info(
          '🏷️ $receiptsWithCategories out of ${newReceipts.length} receipts have custom_category_id',
        );

        // Debug: Log first few receipts' category data
        for (int i = 0; i < newReceipts.length && i < 3; i++) {
          final receipt = newReceipts[i];
          AppLogger.info(
            '🧾 Receipt ${receipt.id}: customCategoryId=${receipt.customCategoryId}, category=${receipt.category}, merchant=${receipt.merchantName}',
          );
        }

        // Debug: Log the raw response to see what we're getting from the database
        if ((response as List).isNotEmpty) {
          final firstReceipt = (response as List).first;
          AppLogger.info(
            '🔍 Raw database response for first receipt: ${firstReceipt.toString()}',
          );
        }

        AppLogger.info('✅ Successfully mapped ${newReceipts.length} receipts');
      } catch (e) {
        AppLogger.error('❌ Failed to load receipts from database', e);
        state = state.copyWith(
          isLoading: false,
          error:
              'Could not load receipts. Check your connection and try again.',
        );
        return;
      }

      final allReceipts = refresh
          ? newReceipts
          : [...state.receipts, ...newReceipts];

      // Group receipts by date if grouped view is enabled
      final groupedReceipts = state.isGroupedView
          ? ReceiptGrouper.groupReceiptsByDate(allReceipts)
          : <GroupedReceipts>[];

      state = state.copyWith(
        receipts: allReceipts,
        groupedReceipts: groupedReceipts,
        isLoading: false,
        hasMore: newReceipts.length == 20,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Map database JSON to ReceiptModel
  ReceiptModel _mapDatabaseToModel(Map<String, dynamic> json) {
    // Parse line items if they exist
    List<LineItemModel>? lineItems;
    if (json['line_items'] != null) {
      final lineItemsData = json['line_items'] as List;
      lineItems = lineItemsData
          .map((item) => LineItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ReceiptModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      teamId: json['team_id'],
      merchantName:
          json['merchant'], // Database uses 'merchant', model uses 'merchantName'
      transactionDate: json['date'] != null
          ? DateTime.parse(json['date'])
          : null,
      totalAmount: json['total'] != null
          ? double.tryParse(json['total'].toString())
          : null,
      taxAmount: json['tax'] != null
          ? double.tryParse(json['tax'].toString())
          : null,
      currency: CurrencyUtils.normalizeCurrencyCode(json['currency'] ?? 'MYR'),
      paymentMethod: json['payment_method'],
      category: json['predicted_category'],
      customCategoryId:
          json['custom_category_id'], // Add the missing custom_category_id field
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      status: _parseReceiptStatus(json['status']),
      processingStatus: _parseProcessingStatus(json['processing_status']),
      isExpense: true, // Default to expense
      isReimbursable: false, // Default to not reimbursable
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      ocrData: json['ai_suggestions'],
      metadata: json['fullText'] != null
          ? {'fullText': json['fullText']}
          : null,
      lineItems: lineItems,
      confidenceScores: json['confidence_scores'] as Map<String, dynamic>?,
      aiSuggestions: json['ai_suggestions'] as Map<String, dynamic>?,
    );
  }

  /// Parse receipt status from string
  ReceiptStatus _parseReceiptStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'unreviewed':
        return ReceiptStatus.unreviewed;
      case 'reviewed':
        return ReceiptStatus.reviewed;
      default:
        return ReceiptStatus.unreviewed;
    }
  }

  /// Parse processing status from string
  ProcessingStatus _parseProcessingStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'complete':
      case 'completed':
        return ProcessingStatus.completed;
      case 'processing':
        return ProcessingStatus.processing;
      case 'failed':
        return ProcessingStatus.failed;
      default:
        return ProcessingStatus.completed;
    }
  }

  /// Add a new receipt to the list
  void addReceipt(ReceiptModel receipt) {
    state = state.copyWith(receipts: [receipt, ...state.receipts]);
  }

  /// Update a receipt in the list
  void updateReceipt(ReceiptModel updatedReceipt) {
    final updatedReceipts = state.receipts.map((receipt) {
      return receipt.id == updatedReceipt.id ? updatedReceipt : receipt;
    }).toList();

    state = state.copyWith(receipts: updatedReceipts);
  }

  /// Delete a receipt
  Future<void> deleteReceipt(String receiptId) async {
    try {
      // Try to delete from database
      try {
        await SupabaseService.client
            .from('receipts')
            .delete()
            .eq('id', receiptId);
      } catch (e) {
        AppLogger.warning('Failed to delete receipt from database', e);
        // Continue anyway - remove from local state
      }

      // Remove from local state
      final updatedReceipts = state.receipts
          .where((receipt) => receipt.id != receiptId)
          .toList();

      state = state.copyWith(receipts: updatedReceipts);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete receipt: ${e.toString()}',
      );
    }
  }

  /// Set date filter and reload receipts
  Future<void> setDateFilter(DateRange dateFilter) async {
    state = state.copyWith(dateFilter: dateFilter);
    await loadReceipts(refresh: true);
  }

  /// Set search query and reload receipts
  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadReceipts(refresh: true);
  }

  /// Set status filter and reload receipts
  Future<void> setStatusFilter(ReceiptStatus? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await loadReceipts(refresh: true);
  }

  /// Set category filters and reload receipts
  Future<void> setCategoryFilters(List<String> categoryIds) async {
    state = state.copyWith(categoryFilters: categoryIds);
    await loadReceipts(refresh: true);
  }

  /// Add a category to the filter list
  Future<void> addCategoryFilter(String categoryId) async {
    if (!state.categoryFilters.contains(categoryId)) {
      final newFilters = [...state.categoryFilters, categoryId];
      await setCategoryFilters(newFilters);
    }
  }

  /// Remove a category from the filter list
  Future<void> removeCategoryFilter(String categoryId) async {
    final newFilters = state.categoryFilters
        .where((id) => id != categoryId)
        .toList();
    await setCategoryFilters(newFilters);
  }

  /// Set reviewed status filter and reload receipts
  Future<void> setReviewedStatusFilter(ReviewedStatusFilter filter) async {
    state = state.copyWith(reviewedStatusFilter: filter);
    await loadReceipts(refresh: true);
  }

  /// Apply multiple filters at once to avoid multiple API calls
  Future<void> applyFilters({
    DateRange? dateFilter,
    String? searchQuery,
    ReceiptStatus? statusFilter,
    List<String>? categoryFilters,
    ReviewedStatusFilter? reviewedStatusFilter,
    bool clearStatusFilter = false,
  }) async {
    state = state.copyWith(
      dateFilter: dateFilter,
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      categoryFilters: categoryFilters,
      reviewedStatusFilter: reviewedStatusFilter,
      clearStatusFilter: clearStatusFilter,
    );
    await loadReceipts(refresh: true);
  }

  /// Toggle between grouped and flat view
  void toggleGroupedView() {
    final newGroupedView = !state.isGroupedView;
    final groupedReceipts = newGroupedView
        ? ReceiptGrouper.groupReceiptsByDate(state.receipts)
        : <GroupedReceipts>[];

    state = state.copyWith(
      isGroupedView: newGroupedView,
      groupedReceipts: groupedReceipts,
    );
  }

  /// Clear all filters
  Future<void> clearAllFilters() async {
    state = state.copyWith(
      dateFilter: const DateRange(option: DateFilterOption.all),
      searchQuery: '',
      clearStatusFilter: true,
      categoryFilters: const [],
      reviewedStatusFilter: ReviewedStatusFilter.all,
    );
    await loadReceipts(refresh: true);
  }

  /// Apply quick date filter
  Future<void> applyQuickDateFilter(DateFilterOption option) async {
    final dateRange = AppDateUtils.getDateRangeForOption(option);
    await setDateFilter(dateRange);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh receipts
  Future<void> refresh() async {
    AppLogger.info(
      '🔄 Manual refresh triggered - clearing cache and reloading receipts',
    );
    await loadReceipts(refresh: true);
    AppLogger.info(
      '✅ Manual refresh completed - ${state.receipts.length} receipts loaded',
    );
  }

  /// Load more receipts (for pagination)
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      AppLogger.info(
        '📄 Loading more receipts - Page ${state.currentPage + 1}',
      );
      await loadReceipts();
    } else if (!state.hasMore) {
      AppLogger.info('📄 No more receipts to load');
    } else {
      AppLogger.info('📄 Already loading receipts, skipping loadMore');
    }
  }

  /// Check if we should load more receipts based on scroll position
  bool shouldLoadMore(double scrollPosition, double maxScrollExtent) {
    const double threshold = 200.0; // Load when 200px from bottom
    return scrollPosition >= (maxScrollExtent - threshold) &&
        !state.isLoading &&
        state.hasMore;
  }

  /// Get receipts for a specific date
  List<ReceiptModel> getReceiptsForDate(DateTime date) {
    final dateKey = AppDateUtils.getDateKey(date);
    return state.receipts.where((receipt) {
      final receiptDate = receipt.transactionDate ?? receipt.createdAt;
      return AppDateUtils.getDateKey(receiptDate) == dateKey;
    }).toList();
  }

  /// Get receipt count for a specific date
  int getReceiptCountForDate(DateTime date) {
    return getReceiptsForDate(date).length;
  }

  // Selection Mode Methods

  /// Toggle selection mode on/off
  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedReceiptIds: const {}, // Clear selections when toggling
    );
  }

  /// Select or deselect a receipt
  void toggleReceiptSelection(String receiptId) {
    final selectedIds = Set<String>.from(state.selectedReceiptIds);

    if (selectedIds.contains(receiptId)) {
      selectedIds.remove(receiptId);
    } else {
      selectedIds.add(receiptId);
    }

    state = state.copyWith(selectedReceiptIds: selectedIds);
  }

  /// Select all visible receipts
  void selectAllReceipts() {
    final allReceiptIds = state.receipts.map((receipt) => receipt.id).toSet();
    state = state.copyWith(selectedReceiptIds: allReceiptIds);
  }

  /// Clear all selections
  void clearSelection() {
    state = state.copyWith(selectedReceiptIds: const {});
  }

  /// Get count of selected receipts
  int get selectedCount => state.selectedReceiptIds.length;

  /// Check if all receipts are selected
  bool get isAllSelected =>
      state.receipts.isNotEmpty &&
      state.selectedReceiptIds.length == state.receipts.length;

  /// Check if a receipt is selected
  bool isReceiptSelected(String receiptId) {
    return state.selectedReceiptIds.contains(receiptId);
  }

  // Bulk Operations

  /// Bulk delete selected receipts
  Future<void> bulkDeleteReceipts() async {
    if (state.selectedReceiptIds.isEmpty) return;

    state = state.copyWith(isPerformingBulkOperation: true);

    try {
      final receiptIds = state.selectedReceiptIds.toList();
      int successCount = 0;
      int failureCount = 0;

      // Delete receipts one by one and count results
      for (final receiptId in receiptIds) {
        try {
          await SupabaseService.client
              .from('receipts')
              .delete()
              .eq('id', receiptId);
          successCount++;
        } catch (e) {
          AppLogger.error('Failed to delete receipt $receiptId: $e');
          failureCount++;
        }
      }

      // Remove successfully deleted receipts from state
      if (successCount > 0) {
        final updatedReceipts = state.receipts
            .where((receipt) => !receiptIds.contains(receipt.id))
            .toList();

        final groupedReceipts = state.isGroupedView
            ? ReceiptGrouper.groupReceiptsByDate(updatedReceipts)
            : <GroupedReceipts>[];

        state = state.copyWith(
          receipts: updatedReceipts,
          groupedReceipts: groupedReceipts,
          isSelectionMode: false,
          selectedReceiptIds: const {},
          isPerformingBulkOperation: false,
        );

        AppLogger.info('✅ Successfully deleted $successCount receipt(s)');
      }

      if (failureCount > 0) {
        AppLogger.warning('⚠️ Failed to delete $failureCount receipt(s)');
      }
    } catch (e) {
      AppLogger.error('❌ Bulk delete failed: $e');
      state = state.copyWith(
        isPerformingBulkOperation: false,
        error: 'Failed to delete receipts: $e',
      );
    }
  }

  /// Bulk assign category to selected receipts
  Future<void> bulkAssignCategory(String? categoryId) async {
    if (state.selectedReceiptIds.isEmpty) return;

    state = state.copyWith(isPerformingBulkOperation: true);

    try {
      final receiptIds = state.selectedReceiptIds.toList();
      final updatedCount = await ref
          .read(categoriesProvider.notifier)
          .bulkAssignCategory(receiptIds, categoryId: categoryId);

      if (updatedCount > 0) {
        // Refresh receipts to get updated category assignments
        await loadReceipts(refresh: true);

        state = state.copyWith(
          isSelectionMode: false,
          selectedReceiptIds: const {},
          isPerformingBulkOperation: false,
        );

        AppLogger.info(
          '✅ Successfully assigned category to $updatedCount receipt(s)',
        );
      } else {
        state = state.copyWith(isPerformingBulkOperation: false);
        AppLogger.warning('⚠️ No receipts were updated');
      }
    } catch (e) {
      AppLogger.error('❌ Bulk category assignment failed: $e');
      state = state.copyWith(
        isPerformingBulkOperation: false,
        error: 'Failed to assign category: $e',
      );
    }
  }

  /// Update a specific receipt in the receipts list
  void updateReceiptInList(ReceiptModel updatedReceipt) {
    final currentReceipts = List<ReceiptModel>.from(state.receipts);
    final index = currentReceipts.indexWhere((r) => r.id == updatedReceipt.id);

    if (index != -1) {
      // Update existing receipt
      currentReceipts[index] = updatedReceipt;
      AppLogger.info('✅ Updated receipt ${updatedReceipt.id} in receipts list');
    } else {
      // Add new receipt if not found
      currentReceipts.insert(0, updatedReceipt);
      AppLogger.info(
        '✅ Added new receipt ${updatedReceipt.id} to receipts list',
      );
    }

    // Recalculate grouped receipts if grouped view is enabled
    final groupedReceipts = state.isGroupedView
        ? ReceiptGrouper.groupReceiptsByDate(currentReceipts)
        : state.groupedReceipts;

    state = state.copyWith(
      receipts: currentReceipts,
      groupedReceipts: groupedReceipts,
    );
  }
}

/// Receipts provider
final receiptsProvider = StateNotifierProvider<ReceiptsNotifier, ReceiptsState>(
  (ref) {
    return ReceiptsNotifier(ref);
  },
);

/// Individual receipt provider with database refresh capability
final receiptProvider = FutureProvider.family<ReceiptModel?, String>((
  ref,
  receiptId,
) async {
  // First try to get from the main receipts list
  final receipts = ref.watch(receiptsProvider).receipts;
  try {
    final cachedReceipt = receipts.firstWhere(
      (receipt) => receipt.id == receiptId,
    );
    return cachedReceipt;
  } catch (e) {
    // If not found in cache, fetch directly from database
    try {
      final receipt = await ReceiptService.getReceiptWithLineItems(receiptId);
      return receipt;
    } catch (dbError) {
      AppLogger.error('❌ Failed to fetch receipt $receiptId: $dbError');
      return null;
    }
  }
});

/// Provider for refreshing a specific receipt from database
final refreshReceiptProvider = FutureProvider.family<ReceiptModel?, String>((
  ref,
  receiptId,
) async {
  try {
    AppLogger.info('🔄 Refreshing receipt $receiptId from database');
    final receipt = await ReceiptService.getReceiptWithLineItems(receiptId);

    if (receipt != null) {
      // Update the main receipts list with the refreshed data
      final receiptsNotifier = ref.read(receiptsProvider.notifier);
      receiptsNotifier.updateReceiptInList(receipt);
    }

    return receipt;
  } catch (error) {
    AppLogger.error('❌ Failed to refresh receipt $receiptId: $error');
    return null;
  }
});
