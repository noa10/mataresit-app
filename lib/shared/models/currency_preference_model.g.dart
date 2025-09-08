// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_preference_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyPreferenceModel _$CurrencyPreferenceModelFromJson(
  Map<String, dynamic> json,
) => CurrencyPreferenceModel(
  userId: json['user_id'] as String,
  preferredCurrency: json['preferred_currency'] as String? ?? 'MYR',
  autoConvert: json['auto_convert'] as bool? ?? true,
  showOriginalAmounts: json['show_original_amounts'] as bool? ?? true,
  rateUpdateFrequencyHours:
      (json['rate_update_frequency'] as num?)?.toInt() ?? 24,
  offlineModeEnabled: json['offline_mode_enabled'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CurrencyPreferenceModelToJson(
  CurrencyPreferenceModel instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'preferred_currency': instance.preferredCurrency,
  'auto_convert': instance.autoConvert,
  'show_original_amounts': instance.showOriginalAmounts,
  'rate_update_frequency': instance.rateUpdateFrequencyHours,
  'offline_mode_enabled': instance.offlineModeEnabled,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

CurrencyDisplayPreferences _$CurrencyDisplayPreferencesFromJson(
  Map<String, dynamic> json,
) => CurrencyDisplayPreferences(
  showCurrencySymbols: json['show_currency_symbols'] as bool? ?? true,
  showCurrencyCodes: json['show_currency_codes'] as bool? ?? false,
  showConversionRates: json['show_conversion_rates'] as bool? ?? true,
  compactAmounts: json['compact_amounts'] as bool? ?? false,
  decimalPlaces: (json['decimal_places'] as num?)?.toInt(),
);

Map<String, dynamic> _$CurrencyDisplayPreferencesToJson(
  CurrencyDisplayPreferences instance,
) => <String, dynamic>{
  'show_currency_symbols': instance.showCurrencySymbols,
  'show_currency_codes': instance.showCurrencyCodes,
  'show_conversion_rates': instance.showConversionRates,
  'compact_amounts': instance.compactAmounts,
  'decimal_places': instance.decimalPlaces,
};
