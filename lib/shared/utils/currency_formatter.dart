import '../models/currency_model.dart';
import '../models/currency_conversion_result.dart';

/// Comprehensive currency formatting utilities
class CurrencyFormatter {
  /// Format currency amount with proper locale and symbol positioning
  static String formatAmount({
    required double amount,
    required CurrencyModel currency,
    bool showSymbol = true,
    bool showCode = false,
    bool compact = false,
    int? overrideDecimals,
  }) {
    final decimals = overrideDecimals ?? currency.decimalPlaces;
    
    String formattedAmount;
    
    if (compact && amount.abs() >= 1000) {
      formattedAmount = _formatCompactAmount(amount, decimals);
    } else {
      formattedAmount = amount.toStringAsFixed(decimals);
      
      // Add thousand separators for readability
      if (amount.abs() >= 1000) {
        formattedAmount = _addThousandSeparators(formattedAmount);
      }
    }
    
    // Build the final formatted string
    final parts = <String>[];
    
    if (showSymbol) {
      if (currency.symbolPosition == 'before') {
        parts.add(currency.symbol);
        parts.add(formattedAmount);
      } else {
        parts.add(formattedAmount);
        parts.add(currency.symbol);
      }
    } else {
      parts.add(formattedAmount);
    }
    
    if (showCode) {
      parts.add(currency.code);
    }
    
    return parts.join(' ').trim();
  }

  /// Format amount with automatic currency detection
  static String formatAmountWithCode({
    required double amount,
    required String currencyCode,
    bool compact = false,
    int? decimals,
  }) {
    final currency = PopularCurrencies.getByCode(currencyCode);
    
    if (currency != null) {
      return formatAmount(
        amount: amount,
        currency: currency,
        compact: compact,
        overrideDecimals: decimals,
      );
    }
    
    // Fallback formatting
    final formattedAmount = amount.toStringAsFixed(decimals ?? 2);
    return '$formattedAmount $currencyCode';
  }

  /// Format conversion result with both original and converted amounts
  static String formatConversionResult({
    required CurrencyConversionResult result,
    CurrencyModel? originalCurrency,
    CurrencyModel? targetCurrency,
    bool showOriginal = true,
    bool showConversionRate = false,
    bool compact = false,
  }) {
    final parts = <String>[];
    
    // Format converted amount
    if (targetCurrency != null) {
      parts.add(formatAmount(
        amount: result.convertedAmount,
        currency: targetCurrency,
        compact: compact,
      ));
    } else {
      parts.add(formatAmountWithCode(
        amount: result.convertedAmount,
        currencyCode: result.targetCurrency,
        compact: compact,
      ));
    }
    
    // Add original amount if requested and conversion was applied
    if (showOriginal && result.conversionApplied) {
      String originalFormatted;
      if (originalCurrency != null) {
        originalFormatted = formatAmount(
          amount: result.originalAmount,
          currency: originalCurrency,
          compact: compact,
        );
      } else {
        originalFormatted = formatAmountWithCode(
          amount: result.originalAmount,
          currencyCode: result.originalCurrency,
          compact: compact,
        );
      }
      parts.add('($originalFormatted)');
    }
    
    // Add conversion rate if requested
    if (showConversionRate && result.conversionApplied) {
      final rateFormatted = result.exchangeRate.toStringAsFixed(4);
      parts.add('@ $rateFormatted');
    }
    
    return parts.join(' ');
  }

  /// Format amount for display in lists (compact format)
  static String formatForList({
    required double amount,
    required String currencyCode,
    bool showCurrencyCode = false,
  }) {
    final currency = PopularCurrencies.getByCode(currencyCode);
    
    if (currency != null) {
      return formatAmount(
        amount: amount,
        currency: currency,
        compact: amount.abs() >= 10000,
        showCode: showCurrencyCode,
      );
    }
    
    // Fallback
    final compactAmount = amount.abs() >= 10000 
        ? _formatCompactAmount(amount, 2)
        : amount.toStringAsFixed(2);
    
    return showCurrencyCode ? '$compactAmount $currencyCode' : compactAmount;
  }

  /// Format amount for input fields (no symbols, proper decimals)
  static String formatForInput({
    required double amount,
    required String currencyCode,
  }) {
    final currency = PopularCurrencies.getByCode(currencyCode);
    final decimals = currency?.decimalPlaces ?? 2;
    
    return amount.toStringAsFixed(decimals);
  }

  /// Parse amount from formatted string
  static double? parseAmount(String formattedAmount) {
    if (formattedAmount.trim().isEmpty) return null;
    
    // Remove common currency symbols and codes
    String cleaned = formattedAmount
        .replaceAll(RegExp(r'[RM$€£¥₱₫฿₩]'), '')
        .replaceAll(RegExp(r'\b[A-Z]{3}\b'), '')
        .replaceAll(',', '')
        .trim();
    
    return double.tryParse(cleaned);
  }

  /// Format compact amounts (1.2K, 1.5M, etc.)
  static String _formatCompactAmount(double amount, int decimals) {
    if (amount.abs() < 1000) {
      return amount.toStringAsFixed(decimals);
    }
    
    final absAmount = amount.abs();
    final isNegative = amount < 0;
    
    String suffix;
    double divisor;
    
    if (absAmount >= 1000000000) {
      suffix = 'B';
      divisor = 1000000000;
    } else if (absAmount >= 1000000) {
      suffix = 'M';
      divisor = 1000000;
    } else {
      suffix = 'K';
      divisor = 1000;
    }
    
    final compactValue = absAmount / divisor;
    final formatted = compactValue.toStringAsFixed(1);
    
    // Remove unnecessary .0
    final cleanFormatted = formatted.endsWith('.0') 
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
    
    return '${isNegative ? '-' : ''}$cleanFormatted$suffix';
  }

  /// Add thousand separators to amount string
  static String _addThousandSeparators(String amount) {
    final parts = amount.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Add commas to integer part
    final reversed = integerPart.split('').reversed.join();
    final withCommas = reversed.replaceAllMapped(
      RegExp(r'(\d{3})(?=\d)'),
      (match) => '${match.group(1)},',
    );
    final formatted = withCommas.split('').reversed.join();
    
    return decimalPart.isNotEmpty ? '$formatted.$decimalPart' : formatted;
  }

  /// Get currency symbol for a currency code
  static String getCurrencySymbol(String currencyCode) {
    final currency = PopularCurrencies.getByCode(currencyCode);
    return currency?.symbol ?? currencyCode;
  }

  /// Get currency name for a currency code
  static String getCurrencyName(String currencyCode) {
    final currency = PopularCurrencies.getByCode(currencyCode);
    return currency?.name ?? currencyCode;
  }

  /// Format percentage change
  static String formatPercentageChange(double percentage) {
    final absPercentage = percentage.abs();
    final sign = percentage >= 0 ? '+' : '-';
    
    if (absPercentage < 0.01) {
      return '0.00%';
    } else if (absPercentage < 1) {
      return '$sign${absPercentage.toStringAsFixed(2)}%';
    } else {
      return '$sign${absPercentage.toStringAsFixed(1)}%';
    }
  }

  /// Format exchange rate for display
  static String formatExchangeRate({
    required double rate,
    required String fromCurrency,
    required String toCurrency,
    int decimals = 4,
  }) {
    final formattedRate = rate.toStringAsFixed(decimals);
    return '1 $fromCurrency = $formattedRate $toCurrency';
  }

  /// Validate currency amount string
  static bool isValidAmount(String amount) {
    if (amount.trim().isEmpty) return false;
    
    final parsed = parseAmount(amount);
    return parsed != null && parsed >= 0;
  }

  /// Format amount range (e.g., "$10 - $50")
  static String formatAmountRange({
    required double minAmount,
    required double maxAmount,
    required String currencyCode,
    bool compact = false,
  }) {
    final minFormatted = formatAmountWithCode(
      amount: minAmount,
      currencyCode: currencyCode,
      compact: compact,
    );
    
    final maxFormatted = formatAmountWithCode(
      amount: maxAmount,
      currencyCode: currencyCode,
      compact: compact,
    );
    
    return '$minFormatted - $maxFormatted';
  }

  /// Get appropriate decimal places for a currency
  static int getDecimalPlaces(String currencyCode) {
    final currency = PopularCurrencies.getByCode(currencyCode);
    return currency?.decimalPlaces ?? 2;
  }

  /// Check if currency uses symbol before or after amount
  static bool isSymbolBefore(String currencyCode) {
    final currency = PopularCurrencies.getByCode(currencyCode);
    return currency?.symbolPosition == 'before';
  }
}
