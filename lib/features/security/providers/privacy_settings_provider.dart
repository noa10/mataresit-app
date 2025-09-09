import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/privacy_settings.dart';
import '../services/privacy_service.dart';

/// State for privacy settings
class PrivacySettingsState {
  final PrivacySettings settings;
  final bool isLoading;
  final String? error;
  final bool isExporting;
  final Map<String, dynamic>? dataUsageStats;

  const PrivacySettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
    this.isExporting = false,
    this.dataUsageStats,
  });

  PrivacySettingsState copyWith({
    PrivacySettings? settings,
    bool? isLoading,
    String? error,
    bool? isExporting,
    Map<String, dynamic>? dataUsageStats,
  }) {
    return PrivacySettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isExporting: isExporting ?? this.isExporting,
      dataUsageStats: dataUsageStats ?? this.dataUsageStats,
    );
  }
}

/// Notifier for privacy settings
class PrivacySettingsNotifier extends StateNotifier<PrivacySettingsState> {
  PrivacySettingsNotifier()
    : super(PrivacySettingsState(settings: PrivacyService.privacySettings)) {
    _initialize();
  }

  final Logger _logger = Logger();

  /// Initialize privacy settings
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await PrivacyService.initialize();

      state = state.copyWith(
        settings: PrivacyService.privacySettings,
        isLoading: false,
      );

      // Load data usage stats
      await _loadDataUsageStats();
    } catch (e) {
      _logger.e('Failed to initialize privacy settings: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load data usage statistics
  Future<void> _loadDataUsageStats() async {
    try {
      final stats = await PrivacyService.getDataUsageStats();
      state = state.copyWith(dataUsageStats: stats);
    } catch (e) {
      _logger.e('Failed to load data usage stats: $e');
    }
  }

  /// Update privacy settings
  Future<void> updateSettings(PrivacySettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await PrivacyService.updatePrivacySettings(settings);

      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      _logger.e('Failed to update privacy settings: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Toggle analytics data collection
  Future<void> toggleAllowAnalytics(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        allowAnalytics: enabled,
        lastUpdated: DateTime.now(),
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle analytics: $e');
      rethrow;
    }
  }

  /// Toggle crash reporting
  Future<void> toggleAllowCrashReporting(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        allowCrashReporting: enabled,
        lastUpdated: DateTime.now(),
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle crash reporting: $e');
      rethrow;
    }
  }

  /// Toggle usage data collection
  Future<void> toggleAllowUsageData(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        allowUsageData: enabled,
        lastUpdated: DateTime.now(),
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle usage data: $e');
      rethrow;
    }
  }

  /// Update data retention period
  Future<void> updateDataRetentionDays(int days) async {
    try {
      final updatedSettings = state.settings.copyWith(
        dataRetentionDays: days,
        lastUpdated: DateTime.now(),
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to update data retention: $e');
      rethrow;
    }
  }

  /// Toggle auto-delete old receipts
  Future<void> toggleAutoDeleteOldReceipts(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        autoDeleteOldReceipts: enabled,
        lastUpdated: DateTime.now(),
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle auto-delete old receipts: $e');
      rethrow;
    }
  }

  /// Toggle team data sharing
  Future<void> toggleAllowTeamDataSharing(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        allowTeamDataSharing: enabled,
        lastUpdated: DateTime.now(),
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle team data sharing: $e');
      rethrow;
    }
  }

  /// Toggle data export permission
  Future<void> toggleAllowDataExport(bool enabled) async {
    try {
      final updatedSettings = state.settings.copyWith(
        allowDataExport: enabled,
        lastUpdated: DateTime.now(),
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      _logger.e('Failed to toggle data export: $e');
      rethrow;
    }
  }

  /// Export user data as JSON
  Future<String?> exportDataAsJson() async {
    try {
      state = state.copyWith(isExporting: true, error: null);

      final filePath = await PrivacyService.exportUserDataAsJson();

      state = state.copyWith(isExporting: false);

      return filePath;
    } catch (e) {
      _logger.e('Failed to export data as JSON: $e');
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  /// Export user data as CSV
  Future<String?> exportDataAsCsv() async {
    try {
      state = state.copyWith(isExporting: true, error: null);

      final filePath = await PrivacyService.exportUserDataAsCsv();

      state = state.copyWith(isExporting: false);

      return filePath;
    } catch (e) {
      _logger.e('Failed to export data as CSV: $e');
      state = state.copyWith(isExporting: false, error: e.toString());
      return null;
    }
  }

  /// Share exported data
  Future<void> shareExportedData(String filePath, String format) async {
    try {
      await PrivacyService.shareExportedData(filePath, format);
    } catch (e) {
      _logger.e('Failed to share exported data: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Cleanup old data
  Future<void> cleanupOldData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await PrivacyService.cleanupOldData();

      // Refresh data usage stats after cleanup
      await _loadDataUsageStats();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      _logger.e('Failed to cleanup old data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Clear all user data
  Future<void> clearAllUserData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await PrivacyService.clearAllUserData();

      // Reset settings to default
      const defaultSettings = PrivacySettings();
      await PrivacyService.updatePrivacySettings(defaultSettings);

      state = state.copyWith(
        settings: defaultSettings,
        isLoading: false,
        dataUsageStats: {},
      );
    } catch (e) {
      _logger.e('Failed to clear all user data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Refresh data usage stats
  Future<void> refreshDataUsageStats() async {
    await _loadDataUsageStats();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh privacy settings
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Provider for privacy settings
final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, PrivacySettingsState>((ref) {
      return PrivacySettingsNotifier();
    });

/// Provider for current privacy settings (read-only)
final currentPrivacySettingsProvider = Provider<PrivacySettings>((ref) {
  return ref.watch(privacySettingsProvider).settings;
});

/// Provider for privacy settings loading state
final privacySettingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(privacySettingsProvider).isLoading;
});

/// Provider for privacy settings error
final privacySettingsErrorProvider = Provider<String?>((ref) {
  return ref.watch(privacySettingsProvider).error;
});

/// Provider for data export loading state
final dataExportLoadingProvider = Provider<bool>((ref) {
  return ref.watch(privacySettingsProvider).isExporting;
});

/// Provider for data usage statistics
final dataUsageStatsProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(privacySettingsProvider).dataUsageStats;
});
