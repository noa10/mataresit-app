import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import '../models/batch_upload_models.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/performance_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/teams_provider.dart';

/// Timeout configurations for batch upload processing
class BatchUploadTimeouts {
  static const Duration functionCallTimeout = Duration(minutes: 3); // AI processing function call timeout
  static const Duration totalItemTimeout = Duration(minutes: 10); // Total timeout per item
  static const Duration waitForCompletionTimeout = Duration(minutes: 8); // Wait for completion timeout
  static const Duration progressStuckTimeout = Duration(seconds: 45); // Progress stuck timeout
  static const Duration maxProcessingTimeout = Duration(minutes: 8); // Max processing time for subscriptions
  static const int maxAutoRetries = 3; // Maximum automatic retries for timeout errors
}

/// Simple semaphore implementation for concurrency control
class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

/// Provider for batch upload functionality
final batchUploadProvider =
    StateNotifierProvider<BatchUploadNotifier, BatchUploadState>((ref) {
      return BatchUploadNotifier(ref);
    });

/// Notifier for managing batch upload state and operations
class BatchUploadNotifier extends StateNotifier<BatchUploadState> {
  final Ref _ref;
  final Logger _logger = Logger();
  Timer? _progressTimer;
  bool _disposed = false;

  // Track active subscriptions and timers for cleanup
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Timer> _itemTimers = {};

  BatchUploadNotifier(this._ref) : super(const BatchUploadState());

  @override
  void dispose() {
    _disposed = true;
    _cancelAllTimers();
    _progressTimer?.cancel();

    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    super.dispose();
  }

  /// Check if the provider is disposed before using ref
  bool get isDisposed => _disposed;

  /// Add files to the batch upload queue
  Future<void> addFiles(List<File> files) async {
    try {
      _logger.i('Adding ${files.length} files to batch upload queue');

      final newItems = <BatchUploadItem>[];
      const uuid = Uuid();

      for (final file in files) {
        // Validate file
        if (!_isValidFile(file)) {
          _logger.w('Skipping invalid file: ${file.path}');
          continue;
        }

        final fileStats = await file.stat();
        final fileName = path.basename(file.path);
        final fileExtension = path.extension(file.path).toLowerCase();

        final item = BatchUploadItem(
          id: uuid.v4(),
          file: file,
          fileName: fileName,
          fileSize: fileStats.size,
          mimeType: _getMimeType(fileExtension),
          createdAt: DateTime.now(),
        );

        newItems.add(item);
      }

      if (newItems.isNotEmpty) {
        final updatedItems = [...state.items, ...newItems];
        state = state.copyWith(
          items: updatedItems,
          status: BatchUploadStatus.ready,
        );

        _logger.i('Added ${newItems.length} valid files to batch queue');
      }
    } catch (e) {
      _logger.e('Error adding files to batch queue: $e');
      state = state.copyWith(error: 'Failed to add files: $e');
    }
  }

  /// Remove a file from the batch upload queue
  void removeFile(String itemId) {
    final updatedItems = state.items
        .where((item) => item.id != itemId)
        .toList();
    state = state.copyWith(
      items: updatedItems,
      status: updatedItems.isEmpty ? BatchUploadStatus.idle : state.status,
    );
    _logger.i('Removed file from batch queue: $itemId');
  }

  /// Clear all files from the batch upload queue
  void clearQueue() {
    // Cancel all running timers
    _cancelAllTimers();

    state = state.copyWith(
      items: [],
      status: BatchUploadStatus.idle,
      totalProgress: 0,
      error: null,
    );
    _logger.i('Cleared batch upload queue');
  }

  /// Start batch processing
  Future<void> startBatchProcessing() async {
    if (state.items.isEmpty) {
      _logger.w('No items to process in batch upload');
      return;
    }

    if (state.status == BatchUploadStatus.processing) {
      _logger.w('Batch upload already in progress');
      return;
    }

    try {
      _logger.i(
        'Starting batch upload processing for ${state.items.length} items',
      );

      state = state.copyWith(
        status: BatchUploadStatus.processing,
        startedAt: DateTime.now(),
        error: null,
      );

      // Start progress tracking
      _startProgressTracking();

      // Process items with concurrency limit
      await _processItemsConcurrently();

      // Log final statistics before marking as completed
      final stats = {
        'totalItems': state.totalItems,
        'completedCount': state.completedCount,
        'failedCount': state.failedCount,
        'activeCount': state.activeCount,
        'queuedCount': state.queuedCount,
      };
      _logger.i('📊 Batch processing finished with stats: $stats');

      // Mark as completed
      state = state.copyWith(
        status: BatchUploadStatus.completed,
        completedAt: DateTime.now(),
        totalProgress: 100,
      );

      _logger.i('✅ Batch upload processing completed successfully');
    } catch (e) {
      _logger.e('Error during batch processing: $e');
      state = state.copyWith(
        status: BatchUploadStatus
            .completed, // Still mark as completed to show results
        error: 'Batch processing error: $e',
        completedAt: DateTime.now(),
      );
    } finally {
      _progressTimer?.cancel();
    }
  }

  /// Pause batch processing
  void pauseBatchProcessing() {
    if (state.status == BatchUploadStatus.processing) {
      state = state.copyWith(status: BatchUploadStatus.paused);
      _logger.i('Batch upload processing paused');
    }
  }

  /// Resume batch processing
  Future<void> resumeBatchProcessing() async {
    if (state.status == BatchUploadStatus.paused) {
      state = state.copyWith(status: BatchUploadStatus.processing);
      _logger.i('Batch upload processing resumed');
      await _processItemsConcurrently();
    }
  }

  /// Cancel batch processing
  void cancelBatchProcessing() {
    _cancelAllTimers();
    _progressTimer?.cancel();

    // Cancel any active uploads
    final updatedItems = state.items.map((item) {
      if (item.isActive) {
        return item.copyWith(
          status: BatchUploadItemStatus.cancelled,
          completedAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    state = state.copyWith(
      items: updatedItems,
      status: BatchUploadStatus.cancelled,
      completedAt: DateTime.now(),
    );

    _logger.i('Batch upload processing cancelled');
  }

  /// Retry a failed upload
  Future<void> retryUpload(String itemId) async {
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    if (item.status != BatchUploadItemStatus.failed) return;

    // Reset the item to queued status and reset retry count for manual retry
    final updatedItem = item.copyWith(
      status: BatchUploadItemStatus.queued,
      progress: 0,
      error: null,
      startedAt: null,
      completedAt: null,
      processingLogs: [],
      retryCount: 0, // Reset retry count for manual retry
    );

    final updatedItems = [...state.items];
    updatedItems[itemIndex] = updatedItem;

    state = state.copyWith(items: updatedItems);

    // Process this single item
    await _processSingleItem(updatedItem);
  }

  /// Process items sequentially for better reliability
  Future<void> _processItemsConcurrently() async {
    final queuedItems = state.queuedItems;
    if (queuedItems.isEmpty) return;

    _logger.i(
      'Processing ${queuedItems.length} items sequentially for batch upload',
    );

    // Process items one by one to avoid overwhelming the AI service
    for (final item in queuedItems) {
      if (state.status != BatchUploadStatus.processing) {
        _logger.i('Batch upload cancelled, stopping processing');
        break;
      }

      _logger.i('Processing item: ${item.fileName}');
      await _processSingleItemWithTimeout(item);

      // Small delay between items to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Process a single item with comprehensive timeout handling and retry logic
  Future<void> _processSingleItemWithTimeout(BatchUploadItem item) async {
    const totalTimeout = BatchUploadTimeouts.totalItemTimeout;
    const maxRetries = BatchUploadTimeouts.maxAutoRetries;

    // Get current retry count from the item
    int currentRetryCount = item.retryCount;

    while (currentRetryCount <= maxRetries) {
      try {
        await _processSingleItemAndWaitForCompletion(item).timeout(totalTimeout);
        return; // Success, exit retry loop
      } on TimeoutException {
        currentRetryCount++;

        if (currentRetryCount <= maxRetries) {
          // Calculate exponential backoff delay (30s, 60s, 120s)
          final delaySeconds = 30 * (1 << (currentRetryCount - 1));
          final delay = Duration(seconds: delaySeconds);

          _logger.w(
            '🔄 Item ${item.fileName} timed out (attempt $currentRetryCount/$maxRetries). Retrying in ${delay.inSeconds} seconds...',
          );

          // Add log entry for retry attempt
          final logEntry = 'Retry attempt $currentRetryCount/$maxRetries after timeout. Waiting ${delay.inSeconds}s before retry.';
          _addProcessingLog(item.id, logEntry);

          // Update item with new retry count and status
          _updateItemWithRetryCount(item.id, currentRetryCount);
          _updateItemStatus(
            item.id,
            BatchUploadItemStatus.processing,
            error: null,
            stage: BatchProcessingStage.retrying,
          );

          _updateItemProgress(
            item.id,
            10, // Reset to initial progress
            'Retrying... (attempt $currentRetryCount/$maxRetries)',
          );

          // Wait before retrying
          await Future.delayed(delay);
        } else {
          // Max retries exceeded
          _logger.e(
            'Item ${item.fileName} failed after $maxRetries retry attempts',
          );
          _updateItemStatus(
            item.id,
            BatchUploadItemStatus.failed,
            error: 'AI processing timed out after $maxRetries automatic retries. The receipt may be complex or the server is busy. Please try again later or use manual retry.',
          );
        }
      } catch (e) {
        _logger.e('Error processing item ${item.fileName}: $e');
        _updateItemStatus(
          item.id,
          BatchUploadItemStatus.failed,
          error: 'Processing failed: $e',
        );
        return; // Don't retry for non-timeout errors
      }
    }
  }

  /// Process a single item and wait for it to complete
  Future<void> _processSingleItemAndWaitForCompletion(
    BatchUploadItem item,
  ) async {
    // Add delay between batch requests to avoid race conditions (like React app)
    await Future.delayed(const Duration(milliseconds: 100));

    // Start the processing
    await _processSingleItem(item);

    // Wait for the item to finish processing
    await _waitForItemCompletion(item.id);
  }

  /// Wait for an item to complete processing
  Future<void> _waitForItemCompletion(String itemId) async {
    const checkInterval = Duration(
      milliseconds: 300,
    ); // More responsive checking
    const maxWaitTime = BatchUploadTimeouts.waitForCompletionTimeout;
    const progressStuckTimeout = BatchUploadTimeouts.progressStuckTimeout;
    final startTime = DateTime.now();
    int checkCount = 0;
    DateTime? progressStuckStartTime;

    _logger.d('🕐 Starting to wait for item completion: $itemId');

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      checkCount++;
      final itemIndex = state.items.indexWhere((item) => item.id == itemId);
      if (itemIndex == -1) {
        // Item was removed, consider it completed
        _logger.i('Item $itemId was removed from queue, considering completed');
        break;
      }

      final item = state.items[itemIndex];
      _logger.d(
        '🕐 Check #$checkCount for item ${item.fileName}: status=${item.status}, isFinished=${item.isFinished}, progress=${item.progress}%',
      );

      if (item.isFinished) {
        _logger.i(
          '✅ Item ${item.fileName} finished with status: ${item.status} after $checkCount checks',
        );
        break;
      }

      // Fallback completion logic: If progress is 100% but status is still processing
      if (item.progress >= 100 &&
          item.status == BatchUploadItemStatus.processing) {
        if (progressStuckStartTime == null) {
          progressStuckStartTime = DateTime.now();
          _logger.w(
            '⚠️ Item ${item.fileName} has 100% progress but is still processing. Starting fallback timer.',
          );
        } else if (DateTime.now().difference(progressStuckStartTime) >
            progressStuckTimeout) {
          _logger.w(
            '🔧 Fallback completion: Item ${item.fileName} stuck at 100% progress for ${progressStuckTimeout.inSeconds} seconds. Marking as completed.',
          );

          // Force completion if we have a receipt ID
          if (item.receiptId != null) {
            _handleReceiptCompletion(itemId, item.receiptId!, null, null);
          } else {
            // Mark as failed if no receipt ID
            _updateItemStatus(
              itemId,
              BatchUploadItemStatus.failed,
              error: 'Processing timeout - no completion signal received',
            );
          }
          break;
        }
      } else {
        // Reset the stuck timer if progress changes or status changes
        progressStuckStartTime = null;
      }

      // Wait before checking again (more responsive than before)
      await Future.delayed(checkInterval);
    }

    // Handle timeout case
    if (DateTime.now().difference(startTime) >= maxWaitTime) {
      _logger.w(
        '⏰ Item $itemId timed out after ${maxWaitTime.inMinutes} minutes',
      );

      // Check if item is still not finished and mark as failed
      final itemIndex = state.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final item = state.items[itemIndex];
        if (!item.isFinished) {
          _logger.w(
            '🔧 Timeout handling: Marking item ${item.fileName} as failed due to timeout',
          );
          _updateItemStatus(
            itemId,
            BatchUploadItemStatus.failed,
            error: 'Processing timeout after ${maxWaitTime.inMinutes} minutes',
          );
        }
      }
    }

    // Add a small delay before processing next item to ensure state is stable
    await Future.delayed(const Duration(milliseconds: 200));
    _logger.d('🏁 Finished waiting for item completion: $itemId');
  }

  /// Process a single upload item
  Future<void> _processSingleItem(BatchUploadItem item) async {
    try {
      _logger.i('Processing item: ${item.fileName}');

      // Update item status to uploading
      _updateItemStatus(
        item.id,
        BatchUploadItemStatus.uploading,
        stage: BatchProcessingStage.initializing,
      );

      // Check if disposed before using ref
      if (_disposed) {
        _logger.w('Provider disposed, skipping item processing: ${item.fileName}');
        return;
      }

      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Upload image to Supabase Storage
      _updateItemProgress(
        item.id,
        10,
        'Uploading image to cloud storage...',
        stage: BatchProcessingStage.uploadingImage,
      );

      final uuid = const Uuid();
      final receiptId = uuid.v4();
      final fileExtension = path.extension(item.file.path);

      // Use timestamp-based filename to match React app behavior and avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileId = receiptId.substring(0, 8); // Use first 8 chars of UUID as fileId
      final fileName = '${timestamp}_$fileId$fileExtension';
      final filePath = '${user.id}/$fileName';

      // Optimize image before upload (match React app behavior)
      _updateItemProgress(item.id, 25, 'Optimizing image...');
      final optimizedFile = await PerformanceService.optimizeImageForUpload(
        item.file,
      );

      final imageBytes = await optimizedFile.readAsBytes();
      final imageSizeMB = imageBytes.length / 1024 / 1024;

      // Log detailed image information for debugging
      _logger.i('Uploading optimized image:');
      _logger.i('  File: $fileName');
      _logger.i(
        '  Size: ${imageSizeMB.toStringAsFixed(2)} MB (${imageBytes.length} bytes)',
      );
      _logger.i('  Content-Type: image/jpeg');

      final imageUrl = await SupabaseService.uploadFile(
        bucket: AppConstants.receiptImagesBucket,
        path: filePath,
        bytes: imageBytes,
        contentType:
            'image/jpeg', // Always JPEG after optimization (match React app)
      );

      _logger.i('Image uploaded successfully: $imageUrl');

      _updateItemProgress(item.id, 40, 'Image upload completed');

      // Step 2: Create receipt record
      _updateItemProgress(
        item.id,
        50,
        'Creating receipt record...',
        stage: BatchProcessingStage.creatingRecord,
      );

      // Check if disposed before using ref
      if (_disposed) {
        _logger.w('Provider disposed during receipt record creation');
        return;
      }

      final currentTeamState = _ref.read(currentTeamModelProvider);
      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // Get date in YYYY-MM-DD format

      final initialReceiptData = {
        'id': receiptId,
        'user_id': user.id,
        'team_id': currentTeamState?.id,
        'merchant': 'Processing...', // Required field
        'date': today, // Required field
        'total': 0.0, // Required field
        'tax': 0.0,
        'currency': 'MYR',
        'payment_method': '', // Required field
        'image_url': imageUrl,
        'status': 'unreviewed',
        'processing_status': 'processing',
        'fullText': '',
        'ai_suggestions': {},
        'predicted_category': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client.from('receipts').insert(initialReceiptData);

      _updateItemProgress(item.id, 70, 'Receipt record created');

      // Step 3: Process with AI
      _updateItemProgress(
        item.id,
        80,
        'Processing with AI Vision...',
        stage: BatchProcessingStage.aiProcessing,
      );

      // Set up real-time subscription for processing logs
      _subscribeToProcessingLogs(item.id, receiptId);

      // Trigger AI processing with error handling (matching React app)
      try {
        _logger.i('Triggering AI processing for receipt $receiptId');

        // Add request payload logging like React app
        final requestPayload = {
          'receiptId': receiptId,
          'imageUrl': imageUrl,
          'modelId':
              'gemini-2.5-flash-lite', // Revert to original model for debugging
          'skipOptimization': true, // Flutter has already optimized the image
          'clientOptimized':
              true, // Indicate client-side optimization was performed
        };

        _logger.d('AI processing request payload: $requestPayload');

        final response = await SupabaseService.client.functions
            .invoke('process-receipt', body: requestPayload)
            .timeout(
              BatchUploadTimeouts.functionCallTimeout,
            ); // Increased timeout for batch uploads to handle AI processing delays

        _logger.d(
          'AI processing response for $receiptId: status=${response.status}, data=${response.data}',
        );

        if (response.status != 200) {
          final errorData = response.data;
          String errorMessage =
              'AI processing failed with status: ${response.status}';

          // Check for specific error types like React app does
          if (errorData != null &&
              errorData.toString().contains('WORKER_LIMIT')) {
            errorMessage =
                'Processing failed due to resource limits. Please try again later.';
          } else if (errorData != null &&
              errorData.toString().contains('compute resources')) {
            errorMessage =
                'The receipt is too complex to process. Try using a smaller image.';
          }

          throw Exception(errorMessage);
        }
      } on TimeoutException {
        _logger.e('AI processing request timed out for $receiptId');
        _updateItemStatus(
          item.id,
          BatchUploadItemStatus.failed,
          error: 'AI processing request timed out',
        );
        return;
      } catch (e) {
        _logger.e('Failed to trigger AI processing for $receiptId: $e');
        _updateItemStatus(
          item.id,
          BatchUploadItemStatus.failed,
          error: 'Failed to start AI processing: $e',
        );
        return; // Exit early if AI processing can't be triggered
      }

      // Update item with receipt ID and mark as processing
      _updateItemWithReceiptId(item.id, receiptId);
      _updateItemStatus(
        item.id,
        BatchUploadItemStatus.processing,
        stage: BatchProcessingStage.aiProcessing,
      );

      // Immediate completion check - sometimes the processing is so fast that
      // real-time subscriptions miss it
      _performImmediateCompletionCheck(item.id, receiptId);

      // Also perform multiple quick checks in the first 30 seconds
      _performQuickCompletionChecks(item.id, receiptId);
    } catch (e) {
      _logger.e('Error processing item ${item.fileName}: $e');
      _updateItemStatus(
        item.id,
        BatchUploadItemStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Subscribe to processing logs for real-time updates with timeout handling
  void _subscribeToProcessingLogs(String itemId, String receiptId) {
    final startTime = DateTime.now();
    const maxProcessingTime = BatchUploadTimeouts.maxProcessingTimeout;

    _logger.i('🔔 SETTING UP SUBSCRIPTION for receipt $receiptId');
    _logger.i('🔔 Item ID: $itemId');

    // Use real-time subscription like React app instead of polling
    final subscription = SupabaseService.client
        .from('receipts')
        .stream(primaryKey: ['id'])
        .eq('id', receiptId)
        .listen(
          (data) {
            _logger.d(
              '🔔 Real-time subscription triggered for receipt $receiptId',
            );
            _logger.d('🔔 Raw data received: $data');

            if (data.isNotEmpty) {
              final receiptData = data.first;
              final processingStatus =
                  receiptData['processing_status'] as String?;
              final merchant = receiptData['merchant'] as String?;
              final total = receiptData['total'] as double?;

              // Log ALL fields to see what's in the database
              _logger.d('🔔 Full receipt data: $receiptData');
              _logger.d(
                '🔔 Processing status: "$processingStatus" (type: ${processingStatus.runtimeType})',
              );
              _logger.d('🔔 Merchant: "$merchant"');
              _logger.d('🔔 Total: $total');

              _logger.d(
                'Real-time update for receipt $receiptId: status=$processingStatus, merchant=$merchant, total=$total',
              );

              if (processingStatus == 'complete') {
                _logger.i(
                  '🎉 COMPLETION DETECTED via real-time subscription for $receiptId',
                );
                _handleReceiptCompletion(itemId, receiptId, merchant, total);
                // Cancel subscription and timer after completion
                _subscriptions[itemId]?.cancel();
                _subscriptions.remove(itemId);
                // Cancel the specific timer for this item
                _itemTimers[itemId]?.cancel();
                _itemTimers.remove(itemId);
              } else if (processingStatus == 'failed' ||
                  processingStatus == 'failed_ai') {
                _logger.i(
                  '🚨 FAILURE DETECTED via real-time subscription for $receiptId',
                );
                _handleReceiptFailure(itemId, receiptId);
                // Cancel subscription and timer after failure
                _subscriptions[itemId]?.cancel();
                _subscriptions.remove(itemId);
                // Cancel the specific timer for this item
                _itemTimers[itemId]?.cancel();
                _itemTimers.remove(itemId);
              } else {
                _logger.d(
                  '🔔 Status "$processingStatus" does not match "complete" - continuing to wait',
                );
              }
            }
          },
          onError: (error) {
            _logger.e(
              '🚨 Real-time subscription error for receipt $receiptId: $error',
            );
          },
        );

    // Store subscription for cleanup
    _subscriptions[itemId] = subscription;

    // Fallback polling timer as backup - more aggressive polling
    int pollCount = 0;
    const maxPollAttempts = 160; // 8 minutes at 3-second intervals
    final timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        pollCount++;
        final elapsed = DateTime.now().difference(startTime);

        // Check if item is still being processed
        final itemIndex = state.items.indexWhere((item) => item.id == itemId);
        if (itemIndex == -1 || state.items[itemIndex].isFinished) {
          timer.cancel();
          _itemTimers.remove(itemId);
          _subscriptions[itemId]?.cancel();
          _subscriptions.remove(itemId);
          return;
        }

        // Check for timeout
        if (elapsed > maxProcessingTime || pollCount > maxPollAttempts) {
          _logger.w(
            'Processing timeout for item $itemId after ${elapsed.inMinutes} minutes',
          );
          _updateItemStatus(
            itemId,
            BatchUploadItemStatus.failed,
            error: 'Processing timeout - please try again',
          );
          timer.cancel();
          _itemTimers.remove(itemId);
          _subscriptions[itemId]?.cancel();
          _subscriptions.remove(itemId);
          return;
        }

        // Fallback polling - check receipt status
        _logger.d(
          '🔍 Polling database for receipt $receiptId (poll #$pollCount)',
        );

        try {
          final response = await SupabaseService.client
              .from('receipts')
              .select(
                'processing_status, merchant, total, currency, created_at, updated_at',
              )
              .eq('id', receiptId)
              .single();

          _logger.d('🔍 Polling query successful for $receiptId');
          _logger.d('🔍 Full polling response: $response');

          final processingStatus = response['processing_status'] as String?;
          final merchant = response['merchant'] as String?;
          final total = response['total'] as double?;
          final updatedAt = response['updated_at'] as String?;

          _logger.d(
            '🔍 Polling results - Status: "$processingStatus" (type: ${processingStatus.runtimeType})',
          );
          _logger.d(
            '🔍 Polling results - Merchant: "$merchant", Total: $total',
          );
          _logger.d('🔍 Polling results - Updated at: $updatedAt');
          _logger.d(
            'Fallback polling receipt $receiptId: status=$processingStatus, merchant=$merchant, total=$total',
          );

          if (processingStatus == 'complete') {
            _logger.i('🎉 COMPLETION DETECTED via polling for $receiptId');
            _handleReceiptCompletion(itemId, receiptId, merchant, total);
            timer.cancel();
            _itemTimers.remove(itemId);
            _subscriptions[itemId]?.cancel();
            _subscriptions.remove(itemId);
          } else if (processingStatus == 'failed' ||
              processingStatus == 'failed_ai') {
            _logger.i('🚨 FAILURE DETECTED via polling for $receiptId');
            _handleReceiptFailure(itemId, receiptId);
            timer.cancel();
            _itemTimers.remove(itemId);
            _subscriptions[itemId]?.cancel();
            _subscriptions.remove(itemId);
          } else {
            _logger.d(
              '🔍 Polling status "$processingStatus" does not match "complete" - continuing to poll',
            );
            // Still processing - update progress message with more granular feedback
            String progressMessage;
            int progressValue;

            if (elapsed.inSeconds < 10) {
              progressMessage = 'Analyzing receipt image...';
              progressValue = 85;
            } else if (elapsed.inSeconds < 20) {
              progressMessage = 'Extracting data with AI Vision...';
              progressValue = 90;
            } else if (elapsed.inSeconds < 30) {
              progressMessage = 'Processing line items...';
              progressValue = 95;
            } else {
              progressMessage =
                  'Finalizing processing... (${elapsed.inSeconds}s)';
              progressValue = 98;
            }

            _updateItemProgress(itemId, progressValue, progressMessage);
          }
        } catch (e) {
          _logger.w('🚨 Error in fallback polling for $itemId: $e');
          // Don't fail immediately on network errors, but count them
          if (pollCount > maxPollAttempts) {
            _updateItemStatus(
              itemId,
              BatchUploadItemStatus.failed,
              error: 'Network error during processing check',
            );
            timer.cancel();
            _itemTimers.remove(itemId);
            _subscriptions[itemId]?.cancel();
            _subscriptions.remove(itemId);
          }
        }
      } catch (e) {
        // Catch any unexpected errors in the timer callback
        _logger.e('🚨 Unexpected error in polling timer for $itemId: $e');
        _updateItemStatus(
          itemId,
          BatchUploadItemStatus.failed,
          error: 'Unexpected error during processing',
        );
        timer.cancel();
        _itemTimers.remove(itemId);
        _subscriptions[itemId]?.cancel();
        _subscriptions.remove(itemId);
      }
    });

    _itemTimers[itemId] = timer;
  }

  /// Perform immediate completion check after AI processing is triggered
  /// This helps catch cases where processing completes very quickly
  Future<void> _performImmediateCompletionCheck(
    String itemId,
    String receiptId,
  ) async {
    _logger.d(
      '🚀 Performing immediate completion check for receipt $receiptId',
    );

    // Wait a short moment for the edge function to potentially complete
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await SupabaseService.client
          .from('receipts')
          .select('processing_status, merchant, total')
          .eq('id', receiptId)
          .single();

      final processingStatus = response['processing_status'] as String?;
      final merchant = response['merchant'] as String?;
      final total = response['total'] as double?;

      _logger.d(
        '🚀 Immediate check result for $receiptId: status="$processingStatus"',
      );

      if (processingStatus == 'complete') {
        _logger.i('🎉 IMMEDIATE COMPLETION DETECTED for $receiptId');
        _handleReceiptCompletion(itemId, receiptId, merchant, total);
        // Cancel any existing subscriptions and timers since we found completion
        _subscriptions[itemId]?.cancel();
        _subscriptions.remove(itemId);
        _itemTimers[itemId]?.cancel();
        _itemTimers.remove(itemId);
      } else if (processingStatus == 'failed' ||
          processingStatus == 'failed_ai') {
        _logger.i('🚨 IMMEDIATE FAILURE DETECTED for $receiptId');
        _handleReceiptFailure(itemId, receiptId);
        // Cancel any existing subscriptions and timers
        _subscriptions[itemId]?.cancel();
        _subscriptions.remove(itemId);
        _itemTimers[itemId]?.cancel();
        _itemTimers.remove(itemId);
      } else {
        _logger.d(
          '🚀 Immediate check: Receipt $receiptId still processing (status: "$processingStatus")',
        );
      }
    } catch (e) {
      _logger.w('🚀 Error in immediate completion check for $receiptId: $e');
      // Don't fail the item, let the normal subscription/polling handle it
    }
  }

  /// Perform multiple quick completion checks in the first 30 seconds
  /// This helps catch completions that happen within the typical processing time
  void _performQuickCompletionChecks(String itemId, String receiptId) {
    _logger.d('⚡ Starting quick completion checks for receipt $receiptId');

    // Check at 5, 10, 15, 20, 25, and 30 seconds
    final checkTimes = [5, 10, 15, 20, 25, 30];

    for (final seconds in checkTimes) {
      Timer(Duration(seconds: seconds), () async {
        // Check if item is still being processed
        final itemIndex = state.items.indexWhere((item) => item.id == itemId);
        if (itemIndex == -1 || state.items[itemIndex].isFinished) {
          return; // Item already finished, no need to check
        }

        _logger.d('⚡ Quick check #${seconds}s for receipt $receiptId');

        try {
          final response = await SupabaseService.client
              .from('receipts')
              .select('processing_status, merchant, total')
              .eq('id', receiptId)
              .single();

          final processingStatus = response['processing_status'] as String?;
          final merchant = response['merchant'] as String?;
          final total = response['total'] as double?;

          _logger.d(
            '⚡ Quick check ${seconds}s result for $receiptId: status="$processingStatus"',
          );

          if (processingStatus == 'complete') {
            _logger.i(
              '🎉 QUICK COMPLETION DETECTED at ${seconds}s for $receiptId',
            );
            _handleReceiptCompletion(itemId, receiptId, merchant, total);
            // Cancel any existing subscriptions and timers
            _subscriptions[itemId]?.cancel();
            _subscriptions.remove(itemId);
            _itemTimers[itemId]?.cancel();
            _itemTimers.remove(itemId);
          } else if (processingStatus == 'failed' ||
              processingStatus == 'failed_ai') {
            _logger.i(
              '🚨 QUICK FAILURE DETECTED at ${seconds}s for $receiptId',
            );
            _handleReceiptFailure(itemId, receiptId);
            // Cancel any existing subscriptions and timers
            _subscriptions[itemId]?.cancel();
            _subscriptions.remove(itemId);
            _itemTimers[itemId]?.cancel();
            _itemTimers.remove(itemId);
          }
        } catch (e) {
          _logger.w(
            '⚡ Error in quick completion check at ${seconds}s for $receiptId: $e',
          );
        }
      });
    }
  }

  /// Handle receipt completion (extracted from polling logic)
  void _handleReceiptCompletion(
    String itemId,
    String receiptId,
    String? merchant,
    double? total,
  ) {
    _logger.i(
      '🎯 _handleReceiptCompletion called for itemId: $itemId, receiptId: $receiptId',
    );
    _logger.i('🎯 Completion data - Merchant: "$merchant", Total: $total');

    _updateItemStatus(
      itemId,
      BatchUploadItemStatus.completed,
      stage: BatchProcessingStage.completed,
    );
    _updateItemProgress(
      itemId,
      100,
      'Processing completed successfully!',
      stage: BatchProcessingStage.completed,
    );

    // Debug: Check if item is now marked as finished
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      final item = state.items[itemIndex];
      _logger.i(
        '🎯 Item $itemId status after completion: ${item.status}, isFinished: ${item.isFinished}',
      );
    } else {
      _logger.w('🎯 Item $itemId not found in state after completion');
    }

    // Check if all items are now finished to trigger batch completion
    _checkIfBatchIsComplete();

    if (merchant != null &&
        merchant.isNotEmpty &&
        merchant != 'Processing...') {
      _logger.i(
        'Receipt $receiptId completed with merchant: $merchant, total: $total',
      );
    } else {
      _logger.w(
        'Receipt $receiptId completed but AI could not extract meaningful data',
      );
    }
  }

  /// Check if batch is complete and update status accordingly
  void _checkIfBatchIsComplete() {
    final allFinished = state.items.every((item) => item.isFinished);

    if (allFinished && state.status == BatchUploadStatus.processing) {
      _logger.i('🎉 All items finished - triggering batch completion');

      // Calculate final statistics
      final stats = {
        'total': state.totalItems,
        'completed': state.completedCount,
        'failed': state.failedCount,
        'success_rate': state.successRate,
      };
      _logger.i('📊 Final batch stats: $stats');

      // Mark batch as completed
      state = state.copyWith(
        status: BatchUploadStatus.completed,
        completedAt: DateTime.now(),
        totalProgress: 100,
      );

      _logger.i('✅ Batch upload completed successfully');
    }
  }

  /// Handle receipt failure (extracted from polling logic)
  void _handleReceiptFailure(String itemId, String receiptId) {
    _logger.d(
      '🚨 _handleReceiptFailure called for itemId: $itemId, receiptId: $receiptId',
    );

    _updateItemStatus(
      itemId,
      BatchUploadItemStatus.failed,
      stage: BatchProcessingStage.failed,
      error: 'AI processing failed',
    );
    _updateItemProgress(
      itemId,
      100,
      'Processing failed',
      stage: BatchProcessingStage.failed,
    );

    // Store receipt ID for reference
    _updateItemWithReceiptId(itemId, receiptId);

    // Add failure log
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      final item = state.items[itemIndex];
      final updatedItem = item.addLog(
        'Receipt processing failed - AI analysis unsuccessful',
      );
      final updatedItems = [...state.items];
      updatedItems[itemIndex] = updatedItem;
      state = state.copyWith(items: updatedItems);
    }

    _logger.w('❌ Receipt processing failed for $receiptId');
  }

  /// Update item status
  void _updateItemStatus(
    String itemId,
    BatchUploadItemStatus status, {
    BatchProcessingStage? stage,
    String? error,
  }) {
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final updatedItem = item.copyWith(
      status: status,
      currentStage: stage,
      error: error,
      startedAt: status == BatchUploadItemStatus.uploading
          ? DateTime.now()
          : item.startedAt,
      completedAt: status.index >= BatchUploadItemStatus.completed.index
          ? DateTime.now()
          : null,
    );

    final updatedItems = [...state.items];
    updatedItems[itemIndex] = updatedItem;
    state = state.copyWith(items: updatedItems);
  }

  /// Update item retry count
  void _updateItemWithRetryCount(String itemId, int retryCount) {
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final updatedItem = item.copyWith(retryCount: retryCount);

    final updatedItems = [...state.items];
    updatedItems[itemIndex] = updatedItem;
    state = state.copyWith(items: updatedItems);
  }

  /// Add processing log entry to item
  void _addProcessingLog(String itemId, String logEntry) {
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final updatedLogs = [...item.processingLogs, logEntry];
    final updatedItem = item.copyWith(processingLogs: updatedLogs);

    final updatedItems = [...state.items];
    updatedItems[itemIndex] = updatedItem;
    state = state.copyWith(items: updatedItems);
  }

  /// Update item progress
  void _updateItemProgress(
    String itemId,
    int progress,
    String message, {
    BatchProcessingStage? stage,
  }) {
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final updatedItem = item
        .copyWith(progress: progress, currentStage: stage ?? item.currentStage)
        .addLog(message);

    final updatedItems = [...state.items];
    updatedItems[itemIndex] = updatedItem;
    state = state.copyWith(items: updatedItems);
  }

  /// Update item with receipt ID
  void _updateItemWithReceiptId(String itemId, String receiptId) {
    final itemIndex = state.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final updatedItem = item.copyWith(receiptId: receiptId);

    final updatedItems = [...state.items];
    updatedItems[itemIndex] = updatedItem;
    state = state.copyWith(items: updatedItems);
  }

  /// Start progress tracking timer
  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTotalProgress();
    });
  }

  /// Update total progress based on individual item progress
  void _updateTotalProgress() {
    if (state.items.isEmpty) return;

    final totalProgress =
        state.items.fold<int>(0, (sum, item) => sum + item.progress) /
        state.items.length;
    state = state.copyWith(totalProgress: totalProgress.round());
  }

  /// Cancel all active timers and subscriptions
  void _cancelAllTimers() {
    _logger.d(
      'Cancelling ${_itemTimers.length} active timers and ${_subscriptions.length} subscriptions',
    );
    for (final timer in _itemTimers.values) {
      if (timer.isActive) {
        timer.cancel();
      }
    }
    _itemTimers.clear();

    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Validate if file is acceptable for upload
  bool _isValidFile(File file) {
    final fileExtension = path.extension(file.path).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];

    if (!allowedExtensions.contains(fileExtension)) {
      return false;
    }

    // Check file size (max 5MB)
    final fileStats = file.statSync();
    const maxFileSize = 5 * 1024 * 1024; // 5MB

    return fileStats.size <= maxFileSize;
  }

  /// Get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Reset the batch upload state
  void reset() {
    _cancelAllTimers();
    _progressTimer?.cancel();
    state = const BatchUploadState();
    _logger.i('Batch upload state reset');
  }

  /// Get formatted file size
  String getFormattedFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get batch upload statistics
  Map<String, dynamic> getBatchStatistics() {
    return {
      'totalItems': state.totalItems,
      'completedCount': state.completedCount,
      'failedCount': state.failedCount,
      'activeCount': state.activeCount,
      'queuedCount': state.queuedCount,
      'successRate': state.successRate,
      'totalProgress': state.totalProgress,
      'isProcessing': state.isProcessing,
      'isCompleted': state.isCompleted,
      'hasFailures': state.hasFailures,
    };
  }

  /// Get estimated time remaining (simple calculation)
  Duration? getEstimatedTimeRemaining() {
    if (!state.isProcessing || state.startedAt == null) return null;

    final elapsed = DateTime.now().difference(state.startedAt!);
    final completedItems = state.completedCount;
    final totalItems = state.totalItems;

    if (completedItems == 0) return null;

    final averageTimePerItem = elapsed.inMilliseconds / completedItems;
    final remainingItems = totalItems - completedItems;
    final estimatedRemainingMs = (averageTimePerItem * remainingItems).round();

    return Duration(milliseconds: estimatedRemainingMs);
  }
}
