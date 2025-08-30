// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LineItemModel _$LineItemModelFromJson(Map<String, dynamic> json) =>
    LineItemModel(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$LineItemModelToJson(LineItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receipt_id': instance.receiptId,
      'description': instance.description,
      'amount': instance.amount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
