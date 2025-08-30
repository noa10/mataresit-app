import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:logger/logger.dart';
import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'core/services/gemini_vision_service.dart';
import 'core/services/offline_database_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/performance_service.dart';
import 'core/services/workspace_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  try {
    // Initialize core services first (required for app to function)
    logger.i('🔧 Initializing core services...');
    await SupabaseService.initialize();
    logger.i('✅ Supabase initialized');

    GeminiVisionService.initialize();
    logger.i('✅ Gemini Vision initialized');

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

    logger.i('🎉 All services initialized successfully');
  } catch (e) {
    logger.e('❌ Critical service initialization failed: $e');
    // Continue anyway - app should still work with limited functionality
  }

  runApp(
    const ProviderScope(
      child: MataresitApp(),
    ),
  );
}
