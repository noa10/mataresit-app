import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/search_result_model.dart';
import '../providers/search_provider.dart';
import '../widgets/search_initial_state.dart';
import '../widgets/search_result_card.dart';
import '../widgets/search_result_detail_sheet.dart';
import '../widgets/search_source_filter.dart';

/// Unified search across receipts, categories and the business directory.
///
/// Mirrors the web app's unified search: every query is sent to the
/// `unified-search` edge function, which embeds the query and ranks results by
/// similarity. There is no debounce — the query is submitted explicitly.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Example queries, submitted verbatim so the server parses the same text the
  /// user tapped.
  List<String> get _exampleQueries => [
    'search.examples.recentReceipts'.tr(),
    'search.examples.grocery'.tr(),
    'search.examples.restaurant'.tr(),
    'search.examples.businesses'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _submitQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _queryController.text = trimmed;
    FocusScope.of(context).unfocus();
    ref.read(searchProvider.notifier).search(trimmed);
  }

  void _resetSearch() {
    _queryController.clear();
    ref.read(searchProvider.notifier).clear();
  }

  void _openResult(SearchResultItem result) {
    if (result.isReceipt && result.sourceId.isNotEmpty) {
      context.push('/receipts/${result.sourceId}');
      return;
    }

    showSearchResultDetailSheet(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(searchState, notifier),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildQueryField(searchState),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SearchSourceFilter(
                    selectedSources: searchState.selectedSources,
                    onToggle: notifier.toggleSource,
                  ),
                ),
                if (searchState.isDegraded)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _PartialResultsBanner(),
                  ),
                if (_showResultCount(searchState))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _buildResultCount(searchState),
                  ),
              ],
            ),
          ),
          _buildBodySliver(searchState),
        ],
      ),
    );
  }

  Widget _buildPageHeader(SearchState searchState, SearchNotifier notifier) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (GoRouter.maybeOf(context)?.canPop() ?? false)
            IconButton(
              onPressed: () => GoRouter.of(context).pop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(Icons.arrow_back),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'search.eyebrow'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'search.title'.tr(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: 'InstrumentSerif',
                    fontSize: 32,
                    height: 1.05,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'search.initial.message'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (searchState.hasSearched)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'common.buttons.refresh'.tr(),
              onPressed: searchState.isLoading ? null : notifier.retry,
            ),
        ],
      ),
    );
  }

  bool _showResultCount(SearchState state) =>
      state.hasSearched &&
      state.error == null &&
      !state.isLoading &&
      state.results.isNotEmpty;

  Widget _buildQueryField(SearchState searchState) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _queryController,
            builder: (context, value, _) {
              return TextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitQuery,
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: 'search.field.hint'.tr(),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                          tooltip: 'search.field.clear'.tr(),
                          onPressed: _resetSearch,
                        ),
                  border: _queryBorder(colors.outlineVariant),
                  enabledBorder: _queryBorder(colors.outlineVariant),
                  focusedBorder: _queryBorder(colors.primary),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        LoadingButton(
          onPressed: () => _submitQuery(_queryController.text),
          text: 'search.button'.tr(),
          isLoading: searchState.isLoading,
        ),
      ],
    );
  }

  OutlineInputBorder _queryBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );

  Widget _buildResultCount(SearchState searchState) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Text(
      'search.total'.tr(
        namedArgs: {
          'count': '${searchState.totalResults ?? searchState.results.length}',
        },
      ),
      style: theme.textTheme.labelSmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontFamily: 'IBMPlexMono',
        fontSize: 11,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildBody(SearchState searchState) {
    if (searchState.isLoading && searchState.results.isEmpty) {
      return LoadingWidget(message: 'search.loading'.tr());
    }

    if (searchState.error != null && searchState.results.isEmpty) {
      return _SearchErrorPanel(
        error: searchState.isAuthError
            ? 'search.error.sessionExpired'.tr()
            : searchState.error!,
        onRetry: () => ref.read(searchProvider.notifier).retry(),
      );
    }

    if (!searchState.hasSearched) {
      return SearchInitialState(
        examples: _exampleQueries,
        onExampleSelected: _submitQuery,
      );
    }

    if (searchState.results.isEmpty) {
      return _SearchEmptyPanel(
        query: searchState.query,
        onNewSearch: _resetSearch,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBodySliver(SearchState searchState) {
    if (searchState.results.isNotEmpty) {
      return _buildResultsSliver(searchState);
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: _buildBody(searchState),
    );
  }

  Widget _buildResultsSliver(SearchState searchState) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      sliver: SliverList.builder(
        itemCount: searchState.results.length + (searchState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= searchState.results.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final result = searchState.results[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SearchResultCard(
              result: result,
              onTap: () => _openResult(result),
            ),
          );
        },
      ),
    );
  }
}

/// Shown when the server answered with `success: true` but had to fall back to
/// a degraded search path, so the results are honestly labelled.
class _PartialResultsBanner extends StatelessWidget {
  const _PartialResultsBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'search.degraded.title'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'search.degraded.message'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ledger-styled error state for a failed search.
class _SearchErrorPanel extends StatelessWidget {
  const _SearchErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'search.error.title'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: Text('common.buttons.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ledger-styled empty state for a query with no hits.
class _SearchEmptyPanel extends StatelessWidget {
  const _SearchEmptyPanel({required this.query, required this.onNewSearch});

  final String query;
  final VoidCallback onNewSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.search_off, size: 28, color: colors.onSurfaceVariant),
              const SizedBox(height: 10),
              Text(
                'search.empty.title'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'search.empty.message'.tr(namedArgs: {'query': query}),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onNewSearch,
                child: Text('search.empty.action'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
