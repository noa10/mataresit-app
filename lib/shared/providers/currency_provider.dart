import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../models/currency_model.dart';
import '../models/currency_conversion_result.dart';
import '../models/currency_preference_model.dart';
import '../../core/services/currency_preference_service.dart';
import '../../core/services/currency_exchange_service.dart';
import '../../core/services/currency_cache_service.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Currency state
class CurrencyState extends Equatable {
  final List<CurrencyModel> supportedCurrencies;
  final List<CurrencyModel> popularCurrencies;
  final String? userPreferredCurrency;
  final CurrencyPreferenceModel? userPreferences;
  final bool isLoading;
  final bool isUpdating;
  final String? error;

  const CurrencyState({
    this.supportedCurrencies = const [],
    this.popularCurrencies = const [],
    this.userPreferredCurrency,
    this.userPreferences,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
  });

  CurrencyState copyWith({
    List<CurrencyModel>? supportedCurrencies,
    List<CurrencyModel>? popularCurrencies,
    String? userPreferredCurrency,
    CurrencyPreferenceModel? userPreferences,
    bool? isLoading,
    bool? isUpdating,
    String? error,
  }) {
    return CurrencyState(
      supportedCurrencies: supportedCurrencies ?? this.supportedCurrencies,
      popularCurrencies: popularCurrencies ?? this.popularCurrencies,
      userPreferredCurrency: userPreferredCurrency ?? this.userPreferredCurrency,
      userPreferences: userPreferences ?? this.userPreferences,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        supportedCurrencies,
        popularCurrencies,
        userPreferredCurrency,
        userPreferences,
        isLoading,
        isUpdating,
        error,
      ];
}

/// Currency notifier
class CurrencyNotifier extends StateNotifier<CurrencyState> {
  CurrencyNotifier() : super(const CurrencyState());

  /// Load supported currencies
  Future<void> loadSupportedCurrencies() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final currencies = await CurrencyPreferenceService.getSupportedCurrencies();
      
      state = state.copyWith(
        supportedCurrencies: currencies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load supported currencies: ${e.toString()}',
      );
    }
  }

  /// Load popular currencies
  Future<void> loadPopularCurrencies() async {
    try {
      final currencies = await CurrencyPreferenceService.getPopularCurrencies();
      
      state = state.copyWith(popularCurrencies: currencies);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load popular currencies: ${e.toString()}',
      );
    }
  }

  /// Load user preferences
  Future<void> loadUserPreferences(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final preferences = await CurrencyPreferenceService.getUserCurrencyPreferences(userId);
      
      state = state.copyWith(
        userPreferences: preferences,
        userPreferredCurrency: preferences.preferredCurrency,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user preferences: ${e.toString()}',
      );
    }
  }

  /// Update user preferred currency
  Future<bool> updatePreferredCurrency(String userId, String currency) async {
    try {
      state = state.copyWith(isUpdating: true, error: null);
      
      final success = await CurrencyPreferenceService.updateUserPreferredCurrency(userId, currency);
      
      if (success) {
        state = state.copyWith(
          userPreferredCurrency: currency,
          userPreferences: state.userPreferences?.copyWith(
            preferredCurrency: currency,
            updatedAt: DateTime.now(),
          ),
          isUpdating: false,
        );
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: 'Failed to update preferred currency',
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Error updating preferred currency: ${e.toString()}',
      );
      return false;
    }
  }

  /// Search currencies
  Future<List<CurrencyModel>> searchCurrencies(String query) async {
    try {
      return await CurrencyPreferenceService.searchCurrencies(query);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to search currencies: ${e.toString()}',
      );
      return [];
    }
  }

  /// Get currency by code
  Future<CurrencyModel?> getCurrencyByCode(String code) async {
    try {
      return await CurrencyPreferenceService.getCurrencyByCode(code);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to get currency: ${e.toString()}',
      );
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Currency provider
final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  final notifier = CurrencyNotifier();
  
  // Listen to auth state changes
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated && next.user != null) {
      // Load user preferences when authenticated
      notifier.loadUserPreferences(next.user!.id);
    }
  });
  
  // Load initial data
  notifier.loadPopularCurrencies();
  notifier.loadSupportedCurrencies();
  
  return notifier;
});

/// Provider for user's preferred currency
final userPreferredCurrencyProvider = Provider<String>((ref) {
  final currencyState = ref.watch(currencyProvider);
  return currencyState.userPreferredCurrency ?? 'MYR';
});

/// Provider for popular currencies
final popularCurrenciesProvider = Provider<List<CurrencyModel>>((ref) {
  final currencyState = ref.watch(currencyProvider);
  return currencyState.popularCurrencies;
});

/// Provider for supported currencies
final supportedCurrenciesProvider = Provider<List<CurrencyModel>>((ref) {
  final currencyState = ref.watch(currencyProvider);
  return currencyState.supportedCurrencies;
});

/// Provider for currency search
final currencySearchProvider = FutureProvider.family<List<CurrencyModel>, String>((ref, query) async {
  final notifier = ref.read(currencyProvider.notifier);
  return await notifier.searchCurrencies(query);
});

/// Provider for getting currency by code
final currencyByCodeProvider = FutureProvider.family<CurrencyModel?, String>((ref, code) async {
  final notifier = ref.read(currencyProvider.notifier);
  return await notifier.getCurrencyByCode(code);
});

/// Provider for currency conversion
final currencyConversionProvider = FutureProvider.family<CurrencyConversionResult, CurrencyConversionParams>((ref, params) async {
  // Try cached conversion first
  final cachedResult = await CurrencyCacheService.convertWithCachedRates(
    amount: params.amount,
    fromCurrency: params.fromCurrency,
    toCurrency: params.toCurrency,
  );
  
  if (cachedResult != null) {
    return cachedResult;
  }
  
  // Fall back to live API
  return await CurrencyExchangeService.convertCurrency(
    amount: params.amount,
    fromCurrency: params.fromCurrency,
    toCurrency: params.toCurrency,
  );
});

/// Parameters for currency conversion
class CurrencyConversionParams extends Equatable {
  final double amount;
  final String fromCurrency;
  final String toCurrency;

  const CurrencyConversionParams({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  List<Object?> get props => [amount, fromCurrency, toCurrency];
}

/// Provider for formatting currency amounts
final currencyFormatterProvider = Provider.family<String, CurrencyFormatterParams>((ref, params) {
  // Get currency model if available
  final currencyAsync = ref.watch(currencyByCodeProvider(params.currencyCode));
  
  return currencyAsync.when(
    data: (currency) {
      if (currency != null) {
        return currency.formatAmount(params.amount);
      }
      return '${params.amount.toStringAsFixed(2)} ${params.currencyCode}';
    },
    loading: () => '${params.amount.toStringAsFixed(2)} ${params.currencyCode}',
    error: (_, __) => '${params.amount.toStringAsFixed(2)} ${params.currencyCode}',
  );
});

/// Parameters for currency formatting
class CurrencyFormatterParams extends Equatable {
  final double amount;
  final String currencyCode;

  const CurrencyFormatterParams({
    required this.amount,
    required this.currencyCode,
  });

  @override
  List<Object?> get props => [amount, currencyCode];
}
