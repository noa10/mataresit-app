import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'batch_upload_models.g.dart';

/// Status of an individual batch upload item
@JsonEnum()
enum BatchUploadItemStatus {
  @JsonValue('queued')
  queued,
  @JsonValue('uploading')
  uploading,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

/// Status of the overall batch upload operation
@JsonEnum()
enum BatchUploadStatus {
  @JsonValue('idle')
  idle,
  @JsonValue('selecting')
  selecting,
  @JsonValue('ready')
  ready,
  @JsonValue('processing')
  processing,
  @JsonValue('paused')
  paused,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

/// Processing stage for detailed progress tracking
@JsonEnum()
enum BatchProcessingStage {
  @JsonValue('initializing')
  initializing,
  @JsonValue('uploading_image')
  uploadingImage,
  @JsonValue('creating_record')
  creatingRecord,
  @JsonValue('ai_processing')
  aiProcessing,
  @JsonValue('finalizing')
  finalizing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

/// Individual batch upload item representing a single file
/// Note: This class is not JSON serializable due to the File object
class BatchUploadItem extends Equatable {
  final String id;
  final File file;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final BatchUploadItemStatus status;
  final BatchProcessingStage? currentStage;
  final int progress; // 0-100
  final String? error;
  final String? receiptId;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> processingLogs;
  final Map<String, dynamic>? metadata;

  const BatchUploadItem({
    required this.id,
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.status = BatchUploadItemStatus.queued,
    this.currentStage,
    this.progress = 0,
    this.error,
    this.receiptId,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.processingLogs = const [],
    this.metadata,
  });

  BatchUploadItem copyWith({
    String? id,
    File? file,
    String? fileName,
    int? fileSize,
    String? mimeType,
    BatchUploadItemStatus? status,
    BatchProcessingStage? currentStage,
    int? progress,
    String? error,
    String? receiptId,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? processingLogs,
    Map<String, dynamic>? metadata,
  }) {
    return BatchUploadItem(
      id: id ?? this.id,
      file: file ?? this.file,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      currentStage: currentStage ?? this.currentStage,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      receiptId: receiptId ?? this.receiptId,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      processingLogs: processingLogs ?? this.processingLogs,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Add a processing log entry
  BatchUploadItem addLog(String logEntry) {
    final updatedLogs = List<String>.from(processingLogs)..add(logEntry);
    return copyWith(processingLogs: updatedLogs);
  }

  /// Check if the item is in a final state (completed, failed, or cancelled)
  bool get isFinished => [
        BatchUploadItemStatus.completed,
        BatchUploadItemStatus.failed,
        BatchUploadItemStatus.cancelled,
      ].contains(status);

  /// Check if the item is currently being processed
  bool get isActive => [
        BatchUploadItemStatus.uploading,
        BatchUploadItemStatus.processing,
      ].contains(status);

  /// Get human-readable status description
  String get statusDescription {
    switch (status) {
      case BatchUploadItemStatus.queued:
        return 'Waiting in queue';
      case BatchUploadItemStatus.uploading:
        return 'Uploading image';
      case BatchUploadItemStatus.processing:
        return 'Processing with AI';
      case BatchUploadItemStatus.completed:
        return 'Completed successfully';
      case BatchUploadItemStatus.failed:
        return 'Failed: ${error ?? 'Unknown error'}';
      case BatchUploadItemStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get human-readable stage description
  String get stageDescription {
    if (currentStage == null) return statusDescription;
    
    switch (currentStage!) {
      case BatchProcessingStage.initializing:
        return 'Initializing...';
      case BatchProcessingStage.uploadingImage:
        return 'Uploading image to cloud storage...';
      case BatchProcessingStage.creatingRecord:
        return 'Creating receipt record...';
      case BatchProcessingStage.aiProcessing:
        return 'Processing with AI Vision...';
      case BatchProcessingStage.finalizing:
        return 'Finalizing receipt data...';
      case BatchProcessingStage.completed:
        return 'Processing completed';
      case BatchProcessingStage.failed:
        return 'Processing failed';
    }
  }



  @override
  List<Object?> get props => [
        id,
        file,
        fileName,
        fileSize,
        mimeType,
        status,
        currentStage,
        progress,
        error,
        receiptId,
        createdAt,
        startedAt,
        completedAt,
        processingLogs,
        metadata,
      ];
}

/// Overall state of the batch upload operation
@JsonSerializable()
class BatchUploadState extends Equatable {
  final BatchUploadStatus status;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<BatchUploadItem> items;
  final int maxConcurrentUploads;
  final int totalProgress; // 0-100
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? settings;

  const BatchUploadState({
    this.status = BatchUploadStatus.idle,
    this.items = const [],
    this.maxConcurrentUploads = 2,
    this.totalProgress = 0,
    this.error,
    this.startedAt,
    this.completedAt,
    this.settings,
  });



  BatchUploadState copyWith({
    BatchUploadStatus? status,
    List<BatchUploadItem>? items,
    int? maxConcurrentUploads,
    int? totalProgress,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? settings,
  }) {
    return BatchUploadState(
      status: status ?? this.status,
      items: items ?? this.items,
      maxConcurrentUploads: maxConcurrentUploads ?? this.maxConcurrentUploads,
      totalProgress: totalProgress ?? this.totalProgress,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      settings: settings ?? this.settings,
    );
  }

  /// Get items by status
  List<BatchUploadItem> get queuedItems =>
      items.where((item) => item.status == BatchUploadItemStatus.queued).toList();

  List<BatchUploadItem> get activeItems =>
      items.where((item) => item.isActive).toList();

  List<BatchUploadItem> get completedItems =>
      items.where((item) => item.status == BatchUploadItemStatus.completed).toList();

  List<BatchUploadItem> get failedItems =>
      items.where((item) => item.status == BatchUploadItemStatus.failed).toList();

  /// Get processing statistics
  int get totalItems => items.length;
  int get completedCount => completedItems.length;
  int get failedCount => failedItems.length;
  int get activeCount => activeItems.length;
  int get queuedCount => queuedItems.length;

  /// Check if batch is currently processing
  bool get isProcessing => status == BatchUploadStatus.processing;

  /// Check if batch is completed (all items finished)
  bool get isCompleted => status == BatchUploadStatus.completed;

  /// Check if batch has any failures
  bool get hasFailures => failedItems.isNotEmpty;

  /// Get success rate as percentage
  double get successRate {
    if (totalItems == 0) return 0.0;
    return (completedCount / totalItems) * 100;
  }

  /// Get list of successful receipt IDs
  List<String> get successfulReceiptIds =>
      completedItems.where((item) => item.receiptId != null).map((item) => item.receiptId!).toList();

  factory BatchUploadState.fromJson(Map<String, dynamic> json) =>
      _$BatchUploadStateFromJson(json);

  Map<String, dynamic> toJson() => _$BatchUploadStateToJson(this);

  @override
  List<Object?> get props => [
        status,
        items,
        maxConcurrentUploads,
        totalProgress,
        error,
        startedAt,
        completedAt,
        settings,
      ];
}
