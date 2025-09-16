import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../services/app_logger.dart';

/// iOS compatibility service to handle iOS 18.x rendering issues
class IOSCompatibilityService {
  static bool _initialized = false;
  static Timer? _windowSizeMonitor;
  static int _retryCount = 0;
  static const int _maxRetries = 10;

  /// Initialize iOS compatibility fixes
  static Future<void> initialize() async {
    if (_initialized || !Platform.isIOS) return;

    AppLogger.info('🔧 iOS_COMPAT: Initializing iOS compatibility service');

    try {
      // Apply iOS 18.x specific fixes
      await _applyiOS18Fixes();

      // Start window size monitoring
      _startWindowSizeMonitoring();

      _initialized = true;
      AppLogger.info(
        '✅ iOS_COMPAT: iOS compatibility service initialized successfully',
      );
    } catch (e) {
      AppLogger.warning(
        '⚠️ iOS_COMPAT: Failed to initialize iOS compatibility service: $e',
      );
    }
  }

  /// Apply iOS 18.x specific fixes
  static Future<void> _applyiOS18Fixes() async {
    AppLogger.debug('🔧 iOS_COMPAT: Applying iOS 18.x compatibility fixes');

    // Fix 1: Ensure WidgetsBinding is properly initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Fix 2: Force window metrics update
    final binding = WidgetsBinding.instance;
    binding.handleMetricsChanged();

    // Fix 3: Check and fix zero-size window
    await _checkAndFixZeroSizeWindow();

    // Fix 4: Apply iOS-specific rendering optimizations
    _applyiOSRenderingOptimizations();
  }

  /// Check and fix zero-size window issue
  static Future<void> _checkAndFixZeroSizeWindow() async {
    final binding = WidgetsBinding.instance;
    final view = binding.platformDispatcher.views.first;

    AppLogger.debug(
      '🔧 iOS_COMPAT: Checking window size - Physical: ${view.physicalSize}, DPR: ${view.devicePixelRatio}',
    );

    if (view.physicalSize.width == 0 || view.physicalSize.height == 0) {
      AppLogger.warning(
        '🚨 iOS_COMPAT: Zero-size window detected, applying fixes',
      );

      // Retry mechanism for window size fix
      for (int i = 0; i < _maxRetries; i++) {
        await _attemptWindowSizeFix(i + 1);

        // Check if fix was successful
        final currentView = binding.platformDispatcher.views.first;
        if (currentView.physicalSize.width > 0 &&
            currentView.physicalSize.height > 0) {
          AppLogger.info(
            '✅ iOS_COMPAT: Window size fix successful on attempt ${i + 1}',
          );
          break;
        }

        // Wait before next attempt
        await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
      }
    } else {
      AppLogger.debug('✅ iOS_COMPAT: Window size is valid');
    }
  }

  /// Attempt to fix window size
  static Future<void> _attemptWindowSizeFix(int attempt) async {
    AppLogger.debug(
      '🔧 iOS_COMPAT: Window size fix attempt $attempt/$_maxRetries',
    );

    final binding = WidgetsBinding.instance;

    // Method 1: Force metrics update
    binding.handleMetricsChanged();

    // Method 2: Schedule multiple frames
    binding.scheduleFrame();
    await Future.delayed(const Duration(milliseconds: 16));
    binding.scheduleFrame();

    // Method 3: Force render view update if available
    final renderViews = binding.renderViews;
    if (renderViews.isNotEmpty) {
      final renderView = renderViews.first;
      renderView.markNeedsLayout();
      renderView.markNeedsPaint();
      renderView.markNeedsCompositingBitsUpdate();
    }

    // Method 4: Platform-specific window size request
    try {
      await _requestWindowSizeUpdate();
    } catch (e) {
      AppLogger.warning(
        '⚠️ iOS_COMPAT: Platform window size request failed: $e',
      );
    }
  }

  /// Request window size update from platform
  static Future<void> _requestWindowSizeUpdate() async {
    const platform = MethodChannel('flutter/platform');
    try {
      await platform.invokeMethod(
        'SystemChrome.setApplicationSwitcherDescription',
        {'label': 'Mataresit', 'primaryColor': 0xFF2196F3},
      );
    } catch (e) {
      // Ignore platform method errors
    }
  }

  /// Apply iOS-specific rendering optimizations
  static void _applyiOSRenderingOptimizations() {
    AppLogger.debug('🔧 iOS_COMPAT: Applying iOS rendering optimizations');

    // Disable problematic debug flags that might interfere with iOS rendering
    debugPaintSizeEnabled = false;
    debugRepaintRainbowEnabled = false;

    // Set iOS-specific rendering preferences
    if (Platform.isIOS) {
      // Force immediate frame scheduling
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  /// Start monitoring window size changes
  static void _startWindowSizeMonitoring() {
    AppLogger.debug('🔧 iOS_COMPAT: Starting window size monitoring');

    _windowSizeMonitor = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkWindowSizeHealth();
    });
  }

  /// Check window size health periodically
  static void _checkWindowSizeHealth() {
    final binding = WidgetsBinding.instance;
    final view = binding.platformDispatcher.views.first;

    if (view.physicalSize.width == 0 || view.physicalSize.height == 0) {
      _retryCount++;
      AppLogger.warning(
        '🚨 iOS_COMPAT: Window size became zero during runtime (retry $_retryCount)',
      );

      if (_retryCount <= 3) {
        // Attempt to fix
        _attemptWindowSizeFix(_retryCount);
      } else {
        AppLogger.error(
          '🚨 iOS_COMPAT: Too many window size failures, stopping monitoring',
        );
        _windowSizeMonitor?.cancel();
      }
    } else {
      // Reset retry count on successful check
      if (_retryCount > 0) {
        AppLogger.info('✅ iOS_COMPAT: Window size recovered');
        _retryCount = 0;
      }
    }
  }

  /// Get diagnostic information
  static Map<String, dynamic> getDiagnosticInfo() {
    final binding = WidgetsBinding.instance;
    final view = binding.platformDispatcher.views.first;
    final renderViews = binding.renderViews;

    return {
      'initialized': _initialized,
      'platform': Platform.operatingSystem,
      'window_physical_size': '${view.physicalSize}',
      'window_device_pixel_ratio': view.devicePixelRatio,
      'window_view_padding': '${view.viewPadding}',
      'window_view_insets': '${view.viewInsets}',
      'render_view_exists': renderViews.isNotEmpty,
      'render_view_size': renderViews.isNotEmpty
          ? renderViews.first.size.toString()
          : 'null',
      'monitoring_active': _windowSizeMonitor?.isActive ?? false,
      'retry_count': _retryCount,
    };
  }

  /// Dispose of the service
  static void dispose() {
    _windowSizeMonitor?.cancel();
    _windowSizeMonitor = null;
    _initialized = false;
    _retryCount = 0;
    AppLogger.debug('🔧 iOS_COMPAT: iOS compatibility service disposed');
  }
}
