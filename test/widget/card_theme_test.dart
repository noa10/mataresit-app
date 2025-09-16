import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/themes/ios_theme.dart';
import 'package:mataresit_app/shared/models/theme_model.dart' as theme_model;

void main() {
  group('Card Theme Tests', () {
    test('Card theme should have border configuration in light mode', () {
      final lightTheme = IOSTheme.buildIOSTheme(
        theme_model.ThemeVariant.defaultTheme,
        Brightness.light,
      );

      // Check that the card theme has the expected configuration
      expect(lightTheme.cardTheme.elevation, equals(0));
      expect(lightTheme.cardTheme.shadowColor, equals(Colors.transparent));
      expect(lightTheme.cardTheme.surfaceTintColor, equals(Colors.transparent));
      expect(
        lightTheme.cardTheme.color,
        equals(lightTheme.colorScheme.surface),
      );

      // Check that the shape has a border
      expect(lightTheme.cardTheme.shape, isA<RoundedRectangleBorder>());

      final shape = lightTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(0.5));
      expect(shape.side.color, equals(lightTheme.colorScheme.outlineVariant));
      expect(shape.borderRadius, equals(BorderRadius.circular(12)));
    });

    test('Card theme should have border configuration in dark mode', () {
      final darkTheme = IOSTheme.buildIOSTheme(
        theme_model.ThemeVariant.defaultTheme,
        Brightness.dark,
      );

      // Check that the card theme has the expected configuration
      expect(darkTheme.cardTheme.elevation, equals(0));
      expect(darkTheme.cardTheme.shadowColor, equals(Colors.transparent));
      expect(darkTheme.cardTheme.surfaceTintColor, equals(Colors.transparent));
      expect(darkTheme.cardTheme.color, equals(darkTheme.colorScheme.surface));

      // Check that the shape has a border
      expect(darkTheme.cardTheme.shape, isA<RoundedRectangleBorder>());

      final shape = darkTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(0.5));
      expect(shape.side.color, equals(darkTheme.colorScheme.outlineVariant));
      expect(shape.borderRadius, equals(BorderRadius.circular(12)));
    });

    test('Card theme should work with all theme variants', () {
      for (final variant in theme_model.ThemeVariant.values) {
        final lightTheme = IOSTheme.buildIOSTheme(variant, Brightness.light);
        final darkTheme = IOSTheme.buildIOSTheme(variant, Brightness.dark);

        // Test light theme configuration
        expect(lightTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
        final lightShape = lightTheme.cardTheme.shape as RoundedRectangleBorder;
        expect(lightShape.side.width, equals(0.5));
        expect(
          lightShape.side.color,
          equals(lightTheme.colorScheme.outlineVariant),
        );

        // Test dark theme configuration
        expect(darkTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
        final darkShape = darkTheme.cardTheme.shape as RoundedRectangleBorder;
        expect(darkShape.side.width, equals(0.5));
        expect(
          darkShape.side.color,
          equals(darkTheme.colorScheme.outlineVariant),
        );
      }
    });

    test('Card theme should have proper iOS-style configuration', () {
      final theme = IOSTheme.buildIOSTheme(
        theme_model.ThemeVariant.defaultTheme,
        Brightness.dark,
      );

      // Check iOS-style properties
      expect(
        theme.cardTheme.elevation,
        equals(0),
      ); // iOS style has no elevation
      expect(theme.cardTheme.shadowColor, equals(Colors.transparent));
      expect(theme.cardTheme.surfaceTintColor, equals(Colors.transparent));
      expect(theme.cardTheme.color, equals(theme.colorScheme.surface));

      // Verify border radius
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.circular(12)));
    });
  });
}
