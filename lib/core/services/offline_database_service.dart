import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../../shared/models/receipt_model.dart';
import '../../shared/models/team_model.dart';
import '../../shared/models/user_model.dart';

/// Service for managing offline data storage using Hive
class OfflineDatabaseService {
  static final Logger _logger = Logger();

  // Box names
  static const String _receiptsBox = 'receipts';
  static const String _teamsBox = 'teams';
  static const String _usersBox = 'users';
  static const String _syncQueueBox = 'sync_queue';
  static const String _settingsBox = 'settings';

  // Boxes
  static Box<Map>? _receipts;
  static Box<Map>? _teams;
  static Box<Map>? _users;
  static Box<Map>? _syncQueue;
  static Box<dynamic>? _settings;

  /// Initialize Hive and open boxes
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Register adapters if needed (for custom types)
      // Hive.registerAdapter(ReceiptModelAdapter());

      // Open boxes
      _receipts = await Hive.openBox<Map>(_receiptsBox);
      _teams = await Hive.openBox<Map>(_teamsBox);
      _users = await Hive.openBox<Map>(_usersBox);
      _syncQueue = await Hive.openBox<Map>(_syncQueueBox);
      _settings = await Hive.openBox(_settingsBox);

      _logger.i('Offline Database Service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Offline Database Service: $e');
      rethrow;
    }
  }

  /// Close all boxes
  static Future<void> close() async {
    await _receipts?.close();
    await _teams?.close();
    await _users?.close();
    await _syncQueue?.close();
    await _settings?.close();
  }

  // RECEIPT OPERATIONS

  /// Save receipt to local storage
  static Future<void> saveReceipt(ReceiptModel receipt) async {
    try {
      await _receipts?.put(receipt.id, receipt.toJson());
      _logger.d('Receipt saved offline: ${receipt.id}');
    } catch (e) {
      _logger.e('Failed to save receipt offline: $e');
      rethrow;
    }
  }

  /// Get receipt from local storage
  static ReceiptModel? getReceipt(String receiptId) {
    try {
      final data = _receipts?.get(receiptId);
      if (data != null) {
        return ReceiptModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get receipt from offline storage: $e');
      return null;
    }
  }

  /// Get all receipts from local storage
  static List<ReceiptModel> getAllReceipts() {
    try {
      final receipts = <ReceiptModel>[];
      for (final data in _receipts?.values ?? []) {
        try {
          if (data is Map) {
            receipts.add(
              ReceiptModel.fromJson(Map<String, dynamic>.from(data)),
            );
          }
        } catch (e) {
          _logger.w('Failed to parse receipt from offline storage: $e');
        }
      }
      return receipts;
    } catch (e) {
      _logger.e('Failed to get receipts from offline storage: $e');
      return [];
    }
  }

  /// Delete receipt from local storage
  static Future<void> deleteReceipt(String receiptId) async {
    try {
      await _receipts?.delete(receiptId);
      _logger.d('Receipt deleted from offline storage: $receiptId');
    } catch (e) {
      _logger.e('Failed to delete receipt from offline storage: $e');
      rethrow;
    }
  }

  // TEAM OPERATIONS

  /// Save team to local storage
  static Future<void> saveTeam(TeamModel team) async {
    try {
      await _teams?.put(team.id, team.toJson());
      _logger.d('Team saved offline: ${team.id}');
    } catch (e) {
      _logger.e('Failed to save team offline: $e');
      rethrow;
    }
  }

  /// Get team from local storage
  static TeamModel? getTeam(String teamId) {
    try {
      final data = _teams?.get(teamId);
      if (data != null) {
        return TeamModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get team from offline storage: $e');
      return null;
    }
  }

  /// Get all teams from local storage
  static List<TeamModel> getAllTeams() {
    try {
      final teams = <TeamModel>[];
      for (final data in _teams?.values ?? []) {
        try {
          if (data is Map) {
            teams.add(TeamModel.fromJson(Map<String, dynamic>.from(data)));
          }
        } catch (e) {
          _logger.w('Failed to parse team from offline storage: $e');
        }
      }
      return teams;
    } catch (e) {
      _logger.e('Failed to get teams from offline storage: $e');
      return [];
    }
  }

  // USER OPERATIONS

  /// Save user to local storage
  static Future<void> saveUser(UserModel user) async {
    try {
      await _users?.put(user.id, user.toJson());
      _logger.d('User saved offline: ${user.id}');
    } catch (e) {
      _logger.e('Failed to save user offline: $e');
      rethrow;
    }
  }

  /// Get user from local storage
  static UserModel? getUser(String userId) {
    try {
      final data = _users?.get(userId);
      if (data != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get user from offline storage: $e');
      return null;
    }
  }

  // SYNC QUEUE OPERATIONS

  /// Add operation to sync queue
  static Future<void> addToSyncQueue({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final syncItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'operation': operation, // 'create', 'update', 'delete'
        'entityType': entityType, // 'receipt', 'team', 'user'
        'entityId': entityId,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      await _syncQueue?.put(syncItem['id'], syncItem);
      _logger.d('Added to sync queue: $operation $entityType $entityId');
    } catch (e) {
      _logger.e('Failed to add to sync queue: $e');
      rethrow;
    }
  }

  /// Get all pending sync operations
  static List<Map<String, dynamic>> getPendingSyncOperations() {
    try {
      final operations = <Map<String, dynamic>>[];
      for (final data in _syncQueue?.values ?? []) {
        if (data is Map) {
          operations.add(Map<String, dynamic>.from(data));
        }
      }
      return operations;
    } catch (e) {
      _logger.e('Failed to get pending sync operations: $e');
      return [];
    }
  }

  /// Remove operation from sync queue
  static Future<void> removeFromSyncQueue(String syncId) async {
    try {
      await _syncQueue?.delete(syncId);
      _logger.d('Removed from sync queue: $syncId');
    } catch (e) {
      _logger.e('Failed to remove from sync queue: $e');
      rethrow;
    }
  }

  /// Update retry count for sync operation
  static Future<void> updateSyncRetryCount(
    String syncId,
    int retryCount,
  ) async {
    try {
      final data = _syncQueue?.get(syncId);
      if (data != null) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['retryCount'] = retryCount;
        await _syncQueue?.put(syncId, updatedData);
      }
    } catch (e) {
      _logger.e('Failed to update sync retry count: $e');
      rethrow;
    }
  }

  // SETTINGS OPERATIONS

  /// Save setting
  static Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settings?.put(key, value);
    } catch (e) {
      _logger.e('Failed to save setting: $e');
      rethrow;
    }
  }

  /// Get setting
  static T? getSetting<T>(String key, [T? defaultValue]) {
    try {
      return _settings?.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      _logger.e('Failed to get setting: $e');
      return defaultValue;
    }
  }

  /// Clear all data (for logout)
  static Future<void> clearAllData() async {
    try {
      await _receipts?.clear();
      await _teams?.clear();
      await _users?.clear();
      await _syncQueue?.clear();
      await _settings?.clear();
      _logger.i('All offline data cleared');
    } catch (e) {
      _logger.e('Failed to clear offline data: $e');
      rethrow;
    }
  }

  /// Get storage statistics
  static Map<String, int> getStorageStats() {
    return {
      'receipts': _receipts?.length ?? 0,
      'teams': _teams?.length ?? 0,
      'users': _users?.length ?? 0,
      'syncQueue': _syncQueue?.length ?? 0,
      'settings': _settings?.length ?? 0,
    };
  }
}
