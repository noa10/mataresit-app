import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'claim_model.dart';

part 'claim_requests.g.dart';

/// Request model for creating a new claim
@JsonSerializable()
class CreateClaimRequest extends Equatable {
  @JsonKey(name: 'team_id')
  final String teamId;
  final String title;
  final String? description;
  final double amount;
  final String? currency;
  final String? category;
  final ClaimPriority? priority;
  final List<String>? attachments;

  const CreateClaimRequest({
    required this.teamId,
    required this.title,
    this.description,
    required this.amount,
    this.currency,
    this.category,
    this.priority,
    this.attachments,
  });

  factory CreateClaimRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateClaimRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateClaimRequestToJson(this);

  @override
  List<Object?> get props => [
    teamId,
    title,
    description,
    amount,
    currency,
    category,
    priority,
    attachments,
  ];
}

/// Request model for updating an existing claim
@JsonSerializable()
class UpdateClaimRequest extends Equatable {
  final String? title;
  final String? description;
  final double? amount;
  final String? currency;
  final String? category;
  final ClaimPriority? priority;
  final List<String>? attachments;

  const UpdateClaimRequest({
    this.title,
    this.description,
    this.amount,
    this.currency,
    this.category,
    this.priority,
    this.attachments,
  });

  factory UpdateClaimRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateClaimRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateClaimRequestToJson(this);

  /// Convert to map for Supabase update, excluding null values
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (amount != null) map['amount'] = amount;
    if (currency != null) map['currency'] = currency;
    if (category != null) map['category'] = category;
    if (priority != null) map['priority'] = priority?.name;
    if (attachments != null) map['attachments'] = attachments;
    map['updated_at'] = DateTime.now().toIso8601String();
    return map;
  }

  @override
  List<Object?> get props => [
    title,
    description,
    amount,
    currency,
    category,
    priority,
    attachments,
  ];
}

/// Request model for approving a claim
@JsonSerializable()
class ClaimApprovalRequest extends Equatable {
  @JsonKey(name: 'claim_id')
  final String claimId;
  final String? comment;

  const ClaimApprovalRequest({required this.claimId, this.comment});

  factory ClaimApprovalRequest.fromJson(Map<String, dynamic> json) =>
      _$ClaimApprovalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimApprovalRequestToJson(this);

  @override
  List<Object?> get props => [claimId, comment];
}

/// Request model for rejecting a claim
@JsonSerializable()
class ClaimRejectionRequest extends Equatable {
  @JsonKey(name: 'claim_id')
  final String claimId;
  @JsonKey(name: 'rejection_reason')
  final String rejectionReason;

  const ClaimRejectionRequest({
    required this.claimId,
    required this.rejectionReason,
  });

  factory ClaimRejectionRequest.fromJson(Map<String, dynamic> json) =>
      _$ClaimRejectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimRejectionRequestToJson(this);

  @override
  List<Object?> get props => [claimId, rejectionReason];
}

/// Filter model for querying claims
@JsonSerializable()
class ClaimFilters extends Equatable {
  final ClaimStatus? status;
  final ClaimPriority? priority;
  @JsonKey(name: 'claimant_id')
  final String? claimantId;
  @JsonKey(name: 'date_from')
  final DateTime? dateFrom;
  @JsonKey(name: 'date_to')
  final DateTime? dateTo;
  @JsonKey(name: 'amount_min')
  final double? amountMin;
  @JsonKey(name: 'amount_max')
  final double? amountMax;
  final String? category;

  const ClaimFilters({
    this.status,
    this.priority,
    this.claimantId,
    this.dateFrom,
    this.dateTo,
    this.amountMin,
    this.amountMax,
    this.category,
  });

  factory ClaimFilters.fromJson(Map<String, dynamic> json) =>
      _$ClaimFiltersFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimFiltersToJson(this);

  /// Check if any filters are applied
  bool get hasFilters =>
      status != null ||
      priority != null ||
      claimantId != null ||
      dateFrom != null ||
      dateTo != null ||
      amountMin != null ||
      amountMax != null ||
      category != null;

  /// Create a copy with updated filters
  ClaimFilters copyWith({
    ClaimStatus? status,
    ClaimPriority? priority,
    String? claimantId,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? amountMin,
    double? amountMax,
    String? category,
  }) {
    return ClaimFilters(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      claimantId: claimantId ?? this.claimantId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      category: category ?? this.category,
    );
  }

  /// Clear all filters
  ClaimFilters clear() {
    return const ClaimFilters();
  }

  @override
  List<Object?> get props => [
    status,
    priority,
    claimantId,
    dateFrom,
    dateTo,
    amountMin,
    amountMax,
    category,
  ];
}

/// Statistics model for claims dashboard
@JsonSerializable()
class ClaimStats extends Equatable {
  @JsonKey(name: 'total_claims')
  final int totalClaims;
  @JsonKey(name: 'pending_claims')
  final int pendingClaims;
  @JsonKey(name: 'approved_claims')
  final int approvedClaims;
  @JsonKey(name: 'rejected_claims')
  final int rejectedClaims;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'approved_amount')
  final double approvedAmount;
  @JsonKey(name: 'average_processing_time')
  final double? averageProcessingTime; // in hours

  const ClaimStats({
    required this.totalClaims,
    required this.pendingClaims,
    required this.approvedClaims,
    required this.rejectedClaims,
    required this.totalAmount,
    required this.approvedAmount,
    this.averageProcessingTime,
  });

  factory ClaimStats.fromJson(Map<String, dynamic> json) =>
      _$ClaimStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimStatsToJson(this);

  /// Calculate approval rate as percentage
  double get approvalRate {
    final processedClaims = approvedClaims + rejectedClaims;
    if (processedClaims == 0) return 0.0;
    return (approvedClaims / processedClaims) * 100;
  }

  /// Calculate pending rate as percentage
  double get pendingRate {
    if (totalClaims == 0) return 0.0;
    return (pendingClaims / totalClaims) * 100;
  }

  @override
  List<Object?> get props => [
    totalClaims,
    pendingClaims,
    approvedClaims,
    rejectedClaims,
    totalAmount,
    approvedAmount,
    averageProcessingTime,
  ];
}

/// Claim permissions constants
class ClaimPermissions {
  static const String create = 'create_claims';
  static const String view = 'view_claims';
  static const String review = 'review_claims';
  static const String approve = 'approve_claims';
  static const String delete = 'delete_claims';
}
