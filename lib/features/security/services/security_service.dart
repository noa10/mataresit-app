import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import '../models/security_settings.dart';
import '../models/biometric_settings.dart';
import 'secure_storage_service.dart';

/// Core security service for biometric auth, app lock, and security settings
class SecurityService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final Logger _logger = Logger();
  static SecuritySettings? _cachedSettings;
  static BiometricSettings? _cachedBiometricSettings;

  /// Initialize security service
  static Future<void> initialize() async {
    try {
      await _loadSettings();
      await _checkBiometricAvailability();
      _logger.i('Security service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize security service: $e');
    }
  }

  /// Load security settings from secure storage
  static Future<void> _loadSettings() async {
    try {
      final settingsData = await SecureStorageService.getSecuritySettings();
      if (settingsData != null) {
        _cachedSettings = SecuritySettings.fromJson(settingsData);
      } else {
        _cachedSettings = const SecuritySettings();
      }

      final biometricData = await SecureStorageService.getBiometricSettings();
      if (biometricData != null) {
        _cachedBiometricSettings = BiometricSettings.fromJson(biometricData);
      } else {
        _cachedBiometricSettings = const BiometricSettings();
      }
    } catch (e) {
      _logger.e('Failed to load security settings: $e');
      _cachedSettings = const SecuritySettings();
      _cachedBiometricSettings = const BiometricSettings();
    }
  }

  /// Check biometric availability and update settings
  static Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableTypes = await _localAuth.getAvailableBiometrics();

      _cachedBiometricSettings = _cachedBiometricSettings!.copyWith(
        isAvailable: isAvailable,
        availableTypes: availableTypes,
        lastChecked: DateTime.now(),
      );

      await SecureStorageService.storeBiometricSettings(
        _cachedBiometricSettings!.toJson(),
      );
    } catch (e) {
      _logger.e('Failed to check biometric availability: $e');
    }
  }

  /// Get current security settings
  static SecuritySettings get securitySettings {
    return _cachedSettings ?? const SecuritySettings();
  }

  /// Get current biometric settings
  static BiometricSettings get biometricSettings {
    return _cachedBiometricSettings ?? const BiometricSettings();
  }

  /// Update security settings
  static Future<void> updateSecuritySettings(SecuritySettings settings) async {
    try {
      final updatedSettings = settings.copyWith(lastUpdated: DateTime.now());
      await SecureStorageService.storeSecuritySettings(updatedSettings.toJson());
      _cachedSettings = updatedSettings;
      _logger.d('Security settings updated successfully');
    } catch (e) {
      _logger.e('Failed to update security settings: $e');
      rethrow;
    }
  }

  /// Update biometric settings
  static Future<void> updateBiometricSettings(BiometricSettings settings) async {
    try {
      await SecureStorageService.storeBiometricSettings(settings.toJson());
      _cachedBiometricSettings = settings;
      _logger.d('Biometric settings updated successfully');
    } catch (e) {
      _logger.e('Failed to update biometric settings: $e');
      rethrow;
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      if (!biometricSettings.canUse) {
        _logger.w('Biometric authentication not available or not enabled');
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      _logger.d('Biometric authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      _logger.e('Biometric authentication failed: $e');
      return false;
    }
  }

  /// Set app PIN
  static Future<void> setAppPin(String pin) async {
    try {
      final hashedPin = _hashPin(pin);
      await SecureStorageService.storeAppPin(hashedPin);
      
      final updatedSettings = securitySettings.copyWith(
        hasPinSet: true,
        appLockEnabled: true,
        lastUpdated: DateTime.now(),
      );
      await updateSecuritySettings(updatedSettings);
      
      _logger.d('App PIN set successfully');
    } catch (e) {
      _logger.e('Failed to set app PIN: $e');
      rethrow;
    }
  }

  /// Verify app PIN
  static Future<bool> verifyAppPin(String pin) async {
    try {
      final storedHashedPin = await SecureStorageService.getAppPin();
      if (storedHashedPin == null) {
        _logger.w('No PIN set');
        return false;
      }

      final hashedPin = _hashPin(pin);
      final isValid = hashedPin == storedHashedPin;
      
      _logger.d('PIN verification result: $isValid');
      return isValid;
    } catch (e) {
      _logger.e('Failed to verify app PIN: $e');
      return false;
    }
  }

  /// Remove app PIN
  static Future<void> removeAppPin() async {
    try {
      await SecureStorageService.removeAppPin();
      
      final updatedSettings = securitySettings.copyWith(
        hasPinSet: false,
        appLockEnabled: false,
        lastUpdated: DateTime.now(),
      );
      await updateSecuritySettings(updatedSettings);
      
      _logger.d('App PIN removed successfully');
    } catch (e) {
      _logger.e('Failed to remove app PIN: $e');
      rethrow;
    }
  }

  /// Hash PIN for secure storage
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure random PIN
  static String generateRandomPin({int length = 6}) {
    final random = Random.secure();
    String pin = '';
    for (int i = 0; i < length; i++) {
      pin += random.nextInt(10).toString();
    }
    return pin;
  }

  /// Check if app should be locked based on timeout settings
  static bool shouldLockApp(DateTime? lastActiveTime) {
    if (lastActiveTime == null || securitySettings.autoLogoutMinutes == 0) {
      return false;
    }

    final timeSinceLastActive = DateTime.now().difference(lastActiveTime);
    final timeoutDuration = Duration(minutes: securitySettings.autoLogoutMinutes);
    
    return timeSinceLastActive >= timeoutDuration;
  }

  /// Enable biometric authentication
  static Future<bool> enableBiometricAuth() async {
    try {
      // First check if biometrics are available
      await _checkBiometricAvailability();
      
      if (!biometricSettings.isAvailable) {
        _logger.w('Biometric authentication not available on this device');
        return false;
      }

      // Test biometric authentication
      final isAuthenticated = await authenticateWithBiometrics(
        reason: 'Enable biometric authentication for Mataresit',
      );

      if (isAuthenticated) {
        final updatedBiometricSettings = biometricSettings.copyWith(
          isEnabled: true,
        );
        await updateBiometricSettings(updatedBiometricSettings);

        final updatedSecuritySettings = securitySettings.copyWith(
          biometricEnabled: true,
          lastUpdated: DateTime.now(),
        );
        await updateSecuritySettings(updatedSecuritySettings);

        _logger.d('Biometric authentication enabled successfully');
        return true;
      } else {
        _logger.w('Biometric authentication test failed');
        return false;
      }
    } catch (e) {
      _logger.e('Failed to enable biometric authentication: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  static Future<void> disableBiometricAuth() async {
    try {
      final updatedBiometricSettings = biometricSettings.copyWith(
        isEnabled: false,
      );
      await updateBiometricSettings(updatedBiometricSettings);

      final updatedSecuritySettings = securitySettings.copyWith(
        biometricEnabled: false,
        lastUpdated: DateTime.now(),
      );
      await updateSecuritySettings(updatedSecuritySettings);

      _logger.d('Biometric authentication disabled successfully');
    } catch (e) {
      _logger.e('Failed to disable biometric authentication: $e');
      rethrow;
    }
  }

  /// Clear all security data (for account deletion)
  static Future<void> clearAllSecurityData() async {
    try {
      await SecureStorageService.clearAllSecurityData();
      _cachedSettings = const SecuritySettings();
      _cachedBiometricSettings = const BiometricSettings();
      _logger.d('All security data cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear security data: $e');
      rethrow;
    }
  }
}
