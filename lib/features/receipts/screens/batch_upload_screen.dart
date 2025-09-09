import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';


import '../models/batch_upload_models.dart';
import '../providers/batch_upload_provider.dart';
import '../providers/receipts_provider.dart';
import '../widgets/batch_upload_queue_item.dart';
import '../widgets/batch_upload_review_widget.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/guards/subscription_guard.dart';
import '../../subscription/widgets/subscription_limits_widget.dart';

class BatchUploadScreen extends ConsumerStatefulWidget {
  const BatchUploadScreen({super.key});

  @override
  ConsumerState<BatchUploadScreen> createState() => _BatchUploadScreenState();
}

class _BatchUploadScreenState extends ConsumerState<BatchUploadScreen> {
  bool _showReview = false;
  BatchUploadStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    // Listen for batch completion to auto-refresh receipts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousStatus = ref.read(batchUploadProvider).status;
    });
  }

  /// Handle back navigation and refresh receipts if any were processed
  void _handleBackNavigation(BuildContext context, WidgetRef ref) {
    final batchState = ref.read(batchUploadProvider);

    // If any receipts were processed successfully, refresh the receipts list
    final hasCompletedReceipts = batchState.items.any(
      (item) => item.status == BatchUploadItemStatus.completed
    );

    if (hasCompletedReceipts) {
      // Refresh receipts to show the newly processed data
      ref.read(receiptsProvider.notifier).refresh();
    }

    Navigator.of(context).pop();
  }

  /// Check if batch processing just completed and refresh receipts
  void _checkBatchCompletion(BatchUploadState currentState) {
    if (_previousStatus != null &&
        _previousStatus == BatchUploadStatus.processing &&
        currentState.status == BatchUploadStatus.completed) {

      // Batch processing just completed, check if any receipts were successfully processed
      final hasCompletedReceipts = currentState.items.any(
        (item) => item.status == BatchUploadItemStatus.completed
      );

      if (hasCompletedReceipts) {
        // Refresh receipts in the background to show updated data
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            ref.read(receiptsProvider.notifier).refresh();
          }
        });
      }
    }

    _previousStatus = currentState.status;
  }

  @override
  void dispose() {
    // Reset the batch upload state when leaving the screen
    // Check if the widget is still mounted before accessing ref
    if (mounted) {
      try {
        ref.read(batchUploadProvider.notifier).reset();
      } catch (e) {
        // Ignore errors during disposal
        debugPrint('Error during batch upload disposal: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batchState = ref.watch(batchUploadProvider);

    // Check if batch processing just completed and refresh receipts if needed
    _checkBatchCompletion(batchState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Upload Receipts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context, ref),
        ),
        actions: [
          if (batchState.items.isNotEmpty && !batchState.isProcessing)
            TextButton(
              onPressed: () {
                ref.read(batchUploadProvider.notifier).clearQueue();
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: _showReview ? _buildReviewScreen(batchState) : _buildUploadScreen(batchState),
      bottomNavigationBar: _buildBottomBar(batchState),
    );
  }

  Widget _buildUploadScreen(BatchUploadState batchState) {
    if (batchState.items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Progress indicator
        if (batchState.isProcessing) _buildProgressHeader(batchState),
        
        // File list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: batchState.items.length,
            itemBuilder: (context, index) {
              final item = batchState.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                child: BatchUploadQueueItem(
                  item: item,
                  onRemove: batchState.isProcessing ? null : (itemId) {
                    ref.read(batchUploadProvider.notifier).removeFile(itemId);
                  },
                  onRetry: (itemId) {
                    ref.read(batchUploadProvider.notifier).retryUpload(itemId);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewScreen(BatchUploadState batchState) {
    return BatchUploadReviewWidget(
      batchState: batchState,
      onClose: () {
        setState(() {
          _showReview = false;
        });
      },
      onReset: () {
        ref.read(batchUploadProvider.notifier).reset();
        setState(() {
          _showReview = false;
        });
      },
      onRetryFailed: () {
        // Retry all failed uploads
        for (final item in batchState.failedItems) {
          ref.read(batchUploadProvider.notifier).retryUpload(item.id);
        }
        setState(() {
          _showReview = false;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Subscription Limits Display
            const SubscriptionLimitsWidget(
              showUpgradePrompt: true,
              compact: true,
            ),

            const SizedBox(height: AppConstants.largePadding),

            Icon(
              Icons.cloud_upload_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Select Multiple Receipts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Choose multiple receipt images to upload and process them all at once.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            ElevatedButton.icon(
              onPressed: _selectFiles,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Files'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.largePadding,
                  vertical: AppConstants.defaultPadding,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Supported formats: JPEG, PNG, PDF (max 5MB each)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BatchUploadState batchState) {
    final stats = ref.read(batchUploadProvider.notifier).getBatchStatistics();
    final eta = ref.read(batchUploadProvider.notifier).getEstimatedTimeRemaining();
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processing ${stats['completedCount']} of ${stats['totalItems']} files',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (eta != null)
                Text(
                  'ETA: ${_formatDuration(eta)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          LinearProgressIndicator(
            value: batchState.totalProgress / 100,
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${batchState.totalProgress}% complete',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                children: [
                  if (stats['failedCount'] > 0) ...[
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats['failedCount']} failed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BatchUploadState batchState) {
    if (batchState.items.isEmpty) return const SizedBox.shrink();

    if (batchState.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Complete',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${batchState.completedCount} successful, ${batchState.failedCount} failed',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showReview = true;
                });
              },
              child: const Text('View Results'),
            ),
          ],
        ),
      );
    }

    if (batchState.isProcessing) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text('Processing uploads...'),
            ),
            TextButton(
              onPressed: () {
                ref.read(batchUploadProvider.notifier).pauseBatchProcessing();
              },
              child: const Text('Pause'),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            TextButton(
              onPressed: () {
                ref.read(batchUploadProvider.notifier).cancelBatchProcessing();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    // Ready to start processing
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _selectFiles,
            icon: const Icon(Icons.add),
            label: const Text('Add More'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              // Check batch upload limits before starting
              final canUpload = await SubscriptionGuard.showBatchLimitDialogIfNeeded(
                context,
                ref,
                batchState.items.length,
              );

              if (canUpload) {
                ref.read(batchUploadProvider.notifier).startBatchProcessing();
              }
            },
            icon: const Icon(Icons.upload),
            label: Text('Upload ${batchState.items.length} Files'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        if (files.isNotEmpty) {
          await ref.read(batchUploadProvider.notifier).addFiles(files);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
