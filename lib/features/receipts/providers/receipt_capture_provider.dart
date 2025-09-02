import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/ai_vision_service_manager.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../teams/providers/teams_provider.dart';

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
      
      ReceiptData extractedData;
      try {
        // Check if any AI vision service is configured
        if (!AIVisionServiceManager.hasConfiguredServices()) {
          throw Exception('No AI vision services are configured. Please check your API keys (GEMINI_API_KEY or OPENROUTER_API_KEY).');
        }

        extractedData = await AIVisionServiceManager.processReceiptImage(imageFile);
        
        // Log the extraction results
        AppLogger.info('Receipt processing completed', {
          'confidence': extractedData.confidence,
          'hasError': extractedData.hasError,
          'merchantName': extractedData.merchantName,
          'totalAmount': extractedData.totalAmount,
          'lineItemsCount': extractedData.items?.length ?? 0,
        });
        
        // If there's an error in processing, throw an exception
        if (extractedData.hasError) {
          throw Exception(extractedData.error ?? 'Unknown processing error');
        }
        
        // Log successful extraction
        AppLogger.info('AI extraction successful', {
          'merchant': extractedData.merchantName,
          'amount': extractedData.totalAmount,
          'confidence': extractedData.confidence,
          'lineItems': extractedData.items?.map((item) => {
            'name': item.name,
            'totalPrice': item.totalPrice,
          }).toList() ?? [],
        });
        
      } catch (e) {
        AppLogger.error('Gemini Vision processing failed', e);
        
        // Provide more specific error messages
        String errorMessage = 'AI processing failed';
        if (e.toString().contains('API key') || e.toString().contains('not configured')) {
          errorMessage = 'AI vision services not configured. Please set GEMINI_API_KEY or OPENROUTER_API_KEY environment variable.';
        } else if (e.toString().contains('UnsupportedUserLocation') || e.toString().contains('geographic restriction') || e.toString().contains('not available in your region')) {
          errorMessage = 'AI vision services are not available in your region. Fallback services were attempted but also failed.';
        } else if (e.toString().contains('quota') || e.toString().contains('limit')) {
          errorMessage = 'AI service quotas exceeded. Please try again later.';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('image')) {
          errorMessage = 'Image processing failed. Please try with a clearer image.';
        }
        
        state = state.copyWith(
          isLoading: false,
          isProcessing: false,
          error: '$errorMessage: ${e.toString()}',
          processingStep: null,
        );
        rethrow;
      }

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
        bucket: AppConstants.receiptImagesBucket,
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
    // Get current team for team_id
    final currentTeamState = ref.read(currentTeamProvider);

    final receiptData = {
      'id': receipt.id,
      'user_id': receipt.userId,
      'team_id': currentTeamState.currentTeam?.id,
      'merchant': receipt.merchantName ?? 'Unknown Merchant',
      'date': receipt.transactionDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
      'total': receipt.totalAmount ?? 0.0,
      'tax': receipt.taxAmount,
      'currency': receipt.currency ?? 'USD',
      'payment_method': receipt.paymentMethod,
      'predicted_category': receipt.category,
      'status': receipt.status.name,
      'image_url': receipt.imageUrl,
      'fullText': receipt.notes,
      'ai_suggestions': receipt.ocrData,
      'confidence_scores': state.extractedData?.confidence != null ? {
        'merchant': (state.extractedData!.confidence * 100).round(),
        'date': (state.extractedData!.confidence * 100).round(),
        'total': (state.extractedData!.confidence * 100).round(),
        'tax': (state.extractedData!.confidence * 100).round(),
        'payment_method': (state.extractedData!.confidence * 100).round(),
        'line_items': (state.extractedData!.confidence * 100).round(),
      } : null,
      'processing_status': receipt.processingStatus.name,
      'created_at': receipt.createdAt.toIso8601String(),
      'updated_at': receipt.updatedAt.toIso8601String(),
    };

    // Insert receipt first
    await SupabaseService.client
        .from('receipts')
        .insert(receiptData);

    // Insert line items if available from extracted data
    final extractedData = state.extractedData;
    if (extractedData?.items != null && extractedData!.items!.isNotEmpty) {
      AppLogger.info('Saving ${extractedData.items!.length} line items to database');

      final lineItemsData = extractedData.items!.map((item) {
        return {
          'receipt_id': receipt.id,
          'description': item.name,
          'amount': item.totalPrice ?? item.unitPrice ?? 0.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).where((item) =>
        // Filter out invalid line items
        item['description'] != null &&
        (item['description'] as String).trim().isNotEmpty &&
        (item['amount'] as double) > 0
      ).toList();

      if (lineItemsData.isNotEmpty) {
        try {
          await SupabaseService.client
              .from('line_items')
              .insert(lineItemsData);

          AppLogger.info('Successfully saved ${lineItemsData.length} line items');
        } catch (e) {
          AppLogger.error('Failed to save line items', e);
          // Don't fail the whole operation, just log the error
        }
      } else {
        AppLogger.warning('No valid line items to save after filtering');
      }
    } else {
      AppLogger.info('No line items extracted from AI vision processing');
    }
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
