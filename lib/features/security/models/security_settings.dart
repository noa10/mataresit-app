import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'security_settings.g.dart';

/// Security settings model for the application
@JsonSerializable()
class SecuritySettings extends Equatable {
  /// Whether biometric authentication is enabled
  final bool biometricEnabled;
  
  /// Whether app lock/PIN is enabled
  final bool appLockEnabled;
  
  /// App lock PIN (stored securely, this is just a flag)
  final bool hasPinSet;
  
  /// Auto-logout timeout in minutes (0 = never)
  final int autoLogoutMinutes;
  
  /// Whether two-factor authentication is enabled
  final bool twoFactorEnabled;
  
  /// Whether to require authentication for sensitive operations
  final bool requireAuthForSensitiveOps;
  
  /// Last time security settings were updated
  final DateTime? lastUpdated;

  const SecuritySettings({
    this.biometricEnabled = false,
    this.appLockEnabled = false,
    this.hasPinSet = false,
    this.autoLogoutMinutes = 0, // Never by default
    this.twoFactorEnabled = false,
    this.requireAuthForSensitiveOps = true,
    this.lastUpdated,
  });

  /// Create SecuritySettings from JSON
  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      _$SecuritySettingsFromJson(json);

  /// Convert SecuritySettings to JSON
  Map<String, dynamic> toJson() => _$SecuritySettingsToJson(this);

  /// Create a copy with updated values
  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? appLockEnabled,
    bool? hasPinSet,
    int? autoLogoutMinutes,
    bool? twoFactorEnabled,
    bool? requireAuthForSensitiveOps,
    DateTime? lastUpdated,
  }) {
    return SecuritySettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      autoLogoutMinutes: autoLogoutMinutes ?? this.autoLogoutMinutes,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      requireAuthForSensitiveOps: requireAuthForSensitiveOps ?? this.requireAuthForSensitiveOps,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get auto-logout timeout display text
  String get autoLogoutDisplayText {
    switch (autoLogoutMinutes) {
      case 0:
        return 'Never';
      case 15:
        return '15 minutes';
      case 30:
        return '30 minutes';
      case 60:
        return '1 hour';
      case 240:
        return '4 hours';
      default:
        return '$autoLogoutMinutes minutes';
    }
  }

  /// Available auto-logout options
  static const List<int> autoLogoutOptions = [0, 15, 30, 60, 240];

  @override
  List<Object?> get props => [
        biometricEnabled,
        appLockEnabled,
        hasPinSet,
        autoLogoutMinutes,
        twoFactorEnabled,
        requireAuthForSensitiveOps,
        lastUpdated,
      ];
}
