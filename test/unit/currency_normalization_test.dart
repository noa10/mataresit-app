import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/utils/currency_utils.dart';

void main() {
  group('Currency Normalization Tests', () {
    test('should normalize RM to MYR', () {
      expect(CurrencyUtils.normalizeCurrencyCode('RM'), equals('MYR'));
    });

    test('should normalize rm to MYR', () {
      expect(CurrencyUtils.normalizeCurrencyCode('rm'), equals('MYR'));
    });

    test('should keep MYR as MYR', () {
      expect(CurrencyUtils.normalizeCurrencyCode('MYR'), equals('MYR'));
    });

    test('should normalize USD symbol to USD', () {
      expect(CurrencyUtils.normalizeCurrencyCode(r'$'), equals('USD'));
    });

    test('should default to MYR for null input', () {
      expect(CurrencyUtils.normalizeCurrencyCode(null), equals('MYR'));
    });

    test('should default to MYR for empty input', () {
      expect(CurrencyUtils.normalizeCurrencyCode(''), equals('MYR'));
    });

    test('should return 3-letter codes as-is even if unknown', () {
      expect(CurrencyUtils.normalizeCurrencyCode('XYZ'), equals('XYZ'));
    });

    test('should default to MYR for invalid format', () {
      expect(CurrencyUtils.normalizeCurrencyCode('INVALID'), equals('MYR'));
    });
  });
}
