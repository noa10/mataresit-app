import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/theme_model.dart' as theme_model;
import '../../core/services/theme_service.dart';
import '../../features/auth/providers/auth_provider.dart';

final Logger _logger = Logger();

/// Theme state
class ThemeState {
  final theme_model.ThemeConfig config;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ThemeState({
    required this.config,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ThemeState copyWith({
    theme_model.ThemeConfig? config,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ThemeState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Theme state notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeConfigKey = 'theme_config';

  ThemeNotifier() : super(const ThemeState(config: theme_model.ThemeConfig.defaultConfig)) {
    _loadThemePreference();
  }

  /// Load theme preference from local storage and database
  Future<void> _loadThemePreference() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // First, try to load from SharedPreferences for immediate UI update
      final prefs = await SharedPreferences.getInstance();
      final localConfigJson = prefs.getString(_themeConfigKey);
      
      if (localConfigJson != null) {
        try {
          final localConfig = theme_model.ThemeConfig.fromJson(
            Map<String, dynamic>.from(
              // Simple JSON parsing for basic config
              {'mode': localConfigJson.split(',')[0], 'variant': localConfigJson.split(',')[1]}
            )
          );
          state = state.copyWith(config: localConfig, isLoading: false);
          _logger.d('Loaded theme from local storage: ${localConfig.mode.value}, ${localConfig.variant.value}');
        } catch (e) {
          _logger.w('Failed to parse local theme config: $e');
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      _logger.e('Failed to load theme preference: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load theme preference: $e',
      );
    }
  }

  /// Load theme preference from database for authenticated users
  Future<void> loadUserThemePreference(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final dbConfig = await ThemeService.loadThemePreference(userId);
      if (dbConfig != null) {
        state = state.copyWith(
          config: dbConfig,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        
        // Also save to local storage
        await _saveToLocalStorage(dbConfig);
        _logger.i('Loaded theme from database: ${dbConfig.mode.value}, ${dbConfig.variant.value}');
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      _logger.e('Failed to load user theme preference: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user theme preference: $e',
      );
    }
  }

  /// Save theme configuration to local storage
  Future<void> _saveToLocalStorage(theme_model.ThemeConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simple string format for basic storage
      await prefs.setString(_themeConfigKey, '${config.mode.value},${config.variant.value}');
      _logger.d('Saved theme to local storage');
    } catch (e) {
      _logger.e('Failed to save theme to local storage: $e');
    }
  }

  /// Update theme configuration
  Future<bool> updateTheme(theme_model.ThemeConfig newConfig, {String? userId}) async {
    if (state.config == newConfig) return true;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Save to local storage first for immediate UI update
      await _saveToLocalStorage(newConfig);
      
      // Update state
      state = state.copyWith(
        config: newConfig,
        lastUpdated: DateTime.now(),
      );

      // Save to database if user is authenticated
      if (userId != null) {
        try {
          await ThemeService.saveThemePreference(userId, newConfig);
          _logger.i('Theme saved to database');
        } catch (e) {
          _logger.w('Failed to save theme to database, but local update succeeded: $e');
          // Don't fail the operation if database save fails
        }
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _logger.e('Failed to update theme: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update theme: $e',
      );
      return false;
    }
  }

  /// Update theme mode only
  Future<bool> updateThemeMode(theme_model.ThemeMode mode, {String? userId}) async {
    return updateTheme(state.config.copyWith(mode: mode), userId: userId);
  }

  /// Update theme variant only
  Future<bool> updateThemeVariant(theme_model.ThemeVariant variant, {String? userId}) async {
    return updateTheme(state.config.copyWith(variant: variant), userId: userId);
  }

  /// Reset to default theme
  Future<bool> resetToDefault({String? userId}) async {
    return updateTheme(theme_model.ThemeConfig.defaultConfig, userId: userId);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get current brightness based on theme mode and system settings
  Brightness getCurrentBrightness(BuildContext context) {
    switch (state.config.mode) {
      case theme_model.ThemeMode.light:
        return Brightness.light;
      case theme_model.ThemeMode.dark:
        return Brightness.dark;
      case theme_model.ThemeMode.auto:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Check if dark mode is currently active
  bool isDarkMode(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final notifier = ThemeNotifier();
  
  // Listen to auth state changes to load user preferences
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated && next.user != null) {
      // Load user theme preferences when authenticated
      notifier.loadUserThemePreference(next.user!.id);
    }
  });
  
  return notifier;
});

/// Helper provider to get current theme mode for MaterialApp
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final themeState = ref.watch(themeProvider);

  switch (themeState.config.mode) {
    case theme_model.ThemeMode.light:
      return ThemeMode.light;
    case theme_model.ThemeMode.dark:
      return ThemeMode.dark;
    case theme_model.ThemeMode.auto:
      return ThemeMode.system;
  }
});

/// Helper provider to get current theme variant
final currentThemeVariantProvider = Provider<theme_model.ThemeVariant>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.config.variant;
});
