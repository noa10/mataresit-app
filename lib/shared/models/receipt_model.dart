import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'receipt_model.g.dart';

@JsonSerializable()
class ReceiptModel extends Equatable {
  final String id;
  final String userId;
  final String? teamId;
  final String? merchantName;
  final String? merchantAddress;
  final String? merchantPhone;
  final String? merchantEmail;
  final String? receiptNumber;
  final DateTime? transactionDate;
  final double? totalAmount;
  final double? taxAmount;
  final double? discountAmount;
  final double? tipAmount;
  final String? currency;
  final String? paymentMethod;
  final String? category;
  final String? description;
  final String? notes;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? originalFileName;
  final int? fileSize;
  final String? mimeType;
  final ReceiptStatus status;
  final ProcessingStatus processingStatus;
  final Map<String, dynamic>? ocrData;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  final bool isExpense;
  final bool isReimbursable;
  final String? projectId;
  final String? clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;

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
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) => _$ReceiptModelFromJson(json);

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
      ];
}

@JsonEnum()
enum ReceiptStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('active')
  active,
  @JsonValue('archived')
  archived,
  @JsonValue('deleted')
  deleted,
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

extension ReceiptStatusExtension on ReceiptStatus {
  String get displayName {
    switch (this) {
      case ReceiptStatus.draft:
        return 'Draft';
      case ReceiptStatus.active:
        return 'Active';
      case ReceiptStatus.archived:
        return 'Archived';
      case ReceiptStatus.deleted:
        return 'Deleted';
    }
  }

  bool get isActive => this == ReceiptStatus.active;
  bool get isDraft => this == ReceiptStatus.draft;
  bool get isArchived => this == ReceiptStatus.archived;
  bool get isDeleted => this == ReceiptStatus.deleted;
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
