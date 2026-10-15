import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/search/models/search_result_model.dart';

void main() {
  group('SearchResponse parsing', () {
    test('parses the regular-path envelope including nextOffset', () {
      final response = SearchResponse.fromJson({
        'success': true,
        'results': [
          {
            'id': 'r1',
            'sourceType': 'receipt',
            'sourceId': 'receipt-1',
            'contentType': 'full_text',
            'title': 'Tesco Groceries',
            'description': 'Weekly grocery run',
            'similarity': 0.87,
            'metadata': {'merchant': 'Tesco'},
            'accessLevel': 'user',
            'createdAt': '2026-01-02T03:04:05.000Z',
            'updatedAt': '2026-01-03T03:04:05.000Z',
          },
        ],
        'totalResults': 12,
        'searchMetadata': {
          'sourcesSearched': ['receipt'],
          'searchDuration': 123,
          'modelUsed': 'gemini-embedding',
          'fallbacksUsed': <String>[],
        },
        'pagination': {'hasMore': true, 'nextOffset': 20, 'totalPages': 3},
      });

      expect(response.success, isTrue);
      expect(response.results, hasLength(1));
      expect(response.totalResults, 12);
      expect(response.metadata.searchDuration, 123);
      expect(response.metadata.modelUsed, 'gemini-embedding');
      expect(response.metadata.isDegraded, isFalse);
      expect(response.pagination.hasMore, isTrue);
      expect(response.pagination.nextOffset, 20);
      expect(response.pagination.totalPages, 3);

      final item = response.results.first;
      expect(item.id, 'r1');
      expect(item.sourceType, SearchSources.receipt);
      expect(item.sourceId, 'receipt-1');
      expect(item.similarity, 0.87);
      expect(item.metadata['merchant'], 'Tesco');
      expect(item.accessLevel, 'user');
      expect(item.createdAt, DateTime.parse('2026-01-02T03:04:05.000Z'));
      expect(item.updatedAt, DateTime.parse('2026-01-03T03:04:05.000Z'));
      expect(item.isReceipt, isTrue);
    });

    test('leaves nextOffset null when the enhanced path omits it', () {
      // The enhanced path returns pagination without `nextOffset`, so callers
      // have to derive the next offset from offset + results.length.
      final response = SearchResponse.fromJson({
        'success': true,
        'results': List.generate(20, (index) => {'id': 'r$index'}),
        'totalResults': 45,
        'searchMetadata': {'modelUsed': 'gemini-2.0-flash'},
        'pagination': {'hasMore': true, 'totalPages': 3},
        'enhancedResponse': {
          'content': 'Found 45 results',
          'followUpSuggestions': ['Refine my search'],
          'confidence': 0.9,
          'responseType': 'success',
        },
      });

      expect(response.pagination.nextOffset, isNull);
      expect(response.pagination.hasMore, isTrue);
      expect(response.pagination.totalPages, 3);
      expect(response.results, hasLength(20));
      expect(response.enhancedContent, 'Found 45 results');
      expect(response.followUpSuggestions, ['Refine my search']);
      expect(response.confidence, 0.9);
      expect(response.responseType, 'success');
    });

    test('keeps sourceType as an open string for undocumented values', () {
      final response = SearchResponse.fromJson({
        'success': true,
        'results': [
          {'id': 'a', 'sourceType': 'line_item', 'sourceId': 'li-1'},
          {'id': 'b', 'sourceType': 'financial_analysis', 'sourceId': 'fa-1'},
          {'id': 'c', 'sourceType': 'error', 'sourceId': 'err-1'},
          {'id': 'd', 'sourceType': 'business_directory', 'sourceId': 'biz-1'},
          {'id': 'e'},
        ],
      });

      expect(response.results.map((item) => item.sourceType).toList(), [
        'line_item',
        'financial_analysis',
        'error',
        'business_directory',
        'unknown',
      ]);
      expect(response.results.first.isReceipt, isFalse);
    });

    test('parses the bare error shape that has no results key at all', () {
      final response = SearchResponse.fromJson({
        'success': false,
        'error': 'Invalid parameters',
        'details': ['Invalid sources: receipts'],
      });

      expect(response.success, isFalse);
      expect(response.results, isEmpty);
      expect(response.totalResults, 0);
      expect(response.error, 'Invalid parameters');
      expect(response.details, ['Invalid sources: receipts']);
      expect(response.isAuthFailure, isFalse);
    });

    test('parses the full-envelope error shape with an empty results list', () {
      final response = SearchResponse.fromJson({
        'success': false,
        'error': 'Internal server error',
        'details': 'Missing Authorization header',
        'results': <dynamic>[],
        'totalResults': 0,
        'searchMetadata': {'sourcesSearched': <String>[], 'searchDuration': 42},
        'pagination': {'hasMore': false, 'totalPages': 0},
      });

      expect(response.success, isFalse);
      expect(response.results, isEmpty);
      expect(response.error, 'Internal server error');
      expect(response.details, ['Missing Authorization header']);
      expect(response.pagination.hasMore, isFalse);
    });

    test('normalises a string details field into a list', () {
      final response = SearchResponse.fromJson({
        'success': false,
        'error': 'Boom',
        'details': 'single detail',
      });

      expect(response.details, ['single detail']);
    });

    test('survives a body with only a success flag', () {
      final response = SearchResponse.fromJson({'success': true});

      expect(response.success, isTrue);
      expect(response.results, isEmpty);
      expect(response.metadata.isDegraded, isFalse);
      expect(response.pagination.hasMore, isNull);
      expect(response.error, isNull);
    });
  });

  group('SearchResponse failure classification', () {
    test('flags auth failures from the server wording, not the status code', () {
      // Regular path: HTTP 500 with these messages. Enhanced path: HTTP 401.
      expect(
        SearchResponse.looksLikeAuthFailure('Missing Authorization header'),
        isTrue,
      );
      expect(
        SearchResponse.looksLikeAuthFailure('Invalid authentication token'),
        isTrue,
      );
      expect(
        SearchResponse.looksLikeAuthFailure(
          'Both RAG pipeline and fallback failed: Missing Authorization header',
        ),
        isTrue,
      );
      expect(
        SearchResponse.looksLikeAuthFailure('Internal server error'),
        isFalse,
      );
      expect(SearchResponse.looksLikeAuthFailure(null), isFalse);
    });

    test('exposes isAuthFailure on the parsed response', () {
      final authFailure = SearchResponse.fromJson({
        'success': false,
        'error': 'Missing Authorization header',
      });
      expect(authFailure.isAuthFailure, isTrue);

      final otherFailure = SearchResponse.fromJson({
        'success': false,
        'error': 'Invalid parameters',
      });
      expect(otherFailure.isAuthFailure, isFalse);
    });

    test('marks degraded metadata from fallbacksUsed or modelUsed', () {
      final fallbackModel = SearchResponse.fromJson({
        'success': true,
        'results': [
          {'id': 'r1'},
        ],
        'searchMetadata': {
          'modelUsed': 'fallback-search',
          'fallbacksUsed': ['text_search_fallback'],
        },
      });
      expect(fallbackModel.metadata.isDegraded, isTrue);

      final fallbackOnly = SearchResponse.fromJson({
        'success': true,
        'searchMetadata': {
          'fallbacksUsed': ['keyword_search'],
        },
      });
      expect(fallbackOnly.metadata.isDegraded, isTrue);

      final healthy = SearchResponse.fromJson({
        'success': true,
        'searchMetadata': {'modelUsed': 'gemini-2.0-flash'},
      });
      expect(healthy.metadata.isDegraded, isFalse);
    });
  });

  group('SearchResultItem', () {
    test('renders similarity as a whole percentage', () {
      expect(
        const SearchResultItem(
          id: 'a',
          sourceType: 'receipt',
          sourceId: 'x',
        ).similarityPercent,
        0,
      );
      expect(
        SearchResultItem.fromJson({
          'id': 'a',
          'sourceType': 'receipt',
          'sourceId': 'x',
          'similarity': 0.873,
        }).similarityPercent,
        87,
      );
      expect(
        SearchResultItem.fromJson({
          'id': 'a',
          'sourceType': 'receipt',
          'sourceId': 'x',
          'similarity': 1.4,
        }).similarityPercent,
        100,
      );
      expect(
        SearchResultItem.fromJson({
          'id': 'a',
          'sourceType': 'receipt',
          'sourceId': 'x',
          'similarity': -0.2,
        }).similarityPercent,
        0,
      );
    });

    test('falls back to sensible defaults for missing fields', () {
      final item = SearchResultItem.fromJson({'sourceType': 'receipt'});

      expect(item.id, '');
      expect(item.sourceId, '');
      expect(item.contentType, '');
      expect(item.title, '');
      expect(item.description, '');
      expect(item.similarity, 0.0);
      expect(item.metadata, isEmpty);
      expect(item.accessLevel, isNull);
      expect(item.createdAt, isNull);
      expect(item.updatedAt, isNull);
    });
  });

  group('SearchRequest', () {
    test('defaults to the contract sources in singular form', () {
      const request = SearchRequest(query: 'kopi');

      expect(request.toJson(), {
        'query': 'kopi',
        'sources': ['receipt', 'business_directory'],
        'limit': 20,
        'offset': 0,
      });
    });

    test('serializes selected singular sources with pagination windows', () {
      const request = SearchRequest(
        query: 'tesco',
        sources: ['receipt', 'custom_category'],
        limit: 20,
        offset: 40,
      );

      final body = request.toJson();

      expect(body['sources'], ['receipt', 'custom_category']);
      expect(body['offset'], 40);
      expect(body['limit'], 20);
    });
  });

  group('SearchSources', () {
    test('free tier list only contains singular server names', () {
      expect(SearchSources.freeTier, [
        'receipt',
        'custom_category',
        'business_directory',
      ]);
      expect(
        SearchSources.freeTier.any((source) => source.endsWith('s')),
        isFalse,
        reason: 'plural source names are rejected with HTTP 400',
      );
    });
  });
}
