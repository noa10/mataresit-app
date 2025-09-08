import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:logger/logger.dart';
import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'core/services/ai_vision_service_manager.dart';
import 'core/services/offline_database_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/performance_service.dart';
import 'core/services/workspace_preferences_service.dart';
import 'core/services/currency_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  try {
    // Load environment variables from .env file
    logger.i('🔧 Loading environment variables...');
    try {
      await dotenv.load(fileName: '.env');
      logger.i('✅ Environment variables loaded successfully');
      logger.i('📋 GEMINI_API_KEY loaded: ${dotenv.env['GEMINI_API_KEY']?.isNotEmpty == true ? 'YES' : 'NO'}');
    } catch (envError) {
      logger.w('⚠️ Failed to load .env file: $envError');
      logger.i('ℹ️ Will use default environment variables');
    }

    // Initialize core services first (required for app to function)
    logger.i('🔧 Initializing core services...');
    await SupabaseService.initialize();
    logger.i('✅ Supabase initialized');

    // Initialize AI Vision Services (optional service)
    try {
      AIVisionServiceManager.initialize();
      logger.i('✅ AI Vision Service Manager initialized');

      // Check configuration status
      if (AIVisionServiceManager.hasConfiguredServices()) {
        final services = AIVisionServiceManager.getConfiguredServiceNames();
        logger.i('✅ AI Vision services configured: ${services.join(', ')}');
      } else {
        logger.w('⚠️ No AI Vision services are configured - receipt processing will not work');
        logger.w('ℹ️ Please set GEMINI_API_KEY or OPENROUTER_API_KEY environment variable');
      }
    } catch (e) {
      logger.e('❌ AI Vision Service Manager initialization failed: $e');
      logger.w('ℹ️ Receipt AI processing will not be available');
      // Continue anyway - app should still work without AI processing
    }

    // Initialize offline capabilities
    await OfflineDatabaseService.initialize();
    await ConnectivityService.initialize();
    await SyncService.initialize();
    logger.i('✅ Offline services initialized');

    // Initialize notifications (local notifications only)
    try {
      await NotificationService.initialize();
      logger.i('✅ Local notifications initialized');
    } catch (e) {
      logger.w('⚠️ Notification initialization failed: $e');
      logger.i('ℹ️ Local notifications will not be available');
    }

    // Initialize performance optimizations
    await PerformanceService.initialize();
    logger.i('✅ Performance services initialized');

    // Initialize workspace preferences
    await WorkspacePreferencesService.initialize();
    logger.i('✅ Workspace preferences initialized');

    // Initialize currency cache service
    await CurrencyCacheService.initialize();
    logger.i('✅ Currency cache service initialized');

    // Initialize EasyLocalization
    await EasyLocalization.ensureInitialized();
    logger.i('✅ EasyLocalization initialized');

    logger.i('🎉 All services initialized successfully');
  } catch (e) {
    logger.e('❌ Critical service initialization failed: $e');
    // Continue anyway - app should still work with limited functionality
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: MataresitApp(),
      ),
    ),
  );
}
