import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../../core/network/supabase_client.dart';

class CategoryService {
  static final Logger _logger = Logger();
  static final SupabaseClient _supabase = SupabaseService.client;

  /// Fetch all categories for the current user or team with receipt counts
  static Future<List<CategoryModel>> fetchUserCategories({
    String? teamId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (teamId != null) {
        _logger.d(
          '🏷️ Fetching team categories for team: $teamId, user: ${user.email}',
        );
      } else {
        _logger.d('🏷️ Fetching personal categories for user: ${user.email}');
      }

      // Use the same RPC function as the React web version
      final response = await _supabase.rpc(
        'get_user_categories_with_counts',
        params: {'p_user_id': user.id, 'p_team_id': teamId},
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;

      // Debug: Log the raw response to understand the structure
      _logger.d('🔍 Raw RPC response: $data');

      final categories = <CategoryModel>[];
      for (int i = 0; i < data.length; i++) {
        try {
          final json = data[i] as Map<String, dynamic>;
          _logger.d('🔍 Processing category JSON: $json');
          final category = CategoryModel.fromJson(json);
          categories.add(category);
        } catch (e) {
          _logger.e('❌ Error parsing category at index $i: $e');
          _logger.e('❌ Raw data: ${data[i]}');
        }
      }

      // If user has no categories, create default ones
      if (categories.isEmpty) {
        if (teamId != null) {
          _logger.d('🏷️ No team categories found, creating defaults for team');
          await createDefaultTeamCategories(teamId);
        } else {
          _logger.d('🏷️ No personal categories found, creating defaults');
          await createDefaultCategories();
        }

        // Fetch again after creating defaults
        final newResponse = await _supabase.rpc(
          'get_user_categories_with_counts',
          params: {'p_user_id': user.id, 'p_team_id': teamId},
        );

        if (newResponse != null) {
          final List<dynamic> newData = newResponse as List<dynamic>;
          return newData
              .map(
                (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }

      _logger.d(
        '🏷️ Categories fetched successfully: ${categories.length} categories',
      );
      return categories;
    } catch (error) {
      _logger.e('Error fetching categories: $error');
      return [];
    }
  }

  /// Fetch categories for display purposes (includes both team and personal for resolution)
  static Future<List<CategoryModel>> fetchCategoriesForDisplay({
    String? teamId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (teamId != null) {
        // In team context, fetch both team categories AND personal categories for display resolution
        _logger.d('🏷️ Fetching categories for display in team context');

        final futures = await Future.wait([
          _supabase.rpc(
            'get_user_categories_with_counts',
            params: {'p_user_id': user.id, 'p_team_id': teamId},
          ),
          _supabase.rpc(
            'get_user_categories_with_counts',
            params: {'p_user_id': user.id, 'p_team_id': null},
          ),
        ]);

        final teamCategoriesData = futures[0] as List<dynamic>? ?? [];
        final personalCategoriesData = futures[1] as List<dynamic>? ?? [];

        _logger.d('🔍 Team categories data: $teamCategoriesData');
        _logger.d('🔍 Personal categories data: $personalCategoriesData');

        final teamCategories = <CategoryModel>[];
        for (int i = 0; i < teamCategoriesData.length; i++) {
          try {
            final json = teamCategoriesData[i] as Map<String, dynamic>;
            final category = CategoryModel.fromJson(json);
            teamCategories.add(category);
          } catch (e) {
            _logger.e('❌ Error parsing team category at index $i: $e');
            _logger.e('❌ Raw data: ${teamCategoriesData[i]}');
          }
        }

        final personalCategories = <CategoryModel>[];
        for (int i = 0; i < personalCategoriesData.length; i++) {
          try {
            final json = personalCategoriesData[i] as Map<String, dynamic>;
            final category = CategoryModel.fromJson(json);
            personalCategories.add(category);
          } catch (e) {
            _logger.e('❌ Error parsing personal category at index $i: $e');
            _logger.e('❌ Raw data: ${personalCategoriesData[i]}');
          }
        }

        // Combine both, prioritizing team categories
        final allCategories = [...teamCategories, ...personalCategories];
        _logger.d(
          '🏷️ Display categories: ${teamCategories.length} team + ${personalCategories.length} personal = ${allCategories.length} total',
        );

        return allCategories;
      } else {
        // In personal context, just fetch personal categories.
        // Await inside the try so a fetch failure is handled by the catch
        // below (and reported as "no categories") instead of escaping.
        return await fetchUserCategories(teamId: teamId);
      }
    } catch (error) {
      _logger.e('Error fetching categories for display: $error');
      return [];
    }
  }

  /// Create default team categories
  static Future<void> createDefaultTeamCategories(String teamId) async {
    try {
      await _supabase.rpc(
        'create_default_team_categories',
        params: {'p_team_id': teamId},
      );
      _logger.d('🏷️ Default team categories created successfully');
    } catch (error) {
      _logger.e('Error creating default team categories: $error');
      // Don't throw error as this is called automatically
    }
  }

  /// Create a new category
  static Future<String?> createCategory(
    CreateCategoryRequest categoryData, {
    String? teamId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_custom_category',
        params: {
          'p_name': categoryData.name,
          'p_color': categoryData.color ?? '#3B82F6',
          'p_icon': categoryData.icon ?? 'tag',
          'p_team_id': teamId,
        },
      );

      _logger.d('Category created successfully');
      return response as String?;
    } catch (error) {
      _logger.e('Error creating category: $error');
      return null;
    }
  }

  /// Update an existing category
  static Future<bool> updateCategory(
    String categoryId,
    UpdateCategoryRequest categoryData,
  ) async {
    try {
      await _supabase.rpc(
        'update_custom_category',
        params: {
          'p_category_id': categoryId,
          'p_name': categoryData.name,
          'p_color': categoryData.color,
          'p_icon': categoryData.icon,
        },
      );

      _logger.d('Category updated successfully');
      return true;
    } catch (error) {
      _logger.e('Error updating category: $error');
      return false;
    }
  }

  /// Delete a category
  static Future<bool> deleteCategory(
    String categoryId, {
    String? reassignToCategoryId,
  }) async {
    try {
      await _supabase.rpc(
        'delete_custom_category',
        params: {
          'p_category_id': categoryId,
          'p_reassign_to_category_id': reassignToCategoryId,
        },
      );

      _logger.d('Category deleted successfully');
      return true;
    } catch (error) {
      _logger.e('Error deleting category: $error');
      return false;
    }
  }

  /// Bulk assign category to receipts
  static Future<int> bulkAssignCategory(
    List<String> receiptIds, {
    String? categoryId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'bulk_assign_category',
        params: {'p_receipt_ids': receiptIds, 'p_category_id': categoryId},
      );

      final updatedCount = response as int? ?? 0;
      if (updatedCount > 0) {
        final action = categoryId != null
            ? 'assigned to category'
            : 'removed from category';
        _logger.d('$updatedCount receipt(s) $action');
      }

      return updatedCount;
    } catch (error) {
      _logger.e('Error bulk assigning category: $error');
      return 0;
    }
  }

  /// Get a single category by ID
  static Future<CategoryModel?> fetchCategoryById(String categoryId) async {
    try {
      final response = await _supabase
          .from('custom_categories')
          .select('*')
          .eq('id', categoryId)
          .single();

      return CategoryModel.fromJson(response);
    } catch (error) {
      _logger.e('Error fetching category: $error');
      return null;
    }
  }

  /// Create default categories for new users
  static Future<void> createDefaultCategories() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.rpc(
        'create_default_categories_for_user',
        params: {'p_user_id': user.id},
      );

      _logger.d('Default categories created successfully');
    } catch (error) {
      _logger.e('Error creating default categories: $error');
      // Don't throw error as this is automatic
    }
  }

  /// Validate category data
  static List<String> validateCategoryData(dynamic data) {
    final errors = <String>[];

    if (data is CreateCategoryRequest) {
      if (data.name.trim().isEmpty) {
        errors.add('Category name is required');
      } else if (data.name.trim().length > 50) {
        errors.add('Category name cannot exceed 50 characters');
      }
    }

    if (data is UpdateCategoryRequest && data.name != null) {
      if (data.name!.trim().isEmpty) {
        errors.add('Category name is required');
      } else if (data.name!.trim().length > 50) {
        errors.add('Category name cannot exceed 50 characters');
      }
    }

    // Validate color format if provided
    String? color;
    if (data is CreateCategoryRequest) {
      color = data.color;
    } else if (data is UpdateCategoryRequest) {
      color = data.color;
    }

    if (color != null && !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      errors.add('Color must be a valid hex color (e.g., #3B82F6)');
    }

    return errors;
  }
}
