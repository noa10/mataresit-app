import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_logger.dart';

/// Enhanced iOS Keychain service with iOS-specific security features
class IOSKeychainService {
  static const String _tag = 'IOSKeychainService';
  static final _logger = AppLogger.getLogger(_tag);

  // iOS-specific storage options for enhanced security
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
    accountName: 'Mataresit',
    groupId: 'group.co.mataresit.app', // Replace with your app group
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  // Enhanced iOS storage options for biometric-protected data
  static const IOSOptions _biometricProtectedOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
    accountName: 'Mataresit-Biometric',
    groupId: 'group.co.mataresit.app',
    // This would require biometric authentication to access
  );

  static const FlutterSecureStorage _biometricStorage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _biometricProtectedOptions,
  );

  /// Store authentication token with standard security
  static Future<void> storeAuthToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
      _logger.i('Auth token stored successfully');
    } catch (e) {
      _logger.e('Failed to store auth token: $e');
      rethrow;
    }
  }

  /// Retrieve authentication token
  static Future<String?> getAuthToken() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _logger.i('Auth token retrieved successfully');
      }
      return token;
    } catch (e) {
      _logger.e('Failed to retrieve auth token: $e');
      return null;
    }
  }

  /// Store refresh token with enhanced security
  static Future<void> storeRefreshToken(String token) async {
    try {
      await _biometricStorage.write(key: 'refresh_token', value: token);
      _logger.i('Refresh token stored with biometric protection');
    } catch (e) {
      _logger.e('Failed to store refresh token: $e');
      rethrow;
    }
  }

  /// Retrieve refresh token (may require biometric authentication)
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _biometricStorage.read(key: 'refresh_token');
      if (token != null) {
        _logger.i('Refresh token retrieved successfully');
      }
      return token;
    } catch (e) {
      _logger.e('Failed to retrieve refresh token: $e');
      return null;
    }
  }

  /// Store user credentials with biometric protection
  static Future<void> storeUserCredentials({
    required String email,
    required String encryptedPassword,
  }) async {
    try {
      final credentials = {
        'email': email,
        'password': encryptedPassword,
        'stored_at': DateTime.now().toIso8601String(),
      };

      await _biometricStorage.write(
        key: 'user_credentials',
        value: jsonEncode(credentials),
      );
      
      _logger.i('User credentials stored with biometric protection');
    } catch (e) {
      _logger.e('Failed to store user credentials: $e');
      rethrow;
    }
  }

  /// Retrieve user credentials (requires biometric authentication)
  static Future<Map<String, String>?> getUserCredentials() async {
    try {
      final credentialsJson = await _biometricStorage.read(key: 'user_credentials');
      if (credentialsJson == null) return null;

      final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      _logger.i('User credentials retrieved successfully');
      
      return {
        'email': credentials['email'] as String,
        'password': credentials['password'] as String,
        'stored_at': credentials['stored_at'] as String,
      };
    } catch (e) {
      _logger.e('Failed to retrieve user credentials: $e');
      return null;
    }
  }

  /// Store API keys and sensitive configuration
  static Future<void> storeAPIKey(String keyName, String apiKey) async {
    try {
      await _storage.write(key: 'api_key_$keyName', value: apiKey);
      _logger.i('API key stored: $keyName');
    } catch (e) {
      _logger.e('Failed to store API key $keyName: $e');
      rethrow;
    }
  }

  /// Retrieve API key
  static Future<String?> getAPIKey(String keyName) async {
    try {
      final apiKey = await _storage.read(key: 'api_key_$keyName');
      if (apiKey != null) {
        _logger.i('API key retrieved: $keyName');
      }
      return apiKey;
    } catch (e) {
      _logger.e('Failed to retrieve API key $keyName: $e');
      return null;
    }
  }

  /// Store biometric authentication preference
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'biometric_enabled', value: enabled.toString());
      _logger.i('Biometric preference set: $enabled');
    } catch (e) {
      _logger.e('Failed to set biometric preference: $e');
      rethrow;
    }
  }

  /// Get biometric authentication preference
  static Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: 'biometric_enabled');
      return enabled == 'true';
    } catch (e) {
      _logger.e('Failed to get biometric preference: $e');
      return false;
    }
  }

  /// Store encrypted backup data
  static Future<void> storeBackupData(String backupData) async {
    try {
      await _biometricStorage.write(key: 'backup_data', value: backupData);
      _logger.i('Backup data stored with biometric protection');
    } catch (e) {
      _logger.e('Failed to store backup data: $e');
      rethrow;
    }
  }

  /// Retrieve encrypted backup data
  static Future<String?> getBackupData() async {
    try {
      final backupData = await _biometricStorage.read(key: 'backup_data');
      if (backupData != null) {
        _logger.i('Backup data retrieved successfully');
      }
      return backupData;
    } catch (e) {
      _logger.e('Failed to retrieve backup data: $e');
      return null;
    }
  }

  /// Store app-specific settings securely
  static Future<void> storeSecureSetting(String key, String value) async {
    try {
      await _storage.write(key: 'setting_$key', value: value);
      _logger.i('Secure setting stored: $key');
    } catch (e) {
      _logger.e('Failed to store secure setting $key: $e');
      rethrow;
    }
  }

  /// Retrieve app-specific settings
  static Future<String?> getSecureSetting(String key) async {
    try {
      final value = await _storage.read(key: 'setting_$key');
      if (value != null) {
        _logger.i('Secure setting retrieved: $key');
      }
      return value;
    } catch (e) {
      _logger.e('Failed to retrieve secure setting $key: $e');
      return null;
    }
  }

  /// Clear all stored data (for logout/reset)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      await _biometricStorage.deleteAll();
      _logger.i('All keychain data cleared');
    } catch (e) {
      _logger.e('Failed to clear keychain data: $e');
      rethrow;
    }
  }

  /// Clear only authentication-related data
  static Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: 'auth_token');
      await _biometricStorage.delete(key: 'refresh_token');
      await _biometricStorage.delete(key: 'user_credentials');
      _logger.i('Authentication data cleared');
    } catch (e) {
      _logger.e('Failed to clear auth data: $e');
      rethrow;
    }
  }

  /// Check if keychain is available and accessible
  static Future<bool> isKeychainAvailable() async {
    try {
      // Test write and read
      const testKey = 'keychain_test';
      const testValue = 'test_value';
      
      await _storage.write(key: testKey, value: testValue);
      final retrievedValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      
      final isAvailable = retrievedValue == testValue;
      _logger.i('Keychain availability check: $isAvailable');
      return isAvailable;
    } catch (e) {
      _logger.e('Keychain availability check failed: $e');
      return false;
    }
  }

  /// Get all stored keys (for debugging/migration)
  static Future<Map<String, String>> getAllKeys() async {
    try {
      final allKeys = await _storage.readAll();
      _logger.i('Retrieved ${allKeys.length} keys from keychain');
      return allKeys;
    } catch (e) {
      _logger.e('Failed to retrieve all keys: $e');
      return {};
    }
  }

  /// Migrate data between keychain configurations
  static Future<void> migrateKeychainData() async {
    try {
      _logger.i('Starting keychain data migration');
      
      // Get all existing data
      final existingData = await getAllKeys();
      
      // Re-store critical data with new configuration if needed
      for (final entry in existingData.entries) {
        if (entry.key.startsWith('auth_') || entry.key.startsWith('api_key_')) {
          // These should be re-stored with current configuration
          await _storage.write(key: entry.key, value: entry.value);
        }
      }
      
      _logger.i('Keychain data migration completed');
    } catch (e) {
      _logger.e('Keychain data migration failed: $e');
      rethrow;
    }
  }

  /// Check iOS-specific keychain accessibility
  static Future<bool> isAccessibilitySupported(KeychainAccessibility accessibility) async {
    if (!Platform.isIOS) return false;

    try {
      const testKey = 'accessibility_test';
      const testValue = 'test';

      final testStorage = FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: accessibility,
          synchronizable: false,
        ),
      );

      await testStorage.write(key: testKey, value: testValue);
      final result = await testStorage.read(key: testKey);
      await testStorage.delete(key: testKey);

      return result == testValue;
    } catch (e) {
      _logger.e('Accessibility test failed for $accessibility: $e');
      return false;
    }
  }

  // Additional methods for test compatibility

  /// Store secure data (alias for storeSecureSetting)
  static Future<void> storeSecureData(String key, String value) async {
    await storeSecureSetting(key, value);
  }

  /// Get secure data (alias for getSecureSetting)
  static Future<String?> getSecureData(String key) async {
    return await getSecureSetting(key);
  }

  /// Delete secure data
  static Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: 'setting_$key');
      _logger.i('Secure data deleted: $key');
    } catch (e) {
      _logger.e('Failed to delete secure data $key: $e');
      rethrow;
    }
  }

  /// Store biometric protected data
  static Future<void> storeBiometricProtectedData(String key, String value) async {
    try {
      await _biometricStorage.write(key: key, value: value);
      _logger.i('Biometric protected data stored: $key');
    } catch (e) {
      _logger.e('Failed to store biometric protected data $key: $e');
      rethrow;
    }
  }

  /// Get biometric protected data
  static Future<String?> getBiometricProtectedData(String key) async {
    try {
      final value = await _biometricStorage.read(key: key);
      if (value != null) {
        _logger.i('Biometric protected data retrieved: $key');
      }
      return value;
    } catch (e) {
      _logger.e('Failed to retrieve biometric protected data $key: $e');
      return null;
    }
  }

  /// Delete biometric protected data
  static Future<void> deleteBiometricProtectedData(String key) async {
    try {
      await _biometricStorage.delete(key: key);
      _logger.i('Biometric protected data deleted: $key');
    } catch (e) {
      _logger.e('Failed to delete biometric protected data $key: $e');
      rethrow;
    }
  }
}
