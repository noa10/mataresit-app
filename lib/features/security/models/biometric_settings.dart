import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:local_auth/local_auth.dart';

part 'biometric_settings.g.dart';

/// Biometric authentication settings
@JsonSerializable()
class BiometricSettings extends Equatable {
  /// Whether biometric authentication is available on device
  final bool isAvailable;

  /// Whether biometric authentication is enabled by user
  final bool isEnabled;

  /// Available biometric types on device
  final List<BiometricType> availableTypes;

  /// Whether to use biometric for app unlock
  final bool useForAppUnlock;

  /// Whether to use biometric for sensitive operations
  final bool useForSensitiveOps;

  /// Last time biometric settings were checked
  final DateTime? lastChecked;

  const BiometricSettings({
    this.isAvailable = false,
    this.isEnabled = false,
    this.availableTypes = const [],
    this.useForAppUnlock = true,
    this.useForSensitiveOps = true,
    this.lastChecked,
  });

  /// Create BiometricSettings from JSON
  factory BiometricSettings.fromJson(Map<String, dynamic> json) =>
      _$BiometricSettingsFromJson(json);

  /// Convert BiometricSettings to JSON
  Map<String, dynamic> toJson() => _$BiometricSettingsToJson(this);

  /// Create a copy with updated values
  BiometricSettings copyWith({
    bool? isAvailable,
    bool? isEnabled,
    List<BiometricType>? availableTypes,
    bool? useForAppUnlock,
    bool? useForSensitiveOps,
    DateTime? lastChecked,
  }) {
    return BiometricSettings(
      isAvailable: isAvailable ?? this.isAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      availableTypes: availableTypes ?? this.availableTypes,
      useForAppUnlock: useForAppUnlock ?? this.useForAppUnlock,
      useForSensitiveOps: useForSensitiveOps ?? this.useForSensitiveOps,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  /// Get display text for available biometric types
  String get availableTypesDisplayText {
    if (availableTypes.isEmpty) return 'None available';

    final typeNames = availableTypes.map((type) {
      switch (type) {
        case BiometricType.face:
          return 'Face ID';
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.strong:
          return 'Strong biometric';
        case BiometricType.weak:
          return 'Weak biometric';
      }
    }).toList();

    return typeNames.join(', ');
  }

  /// Whether biometric authentication can be used
  bool get canUse => isAvailable && isEnabled && availableTypes.isNotEmpty;

  @override
  List<Object?> get props => [
    isAvailable,
    isEnabled,
    availableTypes,
    useForAppUnlock,
    useForSensitiveOps,
    lastChecked,
  ];
}
