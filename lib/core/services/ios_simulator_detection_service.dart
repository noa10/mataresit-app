import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// Service to detect if the app is running on iOS Simulator
/// This is crucial for providing simulator-compatible implementations
/// of services that don't work properly in the simulator environment
class IOSSimulatorDetectionService {
  static bool? _isSimulator;
  static bool? _isPhysicalDevice;

  /// Check if the current platform is iOS Simulator
  static bool get isIOSSimulator {
    if (_isSimulator != null) return _isSimulator!;

    if (!Platform.isIOS) {
      _isSimulator = false;
      return false;
    }

    // In debug mode, we can use additional checks
    if (kDebugMode) {
      // iOS Simulator typically has these characteristics:
      // 1. x86_64 or arm64 architecture (but arm64 is also on physical devices now)
      // 2. Specific environment variables
      // 3. Different system properties

      try {
        // Check for simulator-specific environment
        final result = Process.runSync('uname', ['-m']);
        final architecture = result.stdout.toString().trim();

        // Additional simulator detection methods
        final isSimulatorArch = architecture.contains('x86_64');

        // For now, we'll use a simple heuristic
        // In production, you might want more sophisticated detection
        _isSimulator = isSimulatorArch;

        print('🔍 SIMULATOR_DETECTION: Architecture: $architecture');
        print('🔍 SIMULATOR_DETECTION: Is simulator: $_isSimulator');

        return _isSimulator!;
      } catch (e) {
        print('⚠️ SIMULATOR_DETECTION: Failed to detect simulator: $e');
        // Fallback: assume physical device if detection fails
        _isSimulator = false;
        return false;
      }
    }

    // In release mode, assume physical device for safety
    _isSimulator = false;
    return false;
  }

  /// Check if the current platform is a physical iOS device
  static bool get isPhysicalIOSDevice {
    if (_isPhysicalDevice != null) return _isPhysicalDevice!;

    _isPhysicalDevice = Platform.isIOS && !isIOSSimulator;
    return _isPhysicalDevice!;
  }

  /// Get a description of the current platform for debugging
  static String get platformDescription {
    if (!Platform.isIOS) return 'Non-iOS Platform';
    if (isIOSSimulator) return 'iOS Simulator';
    if (isPhysicalIOSDevice) return 'Physical iOS Device';
    return 'Unknown iOS Platform';
  }

  /// Reset detection cache (useful for testing)
  static void resetDetection() {
    _isSimulator = null;
    _isPhysicalDevice = null;
  }

  /// Get diagnostic information about the platform
  static Map<String, dynamic> getDiagnosticInfo() {
    return {
      'platform': Platform.operatingSystem,
      'isIOS': Platform.isIOS,
      'isSimulator': isIOSSimulator,
      'isPhysicalDevice': isPhysicalIOSDevice,
      'platformDescription': platformDescription,
      'debugMode': kDebugMode,
    };
  }

  /// Log platform information for debugging
  static void logPlatformInfo() {
    final info = getDiagnosticInfo();
    AppLogger.debug('🔍 PLATFORM_INFO: ${info.toString()}');
  }
}
