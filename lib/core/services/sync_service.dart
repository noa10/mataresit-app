import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/supabase_client.dart';
import 'offline_database_service.dart';
import 'connectivity_service.dart';
import '../../shared/models/receipt_model.dart';
import '../../shared/models/team_model.dart';
import '../../shared/models/user_model.dart';

/// Service for synchronizing data between local and remote storage
class SyncService {
  static final Logger _logger = Logger();
  static Timer? _syncTimer;
  static bool _isSyncing = false;
  static final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();

  /// Stream of sync status updates
  static Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Initialize sync service
  static Future<void> initialize() async {
    try {
      // Listen to connectivity changes
      ConnectivityService.connectivityStream.listen((isOnline) {
        if (isOnline && !_isSyncing) {
          _logger.i('Device online - starting sync');
          syncPendingOperations();
        }
      });

      // Start periodic sync (every 5 minutes when online)
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        if (ConnectivityService.isOnline && !_isSyncing) {
          syncPendingOperations();
        }
      });

      _logger.i('Sync Service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Sync Service: $e');
      rethrow;
    }
  }

  /// Sync all pending operations
  static Future<void> syncPendingOperations() async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping');
      return;
    }

    if (!ConnectivityService.isOnline) {
      _logger.d('Device offline, skipping sync');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      final pendingOperations = OfflineDatabaseService.getPendingSyncOperations();
      _logger.i('Starting sync of ${pendingOperations.length} operations');

      int successCount = 0;
      int failureCount = 0;

      for (final operation in pendingOperations) {
        try {
          await _processSyncOperation(operation);
          await OfflineDatabaseService.removeFromSyncQueue(operation['id']);
          successCount++;
        } catch (e) {
          _logger.e('Failed to sync operation ${operation['id']}: $e');
          
          // Update retry count
          final retryCount = (operation['retryCount'] as int? ?? 0) + 1;
          if (retryCount < 3) {
            await OfflineDatabaseService.updateSyncRetryCount(operation['id'], retryCount);
          } else {
            // Remove after 3 failed attempts
            await OfflineDatabaseService.removeFromSyncQueue(operation['id']);
            _logger.w('Removing operation ${operation['id']} after 3 failed attempts');
          }
          failureCount++;
        }
      }

      _logger.i('Sync completed: $successCount success, $failureCount failures');
      _syncStatusController.add(SyncStatus.completed);

      // Sync remote changes to local
      await _syncRemoteChanges();

    } catch (e) {
      _logger.e('Sync failed: $e');
      _syncStatusController.add(SyncStatus.failed);
    } finally {
      _isSyncing = false;
    }
  }

  /// Process individual sync operation
  static Future<void> _processSyncOperation(Map<String, dynamic> operation) async {
    final operationType = operation['operation'] as String;
    final entityType = operation['entityType'] as String;
    final entityId = operation['entityId'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    switch (entityType) {
      case 'receipt':
        await _syncReceiptOperation(operationType, entityId, data);
        break;
      case 'team':
        await _syncTeamOperation(operationType, entityId, data);
        break;
      case 'user':
        await _syncUserOperation(operationType, entityId, data);
        break;
      default:
        throw Exception('Unknown entity type: $entityType');
    }
  }

  /// Sync receipt operation
  static Future<void> _syncReceiptOperation(String operation, String entityId, Map<String, dynamic> data) async {
    switch (operation) {
      case 'create':
      case 'update':
        // Map the data to match database schema
        final mappedData = _mapReceiptDataForDatabase(data);
        await SupabaseService.client
            .from('receipts')
            .upsert(mappedData);
        break;
      case 'delete':
        await SupabaseService.client
            .from('receipts')
            .delete()
            .eq('id', entityId);
        break;
    }
  }

  /// Map receipt data from model format to database format
  static Map<String, dynamic> _mapReceiptDataForDatabase(Map<String, dynamic> data) {
    final mappedData = Map<String, dynamic>.from(data);

    // Map category to predicted_category
    if (mappedData.containsKey('category')) {
      mappedData['predicted_category'] = mappedData.remove('category');
    }

    // Map other fields that might have different names
    if (mappedData.containsKey('merchantName')) {
      mappedData['merchant'] = mappedData.remove('merchantName');
    }

    if (mappedData.containsKey('transactionDate')) {
      mappedData['date'] = mappedData.remove('transactionDate');
    }

    if (mappedData.containsKey('totalAmount')) {
      mappedData['total'] = mappedData.remove('totalAmount');
    }

    if (mappedData.containsKey('taxAmount')) {
      mappedData['tax'] = mappedData.remove('taxAmount');
    }

    if (mappedData.containsKey('paymentMethod')) {
      mappedData['payment_method'] = mappedData.remove('paymentMethod');
    }

    return mappedData;
  }

  /// Sync team operation
  static Future<void> _syncTeamOperation(String operation, String entityId, Map<String, dynamic> data) async {
    switch (operation) {
      case 'create':
      case 'update':
        await SupabaseService.client
            .from('teams')
            .upsert(data);
        break;
      case 'delete':
        await SupabaseService.client
            .from('teams')
            .delete()
            .eq('id', entityId);
        break;
    }
  }

  /// Sync user operation
  static Future<void> _syncUserOperation(String operation, String entityId, Map<String, dynamic> data) async {
    switch (operation) {
      case 'create':
      case 'update':
        await SupabaseService.client
            .from('profiles')
            .upsert(data);
        break;
      case 'delete':
        await SupabaseService.client
            .from('profiles')
            .delete()
            .eq('id', entityId);
        break;
    }
  }

  /// Migrate user data from offline storage to Supabase
  static Future<void> migrateUserDataToSupabase(String userId) async {
    try {
      _logger.i('Starting user data migration for user: $userId');

      // Get user data from offline storage
      final userData = OfflineDatabaseService.getUser(userId);
      if (userData != null) {
        // Convert to profile format and sync
        final profileData = _convertUserToProfileFormat(userData.toJson());
        await queueOperation(
          operation: 'update',
          entityType: 'user',
          entityId: userId,
          data: profileData,
        );
      }

      // Get user's receipts from offline storage
      final receipts = OfflineDatabaseService.getAllReceipts()
          .where((receipt) => receipt.userId == userId)
          .toList();

      for (final receipt in receipts) {
        await queueOperation(
          operation: 'create',
          entityType: 'receipt',
          entityId: receipt.id,
          data: receipt.toJson(),
        );
      }

      // Get user's teams from offline storage
      final teams = OfflineDatabaseService.getAllTeams()
          .where((team) => team.ownerId == userId ||
                          team.memberIds.contains(userId))
          .toList();

      for (final team in teams) {
        await queueOperation(
          operation: 'create',
          entityType: 'team',
          entityId: team.id,
          data: team.toJson(),
        );
      }

      // Trigger sync
      await syncPendingOperations();

      _logger.i('User data migration completed for user: $userId');
    } catch (e) {
      _logger.e('Failed to migrate user data: $e');
      rethrow;
    }
  }

  /// Convert old user format to new profile format
  static Map<String, dynamic> _convertUserToProfileFormat(Map<String, dynamic> userData) {
    return {
      'id': userData['id'],
      'email': userData['email'],
      'first_name': userData['full_name']?.split(' ').first ?? '',
      'last_name': userData['full_name']?.split(' ').skip(1).join(' ') ?? '',
      'avatar_url': userData['avatar_url'],
      'google_avatar_url': userData['google_avatar_url'],
      'subscription_tier': userData['subscription_tier'] ?? 'free',
      'subscription_status': userData['subscription_status'] ?? 'active',
      'receipts_used_this_month': userData['receipts_used_this_month'] ?? 0,
      'preferred_language': userData['language'] ?? 'en',
      'created_at': userData['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Check and resolve data consistency between local and remote
  static Future<void> checkDataConsistency(String userId) async {
    try {
      _logger.i('Checking data consistency for user: $userId');

      // Check profile consistency
      final localProfile = OfflineDatabaseService.getUser(userId);
      final remoteProfile = await SupabaseService.getUserProfile(userId);

      if (localProfile != null && remoteProfile != null) {
        // Compare timestamps and sync newer data
        final localUpdated = localProfile.updatedAt;
        final remoteUpdated = DateTime.tryParse(remoteProfile['updated_at'] ?? '');

        if (remoteUpdated != null) {
          if (localUpdated.isAfter(remoteUpdated)) {
            // Local is newer, sync to remote
            final profileData = _convertUserToProfileFormat(localProfile.toJson());
            await queueOperation(
              operation: 'update',
              entityType: 'user',
              entityId: userId,
              data: profileData,
            );
          } else if (remoteUpdated.isAfter(localUpdated)) {
            // Remote is newer, sync to local
            final updatedUser = UserModel.fromJson(remoteProfile);
            await OfflineDatabaseService.saveUser(updatedUser);
          }
        }
      }

      // Check receipts consistency
      await _checkReceiptsConsistency(userId);

      _logger.i('Data consistency check completed for user: $userId');
    } catch (e) {
      _logger.e('Failed to check data consistency: $e');
      // Don't rethrow - consistency check failures shouldn't break the app
    }
  }

  /// Check receipts consistency between local and remote
  static Future<void> _checkReceiptsConsistency(String userId) async {
    try {
      // Get local receipts
      final localReceipts = OfflineDatabaseService.getAllReceipts()
          .where((receipt) => receipt.userId == userId)
          .toList();

      // Get remote receipts
      final remoteReceipts = await SupabaseService.client
          .from('receipts')
          .select()
          .eq('user_id', userId);

      // Create maps for easier comparison
      final localReceiptMap = {for (var r in localReceipts) r.id: _mapReceiptDataForDatabase(r.toJson())};
      final remoteReceiptMap = {for (var r in remoteReceipts) r['id']: r};

      // Find receipts that exist locally but not remotely
      for (final localId in localReceiptMap.keys) {
        if (!remoteReceiptMap.containsKey(localId)) {
          await queueOperation(
            operation: 'create',
            entityType: 'receipt',
            entityId: localId,
            data: localReceiptMap[localId]!,
          );
        }
      }

      // Find receipts that exist remotely but not locally
      for (final remoteId in remoteReceiptMap.keys) {
        if (!localReceiptMap.containsKey(remoteId)) {
          final remoteReceipt = ReceiptModel.fromJson(remoteReceiptMap[remoteId]!);
          await OfflineDatabaseService.saveReceipt(remoteReceipt);
        }
      }

    } catch (e) {
      _logger.e('Failed to check receipts consistency: $e');
    }
  }

  /// Sync remote changes to local storage
  static Future<void> _syncRemoteChanges() async {
    try {
      _logger.d('Syncing remote changes to local storage');

      // Get last sync timestamp
      final lastSync = OfflineDatabaseService.getSetting<String>('last_sync_timestamp');
      final lastSyncDate = lastSync != null ? DateTime.parse(lastSync) : DateTime.now().subtract(const Duration(days: 30));

      // Sync receipts
      await _syncRemoteReceipts(lastSyncDate);

      // Sync teams
      await _syncRemoteTeams(lastSyncDate);

      // Update last sync timestamp
      await OfflineDatabaseService.saveSetting('last_sync_timestamp', DateTime.now().toIso8601String());

    } catch (e) {
      _logger.e('Failed to sync remote changes: $e');
      rethrow;
    }
  }

  /// Sync remote receipts to local storage
  static Future<void> _syncRemoteReceipts(DateTime lastSync) async {
    try {
      // Get current user to filter receipts properly
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        _logger.w('No authenticated user found, skipping receipt sync');
        return;
      }

      // Build query with proper user filtering (similar to React app)
      var query = SupabaseService.client
          .from('receipts')
          .select()
          .eq('user_id', user.id)  // Filter by current user
          .gte('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: false);

      final response = await query;

      for (final receiptData in response as List) {
        final receipt = ReceiptModel.fromJson(receiptData);
        await OfflineDatabaseService.saveReceipt(receipt);
      }

      _logger.d('Synced ${response.length} receipts from remote for user ${user.email}');
    } catch (e) {
      _logger.e('Failed to sync remote receipts: $e');
      rethrow;
    }
  }

  /// Sync remote teams to local storage
  static Future<void> _syncRemoteTeams(DateTime lastSync) async {
    try {
      final response = await SupabaseService.client
          .from('teams')
          .select()
          .gte('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: false);

      for (final teamData in response as List) {
        final team = TeamModel.fromJson(teamData);
        await OfflineDatabaseService.saveTeam(team);
      }

      _logger.d('Synced ${response.length} teams from remote');
    } catch (e) {
      _logger.e('Failed to sync remote teams: $e');
    }
  }

  /// Force full sync
  static Future<void> forceSyncAll() async {
    _logger.i('Starting force sync of all data');
    
    // Clear last sync timestamp to force full sync
    await OfflineDatabaseService.saveSetting('last_sync_timestamp', null);
    
    // Start sync
    await syncPendingOperations();
  }

  /// Add operation to sync queue (for offline operations)
  static Future<void> queueOperation({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    await OfflineDatabaseService.addToSyncQueue(
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      data: data,
    );

    // Try immediate sync if online
    if (ConnectivityService.isOnline && !_isSyncing) {
      syncPendingOperations();
    }
  }

  /// Get sync statistics
  static Map<String, dynamic> getSyncStats() {
    final pendingOps = OfflineDatabaseService.getPendingSyncOperations();
    final storageStats = OfflineDatabaseService.getStorageStats();
    
    return {
      'pendingOperations': pendingOps.length,
      'isOnline': ConnectivityService.isOnline,
      'isSyncing': _isSyncing,
      'storageStats': storageStats,
      'lastSync': OfflineDatabaseService.getSetting<String>('last_sync_timestamp'),
    };
  }

  /// Dispose resources
  static void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

/// Sync state
class SyncState {
  final SyncStatus status;
  final int pendingOperations;
  final DateTime? lastSync;
  final String? error;

  const SyncState({
    required this.status,
    required this.pendingOperations,
    this.lastSync,
    this.error,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingOperations,
    DateTime? lastSync,
    String? error,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      lastSync: lastSync ?? this.lastSync,
      error: error,
    );
  }
}

/// Sync notifier
class SyncNotifier extends StateNotifier<SyncState> {
  StreamSubscription<SyncStatus>? _subscription;

  SyncNotifier() : super(const SyncState(
    status: SyncStatus.idle,
    pendingOperations: 0,
  )) {
    _initializeSync();
  }

  void _initializeSync() {
    _subscription = SyncService.syncStatusStream.listen((status) {
      final stats = SyncService.getSyncStats();
      state = state.copyWith(
        status: status,
        pendingOperations: stats['pendingOperations'] as int,
        lastSync: stats['lastSync'] != null 
            ? DateTime.parse(stats['lastSync'] as String)
            : null,
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Sync provider
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
