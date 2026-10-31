import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mataresit_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> row(
  String id, {
  String date = '2026-02-01',
  String? currency = 'MYR',
  Object? total = 10,
  Object? tax = 1,
  String? status = 'reviewed',
  String? category,
  Object? customCategory,
  Map<String, dynamic>? confidence,
}) => {
  'id': id,
  'merchant': 'Merchant $id',
  'date': date,
  'created_at': '${date}T08:00:00Z',
  'currency': currency,
  'total': total,
  'tax': tax,
  'status': status,
  'predicted_category': category,
  'custom_categories': customCategory,
  'confidence_scores': confidence,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('separates currencies, missing values and review status', () {
    final summary = buildDashboardSummary([
      row(
        'a',
        total: '100.00',
        tax: 6,
        status: 'unreviewed',
        category: 'Food',
        confidence: {'overall': .9},
      ),
      row(
        'b',
        total: -20,
        tax: null,
        status: 'unreviewed',
        customCategory: {'name': 'Groceries'},
        confidence: {'merchant': .5, 'total': 90},
      ),
      row('c', total: null, tax: 4, status: 'reviewed'),
      row('d', currency: 'USD', total: 1000, tax: 200),
      row('e', currency: null, total: 1000, tax: 100, status: null),
    ], month: DateTime(2026, 2));

    expect(summary.receiptCount, 5);
    expect(summary.reviewCount, 3);
    expect(summary.currency, 'MYR');
    expect(summary.spend, 80);
    expect(summary.tax, 10);
    expect(summary.currencyReceiptCount, 3);
    expect(summary.amountCount, 2);
    expect(summary.taxCount, 2);
    expect(summary.otherCurrencyCount, 1);
    expect(summary.unknownCurrencyCount, 1);
    expect(summary.categories.map((category) => category.name), [
      'Food',
      'Groceries',
    ]);
    expect(summary.categories.map((category) => category.amount), [100, -20]);
    expect(summary.reviewPreview.map((receipt) => receipt.id), ['b', 'a', 'e']);
    expect(summary.reviewPreview.map((receipt) => receipt.confidence), [
      70,
      90,
      null,
    ]);
    expect(summary.recent.first.amount, 100);
  });

  test('does not invent a currency or zero when amounts are missing', () {
    final summary = buildDashboardSummary([
      row('a', currency: null, total: 25),
      row('b', currency: 'USD', total: null, tax: null),
    ], month: DateTime(2026, 2));
    expect(summary.currency, 'USD');
    expect(summary.spend, isNull);
    expect(summary.tax, isNull);
    expect(summary.categories, isEmpty);
    expect(summary.unknownCurrencyCount, 1);
  });

  test('selects currency by count rather than comparing currency values', () {
    final summary = buildDashboardSummary([
      row('a', currency: 'MYR', total: 1),
      row('b', currency: 'MYR', total: 2),
      row('c', currency: 'USD', total: 999999),
    ], month: DateTime(2026, 2));
    expect(summary.currency, 'MYR');
    expect(summary.spend, 3);
    expect(summary.otherCurrencyCount, 1);
  });

  test(
    'queries complete month pages using personal workspace filters',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          final offset = int.parse(request.url.queryParameters['offset']!);
          final page = offset == 0
              ? List.generate(1000, (i) => row('receipt-$i'))
              : [row('receipt-1000')];
          return http.Response(
            jsonEncode(page),
            200,
            request: request,
            headers: {
              'content-type': 'application/json',
              'content-range': '$offset-${offset + page.length - 1}/1001',
            },
          );
        }),
      );
      addTearDown(client.dispose);

      final summary = await DashboardSummaryService(
        client,
      ).fetch(userId: 'user-1', month: DateTime(2026, 2, 15));
      expect(summary.receiptCount, 1001);
      expect(summary.spend, 10010);
      expect(summary.truncated, isFalse);
      expect(requests, hasLength(2));
      final params = requests.first.url.queryParametersAll;
      expect(params['user_id'], ['eq.user-1']);
      expect(params['team_id'], ['is.null']);
      expect(params['date'], containsAll(['gte.2026-02-01', 'lt.2026-03-01']));
      expect(requests[1].url.queryParameters['offset'], '1000');
    },
  );

  test('uses team scope and flags the 5000-row cap', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final offset = int.parse(request.url.queryParameters['offset']!);
        final page = List.generate(1000, (i) => row('receipt-${offset + i}'));
        return http.Response(
          jsonEncode(page),
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '$offset-${offset + 999}/5001',
          },
        );
      }),
    );
    addTearDown(client.dispose);

    final summary = await DashboardSummaryService(
      client,
    ).fetch(userId: 'user-1', teamId: 'team-1', month: DateTime(2026, 2));
    expect(summary.receiptCount, 5000);
    expect(summary.truncated, isTrue);
    expect(requests, hasLength(5));
    expect(requests.first.url.queryParameters['team_id'], 'eq.team-1');
    expect(requests.first.url.queryParameters.containsKey('user_id'), isFalse);
  });

  test('keeps the requested calendar month on the summary', () {
    final summary = buildDashboardSummary([
      row('first', date: '2026-02-01'),
      row('last', date: '2026-02-28'),
    ], month: DateTime(2026, 2));
    expect(summary.month, DateTime(2026, 2));
    expect(summary.recent.map((receipt) => receipt.id), ['last', 'first']);
  });

  test('aborts a read when its workspace changes', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.test',
      'test-key',
      httpClient: MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode([row('a')]),
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '0-0/1',
          },
        );
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      DashboardSummaryService(
        client,
      ).fetch(userId: 'user-1', isCancelled: () => true),
      throwsA(isA<DashboardSummaryCancelled>()),
    );
    expect(calls, 1);
  });

  test('rejects a page that contradicts the reported total', () async {
    final client = SupabaseClient(
      'https://example.test',
      'test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode([row('a')]),
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '0-0/2',
          },
        ),
      ),
    );
    addTearDown(client.dispose);
    await expectLater(
      DashboardSummaryService(client).fetch(userId: 'user-1'),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'surfaces failed or inconsistent reads instead of inventing data',
    () async {
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            '{"message":"permission denied"}',
            403,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(client.dispose);
      await expectLater(
        DashboardSummaryService(client).fetch(userId: 'user-1'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
}
