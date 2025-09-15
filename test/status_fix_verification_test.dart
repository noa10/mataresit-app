import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';

void main() {
  group('Status Fix Verification', () {
    test('should handle unreviewed status correctly without conversion', () {
      // Test data with unreviewed status (which should be valid)
      final testReceiptData = {
        'id': 'test-receipt-1',
        'user_id': 'test-user',
        'status': 'unreviewed', // This should be valid now
        'processing_status': 'completed',
        'merchant': 'Test Merchant',
        'total': 25.50,
        'currency': 'MYR',
        'is_expense': true,
        'is_reimbursable': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // This should work without any conversion
      expect(() {
        final receipt = ReceiptModel.fromJson(testReceiptData);
        expect(receipt.status, equals(ReceiptStatus.unreviewed));
      }, returnsNormally);
    });

    test('should handle reviewed status correctly', () {
      // Test data with reviewed status
      final testReceiptData = {
        'id': 'test-receipt-2',
        'user_id': 'test-user',
        'status': 'reviewed', // This should be valid
        'processing_status': 'completed',
        'merchant': 'Test Merchant',
        'total': 25.50,
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

    test('should reject invalid status values', () {
      // Test data with invalid status
      final testReceiptData = {
        'id': 'test-receipt-3',
        'user_id': 'test-user',
        'status': 'draft', // This should be invalid
        'processing_status': 'completed',
        'merchant': 'Test Merchant',
        'total': 25.50,
        'currency': 'MYR',
        'is_expense': true,
        'is_reimbursable': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // This should throw an exception because 'draft' is not a valid status
      expect(() {
        ReceiptModel.fromJson(testReceiptData);
      }, throwsA(isA<ArgumentError>()));
    });

    test('should verify both valid status values work', () {
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
          'merchant': 'Test Merchant',
          'total': 25.50,
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
}
