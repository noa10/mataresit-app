// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_upload_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchUploadState _$BatchUploadStateFromJson(Map<String, dynamic> json) =>
    BatchUploadState(
      status:
          $enumDecodeNullable(_$BatchUploadStatusEnumMap, json['status']) ??
          BatchUploadStatus.idle,
      maxConcurrentUploads:
          (json['maxConcurrentUploads'] as num?)?.toInt() ?? 2,
      totalProgress: (json['totalProgress'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BatchUploadStateToJson(BatchUploadState instance) =>
    <String, dynamic>{
      'status': _$BatchUploadStatusEnumMap[instance.status]!,
      'maxConcurrentUploads': instance.maxConcurrentUploads,
      'totalProgress': instance.totalProgress,
      'error': instance.error,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'settings': instance.settings,
    };

const _$BatchUploadStatusEnumMap = {
  BatchUploadStatus.idle: 'idle',
  BatchUploadStatus.selecting: 'selecting',
  BatchUploadStatus.ready: 'ready',
  BatchUploadStatus.processing: 'processing',
  BatchUploadStatus.paused: 'paused',
  BatchUploadStatus.completed: 'completed',
  BatchUploadStatus.cancelled: 'cancelled',
};
