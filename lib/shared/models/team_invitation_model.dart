import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'team_model.dart';

part 'team_invitation_model.g.dart';

@JsonSerializable()
class TeamInvitationModel extends Equatable {
  final String id;
  @JsonKey(name: 'team_id')
  final String teamId;
  final String email;
  final TeamRole role;
  @JsonKey(name: 'invited_by')
  final String invitedBy;
  final InvitationStatus status;
  final String token;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Enhanced fields
  @JsonKey(name: 'invitation_attempts')
  final int? invitationAttempts;
  @JsonKey(name: 'last_sent_at')
  final DateTime? lastSentAt;
  @JsonKey(name: 'custom_message')
  final String? customMessage;
  final Map<String, dynamic>? permissions;
  final Map<String, dynamic>? metadata;

  // Joined data
  @JsonKey(name: 'team_name')
  final String? teamName;
  @JsonKey(name: 'invited_by_name')
  final String? invitedByName;

  const TeamInvitationModel({
    required this.id,
    required this.teamId,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.status,
    required this.token,
    required this.expiresAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
    this.invitationAttempts,
    this.lastSentAt,
    this.customMessage,
    this.permissions,
    this.metadata,
    this.teamName,
    this.invitedByName,
  });

  factory TeamInvitationModel.fromJson(Map<String, dynamic> json) =>
      _$TeamInvitationModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamInvitationModelToJson(this);

  TeamInvitationModel copyWith({
    String? id,
    String? teamId,
    String? email,
    TeamRole? role,
    String? invitedBy,
    InvitationStatus? status,
    String? token,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? invitationAttempts,
    DateTime? lastSentAt,
    String? customMessage,
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? metadata,
    String? teamName,
    String? invitedByName,
  }) {
    return TeamInvitationModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      email: email ?? this.email,
      role: role ?? this.role,
      invitedBy: invitedBy ?? this.invitedBy,
      status: status ?? this.status,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      invitationAttempts: invitationAttempts ?? this.invitationAttempts,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      customMessage: customMessage ?? this.customMessage,
      permissions: permissions ?? this.permissions,
      metadata: metadata ?? this.metadata,
      teamName: teamName ?? this.teamName,
      invitedByName: invitedByName ?? this.invitedByName,
    );
  }

  /// Check if invitation is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if invitation is pending
  bool get isPending => status == InvitationStatus.pending && !isExpired;

  /// Check if invitation is accepted
  bool get isAccepted => status == InvitationStatus.accepted;

  /// Check if invitation is cancelled
  bool get isCancelled => status == InvitationStatus.cancelled;

  /// Get time until expiration
  Duration? get timeUntilExpiration {
    if (isExpired) return null;
    return expiresAt.difference(DateTime.now());
  }

  /// Get display name for status
  String get statusDisplayName {
    switch (status) {
      case InvitationStatus.pending:
        return isExpired ? 'Expired' : 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.expired:
        return 'Expired';
      case InvitationStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  List<Object?> get props => [
    id,
    teamId,
    email,
    role,
    invitedBy,
    status,
    token,
    expiresAt,
    acceptedAt,
    createdAt,
    updatedAt,
    invitationAttempts,
    lastSentAt,
    customMessage,
    permissions,
    metadata,
    teamName,
    invitedByName,
  ];
}

@JsonEnum()
enum InvitationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled,
}

extension InvitationStatusExtension on InvitationStatus {
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.expired:
        return 'Expired';
      case InvitationStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == InvitationStatus.pending;
  bool get isCompleted => this == InvitationStatus.accepted;
  bool get isInactive =>
      this == InvitationStatus.expired || this == InvitationStatus.cancelled;
}
