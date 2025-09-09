import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

part 'claim_model.g.dart';

/// Claim status enum matching React app
enum ClaimStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('submitted')
  submitted,
  @JsonValue('pending')
  pending,
  @JsonValue('under_review')
  underReview,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('paid')
  paid,
}

/// Claim priority enum matching React app
enum ClaimPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Extension for ClaimPriority display names
extension ClaimPriorityExtension on ClaimPriority {
  String get displayName {
    switch (this) {
      case ClaimPriority.low:
        return 'Low';
      case ClaimPriority.medium:
        return 'Medium';
      case ClaimPriority.high:
        return 'High';
      case ClaimPriority.urgent:
        return 'Urgent';
    }
  }
}

/// Main claim model matching React app structure
@JsonSerializable()
class ClaimModel extends Equatable {
  static final Logger _logger = Logger();
  final String id;
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'claimant_id')
  final String claimantId;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String? category;
  final ClaimPriority priority;
  final ClaimStatus status;

  // Approval workflow fields
  @JsonKey(name: 'submitted_at')
  final DateTime? submittedAt;
  @JsonKey(name: 'reviewed_by')
  final String? reviewedBy;
  @JsonKey(name: 'reviewed_at')
  final DateTime? reviewedAt;
  @JsonKey(name: 'approved_by')
  final String? approvedBy;
  @JsonKey(name: 'approved_at')
  final DateTime? approvedAt;
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;

  // Metadata and attachments
  final Map<String, dynamic> metadata;
  final List<dynamic> attachments;

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Joined data (optional, populated by queries with joins)
  @JsonKey(name: 'claimant_name')
  final String? claimantName;
  @JsonKey(name: 'claimant_email')
  final String? claimantEmail;
  @JsonKey(name: 'reviewer_name')
  final String? reviewerName;
  @JsonKey(name: 'approver_name')
  final String? approverName;

  // Multilingual fields (optional)
  @JsonKey(name: 'title_ms')
  final String? titleMs;
  @JsonKey(name: 'description_ms')
  final String? descriptionMs;

  const ClaimModel({
    required this.id,
    required this.teamId,
    required this.claimantId,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    this.category,
    required this.priority,
    required this.status,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.metadata = const {},
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.claimantName,
    this.claimantEmail,
    this.reviewerName,
    this.approverName,
    this.titleMs,
    this.descriptionMs,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    _logger.i('  Parsing claim JSON for: ${json['id']}');

    // Handle attachments field that might be stored as JSON string or array
    List<dynamic> attachments = const [];
    if (json['attachments'] != null) {
      _logger.i(
        '    Raw attachments: ${json['attachments']} (${json['attachments'].runtimeType})',
      );
      if (json['attachments'] is String) {
        try {
          // Try to parse JSON string
          final parsed = jsonDecode(json['attachments']);
          if (parsed is List) {
            attachments = List<dynamic>.from(parsed);
          } else {
            _logger.w('    Warning: Parsed attachments is not a list: $parsed');
            attachments = const [];
          }
        } catch (e) {
          // If parsing fails, treat as empty array
          _logger.w('    Warning: Failed to parse attachments JSON: $e');
          attachments = const [];
        }
      } else if (json['attachments'] is List) {
        attachments = List<dynamic>.from(json['attachments']);
      } else {
        _logger.w(
          '    Warning: Unexpected attachments type: ${json['attachments'].runtimeType}',
        );
        attachments = const [];
      }
    }
    _logger.i('    Processed attachments: $attachments');

    // Handle metadata field that might be stored as JSON string or map
    Map<String, dynamic> metadata = const {};
    if (json['metadata'] != null) {
      _logger.i(
        '    Raw metadata: ${json['metadata']} (${json['metadata'].runtimeType})',
      );
      if (json['metadata'] is String) {
        try {
          // Try to parse JSON string
          final parsed = jsonDecode(json['metadata']);
          if (parsed is Map) {
            metadata = Map<String, dynamic>.from(parsed);
          } else {
            _logger.w('    Warning: Parsed metadata is not a map: $parsed');
            metadata = const {};
          }
        } catch (e) {
          // If parsing fails, treat as empty map
          _logger.w('    Warning: Failed to parse metadata JSON: $e');
          metadata = const {};
        }
      } else if (json['metadata'] is Map) {
        metadata = Map<String, dynamic>.from(json['metadata']);
      } else {
        _logger.w(
          '    Warning: Unexpected metadata type: ${json['metadata'].runtimeType}',
        );
        metadata = const {};
      }
    }
    _logger.i('    Processed metadata: $metadata');

    // Create a modified JSON object for the generated parser
    final modifiedJson = Map<String, dynamic>.from(json);
    modifiedJson['attachments'] = attachments;
    modifiedJson['metadata'] = metadata;

    _logger.i('    Calling generated parser with processed data');
    return _$ClaimModelFromJson(modifiedJson);
  }

  Map<String, dynamic> toJson() => _$ClaimModelToJson(this);

  /// Create a copy with updated fields
  ClaimModel copyWith({
    String? id,
    String? teamId,
    String? claimantId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
    ClaimPriority? priority,
    ClaimStatus? status,
    DateTime? submittedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
    List<dynamic>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? claimantName,
    String? claimantEmail,
    String? reviewerName,
    String? approverName,
    String? titleMs,
    String? descriptionMs,
  }) {
    return ClaimModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      claimantId: claimantId ?? this.claimantId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      claimantName: claimantName ?? this.claimantName,
      claimantEmail: claimantEmail ?? this.claimantEmail,
      reviewerName: reviewerName ?? this.reviewerName,
      approverName: approverName ?? this.approverName,
      titleMs: titleMs ?? this.titleMs,
      descriptionMs: descriptionMs ?? this.descriptionMs,
    );
  }

  /// Check if claim can be edited
  bool get canEdit => status == ClaimStatus.draft;

  /// Check if claim can be submitted
  bool get canSubmit =>
      status == ClaimStatus.draft && title.isNotEmpty && amount > 0;

  /// Check if claim can be approved
  bool get canApprove =>
      status == ClaimStatus.submitted ||
      status == ClaimStatus.pending ||
      status == ClaimStatus.underReview;

  /// Check if claim can be rejected
  bool get canReject =>
      status == ClaimStatus.submitted ||
      status == ClaimStatus.pending ||
      status == ClaimStatus.underReview;

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.pending:
        return 'Pending Review';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.paid:
        return 'Paid';
    }
  }

  /// Get priority display name
  String get priorityDisplayName {
    switch (priority) {
      case ClaimPriority.low:
        return 'Low';
      case ClaimPriority.medium:
        return 'Medium';
      case ClaimPriority.high:
        return 'High';
      case ClaimPriority.urgent:
        return 'Urgent';
    }
  }

  @override
  List<Object?> get props => [
    id,
    teamId,
    claimantId,
    title,
    description,
    amount,
    currency,
    category,
    priority,
    status,
    submittedAt,
    reviewedBy,
    reviewedAt,
    approvedBy,
    approvedAt,
    rejectionReason,
    metadata,
    attachments,
    createdAt,
    updatedAt,
    claimantName,
    claimantEmail,
    reviewerName,
    approverName,
    titleMs,
    descriptionMs,
  ];
}

/// Claim audit trail model
@JsonSerializable()
class ClaimAuditTrailModel extends Equatable {
  final String id;
  @JsonKey(name: 'claim_id')
  final String claimId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String action;
  @JsonKey(name: 'old_status')
  final ClaimStatus? oldStatus;
  @JsonKey(name: 'new_status')
  final ClaimStatus? newStatus;
  final String? comment;
  final Map<String, dynamic> metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Joined data
  @JsonKey(name: 'user_name')
  final String? userName;
  @JsonKey(name: 'user_email')
  final String? userEmail;

  const ClaimAuditTrailModel({
    required this.id,
    required this.claimId,
    required this.userId,
    required this.action,
    this.oldStatus,
    this.newStatus,
    this.comment,
    this.metadata = const {},
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory ClaimAuditTrailModel.fromJson(Map<String, dynamic> json) =>
      _$ClaimAuditTrailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimAuditTrailModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    claimId,
    userId,
    action,
    oldStatus,
    newStatus,
    comment,
    metadata,
    createdAt,
    userName,
    userEmail,
  ];
}
