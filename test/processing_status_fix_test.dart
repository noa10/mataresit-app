import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';

void main() {
  group('ProcessingStatus Cross-Platform Compatibility', () {
    test('should handle React app "complete" value correctly', () {
      // Simulate JSON data from database with React app's 'complete' value
      final jsonData = {
        'id': 'test-id',
        'user_id': 'test-user',
        'merchant': 'Test Merchant',
        'date': '2024-01-01',
        'total': 100.0,
        'currency': 'MYR',
        'status': 'unreviewed',
        'processing_status': 'complete', // React app value
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      // Should not throw an exception and should map 'complete' to 'completed'
      expect(() => ReceiptModel.fromJson(jsonData), returnsNormally);

      final receipt = ReceiptModel.fromJson(jsonData);
      expect(receipt.processingStatus, ProcessingStatus.completed);
    });

    test('should handle Flutter app "completed" value correctly', () {
      final jsonData = {
        'id': 'test-id',
        'user_id': 'test-user',
        'merchant': 'Test Merchant',
        'date': '2024-01-01',
        'total': 100.0,
        'currency': 'MYR',
        'status': 'unreviewed',
        'processing_status': 'completed', // Flutter app value
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final receipt = ReceiptModel.fromJson(jsonData);
      expect(receipt.processingStatus, ProcessingStatus.completed);
    });

    test('should handle all valid processing status values', () {
      final validStatuses = {
        'pending': ProcessingStatus.pending,
        'processing': ProcessingStatus.processing,
        'completed': ProcessingStatus.completed,
        'complete': ProcessingStatus.completed, // Cross-platform mapping
        'failed': ProcessingStatus.failed,
        'manual_review': ProcessingStatus.manualReview,
      };

      for (final entry in validStatuses.entries) {
        final jsonData = {
          'id': 'test-id',
          'user_id': 'test-user',
          'merchant': 'Test Merchant',
          'date': '2024-01-01',
          'total': 100.0,
          'currency': 'MYR',
          'status': 'unreviewed',
          'processing_status': entry.key,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        final receipt = ReceiptModel.fromJson(jsonData);
        expect(
          receipt.processingStatus,
          entry.value,
          reason: 'Failed for processing_status: ${entry.key}',
        );
      }
    });

    test(
      'should default to completed for unknown processing status values',
      () {
        final jsonData = {
          'id': 'test-id',
          'user_id': 'test-user',
          'merchant': 'Test Merchant',
          'date': '2024-01-01',
          'total': 100.0,
          'currency': 'MYR',
          'status': 'unreviewed',
          'processing_status': 'unknown_status',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        final receipt = ReceiptModel.fromJson(jsonData);
        expect(receipt.processingStatus, ProcessingStatus.completed);
      },
    );

    test('should handle null processing status', () {
      final jsonData = {
        'id': 'test-id',
        'user_id': 'test-user',
        'merchant': 'Test Merchant',
        'date': '2024-01-01',
        'total': 100.0,
        'currency': 'MYR',
        'status': 'unreviewed',
        'processing_status': null,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final receipt = ReceiptModel.fromJson(jsonData);
      expect(receipt.processingStatus, ProcessingStatus.completed);
    });
  });

  group('ProcessingStatusConverter', () {
    const converter = ProcessingStatusConverter();

    test('should convert enum to correct string values', () {
      expect(converter.toJson(ProcessingStatus.pending), 'pending');
      expect(converter.toJson(ProcessingStatus.processing), 'processing');
      expect(converter.toJson(ProcessingStatus.completed), 'completed');
      expect(converter.toJson(ProcessingStatus.failed), 'failed');
      expect(converter.toJson(ProcessingStatus.manualReview), 'manual_review');
    });

    test('should convert string values to correct enum values', () {
      expect(converter.fromJson('pending'), ProcessingStatus.pending);
      expect(converter.fromJson('processing'), ProcessingStatus.processing);
      expect(converter.fromJson('completed'), ProcessingStatus.completed);
      expect(
        converter.fromJson('complete'),
        ProcessingStatus.completed,
      ); // Cross-platform
      expect(converter.fromJson('failed'), ProcessingStatus.failed);
      expect(
        converter.fromJson('manual_review'),
        ProcessingStatus.manualReview,
      );
    });
  });
}
