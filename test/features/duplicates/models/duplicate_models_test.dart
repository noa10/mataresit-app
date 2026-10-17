import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/duplicates/models/duplicate_models.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';

ReceiptModel model(String id) => ReceiptModel(
  id: id,
  userId: 'user-1',
  status: ReceiptStatus.unreviewed,
  processingStatus: ProcessingStatus.completed,
  isExpense: true,
  isReimbursable: true,
  createdAt: DateTime(2024, 5, 10, 8),
  updatedAt: DateTime(2024, 5, 10, 8),
);

DuplicateGroup groupOf(List<String> ids) => DuplicateGroup(
  id: 'duplicate-group-1',
  receipts: [for (final id in ids) model(id)],
  matchCriteria: 'merchant + date + total',
  keptReceiptId: ids.first,
);

void main() {
  group('ScanConfig', () {
    test('defaults match the documented scan behaviour', () {
      const config = ScanConfig();

      expect(config.merchantEnabled, isTrue);
      expect(config.dateEnabled, isTrue);
      expect(config.dateToleranceDays, 0);
      expect(config.totalEnabled, isTrue);
      expect(config.totalTolerance, 0.01);
      expect(config.taxEnabled, isFalse);
      expect(config.currencyEnabled, isFalse);
      expect(config.matchCriteria, 'merchant + date + total');
    });

    test('copies with bounded tolerance values', () {
      final config = const ScanConfig().copyWith(
        dateToleranceDays: ScanConfig.maxDateToleranceDays,
        totalTolerance: ScanConfig.maxTotalTolerance,
      );

      expect(config.dateToleranceDays, 30);
      expect(config.totalTolerance, 1.0);
      expect(config.matchFields, ['merchant', 'date', 'total']);
    });
  });

  group('ScanResult', () {
    test('derives the duplicate and deletable counts from the groups', () {
      final result = ScanResult.fromGroups(
        groups: [
          groupOf(['a', 'b', 'c']),
          DuplicateGroup(
            id: 'duplicate-group-2',
            receipts: [model('d'), model('e')],
            matchCriteria: 'merchant + date + total',
            keptReceiptId: 'd',
          ),
        ],
        scannedCount: 42,
        skippedNoMerchant: 3,
        wasCapped: true,
        scannedAt: DateTime(2024, 5, 10, 10),
      );

      expect(result.totalDuplicates, 5);
      expect(result.deletableCount, 3);
      expect(result.scannedCount, 42);
      expect(result.skippedNoMerchant, 3);
      expect(result.wasCapped, isTrue);
      expect(result.hasGroups, isTrue);
      expect(result.hasPartialInfo, isTrue);
      expect(result.deletableReceiptIds, ['b', 'c', 'e']);
      expect(result.duplicateReceiptIds, ['a', 'b', 'c', 'd', 'e']);
    });

    test('flags a scan older than five minutes as stale', () {
      final scannedAt = DateTime(2024, 5, 10, 10);
      final result = ScanResult.fromGroups(
        groups: const [],
        scannedCount: 0,
        skippedNoMerchant: 0,
        wasCapped: false,
        scannedAt: scannedAt,
      );

      expect(result.isStaleAt(scannedAt), isFalse);
      expect(
        result.isStaleAt(scannedAt.add(const Duration(minutes: 5))),
        isFalse,
      );
      expect(
        result.isStaleAt(scannedAt.add(const Duration(minutes: 5, seconds: 1))),
        isTrue,
      );
    });

    test('withoutReceipts drops receipts and small groups', () {
      final result = ScanResult.fromGroups(
        groups: [
          groupOf(['a', 'b', 'c']),
          DuplicateGroup(
            id: 'duplicate-group-2',
            receipts: [model('d'), model('e')],
            matchCriteria: 'merchant + date + total',
            keptReceiptId: 'd',
          ),
        ],
        scannedCount: 42,
        skippedNoMerchant: 0,
        wasCapped: false,
        scannedAt: DateTime(2024, 5, 10, 10),
      );

      final updated = result.withoutReceipts({'b', 'c'});

      expect(updated.groups, hasLength(1));
      expect(updated.groups.single.receipts.map((r) => r.id), ['d', 'e']);
      expect(updated.totalDuplicates, 2);
      expect(updated.deletableCount, 1);
      expect(updated.scannedCount, result.scannedCount);
    });

    test('withoutReceipts re-points the kept receipt when it was removed', () {
      final result = ScanResult.fromGroups(
        groups: [
          groupOf(['a', 'b', 'c']),
        ],
        scannedCount: 3,
        skippedNoMerchant: 0,
        wasCapped: false,
      );

      final updated = result.withoutReceipts({'a'});

      expect(updated.groups.single.keptReceiptId, 'b');
      expect(updated.groups.single.deletableReceiptIds, ['c']);
    });

    test('withoutReceipts is a no-op for an empty id set', () {
      final result = ScanResult.fromGroups(
        groups: [
          groupOf(['a', 'b']),
        ],
        scannedCount: 2,
        skippedNoMerchant: 0,
        wasCapped: false,
      );

      expect(result.withoutReceipts(const {}), same(result));
    });
  });
}
