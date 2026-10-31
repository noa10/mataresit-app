import 'package:flutter/material.dart';

/// The shared ledger palette used by the web and mobile workspaces.
class LedgerTheme {
  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final paper = Color(isDark ? 0xFF0C1110 : 0xFFF1F2EE);
    final surface = Color(isDark ? 0xFF141B18 : 0xFFFFFFFF);
    final surfaceVariant = Color(isDark ? 0xFF18211D : 0xFFF6F7F3);
    final ink = Color(isDark ? 0xFFF1F2EE : 0xFF121715);
    final muted = Color(isDark ? 0xFFA7B2AB : 0xFF59625B);
    final line = Color(isDark ? 0xFF26302B : 0xFFDCE0D8);
    final strongLine = Color(isDark ? 0xFF3A4640 : 0xFFC2C8BE);
    final accent = Color(isDark ? 0xFF3FBF8E : 0xFF0B6B4D);
    final accentForeground = Color(isDark ? 0xFF080C0A : 0xFFFFFFFF);
    final accentSoft = Color(isDark ? 0xFF16352A : 0xFFDFEFE6);
    final amber = Color(isDark ? 0xFFE1A85C : 0xFF7A4200);
    final amberSoft = Color(isDark ? 0xFF33260F : 0xFFF8ECD8);
    final danger = Color(isDark ? 0xFFE08B86 : 0xFF9B2C2C);
    final dangerSoft = Color(isDark ? 0xFF3A1E1C : 0xFFF7E4E2);
    final panel = Color(isDark ? 0xFF080C0A : 0xFF101614);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: accentForeground,
          primaryContainer: accentSoft,
          onPrimaryContainer: accent,
          secondary: accent,
          onSecondary: accentForeground,
          secondaryContainer: accentSoft,
          onSecondaryContainer: accent,
          surface: surface,
          onSurface: ink,
          surfaceContainerLowest: surface,
          surfaceContainerLow: surfaceVariant,
          surfaceContainer: surfaceVariant,
          surfaceContainerHigh: surfaceVariant,
          surfaceContainerHighest: surfaceVariant,
          onSurfaceVariant: muted,
          tertiary: amber,
          onTertiary: amberSoft,
          tertiaryContainer: amberSoft,
          onTertiaryContainer: amber,
          outline: strongLine,
          outlineVariant: line,
          error: danger,
          errorContainer: dangerSoft,
          onErrorContainer: danger,
          inverseSurface: panel,
          onInverseSurface: Color(0xFFF1F2EE),
          surfaceTint: Colors.transparent,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'InstrumentSans',
      // Legacy screens still read Theme.of(context).primaryColor; without this
      // it falls back to the surface colour and disappears in dark mode.
      primaryColor: accent,
      scaffoldBackgroundColor: paper,
      dividerColor: line,
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'InstrumentSans',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentForeground,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: shape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentForeground,
          minimumSize: const Size(0, 44),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          side: BorderSide(color: strongLine),
          minimumSize: const Size(0, 44),
          shape: shape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: strongLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: strongLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        hintStyle: TextStyle(color: muted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentSoft,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: muted,
        indicatorColor: accent,
      ),
    );
  }
}
