import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/receipts/providers/batch_upload_provider.dart';
import 'package:mataresit_app/features/receipts/models/batch_upload_models.dart';

void main() {
  group('BatchUploadTimeouts', () {
    test('should have reasonable timeout values', () {
      // Test that timeout values are reasonable for batch processing
      expect(BatchUploadTimeouts.functionCallTimeout.inMinutes, equals(3));
      expect(BatchUploadTimeouts.totalItemTimeout.inMinutes, equals(10));
      expect(BatchUploadTimeouts.waitForCompletionTimeout.inMinutes, equals(8));
      expect(BatchUploadTimeouts.progressStuckTimeout.inSeconds, equals(45));
      expect(BatchUploadTimeouts.maxProcessingTimeout.inMinutes, equals(8));
      expect(BatchUploadTimeouts.maxAutoRetries, equals(3));
    });

    test('function call timeout should be longer than original 30 seconds', () {
      const originalTimeout = Duration(seconds: 30);
      expect(
        BatchUploadTimeouts.functionCallTimeout.inSeconds,
        greaterThan(originalTimeout.inSeconds),
      );
    });

    test('total timeout should be longer than function call timeout', () {
      expect(
        BatchUploadTimeouts.totalItemTimeout.inSeconds,
        greaterThan(BatchUploadTimeouts.functionCallTimeout.inSeconds),
      );
    });
  });

  group('BatchUploadItem retry functionality', () {
    test('should initialize with zero retry count', () {
      final item = BatchUploadItem(
        id: 'test-id',
        file: MockFile(),
        fileName: 'test.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
      );

      expect(item.retryCount, equals(0));
    });

    test('should update retry count with copyWith', () {
      final item = BatchUploadItem(
        id: 'test-id',
        file: MockFile(),
        fileName: 'test.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
      );

      final updatedItem = item.copyWith(retryCount: 2);
      expect(updatedItem.retryCount, equals(2));
      expect(item.retryCount, equals(0)); // Original should be unchanged
    });

    test('should include retry count in equality comparison', () {
      final baseTime = DateTime.now();
      final item1 = BatchUploadItem(
        id: 'test-id',
        file: MockFile(),
        fileName: 'test.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
        createdAt: baseTime,
        retryCount: 0,
      );

      final item2 = BatchUploadItem(
        id: 'test-id',
        file: MockFile(),
        fileName: 'test.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
        createdAt: baseTime,
        retryCount: 1,
      );

      expect(item1, isNot(equals(item2)));
    });
  });

  group('BatchProcessingStage', () {
    test('should include retrying stage', () {
      expect(
        BatchProcessingStage.values,
        contains(BatchProcessingStage.retrying),
      );
    });

    test('retrying stage should have correct description', () {
      final item = BatchUploadItem(
        id: 'test-id',
        file: MockFile(),
        fileName: 'test.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
        currentStage: BatchProcessingStage.retrying,
      );

      expect(item.stageDescription, equals('Retrying processing...'));
    });
  });
}

// Mock File class for testing
class MockFile implements File {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
