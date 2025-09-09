import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for managing biometric authentication and secure storage
class BiometricService {
  static final Logger _logger = Logger();
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      _logger.d(
        'Biometric available: $isAvailable, Device supported: $isDeviceSupported',
      );
      return isAvailable && isDeviceSupported;
    } catch (e) {
      _logger.e('Failed to check biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.e('Failed to get available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your receipts',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _logger.w('Biometric authentication not available');
        return false;
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      _logger.i('Biometric authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      _logger.e('Biometric authentication failed: $e');
      return false;
    }
  }

  /// Enable biometric authentication for the app
  static Future<bool> enableBiometricAuth(String userId) async {
    try {
      final isAuthenticated = await authenticateWithBiometrics(
        reason: 'Authenticate to enable biometric login',
      );

      if (isAuthenticated) {
        await _secureStorage.write(
          key: 'biometric_enabled_$userId',
          value: 'true',
        );
        _logger.i('Biometric authentication enabled for user: $userId');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Failed to enable biometric auth: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  static Future<void> disableBiometricAuth(String userId) async {
    try {
      await _secureStorage.delete(key: 'biometric_enabled_$userId');
      await _secureStorage.delete(key: 'biometric_credentials_$userId');
      _logger.i('Biometric authentication disabled for user: $userId');
    } catch (e) {
      _logger.e('Failed to disable biometric auth: $e');
    }
  }

  /// Check if biometric auth is enabled for user
  static Future<bool> isBiometricEnabled(String userId) async {
    try {
      final enabled = await _secureStorage.read(
        key: 'biometric_enabled_$userId',
      );
      return enabled == 'true';
    } catch (e) {
      _logger.e('Failed to check biometric status: $e');
      return false;
    }
  }

  /// Store encrypted credentials for biometric login
  static Future<void> storeBiometricCredentials({
    required String userId,
    required String email,
    required String passwordHash,
  }) async {
    try {
      final credentials = {
        'email': email,
        'passwordHash': passwordHash,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final credentialsJson = jsonEncode(credentials);
      await _secureStorage.write(
        key: 'biometric_credentials_$userId',
        value: credentialsJson,
      );

      _logger.d('Biometric credentials stored for user: $userId');
    } catch (e) {
      _logger.e('Failed to store biometric credentials: $e');
      rethrow;
    }
  }

  /// Retrieve encrypted credentials after biometric authentication
  static Future<Map<String, String>?> getBiometricCredentials(
    String userId,
  ) async {
    try {
      final isAuthenticated = await authenticateWithBiometrics(
        reason: 'Authenticate to sign in with biometrics',
      );

      if (!isAuthenticated) {
        return null;
      }

      final credentialsJson = await _secureStorage.read(
        key: 'biometric_credentials_$userId',
      );
      if (credentialsJson == null) {
        return null;
      }

      final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      return {
        'email': credentials['email'] as String,
        'passwordHash': credentials['passwordHash'] as String,
      };
    } catch (e) {
      _logger.e('Failed to get biometric credentials: $e');
      return null;
    }
  }

  /// Secure storage operations

  /// Store sensitive data securely
  static Future<void> storeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      _logger.d('Secure data stored for key: $key');
    } catch (e) {
      _logger.e('Failed to store secure data: $e');
      rethrow;
    }
  }

  /// Retrieve sensitive data securely
  static Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      _logger.e('Failed to get secure data: $e');
      return null;
    }
  }

  /// Delete secure data
  static Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      _logger.d('Secure data deleted for key: $key');
    } catch (e) {
      _logger.e('Failed to delete secure data: $e');
    }
  }

  /// Clear all secure data
  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      _logger.i('All secure data cleared');
    } catch (e) {
      _logger.e('Failed to clear secure data: $e');
    }
  }

  /// Encryption utilities

  /// Generate secure hash
  static String generateSecureHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure token
  static String generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return generateSecureHash('$timestamp$random');
  }

  /// Validate biometric authentication settings
  static Future<BiometricAuthStatus> getBiometricStatus() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthStatus.notAvailable;
      }

      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return BiometricAuthStatus.notEnrolled;
      }

      return BiometricAuthStatus.available;
    } catch (e) {
      _logger.e('Failed to get biometric status: $e');
      return BiometricAuthStatus.error;
    }
  }

  /// App lock functionality

  /// Check if app lock is enabled
  static Future<bool> isAppLockEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: 'app_lock_enabled');
      return enabled == 'true';
    } catch (e) {
      _logger.e('Failed to check app lock status: $e');
      return false;
    }
  }

  /// Enable app lock
  static Future<void> enableAppLock() async {
    try {
      await _secureStorage.write(key: 'app_lock_enabled', value: 'true');
      _logger.i('App lock enabled');
    } catch (e) {
      _logger.e('Failed to enable app lock: $e');
    }
  }

  /// Disable app lock
  static Future<void> disableAppLock() async {
    try {
      await _secureStorage.delete(key: 'app_lock_enabled');
      _logger.i('App lock disabled');
    } catch (e) {
      _logger.e('Failed to disable app lock: $e');
    }
  }

  /// Check if app should be locked (based on time since last unlock)
  static Future<bool> shouldLockApp() async {
    try {
      final isEnabled = await isAppLockEnabled();
      if (!isEnabled) return false;

      final lastUnlockStr = await _secureStorage.read(key: 'last_unlock_time');
      if (lastUnlockStr == null) return true;

      final lastUnlock = DateTime.parse(lastUnlockStr);
      final now = DateTime.now();
      final difference = now.difference(lastUnlock);

      // Lock after 5 minutes of inactivity
      return difference.inMinutes >= 5;
    } catch (e) {
      _logger.e('Failed to check app lock status: $e');
      return false;
    }
  }

  /// Update last unlock time
  static Future<void> updateLastUnlockTime() async {
    try {
      await _secureStorage.write(
        key: 'last_unlock_time',
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _logger.e('Failed to update last unlock time: $e');
    }
  }
}

/// Biometric authentication status
enum BiometricAuthStatus { available, notAvailable, notEnrolled, error }

extension BiometricAuthStatusExtension on BiometricAuthStatus {
  String get displayName {
    switch (this) {
      case BiometricAuthStatus.available:
        return 'Available';
      case BiometricAuthStatus.notAvailable:
        return 'Not Available';
      case BiometricAuthStatus.notEnrolled:
        return 'Not Enrolled';
      case BiometricAuthStatus.error:
        return 'Error';
    }
  }

  String get description {
    switch (this) {
      case BiometricAuthStatus.available:
        return 'Biometric authentication is available and ready to use';
      case BiometricAuthStatus.notAvailable:
        return 'This device does not support biometric authentication';
      case BiometricAuthStatus.notEnrolled:
        return 'No biometric data is enrolled on this device';
      case BiometricAuthStatus.error:
        return 'An error occurred while checking biometric availability';
    }
  }
}
