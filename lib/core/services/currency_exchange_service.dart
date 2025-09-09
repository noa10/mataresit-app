import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/models/exchange_rate_model.dart';
import '../../shared/models/currency_conversion_result.dart';
import 'app_logger.dart';

/// Simple class to hold currency amount data
class CurrencyAmount {
  final double amount;
  final String currency;

  const CurrencyAmount({required this.amount, required this.currency});
}

/// Service for fetching and managing currency exchange rates
class CurrencyExchangeService {
  // Primary API endpoint (jsdelivr CDN)
  static const String _primaryApiBase =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies';

  // Fallback API endpoint (Cloudflare Pages)
  static const String _fallbackApiBase =
      'https://latest.currency-api.pages.dev/v1/currencies';

  // HTTP client with timeout
  static final http.Client _httpClient = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 10);

  /// Fetch exchange rates for a base currency from the API
  static Future<ExchangeRateResponse?> fetchExchangeRates(
    String baseCurrency,
  ) async {
    final normalizedBase = baseCurrency.toLowerCase();

    // Try primary API first
    try {
      AppLogger.info(
        'Fetching exchange rates for $baseCurrency from primary API',
      );
      final response = await _fetchFromEndpoint(
        _primaryApiBase,
        normalizedBase,
      );
      if (response != null) {
        AppLogger.info('Successfully fetched rates from primary API');
        return response;
      }
    } catch (e) {
      AppLogger.warning('Primary API failed: $e');
    }

    // Try fallback API
    try {
      AppLogger.info('Trying fallback API for $baseCurrency');
      final response = await _fetchFromEndpoint(
        _fallbackApiBase,
        normalizedBase,
      );
      if (response != null) {
        AppLogger.info('Successfully fetched rates from fallback API');
        return response;
      }
    } catch (e) {
      AppLogger.error('Fallback API also failed: $e');
    }

    AppLogger.error('All API endpoints failed for $baseCurrency');
    return null;
  }

  /// Fetch from a specific endpoint
  static Future<ExchangeRateResponse?> _fetchFromEndpoint(
    String baseUrl,
    String baseCurrency,
  ) async {
    final url = '$baseUrl/$baseCurrency.min.json';

    try {
      final response = await _httpClient
          .get(Uri.parse(url))
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ExchangeRateResponse.fromJson(jsonData);
      } else {
        AppLogger.warning(
          'API returned status ${response.statusCode} for $url',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error('Error fetching from $url: $e');
      rethrow;
    }
  }

  /// Get exchange rate between two currencies
  static Future<double?> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return 1.0;
    }

    try {
      final rates = await fetchExchangeRates(fromCurrency);
      if (rates != null) {
        return rates.getRateFor(toCurrency.toUpperCase());
      }
    } catch (e) {
      AppLogger.error(
        'Error getting exchange rate from $fromCurrency to $toCurrency: $e',
      );
    }

    return null;
  }

  /// Convert currency amount with detailed result
  static Future<CurrencyConversionResult> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    bool forceConversion = false,
  }) async {
    final normalizedFrom = fromCurrency.toUpperCase();
    final normalizedTo = toCurrency.toUpperCase();

    // No conversion needed if same currency
    if (normalizedFrom == normalizedTo && !forceConversion) {
      return CurrencyConversionResult.noConversion(
        amount: amount,
        currency: normalizedFrom,
      );
    }

    try {
      final exchangeRate = await getExchangeRate(normalizedFrom, normalizedTo);

      if (exchangeRate != null) {
        final convertedAmount = amount * exchangeRate;

        return CurrencyConversionResult(
          originalAmount: amount,
          originalCurrency: normalizedFrom,
          convertedAmount: convertedAmount,
          targetCurrency: normalizedTo,
          exchangeRate: exchangeRate,
          conversionApplied: true,
          confidence: 'high',
          reasoning: 'Converted using live exchange rate',
          rateDate: DateTime.now(),
          rateSource: 'fawazahmed0',
        );
      } else {
        return CurrencyConversionResult.failed(
          amount: amount,
          originalCurrency: normalizedFrom,
          targetCurrency: normalizedTo,
          reasoning: 'Exchange rate not available',
        );
      }
    } catch (e) {
      AppLogger.error('Currency conversion failed: $e');
      return CurrencyConversionResult.failed(
        amount: amount,
        originalCurrency: normalizedFrom,
        targetCurrency: normalizedTo,
        reasoning: 'Conversion failed due to network error',
      );
    }
  }

  /// Batch convert multiple amounts
  static Future<List<CurrencyConversionResult>> convertMultiple({
    required List<CurrencyAmount> amounts,
    required String targetCurrency,
  }) async {
    final results = <CurrencyConversionResult>[];

    // Group by source currency to minimize API calls
    final groupedAmounts = <String, List<CurrencyAmount>>{};
    for (final amount in amounts) {
      final currency = amount.currency.toUpperCase();
      groupedAmounts.putIfAbsent(currency, () => []).add(amount);
    }

    // Convert each group
    for (final entry in groupedAmounts.entries) {
      final sourceCurrency = entry.key;
      final currencyAmounts = entry.value;

      // Get exchange rate once per currency
      final exchangeRate = await getExchangeRate(
        sourceCurrency,
        targetCurrency,
      );

      for (final currencyAmount in currencyAmounts) {
        if (exchangeRate != null) {
          final convertedAmount = currencyAmount.amount * exchangeRate;

          results.add(
            CurrencyConversionResult(
              originalAmount: currencyAmount.amount,
              originalCurrency: sourceCurrency,
              convertedAmount: convertedAmount,
              targetCurrency: targetCurrency.toUpperCase(),
              exchangeRate: exchangeRate,
              conversionApplied: true,
              confidence: 'high',
              reasoning: 'Batch converted using live exchange rate',
              rateDate: DateTime.now(),
              rateSource: 'fawazahmed0',
            ),
          );
        } else {
          results.add(
            CurrencyConversionResult.failed(
              amount: currencyAmount.amount,
              originalCurrency: sourceCurrency,
              targetCurrency: targetCurrency,
              reasoning: 'Exchange rate not available for $sourceCurrency',
            ),
          );
        }
      }
    }

    return results;
  }

  /// Check if the service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_primaryApiBase/usd.min.json'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.warning('Service availability check failed: $e');
      return false;
    }
  }

  /// Get list of supported currencies from the API
  static Future<List<String>?> getSupportedCurrencies() async {
    try {
      final url = '$_primaryApiBase.min.json';
      final response = await _httpClient
          .get(Uri.parse(url))
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData.keys.map((key) => key.toUpperCase()).toList();
      }
    } catch (e) {
      AppLogger.error('Error fetching supported currencies: $e');
    }

    return null;
  }

  /// Dispose resources
  static void dispose() {
    _httpClient.close();
  }
}
