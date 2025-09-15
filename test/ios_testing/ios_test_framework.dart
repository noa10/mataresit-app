import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../test_helpers/test_logger.dart';

/// Comprehensive iOS testing framework for Phase 3 validation
class IOSTestFramework {
  static const String _tag = 'IOSTestFramework';
  static final _logger = TestLogger.getLogger(_tag);
  
  static IosDeviceInfo? _deviceInfo;
  static bool _isInitialized = false;

  /// Initialize the iOS testing framework
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _logger.i('Initializing iOS Test Framework');
    
    try {
      // Initialize device info
      if (Platform.isIOS) {
        final deviceInfoPlugin = DeviceInfoPlugin();
        _deviceInfo = await deviceInfoPlugin.iosInfo;
        _logger.i('iOS Device: ${_deviceInfo?.model} (${_deviceInfo?.systemVersion})');
      }
      
      // Package info initialization removed for testing simplicity
      _logger.i('iOS Test Framework package info skipped for testing');
      
      _isInitialized = true;
      _logger.i('iOS Test Framework initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize iOS Test Framework: $e');
      rethrow;
    }
  }

  /// Get current iOS device information
  static IosDeviceInfo? get deviceInfo => _deviceInfo;
  
  /// Check if running on iOS simulator
  static bool get isSimulator => _deviceInfo?.isPhysicalDevice == false;
  
  /// Check if running on physical iOS device
  static bool get isPhysicalDevice => _deviceInfo?.isPhysicalDevice == true;
  
  /// Get iOS version as comparable version
  static Version get iOSVersion {
    if (_deviceInfo?.systemVersion == null) return Version(0, 0, 0);
    final parts = _deviceInfo!.systemVersion.split('.');
    return Version(
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0,
    );
  }
  
  /// Check if iOS version meets minimum requirement
  static bool meetsMinimumIOSVersion(int major, [int minor = 0, int patch = 0]) {
    final current = iOSVersion;
    final required = Version(major, minor, patch);
    return current.compareTo(required) >= 0;
  }
  
  /// Get device model category for testing
  static DeviceCategory get deviceCategory {
    if (_deviceInfo == null) return DeviceCategory.unknown;
    
    final model = _deviceInfo!.model.toLowerCase();
    if (model.contains('iphone')) {
      if (model.contains('se')) return DeviceCategory.iPhoneSE;
      if (model.contains('mini')) return DeviceCategory.iPhoneMini;
      if (model.contains('pro max')) return DeviceCategory.iPhoneProMax;
      if (model.contains('pro')) return DeviceCategory.iPhonePro;
      if (model.contains('plus')) return DeviceCategory.iPhonePlus;
      return DeviceCategory.iPhone;
    }
    if (model.contains('ipad')) {
      if (model.contains('pro')) return DeviceCategory.iPadPro;
      if (model.contains('air')) return DeviceCategory.iPadAir;
      if (model.contains('mini')) return DeviceCategory.iPadMini;
      return DeviceCategory.iPad;
    }
    return DeviceCategory.unknown;
  }
  
  /// Check if device supports Face ID
  static bool get supportsFaceID {
    if (_deviceInfo == null) return false;
    // Face ID supported on iPhone X and later (excluding SE models)
    final model = _deviceInfo!.model.toLowerCase();
    return model.contains('iphone') && 
           !model.contains('se') && 
           !model.contains('8') && 
           !model.contains('7') && 
           !model.contains('6');
  }
  
  /// Check if device supports Touch ID
  static bool get supportsTouchID {
    if (_deviceInfo == null) return false;
    // Touch ID supported on iPhone 5s and later, iPad Air 2 and later
    final model = _deviceInfo!.model.toLowerCase();
    return (model.contains('iphone') && !supportsFaceID) || 
           model.contains('ipad');
  }
  
  /// Get expected biometric type for device
  static BiometricType get expectedBiometricType {
    if (supportsFaceID) return BiometricType.faceID;
    if (supportsTouchID) return BiometricType.touchID;
    return BiometricType.none;
  }
}

/// Version comparison utility
class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;
  
  const Version(this.major, this.minor, this.patch);
  
  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }
  
  @override
  String toString() => '$major.$minor.$patch';
}

/// Device categories for testing
enum DeviceCategory {
  iPhone,
  iPhoneSE,
  iPhoneMini,
  iPhonePro,
  iPhoneProMax,
  iPhonePlus,
  iPad,
  iPadMini,
  iPadAir,
  iPadPro,
  unknown,
}

/// Biometric authentication types
enum BiometricType {
  none,
  touchID,
  faceID,
}

/// Test result status
enum TestStatus {
  notStarted,
  running,
  passed,
  failed,
  skipped,
}

/// Comprehensive test result
class IOSTestResult {
  final String testName;
  final String testSuite;
  final TestStatus status;
  final Duration? duration;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  
  const IOSTestResult({
    required this.testName,
    required this.testSuite,
    required this.status,
    this.duration,
    this.errorMessage,
    this.metadata = const {},
    required this.timestamp,
  });
  
  /// Create a passed test result
  factory IOSTestResult.passed({
    required String testName,
    required String testSuite,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return IOSTestResult(
      testName: testName,
      testSuite: testSuite,
      status: TestStatus.passed,
      duration: duration,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }
  
  /// Create a failed test result
  factory IOSTestResult.failed({
    required String testName,
    required String testSuite,
    required String errorMessage,
    Duration? duration,
    Map<String, dynamic> metadata = const {},
  }) {
    return IOSTestResult(
      testName: testName,
      testSuite: testSuite,
      status: TestStatus.failed,
      duration: duration,
      errorMessage: errorMessage,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }
  
  /// Create a skipped test result
  factory IOSTestResult.skipped({
    required String testName,
    required String testSuite,
    required String reason,
    Map<String, dynamic> metadata = const {},
  }) {
    return IOSTestResult(
      testName: testName,
      testSuite: testSuite,
      status: TestStatus.skipped,
      errorMessage: reason,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }
  
  /// Convert to JSON for reporting
  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'testSuite': testSuite,
      'status': status.name,
      'duration': duration?.inMilliseconds,
      'errorMessage': errorMessage,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
