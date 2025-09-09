import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'currency_preference_model.g.dart';

/// Represents user currency preferences
@JsonSerializable()
class CurrencyPreferenceModel extends Equatable {
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'preferred_currency')
  final String preferredCurrency;

  @JsonKey(name: 'auto_convert')
  final bool autoConvert;

  @JsonKey(name: 'show_original_amounts')
  final bool showOriginalAmounts;

  @JsonKey(name: 'rate_update_frequency')
  final int rateUpdateFrequencyHours;

  @JsonKey(name: 'offline_mode_enabled')
  final bool offlineModeEnabled;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CurrencyPreferenceModel({
    required this.userId,
    this.preferredCurrency = 'MYR',
    this.autoConvert = true,
    this.showOriginalAmounts = true,
    this.rateUpdateFrequencyHours = 24,
    this.offlineModeEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory CurrencyPreferenceModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyPreferenceModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CurrencyPreferenceModelToJson(this);

  /// Create default preferences for a user
  factory CurrencyPreferenceModel.defaultFor(String userId) {
    final now = DateTime.now();
    return CurrencyPreferenceModel(
      userId: userId,
      preferredCurrency: 'MYR',
      autoConvert: true,
      showOriginalAmounts: true,
      rateUpdateFrequencyHours: 24,
      offlineModeEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a copy with updated fields
  CurrencyPreferenceModel copyWith({
    String? userId,
    String? preferredCurrency,
    bool? autoConvert,
    bool? showOriginalAmounts,
    int? rateUpdateFrequencyHours,
    bool? offlineModeEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CurrencyPreferenceModel(
      userId: userId ?? this.userId,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      autoConvert: autoConvert ?? this.autoConvert,
      showOriginalAmounts: showOriginalAmounts ?? this.showOriginalAmounts,
      rateUpdateFrequencyHours:
          rateUpdateFrequencyHours ?? this.rateUpdateFrequencyHours,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if rates need updating based on frequency setting
  bool shouldUpdateRates(DateTime lastUpdate) {
    final now = DateTime.now();
    final hoursSinceUpdate = now.difference(lastUpdate).inHours;
    return hoursSinceUpdate >= rateUpdateFrequencyHours;
  }

  /// Get update frequency as Duration
  Duration get updateFrequency => Duration(hours: rateUpdateFrequencyHours);

  @override
  List<Object?> get props => [
    userId,
    preferredCurrency,
    autoConvert,
    showOriginalAmounts,
    rateUpdateFrequencyHours,
    offlineModeEnabled,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'CurrencyPreferenceModel(userId: $userId, preferredCurrency: $preferredCurrency)';
}

/// Enum for currency preference update frequency options
enum CurrencyUpdateFrequency {
  @JsonValue(1)
  hourly(1, 'Every hour'),

  @JsonValue(6)
  sixHourly(6, 'Every 6 hours'),

  @JsonValue(12)
  twelveHourly(12, 'Every 12 hours'),

  @JsonValue(24)
  daily(24, 'Daily'),

  @JsonValue(168)
  weekly(168, 'Weekly');

  const CurrencyUpdateFrequency(this.hours, this.displayName);

  final int hours;
  final String displayName;

  /// Get frequency by hours
  static CurrencyUpdateFrequency fromHours(int hours) {
    return values.firstWhere(
      (freq) => freq.hours == hours,
      orElse: () => daily,
    );
  }
}

/// Currency display preferences
@JsonSerializable()
class CurrencyDisplayPreferences extends Equatable {
  @JsonKey(name: 'show_currency_symbols')
  final bool showCurrencySymbols;

  @JsonKey(name: 'show_currency_codes')
  final bool showCurrencyCodes;

  @JsonKey(name: 'show_conversion_rates')
  final bool showConversionRates;

  @JsonKey(name: 'compact_amounts')
  final bool compactAmounts; // Show 1.2K instead of 1,200

  @JsonKey(name: 'decimal_places')
  final int? decimalPlaces; // Override default decimal places

  const CurrencyDisplayPreferences({
    this.showCurrencySymbols = true,
    this.showCurrencyCodes = false,
    this.showConversionRates = true,
    this.compactAmounts = false,
    this.decimalPlaces,
  });

  /// Create from JSON
  factory CurrencyDisplayPreferences.fromJson(Map<String, dynamic> json) =>
      _$CurrencyDisplayPreferencesFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CurrencyDisplayPreferencesToJson(this);

  /// Create default display preferences
  factory CurrencyDisplayPreferences.defaults() {
    return const CurrencyDisplayPreferences();
  }

  /// Create a copy with updated fields
  CurrencyDisplayPreferences copyWith({
    bool? showCurrencySymbols,
    bool? showCurrencyCodes,
    bool? showConversionRates,
    bool? compactAmounts,
    int? decimalPlaces,
  }) {
    return CurrencyDisplayPreferences(
      showCurrencySymbols: showCurrencySymbols ?? this.showCurrencySymbols,
      showCurrencyCodes: showCurrencyCodes ?? this.showCurrencyCodes,
      showConversionRates: showConversionRates ?? this.showConversionRates,
      compactAmounts: compactAmounts ?? this.compactAmounts,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    );
  }

  @override
  List<Object?> get props => [
    showCurrencySymbols,
    showCurrencyCodes,
    showConversionRates,
    compactAmounts,
    decimalPlaces,
  ];

  @override
  String toString() =>
      'CurrencyDisplayPreferences(symbols: $showCurrencySymbols, codes: $showCurrencyCodes)';
}
