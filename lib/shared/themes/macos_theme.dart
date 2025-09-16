import 'dart:io';
import 'package:flutter/material.dart';
import '../models/theme_model.dart' as theme_model;

/// macOS-specific theme configuration following macOS Human Interface Guidelines
class MacOSTheme {
  /// Build macOS-compatible theme data
  static ThemeData buildMacOSTheme(
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

    // macOS-specific customizations
    return baseTheme.copyWith(
      // macOS-style app bar
      appBarTheme: _buildMacOSAppBarTheme(baseTheme.colorScheme),

      // macOS-style navigation
      bottomNavigationBarTheme: _buildMacOSBottomNavTheme(
        baseTheme.colorScheme,
      ),

      // macOS-style buttons
      elevatedButtonTheme: _buildMacOSElevatedButtonTheme(
        baseTheme.colorScheme,
      ),
      textButtonTheme: _buildMacOSTextButtonTheme(baseTheme.colorScheme),

      // macOS-style cards and surfaces
      cardTheme: _buildMacOSCardTheme(baseTheme.colorScheme),

      // macOS-style input fields
      inputDecorationTheme: _buildMacOSInputTheme(baseTheme.colorScheme),

      // macOS-style dialogs
      dialogTheme: _buildMacOSDialogTheme(baseTheme.colorScheme),

      // macOS-style list tiles
      listTileTheme: _buildMacOSListTileTheme(baseTheme.colorScheme),

      // macOS-style typography
      textTheme: _buildMacOSTextTheme(baseTheme.textTheme, brightness),

      // macOS-style scrollbar
      scrollbarTheme: _buildMacOSScrollbarTheme(baseTheme.colorScheme),
    );
  }

  /// Build macOS-style app bar theme
  static AppBarTheme _buildMacOSAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      toolbarHeight: 52, // macOS standard toolbar height
      centerTitle: false, // macOS apps typically left-align titles
    );
  }

  /// Build macOS-style bottom navigation theme
  static BottomNavigationBarThemeData _buildMacOSBottomNavTheme(
    ColorScheme colorScheme,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Build macOS-style elevated button theme
  static ElevatedButtonThemeData _buildMacOSElevatedButtonTheme(
    ColorScheme colorScheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            8,
          ), // macOS standard corner radius
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Build macOS-style text button theme
  static TextButtonThemeData _buildMacOSTextButtonTheme(
    ColorScheme colorScheme,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Build macOS-style card theme
  static CardThemeData _buildMacOSCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(8),
    );
  }

  /// Build macOS-style input decoration theme
  static InputDecorationTheme _buildMacOSInputTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(
        fontSize: 15,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      hintStyle: TextStyle(
        fontSize: 15,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  /// Build macOS-style dialog theme
  static DialogThemeData _buildMacOSDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: TextStyle(fontSize: 15, color: colorScheme.onSurface),
    );
  }

  /// Build macOS-style list tile theme
  static ListTileThemeData _buildMacOSListTileTheme(ColorScheme colorScheme) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// Build macOS-style text theme
  static TextTheme _buildMacOSTextTheme(
    TextTheme baseTheme,
    Brightness brightness,
  ) {
    final color = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;

    return baseTheme.copyWith(
      // macOS system font sizes and weights
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color,
      ),
    );
  }

  /// Build macOS-style scrollbar theme
  static ScrollbarThemeData _buildMacOSScrollbarTheme(ColorScheme colorScheme) {
    return ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      trackColor: WidgetStateProperty.all(
        colorScheme.surface.withValues(alpha: 0.1),
      ),
      radius: const Radius.circular(4),
      thickness: WidgetStateProperty.all(8),
    );
  }

  /// Check if current platform should use macOS styling
  static bool shouldUseMacOSStyle() {
    try {
      return Platform.isMacOS;
    } catch (e) {
      // Platform.isMacOS is not supported on web
      // Return false for web and other unsupported platforms
      return false;
    }
  }
}
