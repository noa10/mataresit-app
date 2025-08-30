import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'line_item_model.g.dart';

@JsonSerializable()
class LineItemModel extends Equatable {
  final String id;
  @JsonKey(name: 'receipt_id')
  final String receiptId;
  final String description;
  final double amount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const LineItemModel({
    required this.id,
    required this.receiptId,
    required this.description,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LineItemModel.fromJson(Map<String, dynamic> json) =>
      _$LineItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$LineItemModelToJson(this);

  LineItemModel copyWith({
    String? id,
    String? receiptId,
    String? description,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LineItemModel(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        receiptId,
        description,
        amount,
        createdAt,
        updatedAt,
      ];
}


