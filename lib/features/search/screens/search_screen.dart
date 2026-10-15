import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_bar_with_actions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_widget.dart';
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
      appBar: AppBarWithActions(
        title: 'search.title'.tr(),
        actions: [
          if (searchState.hasSearched)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'common.buttons.refresh'.tr(),
              onPressed: searchState.isLoading ? null : () => notifier.retry(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQueryField(searchState),
                const SizedBox(height: AppConstants.defaultPadding),
                SearchSourceFilter(
                  selectedSources: searchState.selectedSources,
                  onToggle: notifier.toggleSource,
                ),
              ],
            ),
          ),
          if (searchState.isDegraded)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppConstants.defaultPadding,
                0,
                AppConstants.defaultPadding,
                AppConstants.smallPadding,
              ),
              child: _PartialResultsBanner(),
            ),
          if (_showResultCount(searchState))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.defaultPadding,
                0,
                AppConstants.defaultPadding,
                AppConstants.smallPadding,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'search.total'.tr(
                    namedArgs: {
                      'count':
                          '${searchState.totalResults ?? searchState.results.length}',
                    },
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Expanded(child: _buildBody(searchState)),
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
                decoration: InputDecoration(
                  hintText: 'search.field.hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'search.field.clear'.tr(),
                          onPressed: _resetSearch,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        LoadingButton(
          onPressed: () => _submitQuery(_queryController.text),
          text: 'search.button'.tr(),
          isLoading: searchState.isLoading,
          icon: const Icon(Icons.search),
        ),
      ],
    );
  }

  Widget _buildBody(SearchState searchState) {
    if (searchState.isLoading && searchState.results.isEmpty) {
      return LoadingWidget(message: 'search.loading'.tr());
    }

    if (searchState.error != null && searchState.results.isEmpty) {
      return AppErrorWidget(
        title: 'search.error.title'.tr(),
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
      // Scrollable so the empty state cannot overflow on short viewports.
      return SingleChildScrollView(
        child: EmptyStateWidget(
          icon: Icons.search_off,
          title: 'search.empty.title'.tr(),
          message: 'search.empty.message'.tr(
            namedArgs: {'query': searchState.query},
          ),
          actionLabel: 'search.empty.action'.tr(),
          onAction: _resetSearch,
        ),
      );
    }

    return _buildResultsList(searchState);
  }

  Widget _buildResultsList(SearchState searchState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        0,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
      ),
      itemCount: searchState.results.length + (searchState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= searchState.results.length) {
          return const Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final result = searchState.results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          child: SearchResultCard(
            result: result,
            onTap: () => _openResult(result),
          ),
        );
      },
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
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppConstants.smallPadding),
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
