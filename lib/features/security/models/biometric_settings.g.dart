// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BiometricSettings _$BiometricSettingsFromJson(Map<String, dynamic> json) =>
    BiometricSettings(
      isAvailable: json['isAvailable'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? false,
      availableTypes:
          (json['availableTypes'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$BiometricTypeEnumMap, e))
              .toList() ??
          const [],
      useForAppUnlock: json['useForAppUnlock'] as bool? ?? true,
      useForSensitiveOps: json['useForSensitiveOps'] as bool? ?? true,
      lastChecked: json['lastChecked'] == null
          ? null
          : DateTime.parse(json['lastChecked'] as String),
    );

Map<String, dynamic> _$BiometricSettingsToJson(BiometricSettings instance) =>
    <String, dynamic>{
      'isAvailable': instance.isAvailable,
      'isEnabled': instance.isEnabled,
      'availableTypes': instance.availableTypes
          .map((e) => _$BiometricTypeEnumMap[e]!)
          .toList(),
      'useForAppUnlock': instance.useForAppUnlock,
      'useForSensitiveOps': instance.useForSensitiveOps,
      'lastChecked': instance.lastChecked?.toIso8601String(),
    };

const _$BiometricTypeEnumMap = {
  BiometricType.face: 'face',
  BiometricType.fingerprint: 'fingerprint',
  BiometricType.iris: 'iris',
  BiometricType.strong: 'strong',
  BiometricType.weak: 'weak',
};
