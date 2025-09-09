import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../models/exchange_rate_model.dart';
import '../../core/services/currency_exchange_service.dart';
import '../../core/services/currency_cache_service.dart';
import '../../core/services/connectivity_service.dart';

/// Exchange rate state
class ExchangeRateState extends Equatable {
  final Map<String, ExchangeRateResponse> rates;
  final Map<String, DateTime> lastUpdated;
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final bool isOnline;

  const ExchangeRateState({
    this.rates = const {},
    this.lastUpdated = const {},
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.isOnline = true,
  });

  ExchangeRateState copyWith({
    Map<String, ExchangeRateResponse>? rates,
    Map<String, DateTime>? lastUpdated,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    bool? isOnline,
  }) {
    return ExchangeRateState(
      rates: rates ?? this.rates,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  /// Check if rates are fresh for a currency (within 24 hours)
  bool areRatesFresh(String baseCurrency) {
    final lastUpdate = lastUpdated[baseCurrency.toUpperCase()];
    if (lastUpdate == null) return false;
    
    final now = DateTime.now();
    final ageInHours = now.difference(lastUpdate).inHours;
    return ageInHours < 24;
  }

  /// Get exchange rate between two currencies
  double? getExchangeRate(String fromCurrency, String toCurrency) {
    final normalizedFrom = fromCurrency.toUpperCase();
    final normalizedTo = toCurrency.toUpperCase();
    
    if (normalizedFrom == normalizedTo) return 1.0;
    
    final ratesData = rates[normalizedFrom];
    return ratesData?.getRateFor(normalizedTo);
  }

  @override
  List<Object?> get props => [
        rates,
        lastUpdated,
        isLoading,
        isUpdating,
        error,
        isOnline,
      ];
}

/// Exchange rate notifier
class ExchangeRateNotifier extends StateNotifier<ExchangeRateState> {
  ExchangeRateNotifier() : super(const ExchangeRateState()) {
    _initializeConnectivityListener();
  }

  /// Initialize connectivity listener
  void _initializeConnectivityListener() {
    ConnectivityService.connectivityStream.listen((isConnected) {
      state = state.copyWith(isOnline: isConnected);
      
      // If we come back online, refresh stale rates
      if (isConnected) {
        _refreshStaleRates();
      }
    });
  }

  /// Load exchange rates for a base currency
  Future<void> loadExchangeRates(String baseCurrency) async {
    final normalizedBase = baseCurrency.toUpperCase();
    
    // Check if we already have fresh rates
    if (state.areRatesFresh(normalizedBase)) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      ExchangeRateResponse? ratesData;
      
      if (state.isOnline) {
        // Try to fetch from API
        ratesData = await CurrencyExchangeService.fetchExchangeRates(normalizedBase);
        
        if (ratesData != null) {
          // Cache the rates
          await CurrencyCacheService.cacheExchangeRates(ratesData);
        }
      }
      
      // If API failed or we're offline, try cache
      ratesData ??= await CurrencyCacheService.getCachedExchangeRates(normalizedBase);
      
      if (ratesData != null) {
        final updatedRates = Map<String, ExchangeRateResponse>.from(state.rates);
        final updatedLastUpdated = Map<String, DateTime>.from(state.lastUpdated);
        
        updatedRates[normalizedBase] = ratesData;
        updatedLastUpdated[normalizedBase] = DateTime.now();
        
        state = state.copyWith(
          rates: updatedRates,
          lastUpdated: updatedLastUpdated,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load exchange rates for $normalizedBase',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading exchange rates: ${e.toString()}',
      );
    }
  }

  /// Refresh exchange rates for a currency
  Future<void> refreshExchangeRates(String baseCurrency) async {
    final normalizedBase = baseCurrency.toUpperCase();
    
    if (!state.isOnline) {
      state = state.copyWith(
        error: 'Cannot refresh rates while offline',
      );
      return;
    }

    try {
      state = state.copyWith(isUpdating: true, error: null);
      
      final ratesData = await CurrencyExchangeService.fetchExchangeRates(normalizedBase);
      
      if (ratesData != null) {
        // Cache the rates
        await CurrencyCacheService.cacheExchangeRates(ratesData);
        
        final updatedRates = Map<String, ExchangeRateResponse>.from(state.rates);
        final updatedLastUpdated = Map<String, DateTime>.from(state.lastUpdated);
        
        updatedRates[normalizedBase] = ratesData;
        updatedLastUpdated[normalizedBase] = DateTime.now();
        
        state = state.copyWith(
          rates: updatedRates,
          lastUpdated: updatedLastUpdated,
          isUpdating: false,
        );
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: 'Failed to refresh exchange rates for $normalizedBase',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Error refreshing exchange rates: ${e.toString()}',
      );
    }
  }

  /// Load multiple currencies at once
  Future<void> loadMultipleCurrencies(List<String> currencies) async {
    final currenciesToLoad = currencies
        .map((c) => c.toUpperCase())
        .where((c) => !state.areRatesFresh(c))
        .toList();
    
    if (currenciesToLoad.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final futures = currenciesToLoad.map((currency) async {
        try {
          ExchangeRateResponse? ratesData;
          
          if (state.isOnline) {
            ratesData = await CurrencyExchangeService.fetchExchangeRates(currency);
            if (ratesData != null) {
              await CurrencyCacheService.cacheExchangeRates(ratesData);
            }
          }
          
          // Fallback to cache
          ratesData ??= await CurrencyCacheService.getCachedExchangeRates(currency);
          
          return MapEntry(currency, ratesData);
        } catch (e) {
          return MapEntry(currency, null);
        }
      });
      
      final results = await Future.wait(futures);
      
      final updatedRates = Map<String, ExchangeRateResponse>.from(state.rates);
      final updatedLastUpdated = Map<String, DateTime>.from(state.lastUpdated);
      final now = DateTime.now();
      
      for (final result in results) {
        if (result.value != null) {
          updatedRates[result.key] = result.value!;
          updatedLastUpdated[result.key] = now;
        }
      }
      
      state = state.copyWith(
        rates: updatedRates,
        lastUpdated: updatedLastUpdated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading multiple currencies: ${e.toString()}',
      );
    }
  }

  /// Get exchange rate between two currencies
  Future<double?> getExchangeRate(String fromCurrency, String toCurrency) async {
    final normalizedFrom = fromCurrency.toUpperCase();
    final normalizedTo = toCurrency.toUpperCase();
    
    if (normalizedFrom == normalizedTo) return 1.0;
    
    // Check if we have the rate in memory
    final rate = state.getExchangeRate(normalizedFrom, normalizedTo);
    if (rate != null) return rate;
    
    // Load rates if not available
    await loadExchangeRates(normalizedFrom);
    
    // Try again after loading
    return state.getExchangeRate(normalizedFrom, normalizedTo);
  }

  /// Refresh stale rates when coming back online
  Future<void> _refreshStaleRates() async {
    final staleRates = state.lastUpdated.entries
        .where((entry) {
          final ageInHours = DateTime.now().difference(entry.value).inHours;
          return ageInHours >= 24;
        })
        .map((entry) => entry.key)
        .toList();
    
    if (staleRates.isNotEmpty) {
      await loadMultipleCurrencies(staleRates);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await CurrencyCacheService.getCacheStats();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await CurrencyCacheService.clearCache();
    state = state.copyWith(
      rates: {},
      lastUpdated: {},
    );
  }
}

/// Exchange rate provider
final exchangeRateProvider = StateNotifierProvider<ExchangeRateNotifier, ExchangeRateState>((ref) {
  return ExchangeRateNotifier();
});

/// Provider for getting exchange rate between two currencies
final exchangeRateForPairProvider = FutureProvider.family<double?, ExchangeRatePair>((ref, pair) async {
  final notifier = ref.read(exchangeRateProvider.notifier);
  return await notifier.getExchangeRate(pair.fromCurrency, pair.toCurrency);
});

/// Exchange rate pair parameters
class ExchangeRatePair extends Equatable {
  final String fromCurrency;
  final String toCurrency;

  const ExchangeRatePair({
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [fromCurrency, toCurrency];
}

/// Provider for checking if rates are fresh
final ratesFreshProvider = Provider.family<bool, String>((ref, baseCurrency) {
  final exchangeRateState = ref.watch(exchangeRateProvider);
  return exchangeRateState.areRatesFresh(baseCurrency);
});

/// Provider for connectivity status
final connectivityProvider = Provider<bool>((ref) {
  final exchangeRateState = ref.watch(exchangeRateProvider);
  return exchangeRateState.isOnline;
});
