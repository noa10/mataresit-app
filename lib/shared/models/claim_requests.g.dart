// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateClaimRequest _$CreateClaimRequestFromJson(Map<String, dynamic> json) =>
    CreateClaimRequest(
      teamId: json['team_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String?,
      category: json['category'] as String?,
      priority: $enumDecodeNullable(_$ClaimPriorityEnumMap, json['priority']),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateClaimRequestToJson(CreateClaimRequest instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'currency': instance.currency,
      'category': instance.category,
      'priority': _$ClaimPriorityEnumMap[instance.priority],
      'attachments': instance.attachments,
    };

const _$ClaimPriorityEnumMap = {
  ClaimPriority.low: 'low',
  ClaimPriority.medium: 'medium',
  ClaimPriority.high: 'high',
  ClaimPriority.urgent: 'urgent',
};

UpdateClaimRequest _$UpdateClaimRequestFromJson(Map<String, dynamic> json) =>
    UpdateClaimRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      category: json['category'] as String?,
      priority: $enumDecodeNullable(_$ClaimPriorityEnumMap, json['priority']),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UpdateClaimRequestToJson(UpdateClaimRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'currency': instance.currency,
      'category': instance.category,
      'priority': _$ClaimPriorityEnumMap[instance.priority],
      'attachments': instance.attachments,
    };

ClaimApprovalRequest _$ClaimApprovalRequestFromJson(
  Map<String, dynamic> json,
) => ClaimApprovalRequest(
  claimId: json['claim_id'] as String,
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$ClaimApprovalRequestToJson(
  ClaimApprovalRequest instance,
) => <String, dynamic>{
  'claim_id': instance.claimId,
  'comment': instance.comment,
};

ClaimRejectionRequest _$ClaimRejectionRequestFromJson(
  Map<String, dynamic> json,
) => ClaimRejectionRequest(
  claimId: json['claim_id'] as String,
  rejectionReason: json['rejection_reason'] as String,
);

Map<String, dynamic> _$ClaimRejectionRequestToJson(
  ClaimRejectionRequest instance,
) => <String, dynamic>{
  'claim_id': instance.claimId,
  'rejection_reason': instance.rejectionReason,
};

ClaimFilters _$ClaimFiltersFromJson(Map<String, dynamic> json) => ClaimFilters(
  status: $enumDecodeNullable(_$ClaimStatusEnumMap, json['status']),
  priority: $enumDecodeNullable(_$ClaimPriorityEnumMap, json['priority']),
  claimantId: json['claimant_id'] as String?,
  dateFrom: json['date_from'] == null
      ? null
      : DateTime.parse(json['date_from'] as String),
  dateTo: json['date_to'] == null
      ? null
      : DateTime.parse(json['date_to'] as String),
  amountMin: (json['amount_min'] as num?)?.toDouble(),
  amountMax: (json['amount_max'] as num?)?.toDouble(),
  category: json['category'] as String?,
);

Map<String, dynamic> _$ClaimFiltersToJson(ClaimFilters instance) =>
    <String, dynamic>{
      'status': _$ClaimStatusEnumMap[instance.status],
      'priority': _$ClaimPriorityEnumMap[instance.priority],
      'claimant_id': instance.claimantId,
      'date_from': instance.dateFrom?.toIso8601String(),
      'date_to': instance.dateTo?.toIso8601String(),
      'amount_min': instance.amountMin,
      'amount_max': instance.amountMax,
      'category': instance.category,
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

ClaimStats _$ClaimStatsFromJson(Map<String, dynamic> json) => ClaimStats(
  totalClaims: (json['total_claims'] as num).toInt(),
  pendingClaims: (json['pending_claims'] as num).toInt(),
  approvedClaims: (json['approved_claims'] as num).toInt(),
  rejectedClaims: (json['rejected_claims'] as num).toInt(),
  totalAmount: (json['total_amount'] as num).toDouble(),
  approvedAmount: (json['approved_amount'] as num).toDouble(),
  averageProcessingTime: (json['average_processing_time'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ClaimStatsToJson(ClaimStats instance) =>
    <String, dynamic>{
      'total_claims': instance.totalClaims,
      'pending_claims': instance.pendingClaims,
      'approved_claims': instance.approvedClaims,
      'rejected_claims': instance.rejectedClaims,
      'total_amount': instance.totalAmount,
      'approved_amount': instance.approvedAmount,
      'average_processing_time': instance.averageProcessingTime,
    };
