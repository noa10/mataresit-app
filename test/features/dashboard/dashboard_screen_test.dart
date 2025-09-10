import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/utils/currency_utils.dart';

void main() {
  group('Dashboard Currency Formatting Tests', () {
    test('should format currency with MYR correctly', () {
      final result = CurrencyUtils.formatCurrencySafe(150.75, 'MYR');
      expect(result, contains('MYR'));
      expect(result, contains('150.75'));
    });

    test('should format currency with USD correctly', () {
      final result = CurrencyUtils.formatCurrencySafe(25.50, 'USD');
      expect(result, contains('\$'));
      expect(result, contains('25.50'));
    });

    test('should handle null currency gracefully', () {
      final result = CurrencyUtils.formatCurrencySafe(50.00, null);
      // Should fall back to default currency (MYR)
      expect(result, contains('MYR'));
      expect(result, contains('50.00'));
    });

    test('should handle null amount gracefully', () {
      final result = CurrencyUtils.formatCurrencySafe(null, 'USD');
      expect(result, contains('\$'));
      expect(result, contains('0.00'));
    });

    test('should format different currencies correctly', () {
      final usdResult = CurrencyUtils.formatCurrencySafe(100.00, 'USD');
      final myrResult = CurrencyUtils.formatCurrencySafe(100.00, 'MYR');
      final eurResult = CurrencyUtils.formatCurrencySafe(100.00, 'EUR');

      expect(usdResult, contains('\$'));
      expect(myrResult, contains('MYR'));
      expect(eurResult, contains('€'));
    });
  });
}
