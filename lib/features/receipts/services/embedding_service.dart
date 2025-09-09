import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Service for managing receipt embeddings and search index synchronization
class EmbeddingService {
  static final _logger = Logger();
  static final _supabase = Supabase.instance.client;

  /// Trigger embedding regeneration for a receipt after data modification
  /// This ensures the search index stays synchronized with updated receipt data
  static Future<bool> regenerateEmbeddingsForReceipt(String receiptId) async {
    try {
      _logger.i('🔄 Triggering embedding regeneration for receipt $receiptId');

      // Call the generate-embeddings edge function
      final response = await _supabase.functions.invoke(
        'generate-embeddings',
        body: {
          'receiptId': receiptId,
          'processAllFields': true,
          'processLineItems': true,
          'useImprovedDimensionHandling': true,
          'forceRegenerate': true, // Force regeneration even if embeddings exist
        },
      );

      if (response.status == 200) {
        _logger.i('✅ Successfully triggered embedding regeneration for receipt $receiptId');
        return true;
      } else {
        _logger.w('⚠️ Embedding regeneration returned status ${response.status} for receipt $receiptId');
        _logger.w('Response: ${response.data}');
        return false;
      }
    } catch (error) {
      _logger.e('❌ Failed to trigger embedding regeneration for receipt $receiptId: $error');
      return false;
    }
  }

  /// Queue embedding regeneration for a receipt (asynchronous processing)
  /// This is preferred for non-critical updates to avoid blocking the UI
  static Future<bool> queueEmbeddingRegeneration(String receiptId) async {
    try {
      _logger.i('📋 Queuing embedding regeneration for receipt $receiptId');

      // Insert into embedding queue for asynchronous processing
      await _supabase
          .from('embedding_queue')
          .insert({
            'source_type': 'receipt',
            'source_id': receiptId,
            'operation': 'regenerate',
            'priority': 'normal',
            'metadata': {
              'trigger': 'receipt_edit',
              'timestamp': DateTime.now().toIso8601String(),
              'source': 'flutter_app',
            },
          });

      _logger.i('✅ Successfully queued embedding regeneration for receipt $receiptId');
      return true;
    } catch (error) {
      _logger.e('❌ Failed to queue embedding regeneration for receipt $receiptId: $error');
      
      // Fallback to direct regeneration if queue fails
      _logger.i('🔄 Falling back to direct embedding regeneration');
      return await regenerateEmbeddingsForReceipt(receiptId);
    }
  }

  /// Check if a receipt has embeddings
  static Future<bool> hasEmbeddings(String receiptId) async {
    try {
      final response = await _supabase
          .from('receipt_embeddings')
          .select('id')
          .eq('receipt_id', receiptId)
          .limit(1);

      return response.isNotEmpty;
    } catch (error) {
      _logger.e('❌ Failed to check embeddings for receipt $receiptId: $error');
      return false;
    }
  }

  /// Get embedding status for a receipt
  static Future<String?> getEmbeddingStatus(String receiptId) async {
    try {
      final response = await _supabase
          .from('receipts')
          .select('embedding_status')
          .eq('id', receiptId)
          .single();

      return response['embedding_status'] as String?;
    } catch (error) {
      _logger.e('❌ Failed to get embedding status for receipt $receiptId: $error');
      return null;
    }
  }

  /// Update embedding status for a receipt
  static Future<bool> updateEmbeddingStatus(String receiptId, String status) async {
    try {
      await _supabase
          .from('receipts')
          .update({'embedding_status': status})
          .eq('id', receiptId);

      _logger.d('✅ Updated embedding status to $status for receipt $receiptId');
      return true;
    } catch (error) {
      _logger.e('❌ Failed to update embedding status for receipt $receiptId: $error');
      return false;
    }
  }

  /// Batch regenerate embeddings for multiple receipts
  static Future<Map<String, bool>> batchRegenerateEmbeddings(List<String> receiptIds) async {
    final results = <String, bool>{};
    
    _logger.i('🔄 Batch regenerating embeddings for ${receiptIds.length} receipts');

    for (final receiptId in receiptIds) {
      final success = await queueEmbeddingRegeneration(receiptId);
      results[receiptId] = success;
      
      // Small delay to avoid overwhelming the system
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final successCount = results.values.where((success) => success).length;
    _logger.i('✅ Batch embedding regeneration completed: $successCount/${receiptIds.length} successful');

    return results;
  }

  /// Check if embedding synchronization is enabled
  static bool isEmbeddingSyncEnabled() {
    // This could be controlled by a feature flag or user preference
    // For now, we'll enable it by default since the infrastructure exists
    return true;
  }

  /// Sync embeddings after receipt modification
  /// This is the main method that should be called after receipt updates
  static Future<void> syncEmbeddingsAfterReceiptUpdate(String receiptId, {
    bool forceImmediate = false,
  }) async {
    if (!isEmbeddingSyncEnabled()) {
      _logger.d('🔇 Embedding synchronization is disabled, skipping for receipt $receiptId');
      return;
    }

    _logger.i('🔄 Syncing embeddings after receipt update for $receiptId');

    try {
      if (forceImmediate) {
        // For critical updates, regenerate immediately
        await regenerateEmbeddingsForReceipt(receiptId);
      } else {
        // For normal updates, use queue for better performance
        await queueEmbeddingRegeneration(receiptId);
      }
    } catch (error) {
      _logger.e('❌ Failed to sync embeddings for receipt $receiptId: $error');
      // Don't throw the error to avoid breaking the receipt update flow
    }
  }
}
