// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyModel _$CurrencyModelFromJson(Map<String, dynamic> json) =>
    CurrencyModel(
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['currency_symbol'] as String,
      decimalPlaces: (json['decimal_places'] as num?)?.toInt() ?? 2,
      symbolPosition: json['symbol_position'] as String? ?? 'before',
      localeCode: json['locale_code'] as String? ?? 'en_US',
      isPopular: json['is_popular'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 999,
      flagEmoji: json['flag_emoji'] as String?,
    );

Map<String, dynamic> _$CurrencyModelToJson(CurrencyModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'currency_symbol': instance.symbol,
      'decimal_places': instance.decimalPlaces,
      'symbol_position': instance.symbolPosition,
      'locale_code': instance.localeCode,
      'is_popular': instance.isPopular,
      'is_active': instance.isActive,
      'display_order': instance.displayOrder,
      'flag_emoji': instance.flagEmoji,
    };
