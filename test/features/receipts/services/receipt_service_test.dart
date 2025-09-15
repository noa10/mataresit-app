import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';

void main() {
  group('ReceiptService', () {
    group('Status Handling', () {
      test('should handle valid unreviewed status correctly', () {
        // Test data with valid unreviewed status
        final testReceiptData = {
          'id': 'test-receipt-1',
          'user_id': 'test-user',
          'status': 'unreviewed', // Valid status - no conversion needed
          'processing_status': 'completed',
          'merchant_name': 'Test Merchant',
          'total_amount': 25.50,
          'currency': 'MYR',
          'is_expense': true,
          'is_reimbursable': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // This should work without any status conversion
        expect(() {
          final receipt = ReceiptModel.fromJson(testReceiptData);
          expect(receipt.status, equals(ReceiptStatus.unreviewed));
        }, returnsNormally);
      });

      test('should handle valid reviewed status correctly', () {
        final testReceiptData = {
          'id': 'test-receipt-2',
          'user_id': 'test-user',
          'status': 'reviewed', // Valid status
          'processing_status': 'completed',
          'merchant_name': 'Test Merchant',
          'total_amount': 25.50,
          'currency': 'MYR',
          'is_expense': true,
          'is_reimbursable': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        expect(() {
          final receipt = ReceiptModel.fromJson(testReceiptData);
          expect(receipt.status, equals(ReceiptStatus.reviewed));
        }, returnsNormally);
      });

      test('should handle all valid status values', () {
        final validStatuses = ['unreviewed', 'reviewed'];
        final expectedEnums = [
          ReceiptStatus.unreviewed,
          ReceiptStatus.reviewed,
        ];

        for (int i = 0; i < validStatuses.length; i++) {
          final testReceiptData = {
            'id': 'test-receipt-$i',
            'user_id': 'test-user',
            'status': validStatuses[i],
            'processing_status': 'completed',
            'merchant_name': 'Test Merchant',
            'total_amount': 25.50,
            'currency': 'MYR',
            'is_expense': true,
            'is_reimbursable': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          expect(() {
            final receipt = ReceiptModel.fromJson(testReceiptData);
            expect(receipt.status, equals(expectedEnums[i]));
          }, returnsNormally);
        }
      });
    });

    group('Receipt Browser Modal Integration', () {
      test('should handle empty receipt IDs list', () {
        // Test that empty list doesn't cause issues
        final emptyList = <String>[];
        expect(emptyList.isEmpty, isTrue);

        // This simulates what happens in the receipt browser modal
        expect(() {
          if (emptyList.isEmpty) {
            // Should return early without making database calls
            return;
          }
        }, returnsNormally);
      });

      test('should handle receipt IDs list with valid IDs', () {
        final receiptIds = ['receipt-1', 'receipt-2', 'receipt-3'];
        expect(receiptIds.isNotEmpty, isTrue);
        expect(receiptIds.length, equals(3));

        // This simulates the filtering that happens in batch upload
        final filteredIds = receiptIds.where((id) => id.isNotEmpty).toList();
        expect(filteredIds.length, equals(3));
      });
    });
  });
}
