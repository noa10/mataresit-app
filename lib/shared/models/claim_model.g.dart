// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimModel _$ClaimModelFromJson(Map<String, dynamic> json) => ClaimModel(
  id: json['id'] as String,
  teamId: json['team_id'] as String,
  claimantId: json['claimant_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  category: json['category'] as String?,
  priority: $enumDecode(_$ClaimPriorityEnumMap, json['priority']),
  status: $enumDecode(_$ClaimStatusEnumMap, json['status']),
  submittedAt: json['submitted_at'] == null
      ? null
      : DateTime.parse(json['submitted_at'] as String),
  reviewedBy: json['reviewed_by'] as String?,
  reviewedAt: json['reviewed_at'] == null
      ? null
      : DateTime.parse(json['reviewed_at'] as String),
  approvedBy: json['approved_by'] as String?,
  approvedAt: json['approved_at'] == null
      ? null
      : DateTime.parse(json['approved_at'] as String),
  rejectionReason: json['rejection_reason'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  attachments: json['attachments'] as List<dynamic>? ?? const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  claimantName: json['claimant_name'] as String?,
  claimantEmail: json['claimant_email'] as String?,
  reviewerName: json['reviewer_name'] as String?,
  approverName: json['approver_name'] as String?,
  titleMs: json['title_ms'] as String?,
  descriptionMs: json['description_ms'] as String?,
);

Map<String, dynamic> _$ClaimModelToJson(ClaimModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'team_id': instance.teamId,
      'claimant_id': instance.claimantId,
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'currency': instance.currency,
      'category': instance.category,
      'priority': _$ClaimPriorityEnumMap[instance.priority]!,
      'status': _$ClaimStatusEnumMap[instance.status]!,
      'submitted_at': instance.submittedAt?.toIso8601String(),
      'reviewed_by': instance.reviewedBy,
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'approved_by': instance.approvedBy,
      'approved_at': instance.approvedAt?.toIso8601String(),
      'rejection_reason': instance.rejectionReason,
      'metadata': instance.metadata,
      'attachments': instance.attachments,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'claimant_name': instance.claimantName,
      'claimant_email': instance.claimantEmail,
      'reviewer_name': instance.reviewerName,
      'approver_name': instance.approverName,
      'title_ms': instance.titleMs,
      'description_ms': instance.descriptionMs,
    };

const _$ClaimPriorityEnumMap = {
  ClaimPriority.low: 'low',
  ClaimPriority.medium: 'medium',
  ClaimPriority.high: 'high',
  ClaimPriority.urgent: 'urgent',
};

const _$ClaimStatusEnumMap = {
  ClaimStatus.draft: 'draft',
  ClaimStatus.submitted: 'submitted',
  ClaimStatus.pending: 'pending',
  ClaimStatus.underReview: 'under_review',
  ClaimStatus.approved: 'approved',
  ClaimStatus.rejected: 'rejected',
  ClaimStatus.paid: 'paid',
};

ClaimAuditTrailModel _$ClaimAuditTrailModelFromJson(
  Map<String, dynamic> json,
) => ClaimAuditTrailModel(
  id: json['id'] as String,
  claimId: json['claim_id'] as String,
  userId: json['user_id'] as String,
  action: json['action'] as String,
  oldStatus: $enumDecodeNullable(_$ClaimStatusEnumMap, json['old_status']),
  newStatus: $enumDecodeNullable(_$ClaimStatusEnumMap, json['new_status']),
  comment: json['comment'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  createdAt: DateTime.parse(json['created_at'] as String),
  userName: json['user_name'] as String?,
  userEmail: json['user_email'] as String?,
);

Map<String, dynamic> _$ClaimAuditTrailModelToJson(
  ClaimAuditTrailModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'claim_id': instance.claimId,
  'user_id': instance.userId,
  'action': instance.action,
  'old_status': _$ClaimStatusEnumMap[instance.oldStatus],
  'new_status': _$ClaimStatusEnumMap[instance.newStatus],
  'comment': instance.comment,
  'metadata': instance.metadata,
  'created_at': instance.createdAt.toIso8601String(),
  'user_name': instance.userName,
  'user_email': instance.userEmail,
};
