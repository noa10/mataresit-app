// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptModel _$ReceiptModelFromJson(Map<String, dynamic> json) => ReceiptModel(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  teamId: json['team_id'] as String?,
  merchantName: json['merchant'] as String?,
  merchantAddress: json['merchant_address'] as String?,
  merchantPhone: json['merchant_phone'] as String?,
  merchantEmail: json['merchant_email'] as String?,
  receiptNumber: json['receipt_number'] as String?,
  transactionDate: json['date'] == null
      ? null
      : DateTime.parse(json['date'] as String),
  totalAmount: (json['total'] as num?)?.toDouble(),
  taxAmount: (json['tax'] as num?)?.toDouble(),
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
  tipAmount: (json['tip_amount'] as num?)?.toDouble(),
  currency: json['currency'] as String?,
  paymentMethod: json['payment_method'] as String?,
  category: json['predicted_category'] as String?,
  customCategoryId: json['custom_category_id'] as String?,
  description: json['description'] as String?,
  notes: json['notes'] as String?,
  imageUrl: json['image_url'] as String?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  originalFileName: json['original_file_name'] as String?,
  fileSize: (json['file_size'] as num?)?.toInt(),
  mimeType: json['mime_type'] as String?,
  status: $enumDecode(_$ReceiptStatusEnumMap, json['status']),
  processingStatus: const ProcessingStatusConverter().fromJson(
    json['processing_status'] as String?,
  ),
  ocrData: json['ocr_data'] as Map<String, dynamic>?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  isExpense: json['is_expense'] as bool? ?? true,
  isReimbursable: json['is_reimbursable'] as bool? ?? true,
  projectId: json['project_id'] as String?,
  clientId: json['client_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  processedAt: json['processed_at'] == null
      ? null
      : DateTime.parse(json['processed_at'] as String),
  lineItems: (json['line_items'] as List<dynamic>?)
      ?.map((e) => LineItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  confidenceScores: json['confidence_scores'] as Map<String, dynamic>?,
  aiSuggestions: json['ai_suggestions'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ReceiptModelToJson(ReceiptModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'team_id': instance.teamId,
      'merchant': instance.merchantName,
      'merchant_address': instance.merchantAddress,
      'merchant_phone': instance.merchantPhone,
      'merchant_email': instance.merchantEmail,
      'receipt_number': instance.receiptNumber,
      'date': instance.transactionDate?.toIso8601String(),
      'total': instance.totalAmount,
      'tax': instance.taxAmount,
      'discount_amount': instance.discountAmount,
      'tip_amount': instance.tipAmount,
      'currency': instance.currency,
      'payment_method': instance.paymentMethod,
      'predicted_category': instance.category,
      'custom_category_id': instance.customCategoryId,
      'description': instance.description,
      'notes': instance.notes,
      'image_url': instance.imageUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'original_file_name': instance.originalFileName,
      'file_size': instance.fileSize,
      'mime_type': instance.mimeType,
      'status': _$ReceiptStatusEnumMap[instance.status]!,
      'processing_status': const ProcessingStatusConverter().toJson(
        instance.processingStatus,
      ),
      'ocr_data': instance.ocrData,
      'metadata': instance.metadata,
      'tags': instance.tags,
      'is_expense': instance.isExpense,
      'is_reimbursable': instance.isReimbursable,
      'project_id': instance.projectId,
      'client_id': instance.clientId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'processed_at': instance.processedAt?.toIso8601String(),
      'line_items': instance.lineItems,
      'confidence_scores': instance.confidenceScores,
      'ai_suggestions': instance.aiSuggestions,
    };

const _$ReceiptStatusEnumMap = {
  ReceiptStatus.draft: 'draft',
  ReceiptStatus.active: 'active',
  ReceiptStatus.archived: 'archived',
  ReceiptStatus.deleted: 'deleted',
};
