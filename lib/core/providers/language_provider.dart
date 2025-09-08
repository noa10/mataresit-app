import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_constants.dart';

/// Supported languages enum
enum SupportedLanguage {
  english('en', 'English', '🇺🇸'),
  malay('ms', 'Bahasa Malaysia', '🇲🇾');

  const SupportedLanguage(this.code, this.name, this.flag);

  final String code;
  final String name;
  final String flag;

  static SupportedLanguage fromCode(String code) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );
  }
}

/// Language state class
class LanguageState {
  final SupportedLanguage currentLanguage;
  final bool isLoading;
  final String? error;

  const LanguageState({
    required this.currentLanguage,
    this.isLoading = false,
    this.error,
  });

  LanguageState copyWith({
    SupportedLanguage? currentLanguage,
    bool? isLoading,
    String? error,
  }) {
    return LanguageState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Language provider class
class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier() : super(const LanguageState(currentLanguage: SupportedLanguage.english)) {
    _loadSavedLanguage();
  }

  /// Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(AppConstants.languageKey) ?? AppConstants.defaultLanguage;
      
      final savedLanguage = SupportedLanguage.fromCode(savedLanguageCode);
      
      state = state.copyWith(
        currentLanguage: savedLanguage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load saved language: $e',
      );
    }
  }

  /// Change language and persist the choice
  Future<bool> changeLanguage(BuildContext context, SupportedLanguage newLanguage) async {
    if (state.currentLanguage == newLanguage) return true;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Change the app's locale using easy_localization
      await context.setLocale(Locale(newLanguage.code));

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.languageKey, newLanguage.code);

      state = state.copyWith(
        currentLanguage: newLanguage,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to change language: $e',
      );
      return false;
    }
  }

  /// Get current language code
  String get currentLanguageCode => state.currentLanguage.code;

  /// Get current language name
  String get currentLanguageName => state.currentLanguage.name;

  /// Get current language flag
  String get currentLanguageFlag => state.currentLanguage.flag;

  /// Check if a language is currently selected
  bool isLanguageSelected(SupportedLanguage language) {
    return state.currentLanguage == language;
  }

  /// Get all supported languages
  List<SupportedLanguage> get supportedLanguages => SupportedLanguage.values;

  /// Clear any errors
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

/// Helper provider to get current language code
final currentLanguageCodeProvider = Provider<String>((ref) {
  return ref.watch(languageProvider).currentLanguage.code;
});

/// Helper provider to get current language name
final currentLanguageNameProvider = Provider<String>((ref) {
  return ref.watch(languageProvider).currentLanguage.name;
});

/// Helper provider to check if language is loading
final isLanguageLoadingProvider = Provider<bool>((ref) {
  return ref.watch(languageProvider).isLoading;
});

/// Helper provider to get language error
final languageErrorProvider = Provider<String?>((ref) {
  return ref.watch(languageProvider).error;
});
