import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/receipts/services/receipt_service.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';

void main() {
  group('ReceiptService Database Mapping', () {
    test('should validate receipt data without processing status errors', () {
      final receiptData = {
        'merchant_name': 'Test Merchant',
        'transaction_date': DateTime.now().toIso8601String(),
        'total_amount': 100.0,
        'processing_status': 'complete', // React app value - should not cause validation errors
      };

      // The validation should pass without errors (processing_status is not validated here)
      final errors = ReceiptService.validateReceiptData(receiptData);
      expect(errors.isEmpty, true);
    });

    test('should handle ProcessingStatus enum values correctly', () {
      final receiptData = {
        'merchant_name': 'Test Merchant',
        'total_amount': 100.0,
        'processing_status': ProcessingStatus.completed,
      };

      // This should not throw an exception
      expect(() => ReceiptService.validateReceiptData(receiptData), returnsNormally);
    });

    test('should validate required fields correctly', () {
      final invalidData = {
        'total_amount': 100.0,
        // Missing merchant_name
      };

      final errors = ReceiptService.validateReceiptData(invalidData);
      expect(errors.isNotEmpty, true);
      expect(errors.containsKey('merchant_name'), true);
    });

    test('should validate transaction date correctly', () {
      final invalidData = {
        'merchant_name': 'Test Merchant',
        'total_amount': 100.0,
        // Missing transaction_date
      };

      final errors = ReceiptService.validateReceiptData(invalidData);
      expect(errors.isNotEmpty, true);
      expect(errors.containsKey('transaction_date'), true);
    });

    test('should validate total amount correctly', () {
      final invalidData = {
        'merchant_name': 'Test Merchant',
        'transaction_date': DateTime.now().toIso8601String(),
        'total_amount': 0.0, // Invalid amount
      };

      final errors = ReceiptService.validateReceiptData(invalidData);
      expect(errors.isNotEmpty, true);
      expect(errors.containsKey('total_amount'), true);
    });

    test('should pass validation with valid data', () {
      final validData = {
        'merchant_name': 'Test Merchant',
        'transaction_date': DateTime.now().toIso8601String(),
        'total_amount': 100.0,
        'processing_status': 'completed',
      };

      final errors = ReceiptService.validateReceiptData(validData);
      expect(errors.isEmpty, true);
    });
  });
}
