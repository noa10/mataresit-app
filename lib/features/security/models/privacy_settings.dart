import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'privacy_settings.g.dart';

/// Privacy settings and data control preferences
@JsonSerializable()
class PrivacySettings extends Equatable {
  /// Whether to allow analytics data collection
  final bool allowAnalytics;
  
  /// Whether to allow crash reporting
  final bool allowCrashReporting;
  
  /// Whether to allow usage data collection
  final bool allowUsageData;
  
  /// Data retention period in days (0 = keep forever)
  final int dataRetentionDays;
  
  /// Whether to automatically delete old receipts
  final bool autoDeleteOldReceipts;
  
  /// Whether to allow data sharing with team members
  final bool allowTeamDataSharing;
  
  /// Whether to allow export of personal data
  final bool allowDataExport;
  
  /// Last time privacy settings were updated
  final DateTime? lastUpdated;

  const PrivacySettings({
    this.allowAnalytics = true,
    this.allowCrashReporting = true,
    this.allowUsageData = true,
    this.dataRetentionDays = 0, // Keep forever by default
    this.autoDeleteOldReceipts = false,
    this.allowTeamDataSharing = true,
    this.allowDataExport = true,
    this.lastUpdated,
  });

  /// Create PrivacySettings from JSON
  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);

  /// Convert PrivacySettings to JSON
  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);

  /// Create a copy with updated values
  PrivacySettings copyWith({
    bool? allowAnalytics,
    bool? allowCrashReporting,
    bool? allowUsageData,
    int? dataRetentionDays,
    bool? autoDeleteOldReceipts,
    bool? allowTeamDataSharing,
    bool? allowDataExport,
    DateTime? lastUpdated,
  }) {
    return PrivacySettings(
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowCrashReporting: allowCrashReporting ?? this.allowCrashReporting,
      allowUsageData: allowUsageData ?? this.allowUsageData,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
      autoDeleteOldReceipts: autoDeleteOldReceipts ?? this.autoDeleteOldReceipts,
      allowTeamDataSharing: allowTeamDataSharing ?? this.allowTeamDataSharing,
      allowDataExport: allowDataExport ?? this.allowDataExport,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get data retention display text
  String get dataRetentionDisplayText {
    switch (dataRetentionDays) {
      case 0:
        return 'Keep forever';
      case 30:
        return '30 days';
      case 90:
        return '3 months';
      case 180:
        return '6 months';
      case 365:
        return '1 year';
      case 730:
        return '2 years';
      default:
        return '$dataRetentionDays days';
    }
  }

  /// Available data retention options
  static const List<int> dataRetentionOptions = [0, 30, 90, 180, 365, 730];

  @override
  List<Object?> get props => [
        allowAnalytics,
        allowCrashReporting,
        allowUsageData,
        dataRetentionDays,
        autoDeleteOldReceipts,
        allowTeamDataSharing,
        allowDataExport,
        lastUpdated,
      ];
}
