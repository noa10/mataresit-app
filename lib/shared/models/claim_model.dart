import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'claim_model.g.dart';

/// Claim status enum matching React app
enum ClaimStatus {
  @JsonValue('draft')
  draft,
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

/// Main claim model matching React app structure
@JsonSerializable()
class ClaimModel extends Equatable {
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
    required this.metadata,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.claimantName,
    this.claimantEmail,
    this.reviewerName,
    this.approverName,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) =>
      _$ClaimModelFromJson(json);

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
    );
  }

  /// Check if claim can be edited
  bool get canEdit => status == ClaimStatus.draft;

  /// Check if claim can be submitted
  bool get canSubmit => status == ClaimStatus.draft && title.isNotEmpty && amount > 0;

  /// Check if claim can be approved
  bool get canApprove => status == ClaimStatus.pending || status == ClaimStatus.underReview;

  /// Check if claim can be rejected
  bool get canReject => status == ClaimStatus.pending || status == ClaimStatus.underReview;

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case ClaimStatus.draft:
        return 'Draft';
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
    required this.metadata,
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
