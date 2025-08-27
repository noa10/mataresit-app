import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/gemini_vision_service.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Receipt capture state
class ReceiptCaptureState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final ReceiptModel? uploadedReceipt;
  final ReceiptData? extractedData;
  final String? processingStep;

  const ReceiptCaptureState({
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.uploadedReceipt,
    this.extractedData,
    this.processingStep,
  });

  ReceiptCaptureState copyWith({
    bool? isLoading,
    bool? isProcessing,
    String? error,
    ReceiptModel? uploadedReceipt,
    ReceiptData? extractedData,
    String? processingStep,
  }) {
    return ReceiptCaptureState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      uploadedReceipt: uploadedReceipt ?? this.uploadedReceipt,
      extractedData: extractedData ?? this.extractedData,
      processingStep: processingStep ?? this.processingStep,
    );
  }
}

/// Receipt capture notifier
class ReceiptCaptureNotifier extends StateNotifier<ReceiptCaptureState> {
  final Ref ref;

  ReceiptCaptureNotifier(this.ref) : super(const ReceiptCaptureState());

  /// Upload receipt image and create receipt record with AI processing
  Future<void> uploadReceipt(File imageFile) async {
    try {
      state = state.copyWith(
        isLoading: true,
        isProcessing: true,
        error: null,
        processingStep: 'Initializing...'
      );

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Process image with Gemini Vision
      state = state.copyWith(processingStep: 'Analyzing receipt with AI...');
      final extractedData = await GeminiVisionService.processReceiptImage(imageFile);

      state = state.copyWith(
        extractedData: extractedData,
        processingStep: 'Uploading image...'
      );

      // Step 2: Upload image to Supabase Storage
      final uuid = const Uuid();
      final receiptId = uuid.v4();
      final fileExtension = path.extension(imageFile.path);
      final fileName = 'receipt_$receiptId$fileExtension';
      final filePath = '${user.id}/$fileName';

      final imageBytes = await imageFile.readAsBytes();
      final imageUrl = await SupabaseService.uploadFile(
        bucket: 'receipt-images',
        path: filePath,
        bytes: Uint8List.fromList(imageBytes),
        contentType: _getContentType(fileExtension),
      );

      state = state.copyWith(processingStep: 'Creating receipt record...');

      // Step 3: Create receipt record with extracted data
      final receipt = ReceiptModel(
        id: receiptId,
        userId: user.id,
        merchantName: extractedData.merchantName,
        merchantAddress: extractedData.merchantAddress,
        merchantPhone: extractedData.merchantPhone,
        receiptNumber: extractedData.receiptNumber,
        transactionDate: extractedData.transactionDate,
        totalAmount: extractedData.totalAmount,
        taxAmount: extractedData.taxAmount,
        discountAmount: extractedData.discountAmount,
        tipAmount: extractedData.tipAmount,
        currency: extractedData.currency ?? 'USD',
        paymentMethod: extractedData.paymentMethod,
        category: extractedData.category,
        notes: extractedData.notes,
        imageUrl: imageUrl,
        originalFileName: path.basename(imageFile.path),
        fileSize: imageBytes.length,
        mimeType: _getContentType(fileExtension),
        status: ReceiptStatus.active,
        processingStatus: extractedData.hasError
            ? ProcessingStatus.failed
            : extractedData.isHighConfidence
                ? ProcessingStatus.completed
                : ProcessingStatus.manualReview,
        ocrData: {
          'gemini_response': extractedData.rawResponse,
          'confidence': extractedData.confidence,
          'processing_time': DateTime.now().toIso8601String(),
          'ai_model': 'gemini-1.5-flash',
        },
        isExpense: true,
        isReimbursable: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        processedAt: DateTime.now(),
      );

      // Step 4: Save receipt to database
      state = state.copyWith(processingStep: 'Saving to database...');
      try {
        await _saveReceiptToDatabase(receipt);
      } catch (e) {
        AppLogger.error('Failed to save receipt to database', e);
        // Continue anyway - we have the uploaded image and extracted data
      }

      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
        uploadedReceipt: receipt,
        processingStep: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
        error: e.toString(),
        processingStep: null,
      );
      rethrow;
    }
  }

  /// Save receipt to database
  Future<void> _saveReceiptToDatabase(ReceiptModel receipt) async {
    final receiptData = {
      'id': receipt.id,
      'user_id': receipt.userId,
      'team_id': receipt.teamId,
      'merchant_name': receipt.merchantName,
      'merchant_address': receipt.merchantAddress,
      'merchant_phone': receipt.merchantPhone,
      'merchant_email': receipt.merchantEmail,
      'receipt_number': receipt.receiptNumber,
      'transaction_date': receipt.transactionDate?.toIso8601String(),
      'total_amount': receipt.totalAmount,
      'tax_amount': receipt.taxAmount,
      'discount_amount': receipt.discountAmount,
      'tip_amount': receipt.tipAmount,
      'currency': receipt.currency,
      'payment_method': receipt.paymentMethod,
      'category': receipt.category,
      'description': receipt.description,
      'notes': receipt.notes,
      'image_url': receipt.imageUrl,
      'thumbnail_url': receipt.thumbnailUrl,
      'original_file_name': receipt.originalFileName,
      'file_size': receipt.fileSize,
      'mime_type': receipt.mimeType,
      'status': receipt.status.name,
      'processing_status': receipt.processingStatus.name,
      'ocr_data': receipt.ocrData,
      'metadata': receipt.metadata,
      'tags': receipt.tags,
      'is_expense': receipt.isExpense,
      'is_reimbursable': receipt.isReimbursable,
      'project_id': receipt.projectId,
      'client_id': receipt.clientId,
      'created_at': receipt.createdAt.toIso8601String(),
      'updated_at': receipt.updatedAt.toIso8601String(),
      'processed_at': receipt.processedAt?.toIso8601String(),
    };

    await SupabaseService.client
        .from('receipts')
        .insert(receiptData);
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const ReceiptCaptureState();
  }
}

/// Receipt capture provider
final receiptCaptureProvider = StateNotifierProvider<ReceiptCaptureNotifier, ReceiptCaptureState>((ref) {
  return ReceiptCaptureNotifier(ref);
});
