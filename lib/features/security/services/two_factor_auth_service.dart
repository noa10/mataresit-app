import 'dart:math';
import 'package:logger/logger.dart';
import 'package:otp/otp.dart';
import 'secure_storage_service.dart';

/// Service for Two-Factor Authentication (2FA) using TOTP
class TwoFactorAuthService {
  static final Logger _logger = Logger();
  static const int _secretLength = 32;
  static const int _backupCodesCount = 10;
  static const int _backupCodeLength = 8;

  /// Generate a new 2FA secret
  static String generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(_secretLength, (i) => random.nextInt(256));
    return base32Encode(bytes);
  }

  /// Generate backup codes
  static List<String> generateBackupCodes() {
    final random = Random.secure();
    final codes = <String>[];
    
    for (int i = 0; i < _backupCodesCount; i++) {
      String code = '';
      for (int j = 0; j < _backupCodeLength; j++) {
        code += random.nextInt(10).toString();
      }
      // Format as XXXX-XXXX
      code = '${code.substring(0, 4)}-${code.substring(4)}';
      codes.add(code);
    }
    
    return codes;
  }

  /// Generate TOTP code for a given secret
  static String generateTOTP(String secret, {DateTime? time}) {
    try {
      final currentTime = time ?? DateTime.now();
      final code = OTP.generateTOTPCodeString(
        secret,
        currentTime.millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      return code;
    } catch (e) {
      _logger.e('Failed to generate TOTP code: $e');
      return '';
    }
  }

  /// Verify TOTP code
  static bool verifyTOTP(String secret, String code, {DateTime? time}) {
    try {
      final currentTime = time ?? DateTime.now();
      
      // Check current time window
      final currentCode = generateTOTP(secret, time: currentTime);
      if (currentCode == code) {
        return true;
      }
      
      // Check previous time window (30 seconds ago)
      final previousTime = currentTime.subtract(const Duration(seconds: 30));
      final previousCode = generateTOTP(secret, time: previousTime);
      if (previousCode == code) {
        return true;
      }
      
      // Check next time window (30 seconds ahead)
      final nextTime = currentTime.add(const Duration(seconds: 30));
      final nextCode = generateTOTP(secret, time: nextTime);
      if (nextCode == code) {
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('Failed to verify TOTP code: $e');
      return false;
    }
  }

  /// Setup 2FA for user
  static Future<Map<String, dynamic>> setup2FA() async {
    try {
      _logger.d('Setting up 2FA');

      final secret = generateSecret();
      final backupCodes = generateBackupCodes();

      // Store secret and backup codes securely
      await SecureStorageService.storeTwoFactorSecret(secret);
      await SecureStorageService.storeBackupCodes(backupCodes);

      // Generate QR code data
      final issuer = 'Mataresit';
      final accountName = 'user@mataresit.com'; // This should be the actual user email
      final qrCodeData = 'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer';

      _logger.d('2FA setup completed successfully');

      return {
        'secret': secret,
        'qrCodeData': qrCodeData,
        'backupCodes': backupCodes,
      };
    } catch (e) {
      _logger.e('Failed to setup 2FA: $e');
      rethrow;
    }
  }

  /// Verify 2FA setup with a test code
  static Future<bool> verify2FASetup(String code) async {
    try {
      _logger.d('Verifying 2FA setup');

      final secret = await SecureStorageService.getTwoFactorSecret();
      if (secret == null) {
        _logger.w('No 2FA secret found');
        return false;
      }

      final isValid = verifyTOTP(secret, code);
      _logger.d('2FA setup verification result: $isValid');

      return isValid;
    } catch (e) {
      _logger.e('Failed to verify 2FA setup: $e');
      return false;
    }
  }

  /// Verify 2FA code during authentication
  static Future<bool> verify2FACode(String code) async {
    try {
      _logger.d('Verifying 2FA code');

      final secret = await SecureStorageService.getTwoFactorSecret();
      if (secret == null) {
        _logger.w('No 2FA secret found');
        return false;
      }

      // First try TOTP verification
      if (verifyTOTP(secret, code)) {
        _logger.d('2FA code verified successfully (TOTP)');
        return true;
      }

      // If TOTP fails, try backup codes
      final backupCodes = await SecureStorageService.getBackupCodes();
      if (backupCodes != null && backupCodes.contains(code)) {
        // Remove used backup code
        backupCodes.remove(code);
        await SecureStorageService.storeBackupCodes(backupCodes);
        
        _logger.d('2FA code verified successfully (backup code)');
        return true;
      }

      _logger.d('2FA code verification failed');
      return false;
    } catch (e) {
      _logger.e('Failed to verify 2FA code: $e');
      return false;
    }
  }

  /// Disable 2FA
  static Future<void> disable2FA() async {
    try {
      _logger.d('Disabling 2FA');

      await SecureStorageService.removeTwoFactorSecret();
      await SecureStorageService.removeBackupCodes();

      _logger.d('2FA disabled successfully');
    } catch (e) {
      _logger.e('Failed to disable 2FA: $e');
      rethrow;
    }
  }

  /// Check if 2FA is enabled
  static Future<bool> is2FAEnabled() async {
    try {
      final secret = await SecureStorageService.getTwoFactorSecret();
      return secret != null;
    } catch (e) {
      _logger.e('Failed to check 2FA status: $e');
      return false;
    }
  }

  /// Get remaining backup codes count
  static Future<int> getRemainingBackupCodesCount() async {
    try {
      final backupCodes = await SecureStorageService.getBackupCodes();
      return backupCodes?.length ?? 0;
    } catch (e) {
      _logger.e('Failed to get backup codes count: $e');
      return 0;
    }
  }

  /// Regenerate backup codes
  static Future<List<String>> regenerateBackupCodes() async {
    try {
      _logger.d('Regenerating backup codes');

      final newBackupCodes = generateBackupCodes();
      await SecureStorageService.storeBackupCodes(newBackupCodes);

      _logger.d('Backup codes regenerated successfully');
      return newBackupCodes;
    } catch (e) {
      _logger.e('Failed to regenerate backup codes: $e');
      rethrow;
    }
  }

  /// Base32 encoding for secret
  static String base32Encode(List<int> bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    String result = '';
    int buffer = 0;
    int bitsLeft = 0;

    for (int byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;

      while (bitsLeft >= 5) {
        result += alphabet[(buffer >> (bitsLeft - 5)) & 31];
        bitsLeft -= 5;
      }
    }

    if (bitsLeft > 0) {
      result += alphabet[(buffer << (5 - bitsLeft)) & 31];
    }

    return result;
  }

  /// Get current TOTP code for testing
  static Future<String?> getCurrentTOTPCode() async {
    try {
      final secret = await SecureStorageService.getTwoFactorSecret();
      if (secret == null) {
        return null;
      }

      return generateTOTP(secret);
    } catch (e) {
      _logger.e('Failed to get current TOTP code: $e');
      return null;
    }
  }

  /// Get time remaining for current TOTP code
  static int getTimeRemainingForCurrentCode() {
    final now = DateTime.now();
    final secondsInInterval = 30;
    final secondsElapsed = now.second % secondsInInterval;
    return secondsInInterval - secondsElapsed;
  }
}
