import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../shared/models/theme_model.dart' as theme_model;

final Logger _logger = Logger();

/// Service for managing theme preferences in Supabase
class ThemeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Save theme preference to database
  static Future<void> saveThemePreference(String userId, theme_model.ThemeConfig config) async {
    try {
      _logger.d('Saving theme preference for user: $userId');
      
      await _supabase
          .from('theme_preferences')
          .upsert({
            'user_id': userId,
            'theme_mode': config.mode.value,
            'theme_variant': config.variant.value,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');

      _logger.i('Theme preference saved successfully');
    } catch (e) {
      _logger.e('Failed to save theme preference: $e');
      rethrow;
    }
  }

  /// Load theme preference from database
  static Future<theme_model.ThemeConfig?> loadThemePreference(String userId) async {
    try {
      _logger.d('Loading theme preference for user: $userId');
      
      final response = await _supabase
          .from('theme_preferences')
          .select('theme_mode, theme_variant')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        _logger.d('No theme preference found for user');
        return null;
      }

      final config = theme_model.ThemeConfig(
        mode: theme_model.ThemeMode.fromString(response['theme_mode'] ?? 'auto'),
        variant: theme_model.ThemeVariant.fromString(response['theme_variant'] ?? 'default'),
      );

      _logger.i('Theme preference loaded successfully: ${config.mode.value}, ${config.variant.value}');
      return config;
    } catch (e) {
      _logger.e('Failed to load theme preference: $e');
      rethrow;
    }
  }

  /// Delete theme preference from database
  static Future<void> deleteThemePreference(String userId) async {
    try {
      _logger.d('Deleting theme preference for user: $userId');
      
      await _supabase
          .from('theme_preferences')
          .delete()
          .eq('user_id', userId);

      _logger.i('Theme preference deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete theme preference: $e');
      rethrow;
    }
  }

  /// Check if theme_preferences table exists and create if needed
  static Future<bool> ensureThemePreferencesTable() async {
    try {
      // Try to query the table to see if it exists
      await _supabase
          .from('theme_preferences')
          .select('user_id')
          .limit(1);
      
      _logger.d('theme_preferences table exists');
      return true;
    } catch (e) {
      _logger.w('theme_preferences table may not exist: $e');
      return false;
    }
  }
}
