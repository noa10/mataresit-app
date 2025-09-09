import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Service for secure storage of sensitive data
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final _logger = Logger();

  // Storage keys
  static const String _securitySettingsKey = 'security_settings';
  static const String _biometricSettingsKey = 'biometric_settings';
  static const String _privacySettingsKey = 'privacy_settings';
  static const String _appPinKey = 'app_pin';
  static const String _twoFactorSecretKey = '2fa_secret';
  static const String _backupCodesKey = '2fa_backup_codes';

  /// Store security settings
  static Future<void> storeSecuritySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final jsonString = jsonEncode(settings);
      await _storage.write(key: _securitySettingsKey, value: jsonString);
      _logger.d('Security settings stored successfully');
    } catch (e) {
      _logger.e('Failed to store security settings: $e');
      rethrow;
    }
  }

  /// Retrieve security settings
  static Future<Map<String, dynamic>?> getSecuritySettings() async {
    try {
      final jsonString = await _storage.read(key: _securitySettingsKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.e('Failed to retrieve security settings: $e');
      return null;
    }
  }

  /// Store biometric settings
  static Future<void> storeBiometricSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final jsonString = jsonEncode(settings);
      await _storage.write(key: _biometricSettingsKey, value: jsonString);
      _logger.d('Biometric settings stored successfully');
    } catch (e) {
      _logger.e('Failed to store biometric settings: $e');
      rethrow;
    }
  }

  /// Retrieve biometric settings
  static Future<Map<String, dynamic>?> getBiometricSettings() async {
    try {
      final jsonString = await _storage.read(key: _biometricSettingsKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.e('Failed to retrieve biometric settings: $e');
      return null;
    }
  }

  /// Store privacy settings
  static Future<void> storePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final jsonString = jsonEncode(settings);
      await _storage.write(key: _privacySettingsKey, value: jsonString);
      _logger.d('Privacy settings stored successfully');
    } catch (e) {
      _logger.e('Failed to store privacy settings: $e');
      rethrow;
    }
  }

  /// Retrieve privacy settings
  static Future<Map<String, dynamic>?> getPrivacySettings() async {
    try {
      final jsonString = await _storage.read(key: _privacySettingsKey);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.e('Failed to retrieve privacy settings: $e');
      return null;
    }
  }

  /// Store app PIN (hashed)
  static Future<void> storeAppPin(String hashedPin) async {
    try {
      await _storage.write(key: _appPinKey, value: hashedPin);
      _logger.d('App PIN stored successfully');
    } catch (e) {
      _logger.e('Failed to store app PIN: $e');
      rethrow;
    }
  }

  /// Retrieve app PIN (hashed)
  static Future<String?> getAppPin() async {
    try {
      return await _storage.read(key: _appPinKey);
    } catch (e) {
      _logger.e('Failed to retrieve app PIN: $e');
      return null;
    }
  }

  /// Remove app PIN
  static Future<void> removeAppPin() async {
    try {
      await _storage.delete(key: _appPinKey);
      _logger.d('App PIN removed successfully');
    } catch (e) {
      _logger.e('Failed to remove app PIN: $e');
      rethrow;
    }
  }

  /// Store 2FA secret
  static Future<void> storeTwoFactorSecret(String secret) async {
    try {
      await _storage.write(key: _twoFactorSecretKey, value: secret);
      _logger.d('2FA secret stored successfully');
    } catch (e) {
      _logger.e('Failed to store 2FA secret: $e');
      rethrow;
    }
  }

  /// Retrieve 2FA secret
  static Future<String?> getTwoFactorSecret() async {
    try {
      return await _storage.read(key: _twoFactorSecretKey);
    } catch (e) {
      _logger.e('Failed to retrieve 2FA secret: $e');
      return null;
    }
  }

  /// Remove 2FA secret
  static Future<void> removeTwoFactorSecret() async {
    try {
      await _storage.delete(key: _twoFactorSecretKey);
      _logger.d('2FA secret removed successfully');
    } catch (e) {
      _logger.e('Failed to remove 2FA secret: $e');
      rethrow;
    }
  }

  /// Store 2FA backup codes
  static Future<void> storeBackupCodes(List<String> codes) async {
    try {
      final jsonString = jsonEncode(codes);
      await _storage.write(key: _backupCodesKey, value: jsonString);
      _logger.d('Backup codes stored successfully');
    } catch (e) {
      _logger.e('Failed to store backup codes: $e');
      rethrow;
    }
  }

  /// Retrieve 2FA backup codes
  static Future<List<String>?> getBackupCodes() async {
    try {
      final jsonString = await _storage.read(key: _backupCodesKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<String>();
      }
      return null;
    } catch (e) {
      _logger.e('Failed to retrieve backup codes: $e');
      return null;
    }
  }

  /// Remove 2FA backup codes
  static Future<void> removeBackupCodes() async {
    try {
      await _storage.delete(key: _backupCodesKey);
      _logger.d('Backup codes removed successfully');
    } catch (e) {
      _logger.e('Failed to remove backup codes: $e');
      rethrow;
    }
  }

  /// Clear all security data
  static Future<void> clearAllSecurityData() async {
    try {
      await Future.wait([
        _storage.delete(key: _securitySettingsKey),
        _storage.delete(key: _biometricSettingsKey),
        _storage.delete(key: _privacySettingsKey),
        _storage.delete(key: _appPinKey),
        _storage.delete(key: _twoFactorSecretKey),
        _storage.delete(key: _backupCodesKey),
      ]);
      _logger.d('All security data cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear security data: $e');
      rethrow;
    }
  }
}
