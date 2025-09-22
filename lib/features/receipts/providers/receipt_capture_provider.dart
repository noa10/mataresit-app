import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/ai_vision_service.dart';
import '../../../core/services/performance_service.dart';

import '../../../core/services/processing_logs_service.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/processing_log_model.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../teams/providers/teams_provider.dart';

/// Receipt capture state with enhanced processing tracking
class ReceiptCaptureState {
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final ReceiptModel? uploadedReceipt;
  final ReceiptData? extractedData;
  final String? processingStep;

  // Enhanced processing fields
  final ReceiptUploadState? uploadState;
  final List<ProcessingLogModel> processLogs;
  final String? currentStage;
  final List<String> stageHistory;
  final int uploadProgress;
  final DateTime? startTime;
  final bool isProgressUpdating;

  const ReceiptCaptureState({
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.uploadedReceipt,
    this.extractedData,
    this.processingStep,
    this.uploadState,
    this.processLogs = const [],
    this.currentStage,
    this.stageHistory = const [],
    this.uploadProgress = 0,
    this.startTime,
    this.isProgressUpdating = false,
  });

  ReceiptCaptureState copyWith({
    bool? isLoading,
    bool? isProcessing,
    String? error,
    ReceiptModel? uploadedReceipt,
    ReceiptData? extractedData,
    String? processingStep,
    ReceiptUploadState? uploadState,
    List<ProcessingLogModel>? processLogs,
    String? currentStage,
    List<String>? stageHistory,
    int? uploadProgress,
    DateTime? startTime,
    bool? isProgressUpdating,
  }) {
    return ReceiptCaptureState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      uploadedReceipt: uploadedReceipt ?? this.uploadedReceipt,
      extractedData: extractedData ?? this.extractedData,
      processingStep: processingStep ?? this.processingStep,
      uploadState: uploadState ?? this.uploadState,
      processLogs: processLogs ?? this.processLogs,
      currentStage: currentStage ?? this.currentStage,
      stageHistory: stageHistory ?? this.stageHistory,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      startTime: startTime ?? this.startTime,
      isProgressUpdating: isProgressUpdating ?? this.isProgressUpdating,
    );
  }
}

/// Receipt capture notifier with enhanced processing tracking
class ReceiptCaptureNotifier extends StateNotifier<ReceiptCaptureState> {
  final Ref ref;
  Timer? _progressTimer;
  final ProcessingLogsService _logsService = ProcessingLogsService();
  StreamSubscription? _logsSubscription;
  bool _disposed = false;
  Timer? _processingTimeoutTimer;
  Timer? _autoResetTimer;
  final Map<String, StreamSubscription> _realtimeSubscriptions = {};

  ReceiptCaptureNotifier(this.ref) : super(const ReceiptCaptureState());

  @override
  void dispose() {
    _disposed = true;
    _progressTimer?.cancel();
    _logsSubscription?.cancel();
    _processingTimeoutTimer?.cancel();
    _autoResetTimer?.cancel();

    // Cancel all realtime subscriptions
    for (final subscription in _realtimeSubscriptions.values) {
      subscription.cancel();
    }
    _realtimeSubscriptions.clear();

    super.dispose();
  }

  /// Check if the provider is disposed before using ref
  bool get isDisposed => _disposed;

  /// Add a processing log entry
  void _addLog(
    String stepName,
    String message, {
    int? progress,
    String? receiptId,
  }) {
    final log = ProcessingLogModel(
      id: const Uuid().v4(),
      receiptId: receiptId ?? 'pending',
      createdAt: DateTime.now(),
      statusMessage: message,
      stepName: stepName,
      progress: progress,
    );

    final updatedLogs = [...state.processLogs, log];
    state = state.copyWith(
      processLogs: updatedLogs,
      currentStage: stepName,
      isProgressUpdating: true,
    );

    // Update stage history if this is a new stage
    if (!state.stageHistory.contains(stepName)) {
      final updatedHistory = [...state.stageHistory, stepName];
      state = state.copyWith(stageHistory: updatedHistory);
    }

    // Save to real-time service if receipt ID is available
    if (receiptId != null && receiptId != 'pending') {
      // Check authentication before attempting database operations
      final user = ref.read(currentUserProvider);
      final currentUser = SupabaseService.currentUser;
      final session = SupabaseService.client.auth.currentSession;

      AppLogger.info('Processing log auth check', {
        'stepName': stepName,
        'receiptId': receiptId,
        'hasProviderUser': user != null,
        'hasSupabaseUser': currentUser != null,
        'hasSession': session != null,
        'userIdMatch': user?.id == currentUser?.id,
      });

      _logsService.addLocalLog(
        receiptId,
        stepName,
        message,
        progress: progress,
      );

      // Only attempt database save if properly authenticated and not an early step
      if (user != null && currentUser != null && session != null) {
        // Skip database saves for early steps that happen before receipt creation
        final shouldSkip = ['START', 'FETCH', 'SAVE'].contains(stepName);
        _logsService.saveProcessingLog(
          receiptId,
          stepName,
          message,
          progress: progress,
          forceSkip: shouldSkip,
        );
      } else {
        AppLogger.warning(
          'Skipping database save for processing log - authentication issue',
          {
            'stepName': stepName,
            'receiptId': receiptId,
            'hasProviderUser': user != null,
            'hasSupabaseUser': currentUser != null,
            'hasSession': session != null,
          },
        );
      }
    }

    // Auto-stop progress updating after a delay
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = state.copyWith(isProgressUpdating: false);
      }
    });
  }

  /// Update upload progress
  void _updateProgress(int progress, {String? message}) {
    state = state.copyWith(uploadProgress: progress, isProgressUpdating: true);

    if (message != null) {
      _addLog(state.currentStage ?? 'PROCESSING', message, progress: progress);
    }
  }

  /// Start processing with initial setup
  void _startProcessing() {
    final uploadState = ReceiptUploadState(
      id: const Uuid().v4(),
      status: 'uploading',
      startTime: DateTime.now(),
    );

    state = state.copyWith(
      uploadState: uploadState,
      startTime: DateTime.now(),
      currentStage: 'START',
      stageHistory: ['START'],
      uploadProgress: 0,
      processLogs: [],
    );

    _addLog('START', 'Initializing receipt upload...');
  }

  /// Upload receipt image and create receipt record with AI processing
  Future<void> uploadReceipt(File imageFile) async {
    try {
      // Initialize processing state
      _startProcessing();

      state = state.copyWith(
        isLoading: true,
        isProcessing: true,
        error: null,
        processingStep: 'Initializing...',
      );

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Upload image to Supabase Storage first
      _addLog('FETCH', 'Starting file upload to cloud storage...');
      _updateProgress(10, message: 'Uploading image to cloud storage...');

      final uuid = const Uuid();
      final receiptId = uuid.v4();
      final fileExtension = path.extension(imageFile.path);

      // Use timestamp-based filename to match React app behavior and avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileId = receiptId.substring(
        0,
        8,
      ); // Use first 8 chars of UUID as fileId
      final fileName = '${timestamp}_$fileId$fileExtension';
      final filePath = '${user.id}/$fileName';

      // Optimize image before upload (match React app behavior)
      _updateProgress(15, message: 'Optimizing image...');
      final optimizedFile = await PerformanceService.optimizeImageForUpload(
        imageFile,
      );

      final imageBytes = await optimizedFile.readAsBytes();

      _updateProgress(25, message: 'Upload progress: 25% complete');
      final imageUrl = await SupabaseService.uploadFile(
        bucket: AppConstants.receiptImagesBucket,
        path: filePath,
        bytes: Uint8List.fromList(imageBytes),
        contentType:
            'image/jpeg', // Always JPEG after optimization (match React app)
      );

      _addLog('FETCH', 'Image uploaded successfully', receiptId: receiptId);
      _updateProgress(40, message: 'Image upload completed');

      // Step 2: Create initial receipt record
      state = state.copyWith(processingStep: 'Creating receipt record...');
      _addLog(
        'SAVE',
        'Creating initial receipt record...',
        receiptId: receiptId,
      );

      // Get current team for team_id
      final currentTeamState = ref.read(currentTeamProvider);

      // Create initial receipt record with required fields
      final initialReceiptData = {
        'id': receiptId,
        'user_id': user.id,
        'team_id': currentTeamState.currentTeam?.id,
        'image_url': imageUrl,
        'status': 'unreviewed',
        'processing_status': 'processing',
        // Required fields with temporary values (will be updated by AI processing)
        'merchant': 'Processing...',
        'date': DateTime.now().toIso8601String().split(
          'T',
        )[0], // Today's date as default
        'total': 0.0, // Will be updated by AI processing
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client.from('receipts').insert(initialReceiptData);

      _addLog('SAVE', 'Initial receipt record created', receiptId: receiptId);
      _updateProgress(50, message: 'Receipt record created');

      // Step 3: Call process-receipt edge function for AI processing and embedding generation
      state = state.copyWith(processingStep: 'Processing with AI...');
      _addLog(
        'PROCESSING',
        'Starting AI processing with edge function...',
        receiptId: receiptId,
      );
      _updateProgress(60, message: 'Starting AI analysis...');

      try {
        final response = await SupabaseService.client.functions.invoke(
          'process-receipt',
          body: {
            'receiptId': receiptId,
            'imageUrl': imageUrl,
            'modelId': 'gemini-2.5-flash-lite', // Match React app default model
          },
        );

        final responseData = response.data;
        if (responseData == null || responseData['success'] != true) {
          throw Exception(
            'Processing failed: ${responseData?['error'] ?? 'Unknown error'}',
          );
        }

        _addLog(
          'PROCESSING',
          'AI processing completed successfully',
          receiptId: receiptId,
        );
        _updateProgress(85, message: 'AI processing completed');

        // Extract the processed data from the response
        final result = responseData['result'];
        if (result != null) {
          // Create a ReceiptData object from the processed result for UI display
          final extractedData = ReceiptData(
            merchantName: result['merchant']?.toString(),
            totalAmount: _parseDouble(result['total']),
            transactionDate: result['date'] != null
                ? DateTime.tryParse(result['date'])
                : null,
            currency: result['currency']?.toString() ?? 'MYR',
            paymentMethod: result['payment_method']?.toString(),
            category: result['predicted_category']?.toString(),
            notes: result['fullText']?.toString(),
            confidence: _parseDouble(result['confidence']?['total']) ?? 0.8,
            rawResponse: responseData.toString(),
          );

          state = state.copyWith(extractedData: extractedData);

          AppLogger.info('Receipt processing completed via edge function', {
            'receiptId': receiptId,
            'merchant': extractedData.merchantName,
            'amount': extractedData.totalAmount,
            'confidence': extractedData.confidence,
          });
        }
      } catch (e) {
        _addLog('ERROR', 'Edge function processing failed: ${e.toString()}');
        AppLogger.error('Process-receipt edge function failed', e);

        // Enhanced error categorization and user-friendly messages
        String errorMessage = 'AI processing failed';
        String errorCategory = 'unknown';

        final errorString = e.toString().toLowerCase();

        if (errorString.contains('api key') ||
            errorString.contains('not configured') ||
            errorString.contains('unauthorized')) {
          errorMessage =
              'AI vision services not configured on server. Please contact support.';
          errorCategory = 'configuration';
        } else if (errorString.contains('quota') ||
            errorString.contains('limit') ||
            errorString.contains('rate limit')) {
          errorMessage = 'AI service quotas exceeded. Please try again later.';
          errorCategory = 'quota';
        } else if (errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('fetch')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
          errorCategory = 'network';
        } else if (errorString.contains('timeout') ||
            errorString.contains('time out')) {
          errorMessage =
              'Processing timeout. Please try again with a smaller or clearer image.';
          errorCategory = 'timeout';
        } else if (errorString.contains('image') ||
            errorString.contains('format') ||
            errorString.contains('invalid')) {
          errorMessage =
              'Image processing failed. Please try with a different image format or clearer photo.';
          errorCategory = 'image';
        } else if (errorString.contains('server') ||
            errorString.contains('internal') ||
            errorString.contains('500')) {
          errorMessage =
              'Server error occurred. Please try again in a few moments.';
          errorCategory = 'server';
        } else if (errorString.contains('function') ||
            errorString.contains('edge')) {
          errorMessage =
              'Processing service temporarily unavailable. Please try again.';
          errorCategory = 'service';
        }

        // Log detailed error information for debugging
        AppLogger.error('Receipt processing failed', {
          'error': e.toString(),
          'category': errorCategory,
          'receiptId': receiptId,
          'userMessage': errorMessage,
        });

        state = state.copyWith(
          isLoading: false,
          isProcessing: false,
          error: errorMessage,
          processingStep: null,
          currentStage: 'ERROR',
          uploadProgress: 100,
        );
        rethrow;
      }

      state = state.copyWith(processingStep: 'Finalizing...');

      // Step 4: Set up real-time subscription to listen for processing completion
      _updateProgress(90, message: 'Waiting for processing completion...');
      _addLog(
        'PROCESSING',
        'Setting up real-time subscription for processing updates...',
        receiptId: receiptId,
      );

      // Subscribe to receipt updates for processing status changes
      await _subscribeToProcessingUpdates(
        receiptId,
        imageFile,
        imageBytes,
        imageUrl,
      );
    } catch (e) {
      _addLog('ERROR', 'Processing failed: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
        error: e.toString(),
        processingStep: null,
        currentStage: 'ERROR',
        uploadProgress: 100,
      );
      rethrow;
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

  /// Subscribe to real-time processing updates
  Future<void> _subscribeToProcessingUpdates(
    String receiptId,
    File imageFile,
    Uint8List imageBytes,
    String imageUrl,
  ) async {
    try {
      // Set up real-time subscription for receipt processing status updates
      final channel = SupabaseService.client
          .channel('receipt-processing-$receiptId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'receipts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: receiptId,
            ),
            callback: (payload) {
              _handleProcessingStatusUpdate(
                payload.newRecord,
                receiptId,
                imageFile,
                imageBytes,
                imageUrl,
              );
            },
          )
          .subscribe();

      // Set a timeout for processing completion (5 minutes max)
      _processingTimeoutTimer = Timer(const Duration(minutes: 5), () {
        if (!_disposed) {
          _addLog(
            'WARNING',
            'Processing timeout reached, checking final status...',
            receiptId: receiptId,
          );
          _finalizeProcessing(receiptId, imageFile, imageBytes, imageUrl);
          SupabaseService.client.removeChannel(channel);
        }
      });
    } catch (e) {
      _addLog(
        'ERROR',
        'Failed to set up real-time subscription: ${e.toString()}',
      );
      AppLogger.error('Real-time subscription failed', {
        'error': e.toString(),
        'receiptId': receiptId,
        'fallbackMethod': 'polling',
      });

      // Fallback to polling with user notification
      _addLog(
        'INFO',
        'Falling back to polling method for status updates...',
        receiptId: receiptId,
      );
      await _fallbackToPolling(receiptId, imageFile, imageBytes, imageUrl);
    }
  }

  /// Handle processing status updates from real-time subscription
  void _handleProcessingStatusUpdate(
    Map<String, dynamic> newData,
    String receiptId,
    File imageFile,
    Uint8List imageBytes,
    String imageUrl,
  ) {
    try {
      if (newData.isEmpty) return;

      final processingStatus = newData['processing_status']?.toString();
      final processingError = newData['processing_error']?.toString();

      _addLog(
        'UPDATE',
        'Processing status updated: $processingStatus',
        receiptId: receiptId,
      );

      if (processingError != null && processingError.isNotEmpty) {
        _addLog(
          'ERROR',
          'Processing error: $processingError',
          receiptId: receiptId,
        );
        _handleProcessingError(
          processingError,
          receiptId,
          imageFile,
          imageBytes,
          imageUrl,
        );
        return;
      }

      switch (processingStatus?.toLowerCase()) {
        case 'processing':
          _updateProgress(95, message: 'AI processing in progress...');
          state = state.copyWith(
            processingStep: 'AI processing in progress...',
          );
          break;
        case 'complete':
        case 'completed':
          _addLog(
            'SUCCESS',
            'Processing completed successfully!',
            receiptId: receiptId,
          );
          _finalizeProcessing(receiptId, imageFile, imageBytes, imageUrl);
          break;
        case 'failed':
        case 'failed_ai':
        case 'failed_ocr':
          _addLog(
            'ERROR',
            'Processing failed with status: $processingStatus',
            receiptId: receiptId,
          );
          _handleProcessingError(
            'Processing failed',
            receiptId,
            imageFile,
            imageBytes,
            imageUrl,
          );
          break;
      }
    } catch (e) {
      _addLog('ERROR', 'Error handling status update: ${e.toString()}');
      AppLogger.error('Error handling processing status update', e);
    }
  }

  /// Finalize processing by fetching the completed receipt
  Future<void> _finalizeProcessing(
    String receiptId,
    File imageFile,
    Uint8List imageBytes,
    String imageUrl,
  ) async {
    try {
      // Check if disposed before proceeding
      if (_disposed) {
        _addLog('WARNING', 'Provider disposed, skipping finalization');
        return;
      }

      _updateProgress(98, message: 'Fetching processed receipt...');
      _addLog(
        'FETCH',
        'Fetching processed receipt from database...',
        receiptId: receiptId,
      );

      final response = await SupabaseService.client
          .from('receipts')
          .select('*')
          .eq('id', receiptId)
          .single();

      final receiptData = response;

      // Check if disposed before using ref
      if (_disposed) {
        _addLog('WARNING', 'Provider disposed during finalization');
        return;
      }

      final user = ref.read(currentUserProvider);

      // Create receipt model from the processed data
      final receipt = ReceiptModel(
        id: receiptId,
        userId: user!.id,
        merchantName: receiptData['merchant']?.toString() ?? 'Unknown Merchant',
        merchantAddress: null, // Not available from edge function
        merchantPhone: null, // Not available from edge function
        receiptNumber: null, // Not available from edge function
        transactionDate: receiptData['date'] != null
            ? DateTime.tryParse(receiptData['date'])
            : null,
        totalAmount: _parseAmount(receiptData['total']) ?? 0.0,
        taxAmount: _parseAmount(receiptData['tax']),
        discountAmount: null, // Not available from edge function
        tipAmount: null, // Not available from edge function
        currency: receiptData['currency']?.toString() ?? 'MYR',
        paymentMethod: receiptData['payment_method']?.toString(),
        category: receiptData['predicted_category']?.toString(),
        notes: receiptData['fullText']?.toString(),
        imageUrl: imageUrl,
        originalFileName: path.basename(imageFile.path),
        fileSize: imageBytes.length,
        mimeType: _getContentType(path.extension(imageFile.path)),
        status: ReceiptStatus.unreviewed,
        processingStatus: _mapProcessingStatusFromString(
          receiptData['processing_status']?.toString() ?? 'completed',
        ),
        ocrData: receiptData['ai_suggestions'] ?? {},
        isExpense: true,
        isReimbursable: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        processedAt: DateTime.now(),
      );

      _addLog(
        'SUCCESS',
        'Receipt processing completed successfully!',
        receiptId: receiptId,
      );

      // Complete processing
      _updateProgress(100, message: 'Processing completed successfully');
      _addLog(
        'COMPLETE',
        'Receipt processing completed successfully',
        receiptId: receiptId,
      );

      state = state.copyWith(
        isLoading: false,
        isProcessing: false,
        uploadedReceipt: receipt,
        processingStep: null,
        currentStage: 'COMPLETE',
        uploadProgress: 100,
      );

      // Auto-reset state after showing completion for 3 seconds
      // Use a cancellable timer instead of Future.delayed
      _autoResetTimer?.cancel(); // Cancel any existing timer
      _autoResetTimer = Timer(const Duration(seconds: 3), () {
        if (!_disposed && state.currentStage == 'COMPLETE') {
          reset();
        }
      });
    } catch (e) {
      _addLog('ERROR', 'Failed to fetch processed receipt: ${e.toString()}');
      AppLogger.error('Failed to fetch processed receipt', {
        'error': e.toString(),
        'receiptId': receiptId,
        'stage': 'finalization',
      });

      // Provide more specific error message based on the error type
      String errorMessage = 'Failed to fetch processed receipt';
      if (e.toString().toLowerCase().contains('not found')) {
        errorMessage =
            'Receipt not found in database. Processing may have failed.';
      } else if (e.toString().toLowerCase().contains('network')) {
        errorMessage =
            'Network error while fetching processed receipt. Please check your connection.';
      }

      _handleProcessingError(
        errorMessage,
        receiptId,
        imageFile,
        imageBytes,
        imageUrl,
      );
    }
  }

  /// Handle processing errors
  void _handleProcessingError(
    String error,
    String receiptId,
    File imageFile,
    Uint8List imageBytes,
    String imageUrl,
  ) {
    // Check if disposed before using ref
    if (_disposed) {
      _addLog('WARNING', 'Provider disposed, skipping error handling');
      return;
    }

    final user = ref.read(currentUserProvider);

    // Create a minimal receipt object for UI purposes
    final receipt = ReceiptModel(
      id: receiptId,
      userId: user!.id,
      merchantName: 'Processing Failed',
      transactionDate: DateTime.now(),
      totalAmount: 0.0,
      currency: 'MYR',
      imageUrl: imageUrl,
      originalFileName: path.basename(imageFile.path),
      fileSize: imageBytes.length,
      mimeType: _getContentType(path.extension(imageFile.path)),
      status: ReceiptStatus.unreviewed,
      processingStatus: ProcessingStatus.failed,
      ocrData: {},
      isExpense: true,
      isReimbursable: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      processedAt: DateTime.now(),
    );

    state = state.copyWith(
      isLoading: false,
      isProcessing: false,
      uploadedReceipt: receipt,
      error: error,
      processingStep: null,
      currentStage: 'ERROR',
      uploadProgress: 100,
    );
  }

  /// Fallback to polling if real-time subscription fails
  Future<void> _fallbackToPolling(
    String receiptId,
    File imageFile,
    Uint8List imageBytes,
    String imageUrl,
  ) async {
    _addLog(
      'INFO',
      'Using polling fallback for processing status...',
      receiptId: receiptId,
    );

    const maxAttempts = 30; // 5 minutes with 10-second intervals
    int attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 10));
      attempts++;

      try {
        final response = await SupabaseService.client
            .from('receipts')
            .select('processing_status, processing_error')
            .eq('id', receiptId)
            .single();

        final processingStatus = response['processing_status']?.toString();
        final processingError = response['processing_error']?.toString();

        _addLog(
          'POLL',
          'Polling attempt $attempts: status = $processingStatus',
          receiptId: receiptId,
        );

        if (processingError != null && processingError.isNotEmpty) {
          _handleProcessingError(
            processingError,
            receiptId,
            imageFile,
            imageBytes,
            imageUrl,
          );
          return;
        }

        if (processingStatus == 'complete' || processingStatus == 'completed') {
          await _finalizeProcessing(receiptId, imageFile, imageBytes, imageUrl);
          return;
        } else if (processingStatus?.startsWith('failed') == true) {
          _handleProcessingError(
            'Processing failed',
            receiptId,
            imageFile,
            imageBytes,
            imageUrl,
          );
          return;
        }

        // Update progress based on attempts
        final progress = 90 + (attempts * 8 ~/ maxAttempts);
        _updateProgress(
          progress,
          message: 'Processing... (attempt $attempts/$maxAttempts)',
        );
      } catch (e) {
        _addLog('WARNING', 'Polling attempt $attempts failed: ${e.toString()}');
        AppLogger.warning('Polling attempt failed', {
          'attempt': attempts,
          'maxAttempts': maxAttempts,
          'receiptId': receiptId,
          'error': e.toString(),
        });

        // If we're getting consistent errors, fail faster
        if (attempts >= 3 && e.toString().toLowerCase().contains('not found')) {
          _addLog(
            'ERROR',
            'Receipt not found after multiple attempts, stopping polling',
          );
          _handleProcessingError(
            'Receipt not found in database',
            receiptId,
            imageFile,
            imageBytes,
            imageUrl,
          );
          return;
        }
      }
    }

    // Timeout reached
    _addLog('ERROR', 'Processing timeout reached after $maxAttempts attempts');
    _handleProcessingError(
      'Processing timeout',
      receiptId,
      imageFile,
      imageBytes,
      imageUrl,
    );
  }

  /// Parse amount from dynamic value
  double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Parse double from dynamic value
  double? _parseDouble(dynamic value) {
    return _parseAmount(value);
  }

  /// Map processing status from string
  ProcessingStatus _mapProcessingStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return ProcessingStatus.processing;
      case 'completed':
      case 'complete':
        return ProcessingStatus.completed;
      case 'failed':
        return ProcessingStatus.failed;
      case 'manual_review':
      case 'manualreview':
        return ProcessingStatus.manualReview;
      default:
        return ProcessingStatus.completed;
    }
  }

  /// Reset state
  void reset() {
    state = const ReceiptCaptureState();
  }
}

/// Receipt capture provider
final receiptCaptureProvider =
    StateNotifierProvider<ReceiptCaptureNotifier, ReceiptCaptureState>((ref) {
      return ReceiptCaptureNotifier(ref);
    });
