// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExchangeRateModel _$ExchangeRateModelFromJson(Map<String, dynamic> json) =>
    ExchangeRateModel(
      id: json['id'] as String,
      baseCurrency: json['base_currency'] as String,
      targetCurrency: json['target_currency'] as String,
      exchangeRate: (json['exchange_rate'] as num).toDouble(),
      rateDate: DateTime.parse(json['rate_date'] as String),
      source: json['source'] as String? ?? 'fawazahmed0',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ExchangeRateModelToJson(ExchangeRateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'base_currency': instance.baseCurrency,
      'target_currency': instance.targetCurrency,
      'exchange_rate': instance.exchangeRate,
      'rate_date': instance.rateDate.toIso8601String(),
      'source': instance.source,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
