// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionInfo _$SessionInfoFromJson(Map<String, dynamic> json) => SessionInfo(
  sessionId: json['sessionId'] as String,
  deviceInfo: json['deviceInfo'] as String,
  ipAddress: json['ipAddress'] as String?,
  location: json['location'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
  isCurrent: json['isCurrent'] as bool? ?? false,
  userAgent: json['userAgent'] as String?,
);

Map<String, dynamic> _$SessionInfoToJson(SessionInfo instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'deviceInfo': instance.deviceInfo,
      'ipAddress': instance.ipAddress,
      'location': instance.location,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'isCurrent': instance.isCurrent,
      'userAgent': instance.userAgent,
    };
