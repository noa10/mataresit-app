import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'processing_log_model.g.dart';

/// Processing log model for real-time receipt processing feedback
@JsonSerializable()
class ProcessingLogModel extends Equatable {
  final String id;
  @JsonKey(name: 'receipt_id')
  final String receiptId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'status_message')
  final String statusMessage;
  @JsonKey(name: 'step_name')
  final String? stepName;
  final int? progress;

  const ProcessingLogModel({
    required this.id,
    required this.receiptId,
    required this.createdAt,
    required this.statusMessage,
    this.stepName,
    this.progress,
  });

  factory ProcessingLogModel.fromJson(Map<String, dynamic> json) =>
      _$ProcessingLogModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessingLogModelToJson(this);

  ProcessingLogModel copyWith({
    String? id,
    String? receiptId,
    DateTime? createdAt,
    String? statusMessage,
    String? stepName,
    int? progress,
  }) {
    return ProcessingLogModel(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      createdAt: createdAt ?? this.createdAt,
      statusMessage: statusMessage ?? this.statusMessage,
      stepName: stepName ?? this.stepName,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        id,
        receiptId,
        createdAt,
        statusMessage,
        stepName,
        progress,
      ];
}

/// Processing stage information
class ProcessingStage {
  final String name;
  final String description;
  final String color;
  final bool isCompleted;
  final bool isActive;
  final bool hasError;

  const ProcessingStage({
    required this.name,
    required this.description,
    required this.color,
    this.isCompleted = false,
    this.isActive = false,
    this.hasError = false,
  });

  ProcessingStage copyWith({
    String? name,
    String? description,
    String? color,
    bool? isCompleted,
    bool? isActive,
    bool? hasError,
  }) {
    return ProcessingStage(
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      hasError: hasError ?? this.hasError,
    );
  }
}

/// Processing stages constants matching React app
class ProcessingStages {
  static const Map<String, ProcessingStage> stages = {
    'START': ProcessingStage(
      name: 'Uploading',
      description: 'Uploading receipt image',
      color: '#3B82F6', // blue-500
    ),
    'FETCH': ProcessingStage(
      name: 'Uploaded',
      description: 'Receipt image uploaded successfully',
      color: '#3B82F6', // blue-500
    ),
    'PROCESSING': ProcessingStage(
      name: 'AI Processing',
      description: 'Processing receipt with AI',
      color: '#6366F1', // indigo-500
    ),
    'EXTRACT': ProcessingStage(
      name: 'Extracting',
      description: 'Extracting key data from receipt',
      color: '#8B5CF6', // purple-500
    ),
    'GEMINI': ProcessingStage(
      name: 'AI Analysis',
      description: 'Analyzing receipt with AI',
      color: '#8B5CF6', // violet-500
    ),
    'SAVE': ProcessingStage(
      name: 'Saving',
      description: 'Saving processed data',
      color: '#D946EF', // fuchsia-500
    ),
    'COMPLETE': ProcessingStage(
      name: 'Complete',
      description: 'Processing complete',
      color: '#10B981', // green-500
    ),
    'ERROR': ProcessingStage(
      name: 'Error',
      description: 'An error occurred during processing',
      color: '#EF4444', // red-500
    ),
  };

  static ProcessingStage getStage(String stageName) {
    return stages[stageName] ?? stages['START']!;
  }

  static List<String> get orderedStages => [
        'START',
        'FETCH',
        'PROCESSING',
        'SAVE',
        'COMPLETE'
      ];
}

/// Enhanced upload state for detailed progress tracking
class ReceiptUploadState extends Equatable {
  final String id;
  final String status; // 'pending', 'uploading', 'processing', 'completed', 'error'
  final int uploadProgress; // 0-100
  final String? currentStage;
  final List<String> stageHistory;
  final List<ProcessingLogModel> processLogs;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? error;
  final bool isProgressUpdating;

  const ReceiptUploadState({
    required this.id,
    this.status = 'pending',
    this.uploadProgress = 0,
    this.currentStage,
    this.stageHistory = const [],
    this.processLogs = const [],
    this.startTime,
    this.endTime,
    this.error,
    this.isProgressUpdating = false,
  });

  ReceiptUploadState copyWith({
    String? id,
    String? status,
    int? uploadProgress,
    String? currentStage,
    List<String>? stageHistory,
    List<ProcessingLogModel>? processLogs,
    DateTime? startTime,
    DateTime? endTime,
    String? error,
    bool? isProgressUpdating,
  }) {
    return ReceiptUploadState(
      id: id ?? this.id,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      currentStage: currentStage ?? this.currentStage,
      stageHistory: stageHistory ?? this.stageHistory,
      processLogs: processLogs ?? this.processLogs,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      error: error,
      isProgressUpdating: isProgressUpdating ?? this.isProgressUpdating,
    );
  }

  bool get isUploading => status == 'uploading' || status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get hasError => status == 'error';
  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
        id,
        status,
        uploadProgress,
        currentStage,
        stageHistory,
        processLogs,
        startTime,
        endTime,
        error,
        isProgressUpdating,
      ];
}
