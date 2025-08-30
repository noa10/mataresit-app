// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptModel _$ReceiptModelFromJson(Map<String, dynamic> json) => ReceiptModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  teamId: json['teamId'] as String?,
  merchantName: json['merchantName'] as String?,
  merchantAddress: json['merchantAddress'] as String?,
  merchantPhone: json['merchantPhone'] as String?,
  merchantEmail: json['merchantEmail'] as String?,
  receiptNumber: json['receiptNumber'] as String?,
  transactionDate: json['transactionDate'] == null
      ? null
      : DateTime.parse(json['transactionDate'] as String),
  totalAmount: (json['totalAmount'] as num?)?.toDouble(),
  taxAmount: (json['taxAmount'] as num?)?.toDouble(),
  discountAmount: (json['discountAmount'] as num?)?.toDouble(),
  tipAmount: (json['tipAmount'] as num?)?.toDouble(),
  currency: json['currency'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  category: json['category'] as String?,
  customCategoryId: json['custom_category_id'] as String?,
  description: json['description'] as String?,
  notes: json['notes'] as String?,
  imageUrl: json['imageUrl'] as String?,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  originalFileName: json['originalFileName'] as String?,
  fileSize: (json['fileSize'] as num?)?.toInt(),
  mimeType: json['mimeType'] as String?,
  status: $enumDecode(_$ReceiptStatusEnumMap, json['status']),
  processingStatus: $enumDecode(
    _$ProcessingStatusEnumMap,
    json['processingStatus'],
  ),
  ocrData: json['ocrData'] as Map<String, dynamic>?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  isExpense: json['isExpense'] as bool,
  isReimbursable: json['isReimbursable'] as bool,
  projectId: json['projectId'] as String?,
  clientId: json['clientId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  processedAt: json['processedAt'] == null
      ? null
      : DateTime.parse(json['processedAt'] as String),
  lineItems: (json['line_items'] as List<dynamic>?)
      ?.map((e) => LineItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReceiptModelToJson(ReceiptModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'teamId': instance.teamId,
      'merchantName': instance.merchantName,
      'merchantAddress': instance.merchantAddress,
      'merchantPhone': instance.merchantPhone,
      'merchantEmail': instance.merchantEmail,
      'receiptNumber': instance.receiptNumber,
      'transactionDate': instance.transactionDate?.toIso8601String(),
      'totalAmount': instance.totalAmount,
      'taxAmount': instance.taxAmount,
      'discountAmount': instance.discountAmount,
      'tipAmount': instance.tipAmount,
      'currency': instance.currency,
      'paymentMethod': instance.paymentMethod,
      'category': instance.category,
      'custom_category_id': instance.customCategoryId,
      'description': instance.description,
      'notes': instance.notes,
      'imageUrl': instance.imageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'originalFileName': instance.originalFileName,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'status': _$ReceiptStatusEnumMap[instance.status]!,
      'processingStatus': _$ProcessingStatusEnumMap[instance.processingStatus]!,
      'ocrData': instance.ocrData,
      'metadata': instance.metadata,
      'tags': instance.tags,
      'isExpense': instance.isExpense,
      'isReimbursable': instance.isReimbursable,
      'projectId': instance.projectId,
      'clientId': instance.clientId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'line_items': instance.lineItems,
    };

const _$ReceiptStatusEnumMap = {
  ReceiptStatus.draft: 'draft',
  ReceiptStatus.active: 'active',
  ReceiptStatus.archived: 'archived',
  ReceiptStatus.deleted: 'deleted',
};

const _$ProcessingStatusEnumMap = {
  ProcessingStatus.pending: 'pending',
  ProcessingStatus.processing: 'processing',
  ProcessingStatus.completed: 'completed',
  ProcessingStatus.failed: 'failed',
  ProcessingStatus.manualReview: 'manual_review',
};
