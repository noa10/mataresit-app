import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/constants/app_constants.dart';
import '../features/auth/providers/auth_provider.dart';
import '../shared/providers/theme_provider.dart';
import '../shared/models/theme_model.dart' as theme_model;

import 'router/app_router.dart';
import '../shared/widgets/loading_widget.dart';

class MataresitApp extends ConsumerWidget {
  const MataresitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    final currentThemeMode = ref.watch(currentThemeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme
      theme: _buildTheme(themeState.config.variant, Brightness.light),
      darkTheme: _buildTheme(themeState.config.variant, Brightness.dark),
      themeMode: currentThemeMode,

      // Router
      routerConfig: router,

      // Builder for global loading state
      builder: (context, child) {
        if (authState.isLoading) {
          return const Scaffold(body: LoadingWidget());
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  ThemeData _buildTheme(
    theme_model.ThemeVariant variant,
    Brightness brightness,
  ) {
    final definition = theme_model.ThemeVariantDefinition.getDefinition(
      variant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: definition.seedColor,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
            vertical: AppConstants.defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.largePadding,
            vertical: AppConstants.defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(
            color: brightness == Brightness.light
                ? Colors.grey.shade300
                : Colors.grey.shade600,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: definition.seedColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.defaultPadding,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedItemColor: brightness == Brightness.light
            ? definition.seedColor
            : Color.lerp(definition.seedColor, Colors.white, 0.3),
        unselectedItemColor: brightness == Brightness.light
            ? Colors.grey.shade600
            : Colors.grey.shade400,
        backgroundColor: brightness == Brightness.light
            ? null // Use default light background
            : const Color(0xFF1A1A1A), // Dark background with better contrast
      ),
    );
  }
}
