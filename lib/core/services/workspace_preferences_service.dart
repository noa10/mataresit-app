import 'package:logger/logger.dart';
import 'shared_preferences_compatibility_service.dart';

/// Service for managing workspace-related preferences
class WorkspacePreferencesService {
  static final Logger _logger = Logger();

  // Preference keys
  static const String _currentWorkspaceKey = 'current_workspace_id';
  static const String _lastSelectedTeamKey = 'last_selected_team_id';
  static const String _workspaceHistoryKey = 'workspace_history';
  static const String _autoSwitchEnabledKey = 'auto_switch_enabled';
  static const String _workspacePreferencesVersionKey =
      'workspace_preferences_version';

  // Current version for migration purposes
  static const int _currentVersion = 1;

  /// Initialize the service and perform any necessary migrations
  static Future<void> initialize() async {
    try {
      final currentVersion = SharedPreferencesCompatibilityService.getInt(_workspacePreferencesVersionKey) ?? 0;

      if (currentVersion < _currentVersion) {
        await _migratePreferences(currentVersion);
        await SharedPreferencesCompatibilityService.setInt(_workspacePreferencesVersionKey, _currentVersion);
      }

      _logger.d(
        'WorkspacePreferencesService initialized (version $_currentVersion)',
      );
    } catch (e) {
      _logger.e('Failed to initialize WorkspacePreferencesService: $e');
    }
  }

  /// Get the currently selected workspace ID
  /// Returns null for personal workspace, team ID for team workspace
  static Future<String?> getCurrentWorkspaceId() async {
    try {
      final workspaceId = SharedPreferencesCompatibilityService.getString(_currentWorkspaceKey);
      _logger.d('Retrieved current workspace ID: $workspaceId');
      return workspaceId;
    } catch (e) {
      _logger.e('Failed to get current workspace ID: $e');
      return null;
    }
  }

  /// Set the currently selected workspace ID
  /// Pass null for personal workspace, team ID for team workspace
  static Future<bool> setCurrentWorkspaceId(String? workspaceId) async {
    try {
      if (workspaceId == null) {
        await SharedPreferencesCompatibilityService.remove(_currentWorkspaceKey);
        _logger.d('Cleared current workspace (switched to personal)');
      } else {
        await SharedPreferencesCompatibilityService.setString(_currentWorkspaceKey, workspaceId);
        _logger.d('Set current workspace ID: $workspaceId');

        // Update workspace history
        await _addToWorkspaceHistory(workspaceId);
      }

      return true;
    } catch (e) {
      _logger.e('Failed to set current workspace ID: $e');
      return false;
    }
  }

  /// Get the last selected team ID (for quick switching)
  static Future<String?> getLastSelectedTeamId() async {
    try {
      return SharedPreferencesCompatibilityService.getString(_lastSelectedTeamKey);
    } catch (e) {
      _logger.e('Failed to get last selected team ID: $e');
      return null;
    }
  }

  /// Set the last selected team ID
  static Future<bool> setLastSelectedTeamId(String? teamId) async {
    try {
      if (teamId == null) {
        await SharedPreferencesCompatibilityService.remove(_lastSelectedTeamKey);
      } else {
        await SharedPreferencesCompatibilityService.setString(_lastSelectedTeamKey, teamId);
      }

      return true;
    } catch (e) {
      _logger.e('Failed to set last selected team ID: $e');
      return false;
    }
  }

  /// Get workspace history (recently accessed workspaces)
  static Future<List<String>> getWorkspaceHistory() async {
    try {
      final history = SharedPreferencesCompatibilityService.getStringList(_workspaceHistoryKey) ?? [];
      return history;
    } catch (e) {
      _logger.e('Failed to get workspace history: $e');
      return [];
    }
  }

  /// Add a workspace to history
  static Future<void> _addToWorkspaceHistory(String workspaceId) async {
    try {
      final history = SharedPreferencesCompatibilityService.getStringList(_workspaceHistoryKey) ?? [];

      // Remove if already exists
      history.remove(workspaceId);

      // Add to beginning
      history.insert(0, workspaceId);

      // Keep only last 10 items
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }

      await SharedPreferencesCompatibilityService.setStringList(_workspaceHistoryKey, history);
    } catch (e) {
      _logger.e('Failed to add to workspace history: $e');
    }
  }

  /// Clear workspace history
  static Future<bool> clearWorkspaceHistory() async {
    try {
      await SharedPreferencesCompatibilityService.remove(_workspaceHistoryKey);
      return true;
    } catch (e) {
      _logger.e('Failed to clear workspace history: $e');
      return false;
    }
  }

  /// Get auto-switch preference
  static Future<bool> getAutoSwitchEnabled() async {
    try {
      return SharedPreferencesCompatibilityService.getBool(_autoSwitchEnabledKey) ?? true; // Default to enabled
    } catch (e) {
      _logger.e('Failed to get auto-switch preference: $e');
      return true;
    }
  }

  /// Set auto-switch preference
  static Future<bool> setAutoSwitchEnabled(bool enabled) async {
    try {
      await SharedPreferencesCompatibilityService.setBool(_autoSwitchEnabledKey, enabled);
      return true;
    } catch (e) {
      _logger.e('Failed to set auto-switch preference: $e');
      return false;
    }
  }

  /// Clear all workspace preferences
  static Future<bool> clearAllPreferences() async {
    try {
      await SharedPreferencesCompatibilityService.remove(_currentWorkspaceKey);
      await SharedPreferencesCompatibilityService.remove(_lastSelectedTeamKey);
      await SharedPreferencesCompatibilityService.remove(_workspaceHistoryKey);
      await SharedPreferencesCompatibilityService.remove(_autoSwitchEnabledKey);

      _logger.d('Cleared all workspace preferences');
      return true;
    } catch (e) {
      _logger.e('Failed to clear workspace preferences: $e');
      return false;
    }
  }

  /// Get all workspace preferences as a map (for debugging/export)
  static Future<Map<String, dynamic>> getAllPreferences() async {
    try {
      return {
        'current_workspace_id': SharedPreferencesCompatibilityService.getString(_currentWorkspaceKey),
        'last_selected_team_id': SharedPreferencesCompatibilityService.getString(_lastSelectedTeamKey),
        'workspace_history': SharedPreferencesCompatibilityService.getStringList(_workspaceHistoryKey),
        'auto_switch_enabled': SharedPreferencesCompatibilityService.getBool(_autoSwitchEnabledKey),
        'version': SharedPreferencesCompatibilityService.getInt(_workspacePreferencesVersionKey),
      };
    } catch (e) {
      _logger.e('Failed to get all workspace preferences: $e');
      return {};
    }
  }

  /// Migrate preferences from older versions
  static Future<void> _migratePreferences(int fromVersion) async {
    _logger.d(
      'Migrating workspace preferences from version $fromVersion to $_currentVersion',
    );

    // Currently no migrations needed, but this is where they would go
    // Example:
    // if (fromVersion < 1) {
    //   // Migrate from version 0 to 1
    // }
  }

  /// Export preferences for backup
  static Future<Map<String, dynamic>> exportPreferences() async {
    return await getAllPreferences();
  }

  /// Import preferences from backup
  static Future<bool> importPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      if (preferences['current_workspace_id'] != null) {
        await SharedPreferencesCompatibilityService.setString(
          _currentWorkspaceKey,
          preferences['current_workspace_id'],
        );
      }

      if (preferences['last_selected_team_id'] != null) {
        await SharedPreferencesCompatibilityService.setString(
          _lastSelectedTeamKey,
          preferences['last_selected_team_id'],
        );
      }

      if (preferences['workspace_history'] != null) {
        await SharedPreferencesCompatibilityService.setStringList(
          _workspaceHistoryKey,
          List<String>.from(preferences['workspace_history']),
        );
      }

      if (preferences['auto_switch_enabled'] != null) {
        await SharedPreferencesCompatibilityService.setBool(
          _autoSwitchEnabledKey,
          preferences['auto_switch_enabled'],
        );
      }

      _logger.d('Imported workspace preferences successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to import workspace preferences: $e');
      return false;
    }
  }
}
