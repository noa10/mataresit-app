// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecuritySettings _$SecuritySettingsFromJson(Map<String, dynamic> json) =>
    SecuritySettings(
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      appLockEnabled: json['appLockEnabled'] as bool? ?? false,
      hasPinSet: json['hasPinSet'] as bool? ?? false,
      autoLogoutMinutes: (json['autoLogoutMinutes'] as num?)?.toInt() ?? 0,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      requireAuthForSensitiveOps:
          json['requireAuthForSensitiveOps'] as bool? ?? true,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$SecuritySettingsToJson(SecuritySettings instance) =>
    <String, dynamic>{
      'biometricEnabled': instance.biometricEnabled,
      'appLockEnabled': instance.appLockEnabled,
      'hasPinSet': instance.hasPinSet,
      'autoLogoutMinutes': instance.autoLogoutMinutes,
      'twoFactorEnabled': instance.twoFactorEnabled,
      'requireAuthForSensitiveOps': instance.requireAuthForSensitiveOps,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
