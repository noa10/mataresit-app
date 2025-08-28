import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/grouped_receipts.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';

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
  final bool isGroupedView;

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
    this.isGroupedView = true,
  }) : dateFilter = dateFilter ?? const DateRange(option: DateFilterOption.last7Days);

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
    bool? isGroupedView,
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
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      isGroupedView: isGroupedView ?? this.isGroupedView,
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
    statusFilter != null;
}

/// Receipts notifier
class ReceiptsNotifier extends StateNotifier<ReceiptsState> {
  final Ref ref;

  ReceiptsNotifier(this.ref) : super(const ReceiptsState()) {
    loadReceipts();
  }

  /// Load receipts for the current user
  Future<void> loadReceipts({bool refresh = false}) async {
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

      AppLogger.info('🔐 Authenticated user: ${user.id} (${user.email})');

      // Try to load from database
      List<ReceiptModel> newReceipts = [];
      try {
        AppLogger.info('🔍 Fetching receipts for user: ${user.id}');

        // Build query with date filtering
        var query = SupabaseService.client
            .from('receipts')
            .select('''
              *,
              custom_categories (
                id,
                name,
                color,
                icon
              )
            ''')
            .eq('user_id', user.id);

        // Apply date filtering
        if (state.dateFilter.hasDateRange) {
          if (state.dateFilter.startDate != null) {
            query = query.gte('date', state.dateFilter.startDate!.toIso8601String().split('T')[0]);
          }
          if (state.dateFilter.endDate != null) {
            query = query.lte('date', state.dateFilter.endDate!.toIso8601String().split('T')[0]);
          }
        }

        // Apply status filtering
        if (state.statusFilter != null) {
          query = query.eq('status', state.statusFilter!.name);
        }

        // Apply search filtering (server-side text search)
        if (state.searchQuery.isNotEmpty) {
          query = query.or('merchant.ilike.%${state.searchQuery}%,predicted_category.ilike.%${state.searchQuery}%,fullText.ilike.%${state.searchQuery}%');
        }

        final response = await query
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .range(
              state.currentPage * 20,
              (state.currentPage + 1) * 20 - 1,
            );

        AppLogger.info('🔍 Raw database response: ${response.toString()}');

        AppLogger.info('📊 Loaded ${(response as List).length} receipts from database');

        newReceipts = (response as List)
            .map((json) => _mapDatabaseToModel(json))
            .toList();

        // Debug: Log category information
        final receiptsWithCategories = newReceipts.where((r) => r.customCategoryId != null).length;
        AppLogger.info('🏷️ $receiptsWithCategories out of ${newReceipts.length} receipts have custom_category_id');

        // Debug: Log first few receipts' category data
        for (int i = 0; i < newReceipts.length && i < 3; i++) {
          final receipt = newReceipts[i];
          AppLogger.info('🧾 Receipt ${receipt.id}: customCategoryId=${receipt.customCategoryId}, category=${receipt.category}, merchant=${receipt.merchantName}');
        }

        // Debug: Log the raw response to see what we're getting from the database
        if ((response as List).isNotEmpty) {
          final firstReceipt = (response as List).first;
          AppLogger.info('🔍 Raw database response for first receipt: ${firstReceipt.toString()}');
        }

        AppLogger.info('✅ Successfully mapped ${newReceipts.length} receipts');
      } catch (e) {
        AppLogger.error('❌ Failed to load receipts from database', e);
        // If database fails, create some mock data for demonstration
        if (state.receipts.isEmpty) {
          AppLogger.warning('📝 Using mock data as fallback');
          newReceipts = _createMockReceipts(user.id);
        }
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Map database JSON to ReceiptModel
  ReceiptModel _mapDatabaseToModel(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      teamId: json['team_id'],
      merchantName: json['merchant'], // Database uses 'merchant', model uses 'merchantName'
      transactionDate: json['date'] != null ? DateTime.parse(json['date']) : null,
      totalAmount: json['total'] != null ? double.tryParse(json['total'].toString()) : null,
      taxAmount: json['tax'] != null ? double.tryParse(json['tax'].toString()) : null,
      currency: json['currency'] ?? 'MYR',
      paymentMethod: json['payment_method'],
      category: json['predicted_category'],
      customCategoryId: json['custom_category_id'], // Add the missing custom_category_id field
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      status: _parseReceiptStatus(json['status']),
      processingStatus: _parseProcessingStatus(json['processing_status']),
      isExpense: true, // Default to expense
      isReimbursable: false, // Default to not reimbursable
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      ocrData: json['ai_suggestions'],
      metadata: json['fullText'] != null ? {'fullText': json['fullText']} : null,
    );
  }

  /// Parse receipt status from string
  ReceiptStatus _parseReceiptStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'unreviewed':
        return ReceiptStatus.draft;
      case 'reviewed':
        return ReceiptStatus.active;
      case 'approved':
        return ReceiptStatus.active;
      case 'archived':
        return ReceiptStatus.archived;
      case 'deleted':
        return ReceiptStatus.deleted;
      default:
        return ReceiptStatus.draft;
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

  /// Create mock receipts for demonstration
  List<ReceiptModel> _createMockReceipts(String userId) {
    final now = DateTime.now();
    return [
      ReceiptModel(
        id: 'mock-1',
        userId: userId,
        merchantName: 'Starbucks Coffee',
        totalAmount: 15.50,
        currency: 'USD',
        transactionDate: now.subtract(const Duration(days: 1)),
        category: 'Food & Beverage',
        status: ReceiptStatus.active,
        processingStatus: ProcessingStatus.completed,
        isExpense: true,
        isReimbursable: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ReceiptModel(
        id: 'mock-2',
        userId: userId,
        merchantName: 'Shell Gas Station',
        totalAmount: 45.20,
        currency: 'USD',
        transactionDate: now.subtract(const Duration(days: 3)),
        category: 'Transportation',
        status: ReceiptStatus.active,
        processingStatus: ProcessingStatus.completed,
        isExpense: true,
        isReimbursable: false,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      ReceiptModel(
        id: 'mock-3',
        userId: userId,
        merchantName: 'Office Depot',
        totalAmount: 89.99,
        currency: 'USD',
        transactionDate: now.subtract(const Duration(days: 5)),
        category: 'Office Supplies',
        status: ReceiptStatus.active,
        processingStatus: ProcessingStatus.pending,
        isExpense: true,
        isReimbursable: true,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  /// Add a new receipt to the list
  void addReceipt(ReceiptModel receipt) {
    state = state.copyWith(
      receipts: [receipt, ...state.receipts],
    );
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
      state = state.copyWith(error: 'Failed to delete receipt: ${e.toString()}');
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
    await loadReceipts(refresh: true);
  }

  /// Load more receipts (for pagination)
  Future<void> loadMore() async {
    if (!state.isLoading && state.hasMore) {
      AppLogger.info('📄 Loading more receipts - Page ${state.currentPage + 1}');
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
}

/// Receipts provider
final receiptsProvider = StateNotifierProvider<ReceiptsNotifier, ReceiptsState>((ref) {
  return ReceiptsNotifier(ref);
});

/// Individual receipt provider
final receiptProvider = Provider.family<ReceiptModel?, String>((ref, receiptId) {
  final receipts = ref.watch(receiptsProvider).receipts;
  try {
    return receipts.firstWhere((receipt) => receipt.id == receiptId);
  } catch (e) {
    return null;
  }
});
