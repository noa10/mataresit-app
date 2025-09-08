// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      allowAnalytics: json['allowAnalytics'] as bool? ?? true,
      allowCrashReporting: json['allowCrashReporting'] as bool? ?? true,
      allowUsageData: json['allowUsageData'] as bool? ?? true,
      dataRetentionDays: (json['dataRetentionDays'] as num?)?.toInt() ?? 0,
      autoDeleteOldReceipts: json['autoDeleteOldReceipts'] as bool? ?? false,
      allowTeamDataSharing: json['allowTeamDataSharing'] as bool? ?? true,
      allowDataExport: json['allowDataExport'] as bool? ?? true,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'allowAnalytics': instance.allowAnalytics,
      'allowCrashReporting': instance.allowCrashReporting,
      'allowUsageData': instance.allowUsageData,
      'dataRetentionDays': instance.dataRetentionDays,
      'autoDeleteOldReceipts': instance.autoDeleteOldReceipts,
      'allowTeamDataSharing': instance.allowTeamDataSharing,
      'allowDataExport': instance.allowDataExport,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
