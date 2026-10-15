import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mataresit_app/features/search/models/search_result_model.dart';
import 'package:mataresit_app/features/search/screens/search_screen.dart';
import 'package:mataresit_app/features/search/services/search_service.dart';
import 'package:mataresit_app/features/search/widgets/search_initial_state.dart';
import 'package:mataresit_app/features/search/widgets/search_result_card.dart';
import 'package:mataresit_app/features/search/widgets/search_result_detail_sheet.dart';
import 'package:mataresit_app/shared/widgets/empty_state_widget.dart';
import 'package:mataresit_app/shared/widgets/error_widget.dart';
import 'package:mataresit_app/shared/widgets/loading_widget.dart';

/// Serves a canned response (or throws a canned exception).
class _FakeSearchService extends SearchService {
  _FakeSearchService(this._step, {this.delay = Duration.zero});

  final Object _step;
  final Duration delay;
  int callCount = 0;

  @override
  Future<SearchResponse> search(SearchRequest request) async {
    callCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    if (_step is SearchException) throw _step;
    return _step as SearchResponse;
  }
}

SearchResponse _emptyResponse() => const SearchResponse(
  success: true,
  pagination: SearchPagination(hasMore: false),
);

SearchResponse _receiptResponse() => SearchResponse(
  success: true,
  totalResults: 1,
  results: [
    SearchResultItem(
      id: 'r1',
      sourceType: SearchSources.receipt,
      sourceId: 'receipt-42',
      title: 'Tesco Groceries',
      description: 'Weekly grocery run',
      similarity: 0.87,
      createdAt: DateTime.parse('2026-01-02T03:04:05.000Z'),
    ),
  ],
  pagination: const SearchPagination(hasMore: false, totalPages: 1),
);

SearchResponse _businessResponse() => SearchResponse(
  success: true,
  totalResults: 1,
  results: [
    SearchResultItem(
      id: 'b1',
      sourceType: SearchSources.businessDirectory,
      sourceId: 'biz-7',
      title: 'Kedai Kopi Ali',
      description: 'Coffee shop in Ipoh',
      similarity: 0.62,
      accessLevel: 'public',
      metadata: const {'address': 'Ipoh, Perak'},
    ),
  ],
  pagination: const SearchPagination(hasMore: false, totalPages: 1),
);

Widget _wrap(SearchService service) {
  return ProviderScope(
    overrides: [searchServiceProvider.overrideWithValue(service)],
    child: const MaterialApp(home: SearchScreen()),
  );
}

/// Wraps the screen in a router so receipt taps can push `/receipts/:id`.
Widget _wrapRouted(SearchService service) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: '/receipts/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('receipt-detail:${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [searchServiceProvider.overrideWithValue(service)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _submitQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.tap(find.byType(LoadingButton));
  await tester.pumpAndSettle();
}

void main() {
  group('SearchScreen initial state', () {
    testWidgets('prompts to search with tappable example queries', (
      tester,
    ) async {
      final service = _FakeSearchService(_emptyResponse());

      await tester.pumpWidget(_wrap(service));

      expect(find.byType(SearchInitialState), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsNothing);
      expect(find.byType(LoadingWidget), findsNothing);
      expect(service.callCount, 0);

      // No search runs until a query is submitted.
      final examples = tester
          .widgetList<ActionChip>(find.byType(ActionChip))
          .toList();
      expect(examples, hasLength(4));
    });

    testWidgets('submitting an example query runs the search', (tester) async {
      final service = _FakeSearchService(_receiptResponse());

      await tester.pumpWidget(_wrap(service));
      await tester.ensureVisible(find.byType(ActionChip).first);
      await tester.tap(find.byType(ActionChip).first);
      await tester.pumpAndSettle();

      expect(service.callCount, 1);
      expect(find.byType(SearchInitialState), findsNothing);
      expect(find.text('Tesco Groceries'), findsOneWidget);
    });
  });

  group('SearchScreen empty results', () {
    testWidgets('shows the empty state when a search matches nothing', (
      tester,
    ) async {
      final service = _FakeSearchService(_emptyResponse());

      await tester.pumpWidget(_wrap(service));
      await _submitQuery(tester, 'nothing at all');

      expect(service.callCount, 1);
      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('search.empty.title'), findsOneWidget);
      expect(find.byType(LoadingWidget), findsNothing);
      expect(find.byType(AppErrorWidget), findsNothing);
    });

    testWidgets('empty state action returns to the initial prompt', (
      tester,
    ) async {
      final service = _FakeSearchService(_emptyResponse());

      await tester.pumpWidget(_wrap(service));
      await _submitQuery(tester, 'nothing at all');
      expect(find.byType(EmptyStateWidget), findsOneWidget);

      await tester.ensureVisible(find.text('search.empty.action'));
      await tester.tap(find.text('search.empty.action'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchInitialState), findsOneWidget);
      expect(find.byType(EmptyStateWidget), findsNothing);
    });
  });

  group('SearchScreen results and errors', () {
    testWidgets('renders a result card with source, match and date', (
      tester,
    ) async {
      final service = _FakeSearchService(_receiptResponse());

      await tester.pumpWidget(_wrap(service));
      await _submitQuery(tester, 'groceries');

      expect(find.text('Tesco Groceries'), findsOneWidget);
      expect(find.text('Weekly grocery run'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SearchResultCard),
          matching: find.text('search.sources.receipt'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SearchResultCard),
          matching: find.text('search.result.similarity'),
        ),
        findsOneWidget,
        reason:
            'the translation key is returned when no localization is loaded',
      );
      expect(
        find.text('search.total'),
        findsOneWidget,
        reason: 'the result count header is rendered once results arrive',
      );
    });

    testWidgets('shows a loading state while the search is in flight', (
      tester,
    ) async {
      final service = _FakeSearchService(
        _receiptResponse(),
        delay: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(_wrap(service));
      await tester.enterText(find.byType(TextField), 'groceries');
      await tester.tap(find.byType(LoadingButton));
      await tester.pump();

      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text('search.loading'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(LoadingWidget), findsNothing);
      expect(find.text('Tesco Groceries'), findsOneWidget);
    });

    testWidgets('shows a partial-results hint when the server degraded', (
      tester,
    ) async {
      final service = _FakeSearchService(
        SearchResponse(
          success: true,
          totalResults: 1,
          results: _receiptResponse().results,
          metadata: const SearchMetadata(
            modelUsed: 'fallback-search',
            fallbacksUsed: ['text_search_fallback'],
          ),
        ),
      );

      await tester.pumpWidget(_wrap(service));
      await _submitQuery(tester, 'groceries');

      expect(find.text('search.degraded.title'), findsOneWidget);
      expect(find.text('search.degraded.message'), findsOneWidget);
      expect(find.text('Tesco Groceries'), findsOneWidget);
    });

    testWidgets('shows the error state with retry when the search fails', (
      tester,
    ) async {
      final service = _FakeSearchService(
        const SearchException('Internal server error'),
      );

      await tester.pumpWidget(_wrap(service));
      await _submitQuery(tester, 'groceries');

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.text('Internal server error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(service.callCount, 2);
    });

    testWidgets('shows the session-expired message for auth failures', (
      tester,
    ) async {
      final service = _FakeSearchService(
        const SearchException('Internal server error', isAuthError: true),
      );

      await tester.pumpWidget(_wrap(service));
      await _submitQuery(tester, 'groceries');

      expect(find.text('search.error.sessionExpired'), findsOneWidget);
      expect(find.text('Internal server error'), findsNothing);
    });
  });

  group('SearchScreen result taps', () {
    testWidgets('a receipt result pushes the receipt detail route', (
      tester,
    ) async {
      final service = _FakeSearchService(_receiptResponse());

      await tester.pumpWidget(_wrapRouted(service));
      await _submitQuery(tester, 'groceries');

      await tester.tap(find.text('Tesco Groceries'));
      await tester.pumpAndSettle();

      expect(find.text('receipt-detail:receipt-42'), findsOneWidget);
    });

    testWidgets('a non-receipt result opens the detail sheet', (tester) async {
      final service = _FakeSearchService(_businessResponse());

      await tester.pumpWidget(_wrap(service));
      await _submitQuery(tester, 'kopi');

      await tester.tap(find.text('Kedai Kopi Ali'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchResultDetailSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SearchResultDetailSheet),
          matching: find.text('Coffee shop in Ipoh'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SearchResultDetailSheet),
          matching: find.text('Ipoh, Perak'),
        ),
        findsOneWidget,
      );
    });
  });

  group('SearchScreen source filter', () {
    testWidgets('offers only the three free-tier sources', (tester) async {
      final service = _FakeSearchService(_emptyResponse());

      await tester.pumpWidget(_wrap(service));

      final chips = tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .toList();
      expect(chips, hasLength(3));
      expect(
        chips.where((chip) => chip.selected).length,
        2,
        reason: 'receipt + business_directory are selected by default',
      );
    });
  });
}
