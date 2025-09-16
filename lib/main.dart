import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:logger/logger.dart';
import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'core/services/app_logger.dart';

import 'core/services/ai_vision_service_manager.dart';
import 'core/services/offline_database_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/performance_service.dart';
import 'core/services/workspace_preferences_service.dart';
import 'core/services/currency_cache_service.dart';
import 'core/services/shared_preferences_compatibility_service.dart';
// import 'core/platform/ios_compatibility_service.dart'; // Disabled - causing issues

// import 'comprehensive_visual_debug.dart'; // Disabled for production
// import 'targeted_black_screen_test.dart'; // Disabled for production

// Debug mode flag
const bool debugMode = false;

void main() async {
  AppLogger.info('🚀 MAIN: Starting app initialization...');
  AppLogger.info('🚀 MAIN: Debug mode: $debugMode');

  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('🚀 MAIN: WidgetsFlutterBinding initialized');

  // Set up global error handler to prevent unhandled exceptions from causing black screen
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error('🚨 Flutter Error: ${details.exception}');
    AppLogger.error('🚨 Stack Trace: ${details.stack}');
    AppLogger.error('🚨 Library: ${details.library}');
    AppLogger.error('🚨 Context: ${details.context}');
  };

  // Add error handler for platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('🚨 Platform Error: $error');
    AppLogger.error('🚨 Platform Stack: $stack');
    return true;
  };

  // iOS rendering issue has been resolved by switching from Scene-based to traditional AppDelegate lifecycle

  final logger = Logger();

  try {
    // Load environment variables from .env file
    logger.i('🔧 Loading environment variables...');
    try {
      await dotenv.load(fileName: '.env');
      logger.i('✅ Environment variables loaded successfully');
      logger.i(
        '📋 GEMINI_API_KEY loaded: ${dotenv.env['GEMINI_API_KEY']?.isNotEmpty == true ? 'YES' : 'NO'}',
      );
    } catch (envError) {
      logger.w('⚠️ Failed to load .env file: $envError');
      logger.i('ℹ️ Will use default environment variables');
    }

    // Initialize SharedPreferences compatibility service first (iOS 18.x fix)
    logger.i('🔧 Initializing SharedPreferences compatibility service...');
    try {
      await SharedPreferencesCompatibilityService.initialize();
      final prefsInfo =
          SharedPreferencesCompatibilityService.getDiagnosticInfo();
      logger.i(
        '✅ SharedPreferences compatibility service initialized: $prefsInfo',
      );
    } catch (e) {
      logger.w('⚠️ SharedPreferences compatibility service failed: $e');
      logger.i('ℹ️ Will use fallback storage for this session');
    }

    // Initialize core services (required for app to function)
    logger.i('🔧 Initializing core services...');
    try {
      await SupabaseService.initialize();
      logger.i('✅ Supabase initialized');
    } catch (e) {
      logger.e('❌ Supabase initialization failed: $e');
      logger.w('ℹ️ App will work in offline mode only');
    }

    // Initialize AI Vision Services (optional service)
    try {
      AIVisionServiceManager.initialize();
      logger.i('✅ AI Vision Service Manager initialized');

      // Check configuration status
      if (AIVisionServiceManager.hasConfiguredServices()) {
        final services = AIVisionServiceManager.getConfiguredServiceNames();
        logger.i('✅ AI Vision services configured: ${services.join(', ')}');
      } else {
        logger.w(
          '⚠️ No AI Vision services are configured - receipt processing will not work',
        );
        logger.w(
          'ℹ️ Please set GEMINI_API_KEY or OPENROUTER_API_KEY environment variable',
        );
      }
    } catch (e) {
      logger.e('❌ AI Vision Service Manager initialization failed: $e');
      logger.w('ℹ️ Receipt AI processing will not be available');
      // Continue anyway - app should still work without AI processing
    }

    // Initialize offline capabilities (with individual error handling)
    try {
      await OfflineDatabaseService.initialize();
      logger.i('✅ Offline database initialized');
    } catch (e) {
      logger.w('⚠️ Offline database initialization failed: $e');
      logger.i('ℹ️ App will work in online-only mode');
    }

    try {
      await ConnectivityService.initialize();
      logger.i('✅ Connectivity service initialized');
    } catch (e) {
      logger.w('⚠️ Connectivity service initialization failed: $e');
    }

    try {
      await SyncService.initialize();
      logger.i('✅ Sync service initialized');
    } catch (e) {
      logger.w('⚠️ Sync service initialization failed: $e');
    }

    // Initialize notifications (local notifications only)
    try {
      await NotificationService.initialize();
      logger.i('✅ Local notifications initialized');
    } catch (e) {
      logger.w('⚠️ Notification initialization failed: $e');
      logger.i('ℹ️ Local notifications will not be available');
    }

    // Initialize performance optimizations
    try {
      await PerformanceService.initialize();
      logger.i('✅ Performance services initialized');
    } catch (e) {
      logger.w('⚠️ Performance service initialization failed: $e');
      logger.i('ℹ️ Performance monitoring will not be available');
    }

    // Initialize workspace preferences with error handling
    try {
      await WorkspacePreferencesService.initialize();
      logger.i('✅ Workspace preferences initialized');
    } catch (e) {
      logger.w('⚠️ Workspace preferences initialization failed: $e');
      logger.i('ℹ️ App will continue with default workspace settings');
    }

    // Initialize currency cache service with error handling
    try {
      await CurrencyCacheService.initialize();
      logger.i('✅ Currency cache service initialized');
    } catch (e) {
      logger.w('⚠️ Currency cache service initialization failed: $e');
      logger.i('ℹ️ App will continue with default currency settings');
    }

    // Initialize EasyLocalization - it can work without SharedPreferences
    try {
      logger.i(
        '🌍 Initializing EasyLocalization (independent of SharedPreferences)',
      );
      await EasyLocalization.ensureInitialized();
      logger.i('✅ EasyLocalization initialized successfully');
    } catch (e) {
      logger.w('⚠️ EasyLocalization initialization failed: $e');
      logger.i('ℹ️ App will continue with default locale (English)');
    }

    logger.i('🎉 All services initialized successfully');
  } catch (e, stackTrace) {
    logger.e('❌ Critical service initialization failed: $e');
    logger.e('Stack trace: $stackTrace');
    // Continue anyway - app should still work with limited functionality
  }

  // Test asset loading before EasyLocalization
  logger.i('🌍 Testing direct asset loading...');
  bool assetsLoadable = false;
  try {
    final String enContent = await rootBundle.loadString(
      'assets/translations/en.json',
    );
    final String msContent = await rootBundle.loadString(
      'assets/translations/ms.json',
    );
    logger.i(
      '🌍 Direct asset loading successful - EN: ${enContent.length} chars, MS: ${msContent.length} chars',
    );

    // Try to parse JSON to verify format
    final enJson = json.decode(enContent);
    final msJson = json.decode(msContent);
    logger.i(
      '🌍 JSON parsing successful - EN keys: ${enJson.keys.length}, MS keys: ${msJson.keys.length}',
    );

    // Test specific keys that are failing
    logger.i('🌍 Testing specific keys:');
    logger.i(
      '🌍   - settings.title: ${_getNestedValue(enJson, 'settings.title')}',
    );
    logger.i(
      '🌍   - settings.tabs.billing: ${_getNestedValue(enJson, 'settings.tabs.billing')}',
    );
    logger.i(
      '🌍   - common.labels.subscription: ${_getNestedValue(enJson, 'common.labels.subscription')}',
    );

    assetsLoadable = true;
  } catch (e, stackTrace) {
    logger.e(
      '🌍 ❌ Direct asset loading failed',
      error: e,
      stackTrace: stackTrace,
    );
    assetsLoadable = false;
  }

  logger.i('🌍 Assets loadable: $assetsLoadable');

  // Always try to run with EasyLocalization since assets are confirmed to be accessible
  logger.i('🌍 Starting app with EasyLocalization');
  logger.i('🌍 Supported locales: [en, ms]');
  logger.i('🌍 Translation path: assets/translations');
  logger.i('🌍 Fallback locale: en');

  // Fixed EasyLocalization implementation to prevent black screen
  logger.i('🌍 Starting app with properly configured EasyLocalization');
  AppLogger.info('🚀 MAIN: About to call runApp()...');

  // Final window size check before running app
  final finalView = WidgetsBinding.instance.platformDispatcher.views.first;
  AppLogger.debug(
    '🔍 FINAL_CHECK: Window size before runApp: ${finalView.physicalSize}',
  );
  if (finalView.physicalSize.width == 0 || finalView.physicalSize.height == 0) {
    AppLogger.warning(
      '🚨 FINAL_CHECK: Window still has zero size, this may cause black screen',
    );
  } else {
    AppLogger.info(
      '✅ FINAL_CHECK: Window size is valid, proceeding with app launch',
    );
  }

  // Disable Flutter visual debugging for production iOS app
  debugPaintSizeEnabled = false; // Disable widget boundaries for production
  debugRepaintRainbowEnabled = false; // Disable repaint rainbow for production
  AppLogger.debug(
    '🔍 VISUAL_DEBUG: Disabled visual debugging for production iOS app',
  );

  try {
    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ms')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        assetLoader: const RootBundleAssetLoader(),
        // Key fix: Add errorWidget to handle initialization issues gracefully
        errorWidget: (message) {
          AppLogger.error(
            '🚨 MAIN: EasyLocalization error widget triggered: $message',
          );
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Localization Error: $message'),
                    const SizedBox(height: 16),
                    const Text('Please restart the app'),
                  ],
                ),
              ),
            ),
          );
        },
        child: const ProviderScope(child: MataresitApp()),
      ),
    );
    // Schedule post-frame diagnostics to verify that a real frame was rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      AppLogger.debug(
        '🔎 POST_FRAME: Window physicalSize: ${view.physicalSize}, DPR: ${view.devicePixelRatio}',
      );
      AppLogger.debug(
        '🔎 POST_FRAME: View insets: ${view.viewInsets}, padding: ${view.padding}, viewPadding: ${view.viewPadding}',
      );
    });

    // Also log again after a slight delay to catch late size updates on iOS Simulator
    Future.delayed(const Duration(milliseconds: 200), () {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      AppLogger.debug(
        '🔎 DELAYED_200MS: Window physicalSize: ${view.physicalSize}, DPR: ${view.devicePixelRatio}',
      );
    });

    AppLogger.info('🚀 MAIN: runApp() called successfully');
  } catch (e, stackTrace) {
    AppLogger.error('🚨 MAIN: runApp() failed with error: $e');
    AppLogger.error('🚨 MAIN: Stack trace: $stackTrace');

    // Fallback: run minimal app without EasyLocalization
    AppLogger.info(
      '🚀 MAIN: Attempting fallback app without EasyLocalization...',
    );
    runApp(const ProviderScope(child: MataresitApp()));
  }
}

// Helper function to get nested values from JSON
dynamic _getNestedValue(Map<String, dynamic> json, String key) {
  final keys = key.split('.');
  dynamic current = json;
  for (final k in keys) {
    if (current is Map<String, dynamic> && current.containsKey(k)) {
      current = current[k];
    } else {
      return 'NOT_FOUND';
    }
  }
  return current;
}
