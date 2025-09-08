import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/security_settings.dart';
import '../services/security_service.dart';

/// State for security settings
class SecuritySettingsState {
  final SecuritySettings settings;
  final bool isLoading;
  final String? error;

  const SecuritySettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
  });

  SecuritySettingsState copyWith({
    SecuritySettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return SecuritySettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for security settings
class SecuritySettingsNotifier extends StateNotifier<SecuritySettingsState> {
  SecuritySettingsNotifier() : super(SecuritySettingsState(
    settings: SecurityService.securitySettings,
  )) {
    _initialize();
  }

  final Logger _logger = Logger();

  /// Initialize security settings
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await SecurityService.initialize();
      
      state = state.copyWith(
        settings: SecurityService.securitySettings,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to initialize security settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update security settings
  Future<void> updateSettings(SecuritySettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await SecurityService.updateSecuritySettings(settings);
      
      state = state.copyWith(
        settings: settings,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to update security settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Toggle biometric authentication
  Future<void> toggleBiometricAuth(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      bool success;
      if (enabled) {
        success = await SecurityService.enableBiometricAuth();
      } else {
        await SecurityService.disableBiometricAuth();
        success = true;
      }

      if (success) {
        final updatedSettings = state.settings.copyWith(
          biometricEnabled: enabled,
          lastUpdated: DateTime.now(),
        );
        
        state = state.copyWith(
          settings: updatedSettings,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to ${enabled ? 'enable' : 'disable'} biometric authentication',
        );
      }
    } catch (e) {
      _logger.e('Failed to toggle biometric auth: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Set app lock PIN
  Future<void> setAppPin(String pin) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await SecurityService.setAppPin(pin);
      
      final updatedSettings = state.settings.copyWith(
        appLockEnabled: true,
        hasPinSet: true,
        lastUpdated: DateTime.now(),
      );
      
      state = state.copyWith(
        settings: updatedSettings,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to set app PIN: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Remove app lock PIN
  Future<void> removeAppPin() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await SecurityService.removeAppPin();
      
      final updatedSettings = state.settings.copyWith(
        appLockEnabled: false,
        hasPinSet: false,
        lastUpdated: DateTime.now(),
      );
      
      state = state.copyWith(
        settings: updatedSettings,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to remove app PIN: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update auto-logout timeout
  Future<void> updateAutoLogoutTimeout(int minutes) async {
    try {
      final updatedSettings = state.settings.copyWith(
        autoLogoutMinutes: minutes,
        lastUpdated: DateTime.now(),
      );
      
      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to update auto-logout timeout: $e');
      rethrow;
    }
  }

  /// Toggle two-factor authentication
  Future<void> toggleTwoFactorAuth(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        twoFactorEnabled: enabled,
        lastUpdated: DateTime.now(),
      );
      
      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle 2FA: $e');
      rethrow;
    }
  }

  /// Toggle require authentication for sensitive operations
  Future<void> toggleRequireAuthForSensitiveOps(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        requireAuthForSensitiveOps: enabled,
        lastUpdated: DateTime.now(),
      );
      
      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle require auth for sensitive ops: $e');
      rethrow;
    }
  }

  /// Verify app PIN
  Future<bool> verifyAppPin(String pin) async {
    try {
      return await SecurityService.verifyAppPin(pin);
    } catch (e) {
      _logger.e('Failed to verify app PIN: $e');
      return false;
    }
  }

  /// Check if app should be locked
  bool shouldLockApp(DateTime? lastActiveTime) {
    return SecurityService.shouldLockApp(lastActiveTime);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh settings
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Provider for security settings
final securitySettingsProvider = StateNotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>((ref) {
  return SecuritySettingsNotifier();
});

/// Provider for current security settings (read-only)
final currentSecuritySettingsProvider = Provider<SecuritySettings>((ref) {
  return ref.watch(securitySettingsProvider).settings;
});

/// Provider for security settings loading state
final securitySettingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(securitySettingsProvider).isLoading;
});

/// Provider for security settings error
final securitySettingsErrorProvider = Provider<String?>((ref) {
  return ref.watch(securitySettingsProvider).error;
});
