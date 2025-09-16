import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/theme_model.dart' as theme_model;
import 'macos_theme.dart';

/// iOS-specific theme configuration following Human Interface Guidelines
class IOSTheme {
  /// Build iOS-compatible theme data
  static ThemeData buildIOSTheme(
    theme_model.ThemeVariant variant,
    Brightness brightness,
  ) {
    final definition = theme_model.ThemeVariantDefinition.getDefinition(
      variant,
    );

    // Base Material theme for compatibility
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: definition.seedColor,
        brightness: brightness,
      ),
      brightness: brightness,
    );

    // iOS-specific customizations
    return baseTheme.copyWith(
      // iOS-style app bar
      appBarTheme: _buildIOSAppBarTheme(baseTheme.colorScheme),

      // iOS-style navigation
      bottomNavigationBarTheme: _buildIOSBottomNavTheme(baseTheme.colorScheme),

      // iOS-style buttons
      elevatedButtonTheme: _buildIOSElevatedButtonTheme(baseTheme.colorScheme),
      textButtonTheme: _buildIOSTextButtonTheme(baseTheme.colorScheme),

      // iOS-style cards and surfaces
      cardTheme: _buildIOSCardTheme(baseTheme.colorScheme),

      // iOS-style input fields
      inputDecorationTheme: _buildIOSInputTheme(baseTheme.colorScheme),

      // iOS-style dialogs
      dialogTheme: _buildIOSDialogTheme(baseTheme.colorScheme),

      // iOS-style list tiles
      listTileTheme: _buildIOSListTileTheme(baseTheme.colorScheme),

      // iOS-style typography
      textTheme: _buildIOSTextTheme(baseTheme.textTheme, brightness),
    );
  }

  /// Build Cupertino theme for iOS-specific widgets
  static CupertinoThemeData buildCupertinoTheme(
    theme_model.ThemeVariant variant,
    Brightness brightness,
  ) {
    final definition = theme_model.ThemeVariantDefinition.getDefinition(
      variant,
    );

    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: definition.seedColor,
      primaryContrastingColor: brightness == Brightness.light
          ? CupertinoColors.white
          : CupertinoColors.black,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? CupertinoColors.systemGroupedBackground
          : CupertinoColors.systemGroupedBackground.darkColor,
      barBackgroundColor: brightness == Brightness.light
          ? CupertinoColors.systemBackground.withValues(alpha: 0.9)
          : CupertinoColors.systemBackground.darkColor.withValues(alpha: 0.9),
      textTheme: _buildCupertinoTextTheme(brightness),
    );
  }

  static AppBarTheme _buildIOSAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: true, // iOS-style centered titles
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      toolbarHeight: 44, // iOS standard navigation bar height
    );
  }

  static BottomNavigationBarThemeData _buildIOSBottomNavTheme(
    ColorScheme colorScheme,
  ) {
    return BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.7),
      selectedLabelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      type: BottomNavigationBarType.fixed,
    );
  }

  static ElevatedButtonThemeData _buildIOSElevatedButtonTheme(
    ColorScheme colorScheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // iOS-style rounded corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _buildIOSTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static CardThemeData _buildIOSCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // iOS-style rounded corners
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 0.5, // Subtle border for dark mode visibility
        ),
      ),
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
    );
  }

  static InputDecorationTheme _buildIOSInputTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: 17,
      ),
    );
  }

  static DialogThemeData _buildIOSDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), // iOS-style dialog corners
      ),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
    );
  }

  static ListTileThemeData _buildIOSListTileTheme(ColorScheme colorScheme) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      iconColor: colorScheme.primary,
    );
  }

  static TextTheme _buildIOSTextTheme(
    TextTheme baseTheme,
    Brightness brightness,
  ) {
    final color = brightness == Brightness.light ? Colors.black : Colors.white;

    return baseTheme.copyWith(
      // iOS system font sizes and weights
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color.withValues(alpha: 0.6),
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color.withValues(alpha: 0.6),
      ),
    );
  }

  static CupertinoTextThemeData _buildCupertinoTextTheme(
    Brightness brightness,
  ) {
    return CupertinoTextThemeData(
      primaryColor: brightness == Brightness.light
          ? CupertinoColors.label
          : CupertinoColors.label.darkColor,
    );
  }

  /// Check if current platform should use iOS styling
  static bool shouldUseIOSStyle() {
    try {
      return Platform.isIOS;
    } catch (e) {
      // Platform.isIOS is not supported on web
      // Return false for web and other unsupported platforms
      return false;
    }
  }

  /// Get appropriate theme based on platform
  static ThemeData getAdaptiveTheme(
    theme_model.ThemeVariant variant,
    Brightness brightness,
  ) {
    if (shouldUseIOSStyle()) {
      return buildIOSTheme(variant, brightness);
    }

    if (MacOSTheme.shouldUseMacOSStyle()) {
      return MacOSTheme.buildMacOSTheme(variant, brightness);
    }

    // Return standard Material theme for Android and other platforms
    final definition = theme_model.ThemeVariantDefinition.getDefinition(
      variant,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: definition.seedColor,
        brightness: brightness,
      ),
      brightness: brightness,
    );
  }
}
