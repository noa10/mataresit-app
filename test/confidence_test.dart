import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/shared/utils/confidence_utils.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';

void main() {
  group('ConfidenceUtils Tests', () {
    test('should correctly read confidence from ai_suggestions field', () {
      // Test case 1: Direct confidence from ai_suggestions (decimal format)
      final receipt1 = ReceiptModel(
        id: 'test1',
        userId: 'user1',
        status: ReceiptStatus.reviewed,
        processingStatus: ProcessingStatus.completed,
        isExpense: true,
        isReimbursable: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        aiSuggestions: {
          'confidence': 0.95, // 95% confidence as decimal
        },
      );

      final confidence1 = ConfidenceUtils.calculateAggregateConfidence(
        receipt1,
      );
      expect(confidence1, equals(95.0));

      // Test case 2: Direct confidence from ai_suggestions (percentage format)
      final receipt2 = ReceiptModel(
        id: 'test2',
        userId: 'user2',
        status: ReceiptStatus.unreviewed,
        processingStatus: ProcessingStatus.completed,
        isExpense: true,
        isReimbursable: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        aiSuggestions: {
          'confidence': 85, // 85% confidence as percentage
        },
      );

      final confidence2 = ConfidenceUtils.calculateAggregateConfidence(
        receipt2,
      );
      expect(confidence2, equals(85.0));
    });

    test(
      'should fallback to confidence_scores when ai_suggestions.confidence is not available',
      () {
        final receipt = ReceiptModel(
          id: 'test3',
          userId: 'user3',
          status: ReceiptStatus.reviewed,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          confidenceScores: {
            'merchant': 90.0,
            'date': 85.0,
            'total': 95.0,
            'payment_method': 80.0,
            'tax': 75.0,
          },
        );

        final confidence = ConfidenceUtils.calculateAggregateConfidence(
          receipt,
        );
        // Expected: (90*0.3 + 85*0.2 + 95*0.3 + 80*0.1 + 75*0.1) = 88.5, but rounded to 88.0
        expect(confidence, closeTo(88.0, 1.0));
      },
    );

    test('should return 0 when no confidence data is available', () {
      final receipt = ReceiptModel(
        id: 'test4',
        userId: 'user4',
        status: ReceiptStatus.unreviewed,
        processingStatus: ProcessingStatus.completed,
        isExpense: true,
        isReimbursable: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final confidence = ConfidenceUtils.calculateAggregateConfidence(receipt);
      expect(confidence, equals(0.0));
    });

    test('should normalize confidence values correctly', () {
      // Test decimal to percentage conversion
      expect(ConfidenceUtils.normalizeConfidence(0.85), equals(85.0));

      // Test percentage values (already normalized)
      expect(ConfidenceUtils.normalizeConfidence(85.0), equals(85.0));

      // Test null values
      expect(ConfidenceUtils.normalizeConfidence(null), equals(50.0));

      // Test clamping
      expect(ConfidenceUtils.normalizeConfidence(150.0), equals(100.0));
      expect(ConfidenceUtils.normalizeConfidence(-10.0), equals(0.0));
    });

    test('should get correct confidence colors', () {
      expect(
        ConfidenceUtils.getConfidenceColor(95.0),
        equals(ConfidenceColor.high),
      );
      expect(
        ConfidenceUtils.getConfidenceColor(70.0),
        equals(ConfidenceColor.medium),
      );
      expect(
        ConfidenceUtils.getConfidenceColor(45.0),
        equals(ConfidenceColor.low),
      );
    });
  });
}
