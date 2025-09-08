import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/exchange_rate_model.dart';
import '../../shared/models/currency_conversion_result.dart';
import 'app_logger.dart';

/// Service for caching currency exchange rates locally
class CurrencyCacheService {
  static const String _boxName = 'currency_rates_cache';
  static const String _metadataBoxName = 'currency_cache_metadata';
  static const Duration _defaultCacheExpiry = Duration(hours: 24);
  
  static Box<String>? _cacheBox;
  static Box<String>? _metadataBox;

  /// Initialize the cache service
  static Future<void> initialize() async {
    try {
      AppLogger.info('Initializing currency cache service');

      if (!Hive.isBoxOpen(_boxName)) {
        _cacheBox = await Hive.openBox<String>(_boxName);
      } else {
        _cacheBox = Hive.box<String>(_boxName);
      }

      if (!Hive.isBoxOpen(_metadataBoxName)) {
        _metadataBox = await Hive.openBox<String>(_metadataBoxName);
      } else {
        _metadataBox = Hive.box<String>(_metadataBoxName);
      }

      AppLogger.info('Currency cache service initialized successfully');

      // Clean up expired entries on startup
      await _cleanupExpiredEntries();
    } catch (e) {
      AppLogger.error('Failed to initialize currency cache service: $e');
      rethrow;
    }
  }

  /// Cache exchange rates from API response
  static Future<void> cacheExchangeRates(ExchangeRateResponse response) async {
    if (_cacheBox == null || _metadataBox == null) {
      AppLogger.warning('Cache not initialized, skipping cache operation');
      return;
    }

    try {
      final baseCurrency = response.baseCurrency;
      final cacheKey = _getCacheKey(baseCurrency);
      final metadataKey = _getMetadataKey(baseCurrency);

      // Store the rates
      await _cacheBox!.put(cacheKey, json.encode(response.toJson()));

      // Store metadata
      final metadata = {
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(_defaultCacheExpiry).toIso8601String(),
        'base_currency': baseCurrency,
        'rate_count': response.rates.length,
      };
      await _metadataBox!.put(metadataKey, json.encode(metadata));

      AppLogger.info('Cached exchange rates for $baseCurrency (${response.rates.length} rates)');
    } catch (e) {
      AppLogger.error('Failed to cache exchange rates: $e');
    }
  }

  /// Get cached exchange rates
  static Future<ExchangeRateResponse?> getCachedExchangeRates(String baseCurrency) async {
    if (_cacheBox == null || _metadataBox == null) {
      AppLogger.warning('Cache not initialized');
      return null;
    }

    try {
      final cacheKey = _getCacheKey(baseCurrency);
      final metadataKey = _getMetadataKey(baseCurrency);

      // Check if data exists and is not expired
      final metadataJson = _metadataBox!.get(metadataKey);
      if (metadataJson == null) {
        return null;
      }

      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(metadata['expires_at'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        AppLogger.info('Cached rates for $baseCurrency have expired');
        await _removeCachedRates(baseCurrency);
        return null;
      }

      // Get cached data
      final cachedJson = _cacheBox!.get(cacheKey);
      if (cachedJson == null) {
        return null;
      }

      final cachedData = json.decode(cachedJson) as Map<String, dynamic>;
      final response = ExchangeRateResponse.fromJson(cachedData);

      AppLogger.info('Retrieved cached exchange rates for $baseCurrency');
      return response;
    } catch (e) {
      AppLogger.error('Failed to get cached exchange rates: $e');
      return null;
    }
  }

  /// Get cached exchange rate between two currencies
  static Future<double?> getCachedExchangeRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return 1.0;
    }

    try {
      final rates = await getCachedExchangeRates(fromCurrency);
      if (rates != null) {
        return rates.getRateFor(toCurrency.toUpperCase());
      }
    } catch (e) {
      AppLogger.error('Error getting cached exchange rate: $e');
    }

    return null;
  }

  /// Convert currency using cached rates
  static Future<CurrencyConversionResult?> convertWithCachedRates({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final normalizedFrom = fromCurrency.toUpperCase();
    final normalizedTo = toCurrency.toUpperCase();

    if (normalizedFrom == normalizedTo) {
      return CurrencyConversionResult.noConversion(
        amount: amount,
        currency: normalizedFrom,
      );
    }

    try {
      final exchangeRate = await getCachedExchangeRate(normalizedFrom, normalizedTo);
      
      if (exchangeRate != null) {
        final convertedAmount = amount * exchangeRate;
        
        return CurrencyConversionResult(
          originalAmount: amount,
          originalCurrency: normalizedFrom,
          convertedAmount: convertedAmount,
          targetCurrency: normalizedTo,
          exchangeRate: exchangeRate,
          conversionApplied: true,
          confidence: 'medium', // Lower confidence for cached rates
          reasoning: 'Converted using cached exchange rate',
          rateSource: 'cache',
        );
      }
    } catch (e) {
      AppLogger.error('Cached currency conversion failed: $e');
    }

    return null;
  }

  /// Check if rates are cached for a currency
  static Future<bool> hasCachedRates(String baseCurrency) async {
    if (_metadataBox == null) return false;
    
    final metadataKey = _getMetadataKey(baseCurrency);
    final metadataJson = _metadataBox!.get(metadataKey);
    
    if (metadataJson == null) return false;
    
    try {
      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(metadata['expires_at'] as String);
      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      return false;
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    if (_cacheBox == null || _metadataBox == null) {
      return {'error': 'Cache not initialized'};
    }

    try {
      final totalEntries = _cacheBox!.length;
      final metadataEntries = _metadataBox!.length;
      
      int validEntries = 0;
      int expiredEntries = 0;
      final currencies = <String>[];
      
      for (final key in _metadataBox!.keys) {
        try {
          final metadataJson = _metadataBox!.get(key);
          if (metadataJson != null) {
            final metadata = json.decode(metadataJson) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(metadata['expires_at'] as String);
            final baseCurrency = metadata['base_currency'] as String;
            
            currencies.add(baseCurrency);
            
            if (DateTime.now().isBefore(expiresAt)) {
              validEntries++;
            } else {
              expiredEntries++;
            }
          }
        } catch (e) {
          expiredEntries++;
        }
      }
      
      return {
        'total_entries': totalEntries,
        'metadata_entries': metadataEntries,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
        'cached_currencies': currencies,
        'cache_size_kb': (_cacheBox!.length * 50) / 1024, // Rough estimate
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    if (_cacheBox == null || _metadataBox == null) return;
    
    try {
      await _cacheBox!.clear();
      await _metadataBox!.clear();
      AppLogger.info('Currency cache cleared');
    } catch (e) {
      AppLogger.error('Failed to clear currency cache: $e');
    }
  }

  /// Remove cached rates for a specific currency
  static Future<void> _removeCachedRates(String baseCurrency) async {
    if (_cacheBox == null || _metadataBox == null) return;
    
    try {
      final cacheKey = _getCacheKey(baseCurrency);
      final metadataKey = _getMetadataKey(baseCurrency);
      
      await _cacheBox!.delete(cacheKey);
      await _metadataBox!.delete(metadataKey);

      AppLogger.info('Removed cached rates for $baseCurrency');
    } catch (e) {
      AppLogger.error('Failed to remove cached rates: $e');
    }
  }

  /// Clean up expired entries
  static Future<void> _cleanupExpiredEntries() async {
    if (_metadataBox == null) return;
    
    try {
      final expiredKeys = <String>[];
      final now = DateTime.now();
      
      for (final key in _metadataBox!.keys) {
        try {
          final metadataJson = _metadataBox!.get(key);
          if (metadataJson != null) {
            final metadata = json.decode(metadataJson) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(metadata['expires_at'] as String);
            
            if (now.isAfter(expiresAt)) {
              expiredKeys.add(key);
            }
          }
        } catch (e) {
          expiredKeys.add(key); // Remove corrupted entries
        }
      }
      
      for (final key in expiredKeys) {
        final baseCurrency = key.replaceAll('metadata_', '');
        await _removeCachedRates(baseCurrency);
      }
      
      if (expiredKeys.isNotEmpty) {
        AppLogger.info('Cleaned up ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      AppLogger.error('Failed to cleanup expired entries: $e');
    }
  }

  /// Generate cache key for rates
  static String _getCacheKey(String baseCurrency) => 'rates_${baseCurrency.toLowerCase()}';

  /// Generate metadata key
  static String _getMetadataKey(String baseCurrency) => 'metadata_${baseCurrency.toLowerCase()}';

  /// Dispose resources
  static Future<void> dispose() async {
    try {
      await _cacheBox?.close();
      await _metadataBox?.close();
      _cacheBox = null;
      _metadataBox = null;
      AppLogger.info('Currency cache service disposed');
    } catch (e) {
      AppLogger.error('Error disposing currency cache service: $e');
    }
  }
}
