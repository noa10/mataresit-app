import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/models/currency_model.dart';
import 'package:mataresit_app/shared/models/exchange_rate_model.dart';
import 'package:mataresit_app/shared/models/currency_conversion_result.dart';
import 'package:mataresit_app/shared/utils/currency_formatter.dart';

void main() {
  group('Currency Models Tests', () {
    test('CurrencyModel should format amounts correctly', () {
      final usd = CurrencyModel(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        decimalPlaces: 2,
        symbolPosition: 'before',
        localeCode: 'en_US',
        isPopular: true,
        isActive: true,
        displayOrder: 1,
      );

      expect(usd.formatAmount(1234.56), equals('\$1234.56'));
      expect(usd.formatAmount(0.99), equals('\$0.99'));
    });

    test('ExchangeRateModel should handle rate freshness', () {
      final now = DateTime.now();
      final rate = ExchangeRateModel(
        id: 'test-1',
        baseCurrency: 'USD',
        targetCurrency: 'EUR',
        exchangeRate: 0.85,
        rateDate: now,
        createdAt: now,
        updatedAt: now,
        source: 'test',
      );

      expect(rate.isFresh(), isTrue);

      final oldRate = ExchangeRateModel(
        id: 'test-2',
        baseCurrency: 'USD',
        targetCurrency: 'EUR',
        exchangeRate: 0.85,
        rateDate: now.subtract(const Duration(hours: 25)),
        createdAt: now.subtract(const Duration(hours: 25)),
        updatedAt: now.subtract(const Duration(hours: 25)),
        source: 'test',
      );

      expect(oldRate.isFresh(), isFalse);
    });

    test('CurrencyConversionResult should handle different scenarios', () {
      // No conversion needed
      final noConversion = CurrencyConversionResult.noConversion(
        amount: 100.0,
        currency: 'USD',
      );

      expect(noConversion.conversionApplied, isFalse);
      expect(noConversion.convertedAmount, equals(100.0));
      expect(noConversion.originalCurrency, equals('USD'));
      expect(noConversion.targetCurrency, equals('USD'));

      // Successful conversion
      final conversion = CurrencyConversionResult(
        originalAmount: 100.0,
        originalCurrency: 'USD',
        convertedAmount: 85.0,
        targetCurrency: 'EUR',
        exchangeRate: 0.85,
        conversionApplied: true,
        confidence: 'high',
        reasoning: 'Live exchange rate',
        rateDate: DateTime.now(),
        rateSource: 'api',
      );

      expect(conversion.conversionApplied, isTrue);
      expect(conversion.convertedAmount, equals(85.0));
      expect(conversion.exchangeRate, equals(0.85));

      // Failed conversion
      final failed = CurrencyConversionResult.failed(
        amount: 100.0,
        originalCurrency: 'USD',
        targetCurrency: 'EUR',
        reasoning: 'API unavailable',
      );

      expect(failed.conversionApplied, isFalse);
      expect(failed.confidence, equals('low'));
    });
  });

  group('Currency Formatter Tests', () {
    test('should format amounts with different currencies', () {
      final usd = CurrencyModel(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        decimalPlaces: 2,
        symbolPosition: 'before',
        localeCode: 'en_US',
        isPopular: true,
        isActive: true,
        displayOrder: 1,
      );

      final eur = CurrencyModel(
        code: 'EUR',
        name: 'Euro',
        symbol: '€',
        decimalPlaces: 2,
        symbolPosition: 'after',
        localeCode: 'en_EU',
        isPopular: true,
        isActive: true,
        displayOrder: 2,
      );

      expect(
        CurrencyFormatter.formatAmount(amount: 1234.56, currency: usd),
        equals('\$ 1,234.56'),
      );

      expect(
        CurrencyFormatter.formatAmount(amount: 1234.56, currency: eur),
        equals('1,234.56 €'),
      );
    });

    test('should format compact amounts', () {
      final usd = CurrencyModel(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        decimalPlaces: 2,
        symbolPosition: 'before',
        localeCode: 'en_US',
        isPopular: true,
        isActive: true,
        displayOrder: 1,
      );

      expect(
        CurrencyFormatter.formatAmount(
          amount: 1500.0,
          currency: usd,
          compact: true,
        ),
        equals('\$ 1.5K'),
      );

      expect(
        CurrencyFormatter.formatAmount(
          amount: 1500000.0,
          currency: usd,
          compact: true,
        ),
        equals('\$ 1.5M'),
      );
    });

    test('should parse amounts correctly', () {
      expect(CurrencyFormatter.parseAmount('1234.56'), equals(1234.56));
      expect(CurrencyFormatter.parseAmount('\$1,234.56'), equals(1234.56));
      expect(CurrencyFormatter.parseAmount('1,234.56 USD'), equals(1234.56));
      expect(CurrencyFormatter.parseAmount('invalid'), isNull);
      expect(CurrencyFormatter.parseAmount(''), isNull);
    });

    test('should validate amounts', () {
      expect(CurrencyFormatter.isValidAmount('1234.56'), isTrue);
      expect(CurrencyFormatter.isValidAmount('\$1,234.56'), isTrue);
      expect(CurrencyFormatter.isValidAmount('0'), isTrue);
      expect(CurrencyFormatter.isValidAmount('-100'), isFalse);
      expect(CurrencyFormatter.isValidAmount('invalid'), isFalse);
      expect(CurrencyFormatter.isValidAmount(''), isFalse);
    });

    test('should format exchange rates', () {
      expect(
        CurrencyFormatter.formatExchangeRate(
          rate: 0.85,
          fromCurrency: 'USD',
          toCurrency: 'EUR',
        ),
        equals('1 USD = 0.8500 EUR'),
      );
    });

    test('should format percentage changes', () {
      expect(CurrencyFormatter.formatPercentageChange(5.25), equals('+5.3%'));
      expect(CurrencyFormatter.formatPercentageChange(-3.75), equals('-3.8%'));
      expect(CurrencyFormatter.formatPercentageChange(0.005), equals('0.00%'));
    });
  });

  group('Popular Currencies Tests', () {
    test('should have predefined popular currencies', () {
      final currencies = PopularCurrencies.all;

      expect(currencies.isNotEmpty, isTrue);
      expect(currencies.any((c) => c.code == 'USD'), isTrue);
      expect(currencies.any((c) => c.code == 'EUR'), isTrue);
      expect(currencies.any((c) => c.code == 'MYR'), isTrue);
    });

    test('should get currency by code', () {
      final usd = PopularCurrencies.getByCode('USD');
      expect(usd, isNotNull);
      expect(usd!.code, equals('USD'));
      expect(usd.name, equals('US Dollar'));

      final invalid = PopularCurrencies.getByCode('INVALID');
      expect(invalid, isNull);
    });

    test('should have currencies in order', () {
      final currencies = PopularCurrencies.all;
      expect(currencies.length, greaterThan(0));

      // Check that currencies are sorted by display order
      for (int i = 0; i < currencies.length - 1; i++) {
        expect(
          currencies[i].displayOrder,
          lessThanOrEqualTo(currencies[i + 1].displayOrder),
        );
      }
    });
  });

  group('Exchange Rate Response Tests', () {
    test('should parse API response correctly', () {
      final apiResponse = {
        'date': '2024-01-01',
        'usd': {'eur': 0.85, 'gbp': 0.75, 'jpy': 110.0},
      };

      final response = ExchangeRateResponse.fromJson(apiResponse);

      expect(response.baseCurrency, equals('USD'));
      expect(response.date, isNotNull);
      expect(response.rates['EUR'], equals(0.85));
      expect(response.rates['GBP'], equals(0.75));
      expect(response.rates['JPY'], equals(110.0));
    });

    test('should get rate for specific currency', () {
      final response = ExchangeRateResponse(
        baseCurrency: 'USD',
        date: DateTime.now(),
        rates: {'EUR': 0.85, 'GBP': 0.75, 'JPY': 110.0},
      );

      expect(response.getRateFor('EUR'), equals(0.85));
      expect(response.getRateFor('GBP'), equals(0.75));
      expect(response.getRateFor('INVALID'), isNull);
    });
  });
}
