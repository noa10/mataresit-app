import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'team_id')
  final String? teamId;
  final String name;
  final String color;
  final String icon;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'receipt_count')
  final int? receiptCount;
  @JsonKey(name: 'is_team_category')
  final bool? isTeamCategory;

  const CategoryModel({
    required this.id,
    this.userId,
    this.teamId,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.receiptCount,
    this.isTeamCategory,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? teamId,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? receiptCount,
    bool? isTeamCategory,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptCount: receiptCount ?? this.receiptCount,
      isTeamCategory: isTeamCategory ?? this.isTeamCategory,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        teamId,
        name,
        color,
        icon,
        createdAt,
        updatedAt,
        receiptCount,
        isTeamCategory,
      ];
}

@JsonSerializable()
class CreateCategoryRequest extends Equatable {
  final String name;
  final String? color;
  final String? icon;

  const CreateCategoryRequest({
    required this.name,
    this.color,
    this.icon,
  });

  factory CreateCategoryRequest.fromJson(Map<String, dynamic> json) => _$CreateCategoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCategoryRequestToJson(this);

  @override
  List<Object?> get props => [name, color, icon];
}

@JsonSerializable()
class UpdateCategoryRequest extends Equatable {
  final String? name;
  final String? color;
  final String? icon;

  const UpdateCategoryRequest({
    this.name,
    this.color,
    this.icon,
  });

  factory UpdateCategoryRequest.fromJson(Map<String, dynamic> json) => _$UpdateCategoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCategoryRequestToJson(this);

  @override
  List<Object?> get props => [name, color, icon];
}

// Default category colors matching the React web version
class DefaultCategoryColors {
  static const List<String> colors = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Yellow
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#F97316', // Orange
    '#06B6D4', // Cyan
    '#84CC16', // Lime
    '#EC4899', // Pink
    '#6B7280', // Gray
  ];
}

// Default category icons matching the React web version
class DefaultCategoryIcons {
  static const List<String> icons = [
    'tag',
    'shopping-cart',
    'utensils',
    'car',
    'home',
    'briefcase',
    'heart',
    'gift',
    'plane',
    'book',
    'music',
    'camera',
    'gamepad',
    'coffee',
    'fuel',
  ];
}
