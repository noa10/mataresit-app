import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'currency_model.g.dart';

/// Represents a currency with its display information
@JsonSerializable()
class CurrencyModel extends Equatable {
  @JsonKey(name: 'code')
  final String code;

  @JsonKey(name: 'name')
  final String name;
  
  @JsonKey(name: 'currency_symbol')
  final String symbol;
  
  @JsonKey(name: 'decimal_places')
  final int decimalPlaces;
  
  @JsonKey(name: 'symbol_position')
  final String symbolPosition; // 'before' or 'after'
  
  @JsonKey(name: 'locale_code')
  final String localeCode;
  
  @JsonKey(name: 'is_popular')
  final bool isPopular;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'display_order')
  final int displayOrder;
  
  @JsonKey(name: 'flag_emoji')
  final String? flagEmoji;

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalPlaces = 2,
    this.symbolPosition = 'before',
    this.localeCode = 'en_US',
    this.isPopular = false,
    this.isActive = true,
    this.displayOrder = 999,
    this.flagEmoji,
  });

  /// Create from JSON
  factory CurrencyModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CurrencyModelToJson(this);

  /// Create a copy with updated fields
  CurrencyModel copyWith({
    String? code,
    String? name,
    String? symbol,
    int? decimalPlaces,
    String? symbolPosition,
    String? localeCode,
    bool? isPopular,
    bool? isActive,
    int? displayOrder,
    String? flagEmoji,
  }) {
    return CurrencyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      symbolPosition: symbolPosition ?? this.symbolPosition,
      localeCode: localeCode ?? this.localeCode,
      isPopular: isPopular ?? this.isPopular,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      flagEmoji: flagEmoji ?? this.flagEmoji,
    );
  }

  /// Create a fallback currency model for unknown currency codes
  factory CurrencyModel.fallback(String currencyCode) {
    return CurrencyModel(
      code: currencyCode.toUpperCase(),
      name: currencyCode.toUpperCase(),
      symbol: currencyCode.toUpperCase(),
      decimalPlaces: 2,
      symbolPosition: 'before',
      localeCode: 'en_US',
      isPopular: false,
      isActive: true,
      displayOrder: 999,
    );
  }

  /// Format an amount using this currency's configuration
  String formatAmount(double amount) {
    final formattedAmount = amount.toStringAsFixed(decimalPlaces);
    
    if (symbolPosition == 'after') {
      return '$formattedAmount $symbol';
    } else {
      return '$symbol$formattedAmount';
    }
  }

  /// Get display name with flag emoji if available
  String get displayName {
    if (flagEmoji != null && flagEmoji!.isNotEmpty) {
      return '$flagEmoji $name';
    }
    return name;
  }

  /// Get short display format (code with flag)
  String get shortDisplay {
    if (flagEmoji != null && flagEmoji!.isNotEmpty) {
      return '$flagEmoji $code';
    }
    return code;
  }

  @override
  List<Object?> get props => [
        code,
        name,
        symbol,
        decimalPlaces,
        symbolPosition,
        localeCode,
        isPopular,
        isActive,
        displayOrder,
        flagEmoji,
      ];

  @override
  String toString() => 'CurrencyModel(code: $code, name: $name, symbol: $symbol)';
}

/// Predefined popular currencies for quick access
class PopularCurrencies {
  static const CurrencyModel myr = CurrencyModel(
    code: 'MYR',
    name: 'Malaysian Ringgit',
    symbol: 'RM',
    decimalPlaces: 2,
    symbolPosition: 'before',
    localeCode: 'ms_MY',
    isPopular: true,
    displayOrder: 1,
    flagEmoji: '🇲🇾',
  );

  static const CurrencyModel usd = CurrencyModel(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
    decimalPlaces: 2,
    symbolPosition: 'before',
    localeCode: 'en_US',
    isPopular: true,
    displayOrder: 2,
    flagEmoji: '🇺🇸',
  );

  static const CurrencyModel sgd = CurrencyModel(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: 'S\$',
    decimalPlaces: 2,
    symbolPosition: 'before',
    localeCode: 'en_SG',
    isPopular: true,
    displayOrder: 3,
    flagEmoji: '🇸🇬',
  );

  static const CurrencyModel eur = CurrencyModel(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    decimalPlaces: 2,
    symbolPosition: 'after',
    localeCode: 'de_DE',
    isPopular: true,
    displayOrder: 4,
    flagEmoji: '🇪🇺',
  );

  static const CurrencyModel gbp = CurrencyModel(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
    decimalPlaces: 2,
    symbolPosition: 'before',
    localeCode: 'en_GB',
    isPopular: true,
    displayOrder: 5,
    flagEmoji: '🇬🇧',
  );

  static const CurrencyModel jpy = CurrencyModel(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    decimalPlaces: 0,
    symbolPosition: 'before',
    localeCode: 'ja_JP',
    isPopular: true,
    displayOrder: 6,
    flagEmoji: '🇯🇵',
  );

  /// Get all popular currencies
  static List<CurrencyModel> get all => [myr, usd, sgd, eur, gbp, jpy];

  /// Get currency by code
  static CurrencyModel? getByCode(String code) {
    try {
      return all.firstWhere((currency) => currency.code == code.toUpperCase());
    } catch (e) {
      return null;
    }
  }
}
