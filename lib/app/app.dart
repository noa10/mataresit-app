import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/constants/app_constants.dart';
import '../core/services/app_logger.dart';
import '../features/auth/providers/auth_provider.dart';
import '../shared/providers/theme_provider.dart';

import '../shared/themes/ios_theme.dart';

import 'router/app_router.dart';
import '../shared/widgets/loading_widget.dart';

class MataresitApp extends ConsumerWidget {
  const MataresitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.debug('🔍 MATARESIT_APP: MataresitApp.build() called');

    try {
      AppLogger.debug('🔍 MATARESIT_APP: About to watch authProvider...');
      final authState = ref.watch(authProvider);
      AppLogger.debug('🔍 MATARESIT_APP: authProvider watched - isLoading=${authState.isLoading}, isAuthenticated=${authState.isAuthenticated}, error=${authState.error}');

      AppLogger.debug('🔍 MATARESIT_APP: About to watch routerProvider...');
      final router = ref.watch(routerProvider);
      AppLogger.debug('🔍 MATARESIT_APP: routerProvider watched successfully');

      AppLogger.debug('🔍 MATARESIT_APP: About to watch themeProvider...');
      final themeState = ref.watch(themeProvider);
      AppLogger.debug('🔍 MATARESIT_APP: themeProvider watched successfully');

      AppLogger.debug('🔍 MATARESIT_APP: About to watch currentThemeModeProvider...');
      final currentThemeMode = ref.watch(currentThemeModeProvider);
      AppLogger.debug('🔍 MATARESIT_APP: currentThemeModeProvider watched - mode=$currentThemeMode');

      AppLogger.debug('🔍 MATARESIT_APP: About to create MaterialApp.router...');
      final app = MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // Localization - conditional based on EasyLocalization availability
        localizationsDelegates: _getLocalizationDelegates(context),
        supportedLocales: _getSupportedLocales(context),
        locale: _getLocale(context),

        // Theme - Use adaptive theme for iOS compatibility
        theme: IOSTheme.getAdaptiveTheme(themeState.config.variant, Brightness.light),
        darkTheme: IOSTheme.getAdaptiveTheme(themeState.config.variant, Brightness.dark),
        themeMode: currentThemeMode,

        // Router
        routerConfig: router,

        // Builder for global loading state with improved error handling
        builder: (context, child) {
          AppLogger.debug('🔍 MATARESIT_APP: MaterialApp.router builder called - child is ${child != null ? 'NOT NULL' : 'NULL'}');

          // Handle authentication loading state
          if (authState.isLoading) {
            AppLogger.debug('🔍 MATARESIT_APP: Showing loading screen');
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingWidget(),
                    SizedBox(height: 16),
                    Text(
                      'Loading authentication...',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
          }

          // Ensure child is not null and provide fallback
          if (child == null) {
            AppLogger.debug('🔍 MATARESIT_APP: Child is null, showing error screen');
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'App content not available',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please restart the application',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          AppLogger.debug('🔍 MATARESIT_APP: Returning child widget');
          // Return the child with proper error boundary
          return child;
        },
      );

      AppLogger.debug('🔍 MATARESIT_APP: MaterialApp.router created successfully');
      return app;

    } catch (e, stackTrace) {
      AppLogger.error('🚨 MATARESIT_APP: Error in MataresitApp.build(): $e');
      AppLogger.error('🚨 MATARESIT_APP: Stack trace: $stackTrace');

      // Return minimal error app
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade50,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bug_report, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// Get localization delegates with fallback for when EasyLocalization is not available
  List<LocalizationsDelegate<dynamic>> _getLocalizationDelegates(BuildContext context) {
    try {
      // Try to get EasyLocalization delegates
      return context.localizationDelegates;
    } catch (e) {
      // Fallback to default Material delegates when EasyLocalization is not available
      return [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];
    }
  }

  /// Get supported locales with fallback for when EasyLocalization is not available
  List<Locale> _getSupportedLocales(BuildContext context) {
    try {
      // Try to get EasyLocalization supported locales
      return context.supportedLocales;
    } catch (e) {
      // Fallback to default locales when EasyLocalization is not available
      return const [
        Locale('en', 'US'), // English
        Locale('ms', 'MY'), // Malay
      ];
    }
  }

  /// Get current locale with fallback for when EasyLocalization is not available
  Locale _getLocale(BuildContext context) {
    try {
      // Try to get EasyLocalization current locale
      return context.locale;
    } catch (e) {
      // Fallback to English when EasyLocalization is not available
      return const Locale('en', 'US');
    }
  }
}
