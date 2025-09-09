import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'team_model.g.dart';

@JsonSerializable()
class TeamModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final TeamStatus status;
  final List<String> memberIds;
  final Map<String, TeamRole> memberRoles;
  final TeamSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.status,
    required this.memberIds,
    required this.memberRoles,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) =>
      _$TeamModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamModelToJson(this);

  TeamModel copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    String? ownerId,
    TeamStatus? status,
    List<String>? memberIds,
    Map<String, TeamRole>? memberRoles,
    TeamSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      memberIds: memberIds ?? this.memberIds,
      memberRoles: memberRoles ?? this.memberRoles,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    avatarUrl,
    ownerId,
    status,
    memberIds,
    memberRoles,
    settings,
    createdAt,
    updatedAt,
  ];

  int get memberCount => memberIds.length;
  bool isOwner(String userId) => ownerId == userId;
  bool isMember(String userId) => memberIds.contains(userId);
  TeamRole getUserRole(String userId) => memberRoles[userId] ?? TeamRole.member;
}

@JsonSerializable()
class TeamSettings extends Equatable {
  final bool allowMemberInvites;
  final bool requireApprovalForExpenses;
  final double? expenseApprovalLimit;
  final bool enableNotifications;
  final List<String> allowedCategories;

  const TeamSettings({
    this.allowMemberInvites = true,
    this.requireApprovalForExpenses = false,
    this.expenseApprovalLimit,
    this.enableNotifications = true,
    this.allowedCategories = const [],
  });

  factory TeamSettings.fromJson(Map<String, dynamic> json) =>
      _$TeamSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$TeamSettingsToJson(this);

  TeamSettings copyWith({
    bool? allowMemberInvites,
    bool? requireApprovalForExpenses,
    double? expenseApprovalLimit,
    bool? enableNotifications,
    List<String>? allowedCategories,
  }) {
    return TeamSettings(
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
      requireApprovalForExpenses:
          requireApprovalForExpenses ?? this.requireApprovalForExpenses,
      expenseApprovalLimit: expenseApprovalLimit ?? this.expenseApprovalLimit,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      allowedCategories: allowedCategories ?? this.allowedCategories,
    );
  }

  @override
  List<Object?> get props => [
    allowMemberInvites,
    requireApprovalForExpenses,
    expenseApprovalLimit,
    enableNotifications,
    allowedCategories,
  ];
}

@JsonEnum()
enum TeamStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('suspended')
  suspended,
}

@JsonEnum()
enum TeamRole {
  @JsonValue('owner')
  owner,
  @JsonValue('admin')
  admin,
  @JsonValue('member')
  member,
  @JsonValue('viewer')
  viewer,
}

extension TeamStatusExtension on TeamStatus {
  String get displayName {
    switch (this) {
      case TeamStatus.active:
        return 'Active';
      case TeamStatus.inactive:
        return 'Inactive';
      case TeamStatus.suspended:
        return 'Suspended';
    }
  }

  bool get isActive => this == TeamStatus.active;
}

extension TeamRoleExtension on TeamRole {
  String get displayName {
    switch (this) {
      case TeamRole.owner:
        return 'Owner';
      case TeamRole.admin:
        return 'Admin';
      case TeamRole.member:
        return 'Member';
      case TeamRole.viewer:
        return 'Viewer';
    }
  }

  bool get canManageTeam => this == TeamRole.owner || this == TeamRole.admin;
  bool get canInviteMembers => this == TeamRole.owner || this == TeamRole.admin;
  bool get canApproveExpenses =>
      this == TeamRole.owner || this == TeamRole.admin;
  bool get canCreateReceipts => this != TeamRole.viewer;
}
