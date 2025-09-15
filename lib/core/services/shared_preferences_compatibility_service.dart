import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Compatibility service for SharedPreferences with iOS 18.x fallback support
/// 
/// This service provides a fallback mechanism when SharedPreferences fails
/// to initialize on iOS 18.x beta with Xcode 26.0 beta due to platform
/// channel communication issues.
class SharedPreferencesCompatibilityService {
  static final Logger _logger = Logger();
  static SharedPreferences? _instance;
  static bool _isAvailable = false;
  static final Map<String, dynamic> _fallbackStorage = {};

  /// Initialize SharedPreferences with fallback support and iOS 18.x beta compatibility
  static Future<void> initialize() async {
    try {
      _logger.i('🔧 Initializing SharedPreferences...');
      _instance = await SharedPreferences.getInstance();
      _isAvailable = true;
      _logger.i('✅ SharedPreferences initialized successfully');
    } catch (e) {
      _isAvailable = false;
      _logger.w('⚠️ SharedPreferences failed to initialize: $e');

      // Check if this is the known iOS 18.x beta channel issue
      if (e.toString().contains('channel-error') &&
          e.toString().contains('LegacyUserDefaultsApi')) {
        _logger.i('📱 Detected iOS 18.x beta compatibility issue - using fallback storage');
      } else {
        _logger.w('📱 Unknown SharedPreferences error - using fallback storage');
      }

      _logger.i('💾 Using in-memory fallback storage for this session');

      // Try to initialize again after a delay (sometimes it works on retry)
      _scheduleRetryInitialization();
    }
  }

  /// Schedule a retry initialization attempt
  static void _scheduleRetryInitialization() {
    Timer(const Duration(seconds: 2), () async {
      if (!_isAvailable) {
        try {
          _logger.d('🔄 Retrying SharedPreferences initialization...');
          _instance = await SharedPreferences.getInstance();
          _isAvailable = true;
          _logger.i('✅ SharedPreferences initialized successfully on retry');
        } catch (e) {
          _logger.d('🔄 SharedPreferences retry failed: $e');
          // Continue using fallback storage
        }
      }
    });
  }

  /// Check if SharedPreferences is available
  static bool get isAvailable => _isAvailable;

  /// Get SharedPreferences instance (may be null if not available)
  static SharedPreferences? get instance => _instance;

  /// Get string value with fallback
  static String? getString(String key) {
    if (_isAvailable && _instance != null) {
      try {
        return _instance!.getString(key);
      } catch (e) {
        _logger.w('⚠️ Failed to get string from SharedPreferences: $e');
      }
    }
    return _fallbackStorage[key] as String?;
  }

  /// Set string value with fallback
  static Future<bool> setString(String key, String value) async {
    bool success = false;
    
    if (_isAvailable && _instance != null) {
      try {
        success = await _instance!.setString(key, value);
      } catch (e) {
        _logger.w('⚠️ Failed to set string in SharedPreferences: $e');
      }
    }
    
    // Always update fallback storage
    _fallbackStorage[key] = value;
    return success || !_isAvailable; // Return true if using fallback
  }

  /// Get bool value with fallback
  static bool? getBool(String key) {
    if (_isAvailable && _instance != null) {
      try {
        return _instance!.getBool(key);
      } catch (e) {
        _logger.w('⚠️ Failed to get bool from SharedPreferences: $e');
      }
    }
    return _fallbackStorage[key] as bool?;
  }

  /// Set bool value with fallback
  static Future<bool> setBool(String key, bool value) async {
    bool success = false;
    
    if (_isAvailable && _instance != null) {
      try {
        success = await _instance!.setBool(key, value);
      } catch (e) {
        _logger.w('⚠️ Failed to set bool in SharedPreferences: $e');
      }
    }
    
    // Always update fallback storage
    _fallbackStorage[key] = value;
    return success || !_isAvailable; // Return true if using fallback
  }

  /// Get int value with fallback
  static int? getInt(String key) {
    if (_isAvailable && _instance != null) {
      try {
        return _instance!.getInt(key);
      } catch (e) {
        _logger.w('⚠️ Failed to get int from SharedPreferences: $e');
      }
    }
    return _fallbackStorage[key] as int?;
  }

  /// Set int value with fallback
  static Future<bool> setInt(String key, int value) async {
    bool success = false;
    
    if (_isAvailable && _instance != null) {
      try {
        success = await _instance!.setInt(key, value);
      } catch (e) {
        _logger.w('⚠️ Failed to set int in SharedPreferences: $e');
      }
    }
    
    // Always update fallback storage
    _fallbackStorage[key] = value;
    return success || !_isAvailable; // Return true if using fallback
  }

  /// Get string list with fallback
  static List<String>? getStringList(String key) {
    if (_isAvailable && _instance != null) {
      try {
        return _instance!.getStringList(key);
      } catch (e) {
        _logger.w('⚠️ Failed to get string list from SharedPreferences: $e');
      }
    }
    return _fallbackStorage[key] as List<String>?;
  }

  /// Set string list with fallback
  static Future<bool> setStringList(String key, List<String> value) async {
    bool success = false;
    
    if (_isAvailable && _instance != null) {
      try {
        success = await _instance!.setStringList(key, value);
      } catch (e) {
        _logger.w('⚠️ Failed to set string list in SharedPreferences: $e');
      }
    }
    
    // Always update fallback storage
    _fallbackStorage[key] = value;
    return success || !_isAvailable; // Return true if using fallback
  }

  /// Remove key with fallback
  static Future<bool> remove(String key) async {
    bool success = false;
    
    if (_isAvailable && _instance != null) {
      try {
        success = await _instance!.remove(key);
      } catch (e) {
        _logger.w('⚠️ Failed to remove key from SharedPreferences: $e');
      }
    }
    
    // Always remove from fallback storage
    _fallbackStorage.remove(key);
    return success || !_isAvailable; // Return true if using fallback
  }

  /// Check if key exists with fallback
  static bool containsKey(String key) {
    if (_isAvailable && _instance != null) {
      try {
        return _instance!.containsKey(key);
      } catch (e) {
        _logger.w('⚠️ Failed to check key in SharedPreferences: $e');
      }
    }
    return _fallbackStorage.containsKey(key);
  }

  /// Get all keys with fallback
  static Set<String> getKeys() {
    if (_isAvailable && _instance != null) {
      try {
        return _instance!.getKeys();
      } catch (e) {
        _logger.w('⚠️ Failed to get keys from SharedPreferences: $e');
      }
    }
    return _fallbackStorage.keys.toSet();
  }

  /// Clear all data with fallback
  static Future<bool> clear() async {
    bool success = false;
    
    if (_isAvailable && _instance != null) {
      try {
        success = await _instance!.clear();
      } catch (e) {
        _logger.w('⚠️ Failed to clear SharedPreferences: $e');
      }
    }
    
    // Always clear fallback storage
    _fallbackStorage.clear();
    return success || !_isAvailable; // Return true if using fallback
  }

  /// Get diagnostic information
  static Map<String, dynamic> getDiagnosticInfo() {
    return {
      'isAvailable': _isAvailable,
      'hasInstance': _instance != null,
      'fallbackStorageSize': _fallbackStorage.length,
      'fallbackKeys': _fallbackStorage.keys.toList(),
    };
  }
}
