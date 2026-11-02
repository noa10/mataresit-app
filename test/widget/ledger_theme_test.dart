import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/themes/ledger_theme.dart';

void main() {
  test('ledger themes use the web palette and theme-aware button text', () {
    final light = LedgerTheme.build(Brightness.light);
    final dark = LedgerTheme.build(Brightness.dark);

    expect(light.scaffoldBackgroundColor, const Color(0xFFF1F2EE));
    expect(light.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(light.colorScheme.primary, const Color(0xFF0B6B4D));
    expect(light.colorScheme.onPrimary, const Color(0xFFFFFFFF));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF0C1110));
    expect(dark.colorScheme.surface, const Color(0xFF141B18));
    expect(dark.colorScheme.primary, const Color(0xFF3FBF8E));
    expect(dark.colorScheme.onPrimary, const Color(0xFF080C0A));

    for (final theme in [light, dark]) {
      final card = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(card.borderRadius, BorderRadius.circular(10));
      expect(card.side.color, theme.colorScheme.outlineVariant);
      expect(theme.cardTheme.elevation, 0);
    }
  });
}
