import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/currency_model.dart';
import '../../shared/models/currency_preference_model.dart';
import 'app_logger.dart';

/// Service for managing user currency preferences
class CurrencyPreferenceService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's preferred currency
  static Future<String> getUserPreferredCurrency(String userId) async {
    try {
      AppLogger.info('Getting preferred currency for user: $userId');

      final response = await _supabase
          .from('profiles')
          .select('preferred_currency')
          .eq('id', userId)
          .single();

      final preferredCurrency = response['preferred_currency'] as String?;
      final result = preferredCurrency ?? 'MYR';

      AppLogger.info('User preferred currency: $result');
      return result;
    } catch (e) {
      AppLogger.error('Error getting user preferred currency: $e');
      return 'MYR'; // Default fallback
    }
  }

  /// Update user's preferred currency
  static Future<bool> updateUserPreferredCurrency(
    String userId,
    String currency,
  ) async {
    try {
      AppLogger.info(
        'Updating preferred currency for user $userId to $currency',
      );

      // Validate currency code
      if (!_isValidCurrencyCode(currency)) {
        AppLogger.warning('Invalid currency code: $currency');
        return false;
      }

      await _supabase
          .from('profiles')
          .update({'preferred_currency': currency.toUpperCase()})
          .eq('id', userId);

      AppLogger.info('Successfully updated preferred currency to $currency');
      return true;
    } catch (e) {
      AppLogger.error('Error updating preferred currency: $e');
      return false;
    }
  }

  /// Get all supported currencies from database
  static Future<List<CurrencyModel>> getSupportedCurrencies() async {
    try {
      AppLogger.info('Fetching supported currencies from database');

      final response = await _supabase
          .from('supported_currencies')
          .select()
          .eq('is_active', true)
          .order('display_order');

      final currencies = (response as List)
          .map((json) => CurrencyModel.fromJson(json))
          .toList();

      AppLogger.info('Fetched ${currencies.length} supported currencies');
      return currencies;
    } catch (e) {
      AppLogger.error('Error fetching supported currencies: $e');
      // Return popular currencies as fallback
      return PopularCurrencies.all;
    }
  }

  /// Get popular currencies
  static Future<List<CurrencyModel>> getPopularCurrencies() async {
    try {
      AppLogger.info('Fetching popular currencies from database');

      final response = await _supabase
          .from('supported_currencies')
          .select()
          .eq('is_popular', true)
          .eq('is_active', true)
          .order('display_order');

      final currencies = (response as List)
          .map((json) => CurrencyModel.fromJson(json))
          .toList();

      AppLogger.info('Fetched ${currencies.length} popular currencies');
      return currencies.isNotEmpty ? currencies : PopularCurrencies.all;
    } catch (e) {
      AppLogger.error('Error fetching popular currencies: $e');
      return PopularCurrencies.all;
    }
  }

  /// Get currency by code
  static Future<CurrencyModel?> getCurrencyByCode(String code) async {
    try {
      final normalizedCode = code.toUpperCase();
      AppLogger.info('Fetching currency details for: $normalizedCode');

      final response = await _supabase
          .from('supported_currencies')
          .select()
          .eq('code', normalizedCode)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        final currency = CurrencyModel.fromJson(response);
        AppLogger.info('Found currency: ${currency.name}');
        return currency;
      } else {
        AppLogger.warning('Currency not found in database: $normalizedCode');
        // Try to get from popular currencies as fallback
        return PopularCurrencies.getByCode(normalizedCode);
      }
    } catch (e) {
      AppLogger.error('Error fetching currency by code: $e');
      return PopularCurrencies.getByCode(code);
    }
  }

  /// Search currencies by name or code
  static Future<List<CurrencyModel>> searchCurrencies(String query) async {
    if (query.trim().isEmpty) {
      return await getSupportedCurrencies();
    }

    try {
      final normalizedQuery = query.trim().toLowerCase();
      AppLogger.info('Searching currencies with query: $normalizedQuery');

      final response = await _supabase
          .from('supported_currencies')
          .select()
          .eq('is_active', true)
          .or(
            'currency_code.ilike.%$normalizedQuery%,currency_name.ilike.%$normalizedQuery%',
          )
          .order('display_order');

      final currencies = (response as List)
          .map((json) => CurrencyModel.fromJson(json))
          .toList();

      AppLogger.info('Found ${currencies.length} currencies matching query');
      return currencies;
    } catch (e) {
      AppLogger.error('Error searching currencies: $e');

      // Fallback to local search in popular currencies
      final popularCurrencies = PopularCurrencies.all;
      final normalizedQuery = query.trim().toLowerCase();

      return popularCurrencies.where((currency) {
        return currency.code.toLowerCase().contains(normalizedQuery) ||
            currency.name.toLowerCase().contains(normalizedQuery);
      }).toList();
    }
  }

  /// Get user's complete currency preferences
  static Future<CurrencyPreferenceModel> getUserCurrencyPreferences(
    String userId,
  ) async {
    try {
      AppLogger.info('Getting currency preferences for user: $userId');

      final preferredCurrency = await getUserPreferredCurrency(userId);

      // For now, return default preferences with the user's preferred currency
      // In the future, this could be expanded to include more preference fields
      return CurrencyPreferenceModel.defaultFor(
        userId,
      ).copyWith(preferredCurrency: preferredCurrency);
    } catch (e) {
      AppLogger.error('Error getting user currency preferences: $e');
      return CurrencyPreferenceModel.defaultFor(userId);
    }
  }

  /// Update user's currency preferences
  static Future<bool> updateUserCurrencyPreferences(
    String userId,
    CurrencyPreferenceModel preferences,
  ) async {
    try {
      AppLogger.info('Updating currency preferences for user: $userId');

      // For now, only update the preferred currency in the profiles table
      // In the future, this could be expanded to include a separate preferences table
      final success = await updateUserPreferredCurrency(
        userId,
        preferences.preferredCurrency,
      );

      if (success) {
        AppLogger.info('Successfully updated currency preferences');
      }

      return success;
    } catch (e) {
      AppLogger.error('Error updating currency preferences: $e');
      return false;
    }
  }

  /// Check if a currency code is valid (3-letter ISO code)
  static bool _isValidCurrencyCode(String code) {
    if (code.length != 3) return false;
    return RegExp(r'^[A-Z]{3}$').hasMatch(code.toUpperCase());
  }

  /// Get currency formatting information
  static Future<Map<String, dynamic>> getCurrencyFormatting(
    String currencyCode,
  ) async {
    try {
      final currency = await getCurrencyByCode(currencyCode);
      if (currency != null) {
        return {
          'symbol': currency.symbol,
          'decimal_places': currency.decimalPlaces,
          'symbol_position': currency.symbolPosition,
          'locale_code': currency.localeCode,
        };
      }
    } catch (e) {
      AppLogger.error('Error getting currency formatting: $e');
    }

    // Default formatting
    return {
      'symbol': currencyCode,
      'decimal_places': 2,
      'symbol_position': 'before',
      'locale_code': 'en_US',
    };
  }

  /// Validate if currency is supported
  static Future<bool> isCurrencySupported(String currencyCode) async {
    try {
      final currency = await getCurrencyByCode(currencyCode);
      return currency != null;
    } catch (e) {
      AppLogger.error('Error checking currency support: $e');
      return false;
    }
  }

  /// Get default currency for the app (MYR for Malaysian context)
  static String getDefaultCurrency() => 'MYR';

  /// Get currency display name with fallback
  static Future<String> getCurrencyDisplayName(String currencyCode) async {
    try {
      final currency = await getCurrencyByCode(currencyCode);
      return currency?.displayName ?? currencyCode;
    } catch (e) {
      AppLogger.error('Error getting currency display name: $e');
      return currencyCode;
    }
  }
}
