import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/currency_model.dart';
import '../../../shared/providers/currency_provider.dart';
import '../../../shared/providers/exchange_rate_provider.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/loading_widget.dart';


class CurrencySettingsScreen extends ConsumerStatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  ConsumerState<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends ConsumerState<CurrencySettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAllCurrencies = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final exchangeRateState = ref.watch(exchangeRateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: exchangeRateState.isOnline ? _refreshRates : null,
            tooltip: 'Refresh exchange rates',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: currencyState.isUpdating,
        child: Column(
          children: [
            // Connection status
            if (!exchangeRateState.isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Offline - Using cached exchange rates',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Current selection
            _buildCurrentSelection(currencyState),
            
            // Search bar
            _buildSearchBar(),
            
            // Currency list
            Expanded(
              child: _buildCurrencyList(currencyState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSelection(CurrencyState currencyState) {
    final preferredCurrency = currencyState.userPreferredCurrency ?? 'MYR';
    final currencyAsync = ref.watch(currencyByCodeProvider(preferredCurrency));
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Currency',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          currencyAsync.when(
            data: (currency) => _buildCurrencyTile(
              currency: currency ?? CurrencyModel.fallback(preferredCurrency),
              isSelected: true,
              showExample: true,
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => _buildCurrencyTile(
              currency: CurrencyModel.fallback(preferredCurrency),
              isSelected: true,
              showExample: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search currencies...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Popular'),
                selected: !_showAllCurrencies,
                onSelected: (selected) {
                  setState(() => _showAllCurrencies = !selected);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('All Currencies'),
                selected: _showAllCurrencies,
                onSelected: (selected) {
                  setState(() => _showAllCurrencies = selected);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyList(CurrencyState currencyState) {
    if (currencyState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading currencies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              currencyState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCurrencies(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    final currencies = _showAllCurrencies 
        ? currencyState.supportedCurrencies
        : currencyState.popularCurrencies;

    if (currencies.isEmpty && currencyState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currencies.isEmpty) {
      return const Center(
        child: Text('No currencies available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        final isSelected = currency.code == currencyState.userPreferredCurrency;
        
        return _buildCurrencyTile(
          currency: currency,
          isSelected: isSelected,
          onTap: () => _selectCurrency(currency),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(currencySearchProvider(_searchQuery));
    
    return searchAsync.when(
      data: (currencies) {
        if (currencies.isEmpty) {
          return const Center(
            child: Text('No currencies found'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: currencies.length,
          itemBuilder: (context, index) {
            final currency = currencies[index];
            final isSelected = currency.code == ref.read(currencyProvider).userPreferredCurrency;
            
            return _buildCurrencyTile(
              currency: currency,
              isSelected: isSelected,
              onTap: () => _selectCurrency(currency),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Search failed: $error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(currencySearchProvider(_searchQuery)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile({
    required CurrencyModel currency,
    required bool isSelected,
    VoidCallback? onTap,
    bool showExample = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            currency.symbol,
            style: TextStyle(
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          currency.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currency.code),
            if (showExample) ...[
              const SizedBox(height: 4),
              Text(
                'Example: ${CurrencyFormatter.formatAmount(
                  amount: 1234.56,
                  currency: currency,
                )}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: isSelected 
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _loadCurrencies() {
    final notifier = ref.read(currencyProvider.notifier);
    notifier.loadSupportedCurrencies();
    notifier.loadPopularCurrencies();
  }

  Future<void> _selectCurrency(CurrencyModel currency) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to change currency settings')),
      );
      return;
    }

    final notifier = ref.read(currencyProvider.notifier);
    final success = await notifier.updatePreferredCurrency(
      authState.user!.id,
      currency.code,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Currency changed to ${currency.name}'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh exchange rates for the new currency
        final exchangeNotifier = ref.read(exchangeRateProvider.notifier);
        exchangeNotifier.loadExchangeRates(currency.code);

        // Go back to settings
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update currency preference'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshRates() async {
    final currencyState = ref.read(currencyProvider);
    final preferredCurrency = currencyState.userPreferredCurrency ?? 'MYR';
    
    final exchangeNotifier = ref.read(exchangeRateProvider.notifier);
    await exchangeNotifier.refreshExchangeRates(preferredCurrency);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exchange rates refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
