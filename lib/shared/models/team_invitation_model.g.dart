// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_invitation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamInvitationModel _$TeamInvitationModelFromJson(Map<String, dynamic> json) =>
    TeamInvitationModel(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      email: json['email'] as String,
      role: $enumDecode(_$TeamRoleEnumMap, json['role']),
      invitedBy: json['invited_by'] as String,
      status: $enumDecode(_$InvitationStatusEnumMap, json['status']),
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      invitationAttempts: (json['invitation_attempts'] as num?)?.toInt(),
      lastSentAt: json['last_sent_at'] == null
          ? null
          : DateTime.parse(json['last_sent_at'] as String),
      customMessage: json['custom_message'] as String?,
      permissions: json['permissions'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      teamName: json['team_name'] as String?,
      invitedByName: json['invited_by_name'] as String?,
    );

Map<String, dynamic> _$TeamInvitationModelToJson(
  TeamInvitationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'team_id': instance.teamId,
  'email': instance.email,
  'role': _$TeamRoleEnumMap[instance.role]!,
  'invited_by': instance.invitedBy,
  'status': _$InvitationStatusEnumMap[instance.status]!,
  'token': instance.token,
  'expires_at': instance.expiresAt.toIso8601String(),
  'accepted_at': instance.acceptedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'invitation_attempts': instance.invitationAttempts,
  'last_sent_at': instance.lastSentAt?.toIso8601String(),
  'custom_message': instance.customMessage,
  'permissions': instance.permissions,
  'metadata': instance.metadata,
  'team_name': instance.teamName,
  'invited_by_name': instance.invitedByName,
};

const _$TeamRoleEnumMap = {
  TeamRole.owner: 'owner',
  TeamRole.admin: 'admin',
  TeamRole.member: 'member',
  TeamRole.viewer: 'viewer',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.pending: 'pending',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.expired: 'expired',
  InvitationStatus.cancelled: 'cancelled',
};
