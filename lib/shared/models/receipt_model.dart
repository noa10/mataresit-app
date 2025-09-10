import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'line_item_model.dart';

part 'receipt_model.g.dart';

/// Custom JSON converter for ProcessingStatus to handle cross-platform compatibility
class ProcessingStatusConverter
    implements JsonConverter<ProcessingStatus, String?> {
  const ProcessingStatusConverter();

  @override
  ProcessingStatus fromJson(String? json) {
    if (json == null) return ProcessingStatus.completed;

    switch (json.toLowerCase()) {
      case 'pending':
        return ProcessingStatus.pending;
      case 'processing':
        return ProcessingStatus.processing;
      case 'completed':
        return ProcessingStatus.completed;
      case 'complete': // Handle React app's 'complete' value
        return ProcessingStatus.completed;
      case 'failed':
        return ProcessingStatus.failed;
      case 'manual_review':
        return ProcessingStatus.manualReview;
      default:
        // Default to completed for unknown values
        return ProcessingStatus.completed;
    }
  }

  @override
  String toJson(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.pending:
        return 'pending';
      case ProcessingStatus.processing:
        return 'processing';
      case ProcessingStatus.completed:
        return 'completed';
      case ProcessingStatus.failed:
        return 'failed';
      case ProcessingStatus.manualReview:
        return 'manual_review';
    }
  }
}

@JsonSerializable()
class ReceiptModel extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'team_id')
  final String? teamId;
  @JsonKey(name: 'merchant')
  final String? merchantName;
  @JsonKey(name: 'merchant_address')
  final String? merchantAddress;
  @JsonKey(name: 'merchant_phone')
  final String? merchantPhone;
  @JsonKey(name: 'merchant_email')
  final String? merchantEmail;
  @JsonKey(name: 'receipt_number')
  final String? receiptNumber;
  @JsonKey(name: 'date')
  final DateTime? transactionDate;
  @JsonKey(name: 'total')
  final double? totalAmount;
  @JsonKey(name: 'tax')
  final double? taxAmount;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'tip_amount')
  final double? tipAmount;
  final String? currency;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'predicted_category')
  final String? category;
  @JsonKey(name: 'custom_category_id')
  final String? customCategoryId;
  final String? description;
  final String? notes;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @JsonKey(name: 'original_file_name')
  final String? originalFileName;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  final ReceiptStatus status;
  @JsonKey(name: 'processing_status')
  @ProcessingStatusConverter()
  final ProcessingStatus processingStatus;
  @JsonKey(name: 'ocr_data')
  final Map<String, dynamic>? ocrData;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  @JsonKey(name: 'is_expense', defaultValue: true)
  final bool isExpense;
  @JsonKey(name: 'is_reimbursable', defaultValue: true)
  final bool isReimbursable;
  @JsonKey(name: 'project_id')
  final String? projectId;
  @JsonKey(name: 'client_id')
  final String? clientId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'processed_at')
  final DateTime? processedAt;
  @JsonKey(name: 'line_items')
  final List<LineItemModel>? lineItems;
  @JsonKey(name: 'confidence_scores')
  final Map<String, dynamic>? confidenceScores;
  @JsonKey(name: 'ai_suggestions')
  final Map<String, dynamic>? aiSuggestions;

  const ReceiptModel({
    required this.id,
    required this.userId,
    this.teamId,
    this.merchantName,
    this.merchantAddress,
    this.merchantPhone,
    this.merchantEmail,
    this.receiptNumber,
    this.transactionDate,
    this.totalAmount,
    this.taxAmount,
    this.discountAmount,
    this.tipAmount,
    this.currency,
    this.paymentMethod,
    this.category,
    this.customCategoryId,
    this.description,
    this.notes,
    this.imageUrl,
    this.thumbnailUrl,
    this.originalFileName,
    this.fileSize,
    this.mimeType,
    required this.status,
    required this.processingStatus,
    this.ocrData,
    this.metadata,
    this.tags,
    required this.isExpense,
    required this.isReimbursable,
    this.projectId,
    this.clientId,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
    this.lineItems,
    this.confidenceScores,
    this.aiSuggestions,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptModelToJson(this);

  ReceiptModel copyWith({
    String? id,
    String? userId,
    String? teamId,
    String? merchantName,
    String? merchantAddress,
    String? merchantPhone,
    String? merchantEmail,
    String? receiptNumber,
    DateTime? transactionDate,
    double? totalAmount,
    double? taxAmount,
    double? discountAmount,
    double? tipAmount,
    String? currency,
    String? paymentMethod,
    String? category,
    String? customCategoryId,
    String? description,
    String? notes,
    String? imageUrl,
    String? thumbnailUrl,
    String? originalFileName,
    int? fileSize,
    String? mimeType,
    ReceiptStatus? status,
    ProcessingStatus? processingStatus,
    Map<String, dynamic>? ocrData,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isExpense,
    bool? isReimbursable,
    String? projectId,
    String? clientId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? processedAt,
    List<LineItemModel>? lineItems,
    Map<String, dynamic>? confidenceScores,
    Map<String, dynamic>? aiSuggestions,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      merchantName: merchantName ?? this.merchantName,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      merchantEmail: merchantEmail ?? this.merchantEmail,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      category: category ?? this.category,
      customCategoryId: customCategoryId ?? this.customCategoryId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      originalFileName: originalFileName ?? this.originalFileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      processingStatus: processingStatus ?? this.processingStatus,
      ocrData: ocrData ?? this.ocrData,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isExpense: isExpense ?? this.isExpense,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      projectId: projectId ?? this.projectId,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedAt: processedAt ?? this.processedAt,
      lineItems: lineItems ?? this.lineItems,
      confidenceScores: confidenceScores ?? this.confidenceScores,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    teamId,
    merchantName,
    merchantAddress,
    merchantPhone,
    merchantEmail,
    receiptNumber,
    transactionDate,
    totalAmount,
    taxAmount,
    discountAmount,
    tipAmount,
    currency,
    paymentMethod,
    category,
    customCategoryId,
    description,
    notes,
    imageUrl,
    thumbnailUrl,
    originalFileName,
    fileSize,
    mimeType,
    status,
    processingStatus,
    ocrData,
    metadata,
    tags,
    isExpense,
    isReimbursable,
    projectId,
    clientId,
    createdAt,
    updatedAt,
    processedAt,
    lineItems,
    confidenceScores,
    aiSuggestions,
  ];
}

@JsonEnum()
enum ReceiptStatus {
  @JsonValue('unreviewed')
  unreviewed,
  @JsonValue('reviewed')
  reviewed,
}

@JsonEnum()
enum ProcessingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('manual_review')
  manualReview,
}

/// Filter enum for reviewed status filtering
enum ReviewedStatusFilter { all, reviewed, unreviewed }

extension ReceiptStatusExtension on ReceiptStatus {
  String get displayName {
    switch (this) {
      case ReceiptStatus.unreviewed:
        return 'Unreviewed';
      case ReceiptStatus.reviewed:
        return 'Reviewed';
    }
  }

  bool get isReviewed => this == ReceiptStatus.reviewed;
  bool get isUnreviewed => this == ReceiptStatus.unreviewed;
}

extension ReviewedStatusFilterExtension on ReviewedStatusFilter {
  String get displayName {
    switch (this) {
      case ReviewedStatusFilter.all:
        return 'All';
      case ReviewedStatusFilter.reviewed:
        return 'Reviewed';
      case ReviewedStatusFilter.unreviewed:
        return 'Unreviewed';
    }
  }

  ReceiptStatus? get receiptStatus {
    switch (this) {
      case ReviewedStatusFilter.all:
        return null;
      case ReviewedStatusFilter.reviewed:
        return ReceiptStatus.reviewed;
      case ReviewedStatusFilter.unreviewed:
        return ReceiptStatus.unreviewed;
    }
  }
}

extension ProcessingStatusExtension on ProcessingStatus {
  String get displayName {
    switch (this) {
      case ProcessingStatus.pending:
        return 'Pending';
      case ProcessingStatus.processing:
        return 'Processing';
      case ProcessingStatus.completed:
        return 'Completed';
      case ProcessingStatus.failed:
        return 'Failed';
      case ProcessingStatus.manualReview:
        return 'Manual Review';
    }
  }

  bool get isCompleted => this == ProcessingStatus.completed;
  bool get isPending => this == ProcessingStatus.pending;
  bool get isProcessing => this == ProcessingStatus.processing;
  bool get isFailed => this == ProcessingStatus.failed;
  bool get needsReview => this == ProcessingStatus.manualReview;
}
