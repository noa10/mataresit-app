// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessingLogModel _$ProcessingLogModelFromJson(Map<String, dynamic> json) =>
    ProcessingLogModel(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      statusMessage: json['status_message'] as String,
      stepName: json['step_name'] as String?,
      progress: (json['progress'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProcessingLogModelToJson(ProcessingLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receipt_id': instance.receiptId,
      'created_at': instance.createdAt.toIso8601String(),
      'status_message': instance.statusMessage,
      'step_name': instance.stepName,
      'progress': instance.progress,
    };
