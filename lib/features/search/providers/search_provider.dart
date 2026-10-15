import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import '../models/search_result_model.dart';
import '../services/search_service.dart';

/// Unified search state
class SearchState extends Equatable {
  /// The query that produced the current results.
  final String query;
  final List<SearchResultItem> results;

  /// Singular wire-level source names sent to `unified-search`.
  final Set<String> selectedSources;
  final bool isLoading;
  final bool isLoadingMore;

  /// False until the first search is submitted, so the UI can show its
  /// start-here prompt instead of an empty-results state.
  final bool hasSearched;
  final bool hasMore;

  /// Offset to request on the next page. Derived locally because the enhanced
  /// path omits `pagination.nextOffset`.
  final int nextOffset;
  final int? totalResults;
  final String? error;
  final bool isAuthError;
  final SearchMetadata? metadata;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.selectedSources = const {
      SearchSources.receipt,
      SearchSources.businessDirectory,
    },
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasSearched = false,
    this.hasMore = false,
    this.nextOffset = 0,
    this.totalResults,
    this.error,
    this.isAuthError = false,
    this.metadata,
  });

  SearchState copyWith({
    String? query,
    List<SearchResultItem>? results,
    Set<String>? selectedSources,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasSearched,
    bool? hasMore,
    int? nextOffset,
    int? totalResults,
    String? error,
    bool? isAuthError,
    SearchMetadata? metadata,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      selectedSources: selectedSources ?? this.selectedSources,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasSearched: hasSearched ?? this.hasSearched,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      totalResults: totalResults ?? this.totalResults,
      error: clearError ? null : (error ?? this.error),
      isAuthError: clearError ? false : (isAuthError ?? this.isAuthError),
      metadata: metadata ?? this.metadata,
    );
  }

  /// Results carry a partial-results hint when the server fell back.
  bool get isDegraded => metadata?.isDegraded ?? false;

  @override
  List<Object?> get props => [
    query,
    results,
    selectedSources,
    isLoading,
    isLoadingMore,
    hasSearched,
    hasMore,
    nextOffset,
    totalResults,
    error,
    isAuthError,
    metadata,
  ];
}

/// Unified search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;
  final Logger _logger = Logger();

  static const int pageSize = 20;

  /// Bumped every time a search replaces the current one. A request in flight
  /// belongs to the generation it started in, and anything older is discarded.
  ///
  /// Comparing the query string is not sufficient: re-running the *same* query
  /// (toggling a source, retrying) leaves it unchanged, so a stale page from
  /// the previous source selection would pass that check and be appended to the
  /// new results.
  int _generation = 0;

  SearchNotifier(this._searchService) : super(const SearchState());

  /// Run a new search, replacing any previous results.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _logger.w('Ignoring empty search query');
      return;
    }
    if (state.isLoading) return;

    _generation++;
    state = SearchState(
      query: trimmed,
      selectedSources: state.selectedSources,
      isLoading: true,
      hasSearched: true,
    );

    await _execute(offset: 0, append: false);
  }

  /// Fetch the next page using the pagination contract.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    await _execute(offset: state.nextOffset, append: true);
  }

  /// Re-run the current query after a failure.
  Future<void> retry() async {
    if (state.query.isEmpty || state.isLoading || state.isLoadingMore) return;

    _generation++;
    await _execute(offset: 0, append: false);
  }

  /// Toggle one of the free-tier sources. Re-runs the search when one has
  /// already been performed so the visible results match the filter.
  void toggleSource(String source) {
    final updated = Set<String>.from(state.selectedSources);
    if (updated.contains(source)) {
      if (updated.length == 1) return; // Never search with zero sources.
      updated.remove(source);
    } else {
      updated.add(source);
    }

    state = state.copyWith(selectedSources: updated);

    if (state.hasSearched && state.query.isNotEmpty) {
      unawaited(search(state.query));
    }
  }

  /// Return to the pre-search state, keeping the selected sources.
  void clear() {
    state = SearchState(selectedSources: state.selectedSources);
  }

  Future<void> _execute({required int offset, required bool append}) async {
    final query = state.query;
    final generation = _generation;

    state = state.copyWith(
      isLoading: !append,
      isLoadingMore: append,
      clearError: true,
    );

    try {
      final request = SearchRequest(
        query: query,
        sources: state.selectedSources.toList(),
        limit: pageSize,
        offset: offset,
      );

      final response = await _searchService.search(request);

      // A newer search may have replaced this one while the request was in
      // flight; drop the stale page instead of mixing it into fresh results.
      if (generation != _generation) return;

      // `pagination.nextOffset` is absent on the enhanced path, so derive the
      // next offset from the offset we asked for plus what came back.
      final results = append
          ? [...state.results, ...response.results]
          : response.results;
      final hasMore =
          response.results.isNotEmpty &&
          (response.pagination.hasMore ??
              response.results.length >= request.limit);

      state = state.copyWith(
        results: results,
        isLoading: false,
        isLoadingMore: false,
        hasSearched: true,
        hasMore: hasMore,
        nextOffset:
            response.pagination.nextOffset ?? offset + response.results.length,
        totalResults: response.totalResults,
        metadata: response.metadata,
        clearError: true,
      );
    } on SearchException catch (e) {
      _logger.e('Search failed: ${e.message}');
      if (generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasSearched: true,
        error: e.message,
        isAuthError: e.isAuthError,
      );
    } catch (e) {
      _logger.e('Search failed: $e');
      if (generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        hasSearched: true,
        error: '$e',
      );
    }
  }
}

/// Unified search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchNotifier(searchService);
});
