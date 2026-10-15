import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mataresit_app/features/search/models/search_result_model.dart';
import 'package:mataresit_app/features/search/providers/search_provider.dart';
import 'package:mataresit_app/features/search/services/search_service.dart';

/// Records every request and replays canned responses / exceptions.
class _FakeSearchService extends SearchService {
  _FakeSearchService(this._script, {this.delay = Duration.zero});

  final List<Object> _script;
  final Duration delay;
  final List<SearchRequest> requests = [];
  int _index = 0;

  @override
  Future<SearchResponse> search(SearchRequest request) async {
    requests.add(request);

    final step = _script[_index < _script.length ? _index : _script.length - 1];
    _index++;

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (step is SearchException) throw step;
    return step as SearchResponse;
  }
}

SearchResultItem _item(int index) => SearchResultItem(
  id: 'r$index',
  sourceType: SearchSources.receipt,
  sourceId: 'receipt-$index',
  title: 'Receipt $index',
  similarity: 0.5,
);

SearchResponse _page(
  int count, {
  bool? hasMore,
  int? nextOffset,
  int totalResults = 0,
  SearchMetadata metadata = const SearchMetadata(),
}) {
  return SearchResponse(
    success: true,
    results: List.generate(count, _item),
    totalResults: totalResults,
    metadata: metadata,
    pagination: SearchPagination(
      hasMore: hasMore,
      nextOffset: nextOffset,
      totalPages: 3,
    ),
  );
}

void main() {
  late _FakeSearchService service;
  late ProviderContainer container;

  ProviderContainer buildContainer(_FakeSearchService fake) {
    return ProviderContainer(
      overrides: [searchServiceProvider.overrideWithValue(fake)],
    );
  }

  setUp(() {
    service = _FakeSearchService([_page(0)]);
    container = buildContainer(service);
  });

  tearDown(() {
    container.dispose();
  });

  group('SearchNotifier initial state', () {
    test('starts on the pre-search prompt with the default sources', () {
      final state = container.read(searchProvider);

      expect(state.hasSearched, isFalse);
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.selectedSources, {
        SearchSources.receipt,
        SearchSources.businessDirectory,
      });
    });

    test('ignores an empty query instead of calling the server', () async {
      await container.read(searchProvider.notifier).search('   ');

      expect(service.requests, isEmpty);
      expect(container.read(searchProvider).hasSearched, isFalse);
    });
  });

  group('SearchNotifier pagination', () {
    test('derives the next offset when the enhanced path omits it', () async {
      service = _FakeSearchService([
        _page(20, hasMore: true, totalResults: 45),
      ]);
      container.dispose();
      container = buildContainer(service);

      await container.read(searchProvider.notifier).search('  tesco  ');

      final state = container.read(searchProvider);
      expect(service.requests.single.query, 'tesco');
      expect(state.results, hasLength(20));
      expect(state.totalResults, 45);
      expect(state.hasMore, isTrue);
      expect(state.nextOffset, 20);
      expect(state.hasSearched, isTrue);
    });

    test('loadMore requests the derived offset and appends results', () async {
      service = _FakeSearchService([
        _page(20, hasMore: true),
        _page(5, hasMore: false),
      ]);
      container.dispose();
      container = buildContainer(service);

      final notifier = container.read(searchProvider.notifier);
      await notifier.search('kopi');
      await notifier.loadMore();

      expect(service.requests.map((request) => request.offset).toList(), [
        0,
        20,
      ]);
      expect(container.read(searchProvider).results, hasLength(25));
      expect(container.read(searchProvider).hasMore, isFalse);
    });

    test(
      'assumes more results when hasMore is absent and the page is full',
      () async {
        service = _FakeSearchService([_page(20)]);
        container.dispose();
        container = buildContainer(service);

        await container.read(searchProvider.notifier).search('kopi');

        final state = container.read(searchProvider);
        expect(state.results, hasLength(20));
        expect(state.hasMore, isTrue);
        expect(state.nextOffset, 20);
      },
    );

    test(
      'stops paginating when the server omits hasMore and returns a short page',
      () async {
        service = _FakeSearchService([_page(3)]);
        container.dispose();
        container = buildContainer(service);

        await container.read(searchProvider.notifier).search('kopi');

        expect(container.read(searchProvider).hasMore, isFalse);
      },
    );

    test('does not paginate forever when a page is empty', () async {
      service = _FakeSearchService([_page(0, hasMore: true)]);
      container.dispose();
      container = buildContainer(service);

      final notifier = container.read(searchProvider.notifier);
      await notifier.search('kopi');
      await notifier.loadMore();

      expect(service.requests, hasLength(1));
      expect(container.read(searchProvider).hasMore, isFalse);
    });

    test(
      'ignores overlapping loadMore calls while a page is in flight',
      () async {
        service = _FakeSearchService([
          _page(20, hasMore: true),
          _page(20, hasMore: true),
        ], delay: const Duration(milliseconds: 20));
        container.dispose();
        container = buildContainer(service);

        final notifier = container.read(searchProvider.notifier);
        await notifier.search('kopi');

        final first = notifier.loadMore();
        final second = notifier
            .loadMore(); // Scrolling again must not duplicate.
        await Future.wait([first, second]);

        expect(service.requests, hasLength(2));
        expect(container.read(searchProvider).results, hasLength(40));
      },
    );

    test('drops a stale page when a new search supersedes it', () async {
      service = _FakeSearchService([
        _page(20, hasMore: true),
        _page(20, hasMore: true),
        _page(2),
      ], delay: const Duration(milliseconds: 20));
      container.dispose();
      container = buildContainer(service);

      final notifier = container.read(searchProvider.notifier);
      await notifier.search('kopi');

      final stalePage = notifier.loadMore();
      final freshSearch = notifier.search('teh');
      await Future.wait([stalePage, freshSearch]);

      final state = container.read(searchProvider);
      expect(state.query, 'teh');
      expect(state.results, hasLength(2));
      expect(state.isLoadingMore, isFalse);
    });
  });

  group('SearchNotifier empty and degraded results', () {
    test('records an empty successful search as searched', () async {
      service = _FakeSearchService([_page(0, totalResults: 0)]);
      container.dispose();
      container = buildContainer(service);

      await container.read(searchProvider.notifier).search('nothing matches');

      final state = container.read(searchProvider);
      expect(state.results, isEmpty);
      expect(state.hasSearched, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.hasMore, isFalse);
    });

    test('surfaces the degraded flag from search metadata', () async {
      service = _FakeSearchService([
        _page(
          2,
          metadata: const SearchMetadata(
            modelUsed: 'fallback-search',
            fallbacksUsed: ['text_search_fallback'],
          ),
        ),
      ]);
      container.dispose();
      container = buildContainer(service);

      await container.read(searchProvider.notifier).search('kopi');

      expect(container.read(searchProvider).isDegraded, isTrue);
    });
  });

  group('SearchNotifier errors', () {
    test('records an auth failure without losing the searched flag', () async {
      service = _FakeSearchService([
        const SearchException('Internal server error', isAuthError: true),
      ]);
      container.dispose();
      container = buildContainer(service);

      await container.read(searchProvider.notifier).search('kopi');

      final state = container.read(searchProvider);
      expect(state.error, 'Internal server error');
      expect(state.isAuthError, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.results, isEmpty);
      expect(state.hasSearched, isTrue);
    });

    test('retry clears the error and re-runs the query', () async {
      service = _FakeSearchService([
        const SearchException('Search failed'),
        _page(2),
      ]);
      container.dispose();
      container = buildContainer(service);

      final notifier = container.read(searchProvider.notifier);
      await notifier.search('kopi');
      expect(container.read(searchProvider).error, 'Search failed');

      await notifier.retry();

      final state = container.read(searchProvider);
      expect(state.error, isNull);
      expect(state.results, hasLength(2));
      expect(service.requests, hasLength(2));
      expect(service.requests.last.query, 'kopi');
      expect(service.requests.last.offset, 0);
    });
  });

  group('SearchNotifier sources', () {
    test('toggleSource adds a source and re-runs the search', () async {
      service = _FakeSearchService([_page(1), _page(1)]);
      container.dispose();
      container = buildContainer(service);

      final notifier = container.read(searchProvider.notifier);
      await notifier.search('kopi');

      notifier.toggleSource(SearchSources.customCategory);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(searchProvider).selectedSources, {
        SearchSources.receipt,
        SearchSources.businessDirectory,
        SearchSources.customCategory,
      });
      expect(service.requests, hasLength(2));
      expect(
        service.requests.last.sources,
        containsAll(<String>[
          SearchSources.receipt,
          SearchSources.businessDirectory,
          SearchSources.customCategory,
        ]),
      );
    });

    test(
      'toggleSource refuses to deselect the last remaining source',
      () async {
        service = _FakeSearchService([_page(1)]);
        container.dispose();
        container = buildContainer(service);

        final notifier = container.read(searchProvider.notifier);
        notifier.toggleSource(SearchSources.businessDirectory);
        notifier.toggleSource(SearchSources.receipt);

        expect(container.read(searchProvider).selectedSources, {
          SearchSources.receipt,
        });
      },
    );

    test(
      'clear returns to the pre-search state but keeps the sources',
      () async {
        service = _FakeSearchService([_page(3)]);
        container.dispose();
        container = buildContainer(service);

        final notifier = container.read(searchProvider.notifier);
        notifier.toggleSource(SearchSources.customCategory);
        await notifier.search('kopi');
        expect(container.read(searchProvider).hasSearched, isTrue);

        notifier.clear();

        final state = container.read(searchProvider);
        expect(state.hasSearched, isFalse);
        expect(state.results, isEmpty);
        expect(state.query, '');
        expect(state.selectedSources, contains(SearchSources.customCategory));
      },
    );
  });
}
