import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'currency_model.dart';

part 'currency_conversion_result.g.dart';

/// Represents the result of a currency conversion
@JsonSerializable()
class CurrencyConversionResult extends Equatable {
  @JsonKey(name: 'original_amount')
  final double originalAmount;
  
  @JsonKey(name: 'original_currency')
  final String originalCurrency;
  
  @JsonKey(name: 'converted_amount')
  final double convertedAmount;
  
  @JsonKey(name: 'target_currency')
  final String targetCurrency;
  
  @JsonKey(name: 'exchange_rate')
  final double exchangeRate;
  
  @JsonKey(name: 'conversion_applied')
  final bool conversionApplied;
  
  final String confidence; // 'high', 'medium', 'low'
  final String reasoning;
  
  @JsonKey(name: 'rate_date')
  final DateTime? rateDate;
  
  @JsonKey(name: 'rate_source')
  final String? rateSource;

  const CurrencyConversionResult({
    required this.originalAmount,
    required this.originalCurrency,
    required this.convertedAmount,
    required this.targetCurrency,
    required this.exchangeRate,
    required this.conversionApplied,
    this.confidence = 'high',
    this.reasoning = '',
    this.rateDate,
    this.rateSource,
  });

  /// Create from JSON
  factory CurrencyConversionResult.fromJson(Map<String, dynamic> json) =>
      _$CurrencyConversionResultFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CurrencyConversionResultToJson(this);

  /// Create a no-conversion result (same currency)
  factory CurrencyConversionResult.noConversion({
    required double amount,
    required String currency,
    String reasoning = 'No conversion needed - same currency',
  }) {
    return CurrencyConversionResult(
      originalAmount: amount,
      originalCurrency: currency,
      convertedAmount: amount,
      targetCurrency: currency,
      exchangeRate: 1.0,
      conversionApplied: false,
      confidence: 'high',
      reasoning: reasoning,
    );
  }

  /// Create a failed conversion result
  factory CurrencyConversionResult.failed({
    required double amount,
    required String originalCurrency,
    required String targetCurrency,
    String reasoning = 'Conversion failed - rate not available',
  }) {
    return CurrencyConversionResult(
      originalAmount: amount,
      originalCurrency: originalCurrency,
      convertedAmount: amount,
      targetCurrency: originalCurrency, // Keep original currency
      exchangeRate: 1.0,
      conversionApplied: false,
      confidence: 'low',
      reasoning: reasoning,
    );
  }

  /// Format the original amount with currency
  String formatOriginalAmount([CurrencyModel? currencyModel]) {
    if (currencyModel != null) {
      return currencyModel.formatAmount(originalAmount);
    }
    return '$originalAmount $originalCurrency';
  }

  /// Format the converted amount with currency
  String formatConvertedAmount([CurrencyModel? currencyModel]) {
    if (currencyModel != null) {
      return currencyModel.formatAmount(convertedAmount);
    }
    return '$convertedAmount $targetCurrency';
  }

  /// Get conversion summary text
  String get conversionSummary {
    if (!conversionApplied) {
      return reasoning;
    }
    
    return 'Converted from $originalCurrency to $targetCurrency at rate $exchangeRate';
  }

  /// Check if conversion is reliable
  bool get isReliable => confidence == 'high' && conversionApplied;

  /// Check if rate is fresh (within 24 hours)
  bool get isFresh {
    if (rateDate == null) return false;
    final now = DateTime.now();
    final ageInHours = now.difference(rateDate!).inHours;
    return ageInHours <= 24;
  }

  /// Get the percentage difference between original and converted amounts
  double get conversionPercentage {
    if (originalAmount == 0) return 0.0;
    return ((convertedAmount - originalAmount) / originalAmount) * 100;
  }

  /// Create a copy with updated fields
  CurrencyConversionResult copyWith({
    double? originalAmount,
    String? originalCurrency,
    double? convertedAmount,
    String? targetCurrency,
    double? exchangeRate,
    bool? conversionApplied,
    String? confidence,
    String? reasoning,
    DateTime? rateDate,
    String? rateSource,
  }) {
    return CurrencyConversionResult(
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      conversionApplied: conversionApplied ?? this.conversionApplied,
      confidence: confidence ?? this.confidence,
      reasoning: reasoning ?? this.reasoning,
      rateDate: rateDate ?? this.rateDate,
      rateSource: rateSource ?? this.rateSource,
    );
  }

  @override
  List<Object?> get props => [
        originalAmount,
        originalCurrency,
        convertedAmount,
        targetCurrency,
        exchangeRate,
        conversionApplied,
        confidence,
        reasoning,
        rateDate,
        rateSource,
      ];

  @override
  String toString() => 
      'CurrencyConversionResult($originalAmount $originalCurrency -> $convertedAmount $targetCurrency)';
}

/// Represents a currency amount with its currency information
@JsonSerializable()
class CurrencyAmount extends Equatable {
  final double amount;
  final String currency;
  @JsonKey(name: 'original_input')
  final String? originalInput;

  const CurrencyAmount({
    required this.amount,
    required this.currency,
    this.originalInput,
  });

  /// Create from JSON
  factory CurrencyAmount.fromJson(Map<String, dynamic> json) =>
      _$CurrencyAmountFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CurrencyAmountToJson(this);

  /// Format the amount with currency
  String format([CurrencyModel? currencyModel]) {
    if (currencyModel != null) {
      return currencyModel.formatAmount(amount);
    }
    return '$amount $currency';
  }

  /// Create a copy with updated fields
  CurrencyAmount copyWith({
    double? amount,
    String? currency,
    String? originalInput,
  }) {
    return CurrencyAmount(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      originalInput: originalInput ?? this.originalInput,
    );
  }

  @override
  List<Object?> get props => [amount, currency, originalInput];

  @override
  String toString() => 'CurrencyAmount($amount $currency)';
}
