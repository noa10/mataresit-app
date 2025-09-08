import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import '../models/biometric_settings.dart';
import '../services/security_service.dart';

/// State for biometric authentication
class BiometricAuthState {
  final BiometricSettings settings;
  final bool isLoading;
  final String? error;
  final bool isAuthenticating;

  const BiometricAuthState({
    required this.settings,
    this.isLoading = false,
    this.error,
    this.isAuthenticating = false,
  });

  BiometricAuthState copyWith({
    BiometricSettings? settings,
    bool? isLoading,
    String? error,
    bool? isAuthenticating,
  }) {
    return BiometricAuthState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }
}

/// Notifier for biometric authentication
class BiometricAuthNotifier extends StateNotifier<BiometricAuthState> {
  BiometricAuthNotifier() : super(BiometricAuthState(
    settings: SecurityService.biometricSettings,
  )) {
    _initialize();
  }

  final Logger _logger = Logger();

  /// Initialize biometric authentication
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await SecurityService.initialize();
      
      state = state.copyWith(
        settings: SecurityService.biometricSettings,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to initialize biometric auth: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Check biometric availability
  Future<void> checkAvailability() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final localAuth = LocalAuthentication();
      final isAvailable = await localAuth.canCheckBiometrics;
      final availableTypes = await localAuth.getAvailableBiometrics();

      final updatedSettings = state.settings.copyWith(
        isAvailable: isAvailable,
        availableTypes: availableTypes,
        lastChecked: DateTime.now(),
      );

      await SecurityService.updateBiometricSettings(updatedSettings);
      
      state = state.copyWith(
        settings: updatedSettings,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to check biometric availability: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometricAuth() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await SecurityService.enableBiometricAuth();
      
      if (success) {
        state = state.copyWith(
          settings: SecurityService.biometricSettings,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to enable biometric authentication',
        );
      }
      
      return success;
    } catch (e) {
      _logger.e('Failed to enable biometric auth: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await SecurityService.disableBiometricAuth();
      
      state = state.copyWith(
        settings: SecurityService.biometricSettings,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to disable biometric auth: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      state = state.copyWith(isAuthenticating: true, error: null);
      
      final isAuthenticated = await SecurityService.authenticateWithBiometrics(
        reason: reason,
        useErrorDialogs: useErrorDialogs,
        stickyAuth: stickyAuth,
      );
      
      state = state.copyWith(isAuthenticating: false);
      
      return isAuthenticated;
    } catch (e) {
      _logger.e('Failed to authenticate with biometrics: $e');
      state = state.copyWith(
        isAuthenticating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update biometric settings for app unlock
  Future<void> updateUseForAppUnlock(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        useForAppUnlock: enabled,
      );
      
      await SecurityService.updateBiometricSettings(updatedSettings);
      
      state = state.copyWith(settings: updatedSettings);
    } catch (e) {
      _logger.e('Failed to update use for app unlock: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update biometric settings for sensitive operations
  Future<void> updateUseForSensitiveOps(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        useForSensitiveOps: enabled,
      );
      
      await SecurityService.updateBiometricSettings(updatedSettings);
      
      state = state.copyWith(settings: updatedSettings);
    } catch (e) {
      _logger.e('Failed to update use for sensitive ops: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Get display text for available biometric types
  String get availableTypesDisplayText {
    return state.settings.availableTypesDisplayText;
  }

  /// Check if biometric authentication can be used
  bool get canUseBiometrics {
    return state.settings.canUse;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh biometric settings
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Provider for biometric authentication
final biometricAuthProvider = StateNotifierProvider<BiometricAuthNotifier, BiometricAuthState>((ref) {
  return BiometricAuthNotifier();
});

/// Provider for current biometric settings (read-only)
final currentBiometricSettingsProvider = Provider<BiometricSettings>((ref) {
  return ref.watch(biometricAuthProvider).settings;
});

/// Provider for biometric availability
final biometricAvailabilityProvider = Provider<bool>((ref) {
  return ref.watch(biometricAuthProvider).settings.isAvailable;
});

/// Provider for biometric enabled status
final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(biometricAuthProvider).settings.isEnabled;
});

/// Provider for biometric authentication loading state
final biometricAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(biometricAuthProvider).isLoading;
});

/// Provider for biometric authentication error
final biometricAuthErrorProvider = Provider<String?>((ref) {
  return ref.watch(biometricAuthProvider).error;
});

/// Provider for biometric authentication in progress
final biometricAuthenticatingProvider = Provider<bool>((ref) {
  return ref.watch(biometricAuthProvider).isAuthenticating;
});
