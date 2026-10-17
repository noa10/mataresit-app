import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/duplicates/models/duplicate_models.dart';
import 'package:mataresit_app/features/duplicates/services/duplicate_detection_service.dart';

/// Build a scan receipt through the production raw-row path, so that reading
/// `normalized_merchant` off the row map is exercised as well.
ScannedReceipt receipt({
  required String id,
  String? merchant,
  String? normalizedMerchant,
  DateTime? date,
  double? total,
  double? tax,
  String? currency,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2024, 3, 1, 9);
  return ScannedReceipt.fromRow({
    'id': id,
    'user_id': 'user-1',
    'team_id': null,
    'merchant': merchant,
    'normalized_merchant': normalizedMerchant,
    'date': date?.toIso8601String(),
    'total': total,
    'tax': tax,
    'currency': currency,
    'status': 'unreviewed',
    'processing_status': 'completed',
    'is_expense': true,
    'is_reimbursable': true,
    'created_at': created.toIso8601String(),
    'updated_at': created.toIso8601String(),
  });
}

DuplicateGrouping groupReceipts(
  List<ScannedReceipt> receipts, {
  ScanConfig config = const ScanConfig(),
}) => DuplicateDetectionService.groupDuplicates(receipts, config);

void main() {
  group('DuplicateDetectionService.groupDuplicates', () {
    group('basic grouping', () {
      test('groups a genuine duplicate pair', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
            createdAt: DateTime(2024, 5, 10, 8),
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
            createdAt: DateTime(2024, 5, 11, 8),
          ),
        ]);

        expect(outcome.groups, hasLength(1));
        final matches = outcome.groups.single;
        expect(matches.receipts.map((r) => r.id), ['a', 'b']);
        expect(matches.keptReceiptId, 'a');
        expect(outcome.skippedNoMerchant, 0);
      });

      test('does not group a pair with different merchants', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Coffee Bean',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
        ]);

        expect(outcome.groups, isEmpty);
      });

      test('does not group a pair on different days', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 12),
            total: 12.50,
          ),
        ]);

        expect(outcome.groups, isEmpty);
      });

      test('does not group a pair with different totals', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 15.90,
          ),
        ]);

        expect(outcome.groups, isEmpty);
      });

      test('discards groups with a single member', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
        ]);

        expect(outcome.groups, isEmpty);
      });

      test('assigns unique ids within one result', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'c',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 80.00,
          ),
          receipt(
            id: 'd',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 80.00,
          ),
        ]);

        expect(outcome.groups, hasLength(2));
        expect(
          outcome.groups.map((g) => g.id).toSet(),
          hasLength(outcome.groups.length),
        );
      });
    });

    group('merchant key', () {
      test('prefers normalized_merchant from the raw row', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks Coffee',
            normalizedMerchant: 'starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks Cafe',
            normalizedMerchant: 'starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
        ]);

        expect(outcome.groups, hasLength(1));
      });

      test('falls back to the raw merchant when normalized is missing', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks Coffee',
            normalizedMerchant: null,
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: '  starbucks coffee ',
            normalizedMerchant: '',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
        ]);

        expect(outcome.groups, hasLength(1));
      });

      test('counts receipts with no merchant instead of dropping them', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(id: 'c', merchant: null, date: DateTime(2024, 5, 10)),
          receipt(id: 'd', merchant: '   ', date: DateTime(2024, 5, 10)),
        ]);

        expect(outcome.groups, hasLength(1));
        expect(outcome.skippedNoMerchant, 2);
        expect(
          outcome.groups.single.receipts.map((r) => r.id),
          ['a', 'b'],
          reason: 'receipts without a merchant must not join a group',
        );
      });
    });

    group('date window', () {
      test('tolerance 0 requires the exact same calendar day', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10, 23, 30),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 11, 0, 30),
            total: 12.50,
          ),
        ]);

        expect(outcome.groups, isEmpty);
      });

      test('tolerance 0 matches the same day at different clock times', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10, 8, 5),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10, 21, 45),
            total: 12.50,
          ),
        ]);

        expect(outcome.groups, hasLength(1));
      });

      test('tolerance 1 groups receipts one day apart', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 10),
            total: 12.50,
          ),
          receipt(
            id: 'b',
            merchant: 'Starbucks',
            date: DateTime(2024, 5, 11),
            total: 12.50,
          ),
        ], config: const ScanConfig(dateToleranceDays: 1));

        expect(outcome.groups, hasLength(1));
        expect(outcome.groups.single.receipts.map((r) => r.id), ['a', 'b']);
      });

      test('tolerance window is symmetric across a month boundary', () {
        // 2024-05-31 and 2024-06-01 are one day apart in either direction.
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 31, 22),
            total: 80.00,
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 6, 1, 1),
            total: 80.00,
          ),
        ], config: const ScanConfig(dateToleranceDays: 1));

        expect(outcome.groups, hasLength(1));
      });

      test('is a symmetric window, not an epoch-anchored bucket', () {
        // Two local midnights one day apart land in different epoch-anchored
        // 1-day buckets, which is exactly how the web client keys dates
        // (`floor(epoch / windowMs)`) and why it can split a pair the
        // "tolerance in days" setting says should match.
        final first = DateTime(2024, 1, 10);
        final second = DateTime(2024, 1, 11);
        const windowMs = Duration.millisecondsPerDay;
        expect(
          first.millisecondsSinceEpoch ~/ windowMs,
          isNot(equals(second.millisecondsSinceEpoch ~/ windowMs)),
          reason: 'sanity check: an epoch bucket splits these two days',
        );

        final outcome = groupReceipts([
          receipt(id: 'a', merchant: 'Tesco', date: first, total: 80.00),
          receipt(id: 'b', merchant: 'Tesco', date: second, total: 80.00),
        ], config: const ScanConfig(dateToleranceDays: 1));

        expect(outcome.groups, hasLength(1));
      });

      test('tolerance boundary is inclusive', () {
        final receipts = [
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 80.00,
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 12),
            total: 80.00,
          ),
        ];

        expect(
          groupReceipts(
            receipts,
            config: const ScanConfig(dateToleranceDays: 1),
          ).groups,
          isEmpty,
        );
        expect(
          groupReceipts(
            receipts,
            config: const ScanConfig(dateToleranceDays: 2),
          ).groups,
          hasLength(1),
        );
      });

      test('links a chain of receipts transitively', () {
        // Tolerance 1 links day 0 -> day 1 -> day 2 into one group. This is the
        // documented behaviour of the window: consecutive receipts within
        // tolerance are treated as one duplicate cluster.
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 80.00,
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 11),
            total: 80.00,
          ),
          receipt(
            id: 'c',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 12),
            total: 80.00,
          ),
        ], config: const ScanConfig(dateToleranceDays: 1));

        expect(outcome.groups, hasLength(1));
        expect(outcome.groups.single.receipts, hasLength(3));
      });

      test(
        'receipts without a date only group with other undated receipts',
        () {
          final outcome = groupReceipts([
            receipt(id: 'a', merchant: 'Tesco', total: 80.00),
            receipt(id: 'b', merchant: 'Tesco', total: 80.00),
            receipt(
              id: 'c',
              merchant: 'Tesco',
              date: DateTime(2024, 5, 10),
              total: 80.00,
            ),
          ]);

          expect(outcome.groups, hasLength(1));
          expect(outcome.groups.single.receipts.map((r) => r.id), ['a', 'b']);
        },
      );
    });

    group('amount tolerance', () {
      test('totalTolerance 0 requires an exact match', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.01,
          ),
        ], config: const ScanConfig(totalTolerance: 0));

        expect(
          outcome.groups,
          isEmpty,
          reason: 'the web client turns 0 into 0.01 and matches these',
        );
      });

      test('totalTolerance 0 still matches identical amounts', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
          ),
        ], config: const ScanConfig(totalTolerance: 0));

        expect(outcome.groups, hasLength(1));
      });

      test('the default 0.01 tolerance absorbs sub-cent noise', () {
        final outcome = groupReceipts([
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.004,
          ),
        ]);

        expect(outcome.groups, hasLength(1));
      });

      test('equal totals cannot split through float representation', () {
        final noisy = 5.1 + 0.2; // 5.300000000000001
        final clean = 5.3;

        for (final tolerance in [0.0, 0.01]) {
          final outcome = groupReceipts([
            receipt(
              id: 'a',
              merchant: 'Tesco',
              date: DateTime(2024, 5, 10),
              total: noisy,
            ),
            receipt(
              id: 'b',
              merchant: 'Tesco',
              date: DateTime(2024, 5, 10),
              total: clean,
            ),
          ], config: ScanConfig(totalTolerance: tolerance));

          expect(
            outcome.groups,
            hasLength(1),
            reason:
                'totals equal in arithmetic must share a bucket '
                'at tolerance $tolerance',
          );
        }
      });

      test('tax only separates receipts when tax matching is enabled', () {
        final receipts = [
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
            tax: 0.60,
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
            tax: 0.90,
          ),
        ];

        expect(groupReceipts(receipts).groups, hasLength(1));
        expect(
          groupReceipts(
            receipts,
            config: const ScanConfig(taxEnabled: true),
          ).groups,
          isEmpty,
        );
      });

      test('currency only separates receipts when currency matching is on', () {
        final receipts = [
          receipt(
            id: 'a',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
            currency: 'MYR',
          ),
          receipt(
            id: 'b',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 10.00,
            currency: 'usd',
          ),
        ];

        expect(groupReceipts(receipts).groups, hasLength(1));
        expect(
          groupReceipts(
            receipts,
            config: const ScanConfig(currencyEnabled: true),
          ).groups,
          isEmpty,
        );
      });
    });

    group('group contents', () {
      test('sorts by date then creation time and keeps the oldest', () {
        final outcome = groupReceipts([
          receipt(
            id: 'third',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 12),
            total: 80.00,
            createdAt: DateTime(2024, 5, 12, 10),
          ),
          receipt(
            id: 'first',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 80.00,
            createdAt: DateTime(2024, 5, 10, 10),
          ),
          receipt(
            id: 'second',
            merchant: 'Tesco',
            date: DateTime(2024, 5, 10),
            total: 80.00,
            createdAt: DateTime(2024, 5, 10, 18),
          ),
        ], config: const ScanConfig(dateToleranceDays: 3));

        final match = outcome.groups.single;
        expect(match.receipts.map((r) => r.id), ['first', 'second', 'third']);
        expect(match.keptReceiptId, 'first');
        expect(match.deletableReceiptIds, ['second', 'third']);
      });

      test('reports the fields that produced the match', () {
        expect(groupReceipts([]).groups, isEmpty);
        expect(const ScanConfig().matchCriteria, 'merchant + date + total');
        expect(
          const ScanConfig(dateEnabled: false).matchCriteria,
          'merchant + total',
        );
        expect(
          const ScanConfig(
            taxEnabled: true,
            currencyEnabled: true,
          ).matchCriteria,
          'merchant + date + total + tax + currency',
        );
      });
    });
  });

  group('DuplicateDetectionService.collectPages', () {
    List<Map<String, dynamic>> sourceRows(int count) => [
      for (var i = 0; i < count; i++) {'id': 'row-$i'},
    ];

    Future<List<Map<String, dynamic>>> Function(int offset, int limit) pager(
      List<Map<String, dynamic>> source,
      List<({int offset, int limit})> calls,
    ) {
      return (offset, limit) async {
        calls.add((offset: offset, limit: limit));
        final end = (offset + limit) > source.length
            ? source.length
            : offset + limit;
        return source.sublist(offset, end);
      };
    }

    test('stops at the last short page and reports no cap', () async {
      final calls = <({int offset, int limit})>[];
      final outcome = await DuplicateDetectionService.collectPages(
        batchSize: 1000,
        maxRows: 10000,
        fetchPage: pager(sourceRows(1500), calls),
      );

      expect(outcome.rows, hasLength(1500));
      expect(outcome.wasCapped, isFalse);
      expect(calls, hasLength(2));
      expect(calls.map((c) => c.offset), [0, 1000]);
    });

    test('pages with range offsets up to the cap', () async {
      final calls = <({int offset, int limit})>[];
      final outcome = await DuplicateDetectionService.collectPages(
        batchSize: 1000,
        maxRows: 2500,
        fetchPage: pager(sourceRows(9000), calls),
      );

      expect(outcome.rows, hasLength(2500));
      expect(
        outcome.rows.first['id'],
        'row-0',
        reason: 'scannedCount must reflect the true rows scanned',
      );
      expect(outcome.wasCapped, isTrue);
      expect(calls.map((c) => c.offset), [0, 1000, 2000]);
      expect(calls.map((c) => c.limit), [1000, 1000, 501]);
    });

    test('is not capped when the account holds exactly the maximum', () async {
      final calls = <({int offset, int limit})>[];
      final outcome = await DuplicateDetectionService.collectPages(
        batchSize: 1000,
        maxRows: 2500,
        fetchPage: pager(sourceRows(2500), calls),
      );

      expect(outcome.rows, hasLength(2500));
      expect(outcome.wasCapped, isFalse);
    });

    test('trims the extra probe row when the cap is hit', () async {
      final outcome = await DuplicateDetectionService.collectPages(
        batchSize: 1000,
        maxRows: 2500,
        fetchPage: pager(sourceRows(2501), []),
      );

      expect(outcome.rows, hasLength(2500));
      expect(outcome.wasCapped, isTrue);
    });

    test('returns an empty result for an empty account', () async {
      final calls = <({int offset, int limit})>[];
      final outcome = await DuplicateDetectionService.collectPages(
        batchSize: 1000,
        maxRows: 10000,
        fetchPage: pager(sourceRows(0), calls),
      );

      expect(outcome.rows, isEmpty);
      expect(outcome.wasCapped, isFalse);
      expect(calls, hasLength(1));
    });
  });
}
