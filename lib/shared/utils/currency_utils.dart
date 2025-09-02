import 'dart:math';
import 'package:intl/intl.dart';

/// Currency configuration for consistent formatting and calculations
class CurrencyConfig {
  final String code;
  final String symbol;
  final String name;
  final int decimals;
  final String locale;
  final CurrencyPosition position;

  const CurrencyConfig({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.locale,
    required this.position,
  });
}

enum CurrencyPosition { before, after }

/// Comprehensive currency configurations
class CurrencyConfigs {
  static const Map<String, CurrencyConfig> _configs = {
    'MYR': CurrencyConfig(
      code: 'MYR',
      symbol: 'MYR',  // Changed from 'RM' to 'MYR' to match React version
      name: 'Malaysian Ringgit',
      decimals: 2,
      locale: 'ms_MY',
      position: CurrencyPosition.before,
    ),
    'USD': CurrencyConfig(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      decimals: 2,
      locale: 'en_US',
      position: CurrencyPosition.before,
    ),
    'EUR': CurrencyConfig(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      decimals: 2,
      locale: 'de_DE',
      position: CurrencyPosition.after,
    ),
    'GBP': CurrencyConfig(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      decimals: 2,
      locale: 'en_GB',
      position: CurrencyPosition.before,
    ),
    'SGD': CurrencyConfig(
      code: 'SGD',
      symbol: 'S\$',
      name: 'Singapore Dollar',
      decimals: 2,
      locale: 'en_SG',
      position: CurrencyPosition.before,
    ),
    'JPY': CurrencyConfig(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      decimals: 0,
      locale: 'ja_JP',
      position: CurrencyPosition.before,
    ),
    'CNY': CurrencyConfig(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan',
      decimals: 2,
      locale: 'zh_CN',
      position: CurrencyPosition.before,
    ),
    'THB': CurrencyConfig(
      code: 'THB',
      symbol: '฿',
      name: 'Thai Baht',
      decimals: 2,
      locale: 'th_TH',
      position: CurrencyPosition.before,
    ),
  };

  /// Get currency configuration with fallback
  static CurrencyConfig getConfig(String currencyCode) {
    final normalizedCode = currencyCode.toUpperCase();
    final config = _configs[normalizedCode];
    if (config != null) return config;

    // Fallback for unknown currencies
    return CurrencyConfig(
      code: normalizedCode,
      symbol: normalizedCode,
      name: normalizedCode,
      decimals: 2,
      locale: 'en_US',
      position: CurrencyPosition.before,
    );
  }

  /// Get list of supported currencies
  static List<CurrencyConfig> getSupportedCurrencies() {
    return _configs.values.toList();
  }
}

/// Calculation result for receipt totals
class CalculationResult {
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String formattedSubtotal;
  final String formattedTax;
  final String formattedDiscount;
  final String formattedTotal;

  const CalculationResult({
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.formattedSubtotal,
    required this.formattedTax,
    required this.formattedDiscount,
    required this.formattedTotal,
  });
}

/// Validation result for currency amounts
class ValidationResult {
  final bool isValid;
  final double value;
  final String? error;

  const ValidationResult({
    required this.isValid,
    required this.value,
    this.error,
  });
}

/// Comprehensive currency utilities
class CurrencyUtils {
  /// Safely formats currency with proper error handling
  /// Matches the React web version's formatCurrencySafe function
  ///
  /// [amount] - The amount to format
  /// [currencyCode] - The currency code to use
  /// [locale] - The locale for formatting (default: 'en_US')
  /// [fallbackCurrency] - Fallback currency if the provided one fails
  ///
  /// Returns formatted currency string
  static String formatCurrencySafe(
    double? amount,
    String? currencyCode, {
    String locale = 'en_US',
    String fallbackCurrency = 'MYR',
  }) {
    final safeAmount = amount ?? 0.0;
    final normalizedCurrency = normalizeCurrencyCode(currencyCode);

    try {
      final config = CurrencyConfigs.getConfig(normalizedCurrency);
      final formatter = NumberFormat.currency(
        locale: locale,
        symbol: config.symbol,
        decimalDigits: config.decimals,
      );
      return formatter.format(safeAmount);
    } catch (error) {
      // Try with fallback currency
      try {
        final fallbackConfig = CurrencyConfigs.getConfig(fallbackCurrency);
        final fallbackFormatter = NumberFormat.currency(
          locale: locale,
          symbol: fallbackConfig.symbol,
          decimalDigits: fallbackConfig.decimals,
        );
        return fallbackFormatter.format(safeAmount);
      } catch (fallbackError) {
        // Last resort: return a simple formatted number with currency symbol
        return '$fallbackCurrency ${safeAmount.toStringAsFixed(2)}';
      }
    }
  }

  /// Enhanced currency formatting with multiple options
  static String formatCurrency(
    double amount,
    String currencyCode, {
    bool showSymbol = true,
    bool showCode = false,
    bool compact = false,
    String? locale,
    int? precision,
  }) {
    final config = CurrencyConfigs.getConfig(currencyCode);
    final effectiveLocale = locale ?? config.locale;
    final effectivePrecision = precision ?? config.decimals;

    // Handle invalid amounts
    if (amount.isNaN || amount.isInfinite) {
      amount = 0.0;
    }

    // Format the number
    String formattedAmount;

    if (compact && amount.abs() >= 1000) {
      // Compact formatting for large numbers
      if (amount.abs() >= 1000000) {
        formattedAmount = '${(amount / 1000000).toStringAsFixed(1)}M';
      } else if (amount.abs() >= 1000) {
        formattedAmount = '${(amount / 1000).toStringAsFixed(1)}K';
      } else {
        formattedAmount = amount.toStringAsFixed(effectivePrecision);
      }
    } else {
      // Standard formatting
      try {
        final formatter = NumberFormat.currency(
          locale: effectiveLocale,
          symbol: '',
          decimalDigits: effectivePrecision,
        );
        formattedAmount = formatter.format(amount);
      } catch (error) {
        // Fallback if NumberFormat fails
        formattedAmount = amount.toStringAsFixed(effectivePrecision);
      }
    }

    // Build the final string
    String result = formattedAmount;

    if (showSymbol && config.symbol.isNotEmpty) {
      if (config.position == CurrencyPosition.before) {
        result = '${config.symbol}$result';
      } else {
        result = '$result ${config.symbol}';
      }
    }

    if (showCode) {
      result = '$result ${config.code}';
    }

    return result;
  }

  /// Parse currency string to number
  static double parseCurrency(String currencyString) {
    if (currencyString.isEmpty) return 0.0;

    // Remove all non-numeric characters except decimal point and minus sign
    final cleanString = currencyString
        .replaceAll(RegExp(r'[^\d.-]'), '')
        .replaceAll(RegExp(r'\.(?=.*\.)'), ''); // Remove all but the last decimal point

    final parsed = double.tryParse(cleanString);
    return parsed ?? 0.0;
  }

  /// Calculate totals with proper rounding
  static CalculationResult calculateTotals(
    List<Map<String, dynamic>> lineItems,
    String currencyCode, {
    double? taxRate,
  }) {
    double total = 0.0;

    // Calculate from line items - just sum the amounts
    for (final item in lineItems) {
      final amount = (item['amount'] as double?) ?? 0.0;
      total += amount;
    }

    // Round to currency precision
    final config = CurrencyConfigs.getConfig(currencyCode);
    final precision = pow(10, config.decimals).toDouble();

    final roundedTotal = (total * precision).round() / precision;

    return CalculationResult(
      subtotal: roundedTotal,
      tax: 0.0,
      discount: 0.0,
      total: roundedTotal,
      formattedSubtotal: formatCurrency(roundedTotal, currencyCode),
      formattedTax: formatCurrency(0.0, currencyCode),
      formattedDiscount: formatCurrency(0.0, currencyCode),
      formattedTotal: formatCurrency(roundedTotal, currencyCode),
    );
  }

  /// Validate currency amount
  static ValidationResult validateCurrencyAmount(dynamic amount) {
    if (amount == null || amount == '') {
      return const ValidationResult(
        isValid: false,
        value: 0.0,
        error: 'Amount is required',
      );
    }

    final numericAmount = amount is double
        ? amount
        : amount is int
            ? amount.toDouble()
            : parseCurrency(amount.toString());

    if (numericAmount.isNaN) {
      return const ValidationResult(
        isValid: false,
        value: 0.0,
        error: 'Invalid amount format',
      );
    }

    if (numericAmount < 0) {
      return ValidationResult(
        isValid: false,
        value: numericAmount,
        error: 'Amount cannot be negative',
      );
    }

    if (numericAmount > 999999999) {
      return ValidationResult(
        isValid: false,
        value: numericAmount,
        error: 'Amount is too large',
      );
    }

    return ValidationResult(
      isValid: true,
      value: numericAmount,
    );
  }

  /// Format currency for input fields (without symbols)
  static String formatCurrencyInput(double amount, String currencyCode) {
    final config = CurrencyConfigs.getConfig(currencyCode);
    return amount.toStringAsFixed(config.decimals);
  }

  /// Calculate percentage
  static double calculatePercentage(double part, double total) {
    if (total == 0) return 0.0;
    return (part / total) * 100;
  }

  /// Format percentage
  static String formatPercentage(double percentage, {int decimals = 1}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Convert between currencies (basic conversion, would need real exchange rates in production)
  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency, {
    double? exchangeRate,
  }) {
    if (fromCurrency == toCurrency) return amount;

    if (exchangeRate != null) {
      return amount * exchangeRate;
    }

    // Mock exchange rates for demonstration
    const mockExchangeRates = <String, Map<String, double>>{
      'MYR': {'USD': 0.21, 'EUR': 0.19, 'GBP': 0.16, 'SGD': 0.29},
      'USD': {'MYR': 4.7, 'EUR': 0.92, 'GBP': 0.79, 'SGD': 1.35},
      'EUR': {'MYR': 5.1, 'USD': 1.09, 'GBP': 0.86, 'SGD': 1.47},
      'GBP': {'MYR': 6.2, 'USD': 1.27, 'EUR': 1.16, 'SGD': 1.71},
      'SGD': {'MYR': 3.4, 'USD': 0.74, 'EUR': 0.68, 'GBP': 0.58},
    };

    final rate = mockExchangeRates[fromCurrency]?[toCurrency];
    if (rate != null) {
      return amount * rate;
    }

    // Fallback: return original amount
    return amount;
  }

  /// Normalize currency code to ISO 4217 with common symbol mappings
  static String normalizeCurrencyCode(String? currency) {
    if (currency == null) return 'MYR';
    final trimmed = currency.trim();
    if (trimmed.isEmpty) return 'MYR';
    final upper = trimmed.toUpperCase();

    switch (upper) {
      case 'RM':
        return 'MYR';
      case r'$':
        return 'USD';
      case 'S\$':
        return 'SGD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        // Ambiguous between JPY/CNY; prefer JPY for symbols
        return 'JPY';
      case 'RMB':
        return 'CNY';
      case '฿':
        return 'THB';
      case 'RP':
        return 'IDR';
      case '₱':
        return 'PHP';
      case '₫':
        return 'VND';
      default:
        final regex = RegExp(r'^[A-Z]{3}$');
        if (regex.hasMatch(upper)) return upper;
        return 'MYR';
    }
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currencyCode) {
    final config = CurrencyConfigs.getConfig(currencyCode);
    return config.symbol;
  }

  /// Check if currency code is supported
  static bool isSupportedCurrency(String currencyCode) {
    return CurrencyConfigs._configs.containsKey(currencyCode.toUpperCase());
  }
}
