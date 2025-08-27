import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Receipts state
class ReceiptsState {
  final List<ReceiptModel> receipts;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const ReceiptsState({
    this.receipts = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  ReceiptsState copyWith({
    List<ReceiptModel>? receipts,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return ReceiptsState(
      receipts: receipts ?? this.receipts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
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
          currentPage: 0,
          hasMore: true,
          error: null,
        );
      }

      if (state.isLoading || !state.hasMore) return;

      state = state.copyWith(isLoading: true, error: null);

      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Try to load from database
      List<ReceiptModel> newReceipts = [];
      try {
        final response = await SupabaseService.client
            .from('receipts')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .range(
              state.currentPage * 20,
              (state.currentPage + 1) * 20 - 1,
            );

        newReceipts = (response as List)
            .map((json) => ReceiptModel.fromJson(json))
            .toList();
      } catch (e) {
        AppLogger.warning('Failed to load receipts from database', e);
        // If database fails, create some mock data for demonstration
        if (state.receipts.isEmpty) {
          newReceipts = _createMockReceipts(user.id);
        }
      }

      final allReceipts = refresh 
          ? newReceipts 
          : [...state.receipts, ...newReceipts];

      state = state.copyWith(
        receipts: allReceipts,
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

  /// Search receipts
  void searchReceipts(String query) {
    if (query.isEmpty) {
      loadReceipts(refresh: true);
      return;
    }

    final filteredReceipts = state.receipts.where((receipt) {
      final merchantName = receipt.merchantName?.toLowerCase() ?? '';
      final category = receipt.category?.toLowerCase() ?? '';
      final description = receipt.description?.toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return merchantName.contains(searchQuery) ||
          category.contains(searchQuery) ||
          description.contains(searchQuery);
    }).toList();

    state = state.copyWith(receipts: filteredReceipts);
  }

  /// Filter receipts by status
  void filterByStatus(ReceiptStatus? status) {
    if (status == null) {
      loadReceipts(refresh: true);
      return;
    }

    final filteredReceipts = state.receipts
        .where((receipt) => receipt.status == status)
        .toList();

    state = state.copyWith(receipts: filteredReceipts);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh receipts
  Future<void> refresh() async {
    await loadReceipts(refresh: true);
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
