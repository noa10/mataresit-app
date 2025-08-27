// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamModel _$TeamModelFromJson(Map<String, dynamic> json) => TeamModel(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  ownerId: json['ownerId'] as String,
  status: $enumDecode(_$TeamStatusEnumMap, json['status']),
  memberIds: (json['memberIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  memberRoles: (json['memberRoles'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, $enumDecode(_$TeamRoleEnumMap, e)),
  ),
  settings: TeamSettings.fromJson(json['settings'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TeamModelToJson(TeamModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'avatarUrl': instance.avatarUrl,
  'ownerId': instance.ownerId,
  'status': _$TeamStatusEnumMap[instance.status]!,
  'memberIds': instance.memberIds,
  'memberRoles': instance.memberRoles.map(
    (k, e) => MapEntry(k, _$TeamRoleEnumMap[e]!),
  ),
  'settings': instance.settings,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$TeamStatusEnumMap = {
  TeamStatus.active: 'active',
  TeamStatus.inactive: 'inactive',
  TeamStatus.suspended: 'suspended',
};

const _$TeamRoleEnumMap = {
  TeamRole.owner: 'owner',
  TeamRole.admin: 'admin',
  TeamRole.member: 'member',
  TeamRole.viewer: 'viewer',
};

TeamSettings _$TeamSettingsFromJson(Map<String, dynamic> json) => TeamSettings(
  allowMemberInvites: json['allowMemberInvites'] as bool? ?? true,
  requireApprovalForExpenses:
      json['requireApprovalForExpenses'] as bool? ?? false,
  expenseApprovalLimit: (json['expenseApprovalLimit'] as num?)?.toDouble(),
  enableNotifications: json['enableNotifications'] as bool? ?? true,
  allowedCategories:
      (json['allowedCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$TeamSettingsToJson(TeamSettings instance) =>
    <String, dynamic>{
      'allowMemberInvites': instance.allowMemberInvites,
      'requireApprovalForExpenses': instance.requireApprovalForExpenses,
      'expenseApprovalLimit': instance.expenseApprovalLimit,
      'enableNotifications': instance.enableNotifications,
      'allowedCategories': instance.allowedCategories,
    };
