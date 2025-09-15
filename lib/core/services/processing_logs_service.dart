import 'dart:async';
import '../../shared/models/processing_log_model.dart';
import '../network/supabase_client.dart';
import 'app_logger.dart';

/// Service for managing real-time processing logs
class ProcessingLogsService {
  static final ProcessingLogsService _instance =
      ProcessingLogsService._internal();
  factory ProcessingLogsService() => _instance;
  ProcessingLogsService._internal();

  final Map<String, StreamController<ProcessingLogModel>> _logControllers = {};

  /// Subscribe to real-time processing logs for a specific receipt
  Stream<ProcessingLogModel> subscribeToProcessingLogs(String receiptId) {
    // Return existing stream if already subscribed
    if (_logControllers.containsKey(receiptId)) {
      return _logControllers[receiptId]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<ProcessingLogModel>.broadcast();
    _logControllers[receiptId] = controller;

    // For now, we'll use local logging only
    // Real-time subscription can be added later when processing_logs table is set up
    AppLogger.info('Created processing logs stream', {'receiptId': receiptId});

    // Clean up when stream is cancelled
    controller.onCancel = () {
      _unsubscribeFromLogs(receiptId);
    };

    return controller.stream;
  }

  /// Unsubscribe from processing logs for a specific receipt
  void _unsubscribeFromLogs(String receiptId) {
    // Close stream controller
    final controller = _logControllers.remove(receiptId);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }

    AppLogger.info('Unsubscribed from processing logs', {
      'receiptId': receiptId,
    });
  }

  /// Add a local processing log (for immediate UI feedback)
  Future<void> addLocalLog(
    String receiptId,
    String stepName,
    String message, {
    int? progress,
  }) async {
    try {
      final log = ProcessingLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        receiptId: receiptId,
        createdAt: DateTime.now(),
        statusMessage: message,
        stepName: stepName,
        progress: progress,
      );

      // Add to local stream if exists
      final controller = _logControllers[receiptId];
      if (controller != null && !controller.isClosed) {
        controller.add(log);
      }

      AppLogger.info('Added local processing log', {
        'receiptId': receiptId,
        'stepName': stepName,
        'message': message,
      });
    } catch (e) {
      AppLogger.error('Failed to add local processing log', e);
    }
  }

  /// Save processing log to database (only after receipt exists)
  Future<void> saveProcessingLog(
    String receiptId,
    String stepName,
    String message, {
    int? progress,
    bool forceSkip = false,
  }) async {
    // Skip database saves for early processing steps before receipt is created
    if (forceSkip || _shouldSkipDatabaseSave(stepName)) {
      AppLogger.info('Skipping database save for processing log', {
        'receiptId': receiptId,
        'stepName': stepName,
        'reason': forceSkip ? 'forced skip' : 'early processing step',
      });
      return;
    }

    try {
      // Check authentication state before attempting to save
      final currentUser = SupabaseService.currentUser;
      final session = SupabaseService.client.auth.currentSession;

      AppLogger.info('Processing log save attempt - Auth check', {
        'receiptId': receiptId,
        'stepName': stepName,
        'hasUser': currentUser != null,
        'userId': currentUser?.id,
        'hasSession': session != null,
        'sessionExpiry': session?.expiresAt,
        'sessionValid': session != null &&
            (session.expiresAt ?? 0) > DateTime.now().millisecondsSinceEpoch / 1000,
      });

      if (currentUser == null || session == null) {
        AppLogger.warning('Cannot save processing log - no authentication', {
          'receiptId': receiptId,
          'stepName': stepName,
          'hasUser': currentUser != null,
          'hasSession': session != null,
        });
        return; // Skip saving if not authenticated
      }

      // Verify receipt exists before saving processing log
      final receiptExists = await _verifyReceiptExists(receiptId);
      if (!receiptExists) {
        AppLogger.warning('Cannot save processing log - receipt does not exist yet', {
          'receiptId': receiptId,
          'stepName': stepName,
        });
        return;
      }

      // Save to database - let the database handle id and created_at defaults
      await SupabaseService.client.from('processing_logs').insert({
        'receipt_id': receiptId,
        'status_message': message,
        'step_name': stepName,
        // Don't set 'id' or 'created_at' - let database defaults handle these
      });

      AppLogger.info('Processing log saved to database', {
        'receiptId': receiptId,
        'stepName': stepName,
        'message': message,
        'progress': progress,
        'userId': currentUser.id,
      });
    } catch (e) {
      AppLogger.error('Failed to save processing log to database', {
        'error': e.toString(),
        'receiptId': receiptId,
        'stepName': stepName,
        'message': message,
      });
      // Don't rethrow - logging failures shouldn't break the main flow
    }
  }

  /// Check if we should skip database saves for certain processing steps
  bool _shouldSkipDatabaseSave(String stepName) {
    // Skip database saves for steps that happen before receipt creation
    const earlySteps = ['START', 'FETCH', 'SAVE'];
    return earlySteps.contains(stepName);
  }

  /// Verify that a receipt exists in the database
  Future<bool> _verifyReceiptExists(String receiptId) async {
    try {
      final response = await SupabaseService.client
          .from('receipts')
          .select('id')
          .eq('id', receiptId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.warning('Failed to verify receipt exists', {
        'receiptId': receiptId,
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Get existing processing logs for a receipt
  Future<List<ProcessingLogModel>> getProcessingLogs(String receiptId) async {
    try {
      final response = await SupabaseService.client
          .from('processing_logs')
          .select('*')
          .eq('receipt_id', receiptId)
          .order('created_at', ascending: true);

      final logs = (response as List)
          .map((data) => ProcessingLogModel.fromJson(data))
          .toList();

      AppLogger.info('Retrieved processing logs', {
        'receiptId': receiptId,
        'count': logs.length,
      });

      return logs;
    } catch (e) {
      AppLogger.error('Failed to retrieve processing logs', e);
      return [];
    }
  }

  /// Test authentication and RLS policies for processing logs
  Future<Map<String, dynamic>> testAuthAndRLS() async {
    try {
      final currentUser = SupabaseService.currentUser;
      final session = SupabaseService.client.auth.currentSession;

      final result = {
        'hasUser': currentUser != null,
        'userId': currentUser?.id,
        'userEmail': currentUser?.email,
        'hasSession': session != null,
        'sessionExpiry': session?.expiresAt,
        'sessionValid': session != null &&
            (session.expiresAt ?? 0) > DateTime.now().millisecondsSinceEpoch / 1000,
      };

      AppLogger.info('Auth and RLS test results', result);

      // Try to query user's receipts to test RLS
      try {
        final receiptsResponse = await SupabaseService.client
            .from('receipts')
            .select('id, created_at')
            .limit(1);

        result['canQueryReceipts'] = true;
        result['receiptsCount'] = (receiptsResponse as List).length;
      } catch (e) {
        result['canQueryReceipts'] = false;
        result['receiptsError'] = e.toString();
      }

      return result;
    } catch (e) {
      AppLogger.error('Auth and RLS test failed', e);
      return {
        'error': e.toString(),
        'hasUser': false,
        'hasSession': false,
      };
    }
  }

  /// Clean up all subscriptions
  void dispose() {
    final receiptIds = _logControllers.keys.toList();
    for (final receiptId in receiptIds) {
      _unsubscribeFromLogs(receiptId);
    }
    AppLogger.info('ProcessingLogsService disposed');
  }

  /// Get active subscription count (for debugging)
  int get activeSubscriptionCount => _logControllers.length;
}
