import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/services/category_service.dart';

/// Categories state
class CategoriesState {
  final List<CategoryModel> categories;
  final List<CategoryModel> displayCategories;
  final bool isLoading;
  final String? error;

  const CategoriesState({
    this.categories = const [],
    this.displayCategories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<CategoryModel>? categories,
    List<CategoryModel>? displayCategories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      displayCategories: displayCategories ?? this.displayCategories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Categories notifier
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final Logger _logger = Logger();
  final Ref _ref;

  CategoriesNotifier(this._ref) : super(const CategoriesState());

  /// Load categories for the current user or team
  Future<void> loadCategories({String? teamId, bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      _logger.d('Loading categories for teamId: $teamId');

      final categories = await CategoryService.fetchUserCategories(teamId: teamId);
      final displayCategories = await CategoryService.fetchCategoriesForDisplay(teamId: teamId);

      state = state.copyWith(
        categories: categories,
        displayCategories: displayCategories,
        isLoading: false,
      );

      _logger.d('Categories loaded successfully: ${categories.length} categories, ${displayCategories.length} display categories');
    } catch (error) {
      _logger.e('Error loading categories: $error');
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// Create a new category
  Future<bool> createCategory(
    CreateCategoryRequest categoryData, {
    String? teamId,
  }) async {
    try {
      _logger.d('Creating category: ${categoryData.name}');

      final categoryId = await CategoryService.createCategory(
        categoryData,
        teamId: teamId,
      );

      if (categoryId != null) {
        // Reload categories to get the updated list
        await loadCategories(teamId: teamId, refresh: true);
        _logger.d('Category created successfully');
        return true;
      } else {
        state = state.copyWith(error: 'Failed to create category');
        return false;
      }
    } catch (error) {
      _logger.e('Error creating category: $error');
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory(
    String categoryId,
    UpdateCategoryRequest categoryData, {
    String? teamId,
  }) async {
    try {
      _logger.d('Updating category: $categoryId');

      final success = await CategoryService.updateCategory(categoryId, categoryData);

      if (success) {
        // Reload categories to get the updated list
        await loadCategories(teamId: teamId, refresh: true);
        _logger.d('Category updated successfully');
        return true;
      } else {
        state = state.copyWith(error: 'Failed to update category');
        return false;
      }
    } catch (error) {
      _logger.e('Error updating category: $error');
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(
    String categoryId, {
    String? reassignToCategoryId,
    String? teamId,
  }) async {
    try {
      _logger.d('Deleting category: $categoryId');

      final success = await CategoryService.deleteCategory(
        categoryId,
        reassignToCategoryId: reassignToCategoryId,
      );

      if (success) {
        // Reload categories to get the updated list
        await loadCategories(teamId: teamId, refresh: true);
        _logger.d('Category deleted successfully');
        return true;
      } else {
        state = state.copyWith(error: 'Failed to delete category');
        return false;
      }
    } catch (error) {
      _logger.e('Error deleting category: $error');
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  /// Bulk assign category to receipts
  Future<int> bulkAssignCategory(
    List<String> receiptIds, {
    String? categoryId,
    String? teamId,
  }) async {
    try {
      _logger.d('Bulk assigning category: $categoryId to ${receiptIds.length} receipts');

      final updatedCount = await CategoryService.bulkAssignCategory(
        receiptIds,
        categoryId: categoryId,
      );

      if (updatedCount > 0) {
        // Reload categories to get updated receipt counts
        await loadCategories(teamId: teamId, refresh: true);
      }

      return updatedCount;
    } catch (error) {
      _logger.e('Error bulk assigning category: $error');
      state = state.copyWith(error: error.toString());
      return 0;
    }
  }

  /// Get category by ID from current state
  CategoryModel? getCategoryById(String categoryId) {
    try {
      return state.displayCategories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh categories
  Future<void> refresh({String? teamId}) async {
    await loadCategories(teamId: teamId, refresh: true);
  }
}

/// Categories provider
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier(ref);
});

/// Provider for user categories (for management/editing)
final userCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(categoriesProvider).categories;
});

/// Provider for display categories (for showing in receipts)
final displayCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(categoriesProvider).displayCategories;
});

/// Provider for categories loading state
final categoriesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(categoriesProvider).isLoading;
});

/// Provider for categories error state
final categoriesErrorProvider = Provider<String?>((ref) {
  return ref.watch(categoriesProvider).error;
});

/// Provider to get a specific category by ID
final categoryByIdProvider = Provider.family<CategoryModel?, String>((ref, categoryId) {
  final categories = ref.watch(displayCategoriesProvider);
  try {
    return categories.firstWhere((category) => category.id == categoryId);
  } catch (e) {
    return null;
  }
});
