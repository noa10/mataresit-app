import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mataresit_app/core/services/offline_database_service.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';

void main() {
  group('OfflineDatabaseService', () {
    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      await OfflineDatabaseService.initialize();
    });

    tearDownAll(() async {
      await OfflineDatabaseService.close();
    });

    setUp(() async {
      // Clear data before each test
      await OfflineDatabaseService.clearAllData();
    });

    group('Receipt Operations', () {
      test('should save and retrieve receipt', () async {
        // Arrange
        final receipt = ReceiptModel(
          id: 'test-receipt-1',
          userId: 'test-user',
          merchantName: 'Test Store',
          totalAmount: 25.99,
          currency: 'USD',
          status: ReceiptStatus.reviewed,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await OfflineDatabaseService.saveReceipt(receipt);
        final retrievedReceipt = OfflineDatabaseService.getReceipt(
          'test-receipt-1',
        );

        // Assert
        expect(retrievedReceipt, isNotNull);
        expect(retrievedReceipt!.id, equals('test-receipt-1'));
        expect(retrievedReceipt.merchantName, equals('Test Store'));
        expect(retrievedReceipt.totalAmount, equals(25.99));
      });

      test('should return null for non-existent receipt', () {
        // Act
        final receipt = OfflineDatabaseService.getReceipt('non-existent');

        // Assert
        expect(receipt, isNull);
      });

      test('should get all receipts', () async {
        // Arrange
        final receipt1 = ReceiptModel(
          id: 'receipt-1',
          userId: 'test-user',
          merchantName: 'Store 1',
          totalAmount: 10.0,
          currency: 'USD',
          status: ReceiptStatus.reviewed,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final receipt2 = ReceiptModel(
          id: 'receipt-2',
          userId: 'test-user',
          merchantName: 'Store 2',
          totalAmount: 20.0,
          currency: 'USD',
          status: ReceiptStatus.unreviewed,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await OfflineDatabaseService.saveReceipt(receipt1);
        await OfflineDatabaseService.saveReceipt(receipt2);
        final receipts = OfflineDatabaseService.getAllReceipts();

        // Assert
        expect(receipts.length, equals(2));
        expect(receipts.any((r) => r.id == 'receipt-1'), isTrue);
        expect(receipts.any((r) => r.id == 'receipt-2'), isTrue);
      });

      test('should delete receipt', () async {
        // Arrange
        final receipt = ReceiptModel(
          id: 'test-receipt',
          userId: 'test-user',
          merchantName: 'Test Store',
          totalAmount: 15.0,
          currency: 'USD',
          status: ReceiptStatus.reviewed,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await OfflineDatabaseService.saveReceipt(receipt);

        // Act
        await OfflineDatabaseService.deleteReceipt('test-receipt');
        final retrievedReceipt = OfflineDatabaseService.getReceipt(
          'test-receipt',
        );

        // Assert
        expect(retrievedReceipt, isNull);
      });
    });

    group('Sync Queue Operations', () {
      test('should add and retrieve sync operations', () async {
        // Arrange
        final data = {
          'id': 'test-receipt',
          'merchantName': 'Test Store',
          'totalAmount': 25.99,
        };

        // Act
        await OfflineDatabaseService.addToSyncQueue(
          operation: 'create',
          entityType: 'receipt',
          entityId: 'test-receipt',
          data: data,
        );

        final operations = OfflineDatabaseService.getPendingSyncOperations();

        // Assert
        expect(operations.length, equals(1));
        expect(operations.first['operation'], equals('create'));
        expect(operations.first['entityType'], equals('receipt'));
        expect(operations.first['entityId'], equals('test-receipt'));
      });

      test('should remove sync operation', () async {
        // Arrange
        await OfflineDatabaseService.addToSyncQueue(
          operation: 'create',
          entityType: 'receipt',
          entityId: 'test-receipt',
          data: {'test': 'data'},
        );

        final operations = OfflineDatabaseService.getPendingSyncOperations();
        final syncId = operations.first['id'] as String;

        // Act
        await OfflineDatabaseService.removeFromSyncQueue(syncId);
        final updatedOperations =
            OfflineDatabaseService.getPendingSyncOperations();

        // Assert
        expect(updatedOperations.length, equals(0));
      });

      test('should update retry count', () async {
        // Arrange
        await OfflineDatabaseService.addToSyncQueue(
          operation: 'create',
          entityType: 'receipt',
          entityId: 'test-receipt',
          data: {'test': 'data'},
        );

        final operations = OfflineDatabaseService.getPendingSyncOperations();
        final syncId = operations.first['id'] as String;

        // Act
        await OfflineDatabaseService.updateSyncRetryCount(syncId, 2);
        final updatedOperations =
            OfflineDatabaseService.getPendingSyncOperations();

        // Assert
        expect(updatedOperations.first['retryCount'], equals(2));
      });
    });

    group('Settings Operations', () {
      test('should save and retrieve settings', () async {
        // Act
        await OfflineDatabaseService.saveSetting('test_key', 'test_value');
        final value = OfflineDatabaseService.getSetting<String>('test_key');

        // Assert
        expect(value, equals('test_value'));
      });

      test('should return default value for non-existent setting', () {
        // Act
        final value = OfflineDatabaseService.getSetting<String>(
          'non_existent',
          'default',
        );

        // Assert
        expect(value, equals('default'));
      });
    });

    group('Storage Statistics', () {
      test('should return storage stats', () async {
        // Arrange
        final receipt = ReceiptModel(
          id: 'test-receipt',
          userId: 'test-user',
          merchantName: 'Test Store',
          totalAmount: 15.0,
          currency: 'USD',
          status: ReceiptStatus.reviewed,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await OfflineDatabaseService.saveReceipt(receipt);
        await OfflineDatabaseService.saveSetting('test_setting', 'value');

        // Act
        final stats = OfflineDatabaseService.getStorageStats();

        // Assert
        expect(stats['receipts'], equals(1));
        expect(stats['settings'], equals(1));
        expect(stats['teams'], equals(0));
        expect(stats['users'], equals(0));
        expect(stats['syncQueue'], equals(0));
      });
    });
  });
}
