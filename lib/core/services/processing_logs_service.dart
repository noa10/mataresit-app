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

  /// Save processing log to database
  Future<void> saveProcessingLog(
    String receiptId,
    String stepName,
    String message, {
    int? progress,
  }) async {
    try {
      // Save to database - the processing_logs table exists
      await SupabaseService.client.from('processing_logs').insert({
        'receipt_id': receiptId,
        'status_message': message,
        'step_name': stepName,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Processing log saved to database', {
        'receiptId': receiptId,
        'stepName': stepName,
        'message': message,
        'progress': progress,
      });
    } catch (e) {
      AppLogger.error('Failed to save processing log to database', e);
      // Don't rethrow - logging failures shouldn't break the main flow
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
