// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_conversion_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyConversionResult _$CurrencyConversionResultFromJson(
  Map<String, dynamic> json,
) => CurrencyConversionResult(
  originalAmount: (json['original_amount'] as num).toDouble(),
  originalCurrency: json['original_currency'] as String,
  convertedAmount: (json['converted_amount'] as num).toDouble(),
  targetCurrency: json['target_currency'] as String,
  exchangeRate: (json['exchange_rate'] as num).toDouble(),
  conversionApplied: json['conversion_applied'] as bool,
  confidence: json['confidence'] as String? ?? 'high',
  reasoning: json['reasoning'] as String? ?? '',
  rateDate: json['rate_date'] == null
      ? null
      : DateTime.parse(json['rate_date'] as String),
  rateSource: json['rate_source'] as String?,
);

Map<String, dynamic> _$CurrencyConversionResultToJson(
  CurrencyConversionResult instance,
) => <String, dynamic>{
  'original_amount': instance.originalAmount,
  'original_currency': instance.originalCurrency,
  'converted_amount': instance.convertedAmount,
  'target_currency': instance.targetCurrency,
  'exchange_rate': instance.exchangeRate,
  'conversion_applied': instance.conversionApplied,
  'confidence': instance.confidence,
  'reasoning': instance.reasoning,
  'rate_date': instance.rateDate?.toIso8601String(),
  'rate_source': instance.rateSource,
};

CurrencyAmount _$CurrencyAmountFromJson(Map<String, dynamic> json) =>
    CurrencyAmount(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      originalInput: json['original_input'] as String?,
    );

Map<String, dynamic> _$CurrencyAmountToJson(CurrencyAmount instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'currency': instance.currency,
      'original_input': instance.originalInput,
    };
