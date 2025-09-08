import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/network/supabase_client.dart';
import '../models/privacy_settings.dart';
import 'secure_storage_service.dart';

/// Service for privacy controls and data management
class PrivacyService {
  static final Logger _logger = Logger();
  static PrivacySettings? _cachedSettings;

  /// Initialize privacy service
  static Future<void> initialize() async {
    try {
      await _loadSettings();
      _logger.i('Privacy service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize privacy service: $e');
    }
  }

  /// Load privacy settings from secure storage
  static Future<void> _loadSettings() async {
    try {
      final settingsData = await SecureStorageService.getPrivacySettings();
      if (settingsData != null) {
        _cachedSettings = PrivacySettings.fromJson(settingsData);
      } else {
        _cachedSettings = const PrivacySettings();
      }
    } catch (e) {
      _logger.e('Failed to load privacy settings: $e');
      _cachedSettings = const PrivacySettings();
    }
  }

  /// Get current privacy settings
  static PrivacySettings get privacySettings {
    return _cachedSettings ?? const PrivacySettings();
  }

  /// Update privacy settings
  static Future<void> updatePrivacySettings(PrivacySettings settings) async {
    try {
      final updatedSettings = settings.copyWith(lastUpdated: DateTime.now());
      await SecureStorageService.storePrivacySettings(updatedSettings.toJson());
      _cachedSettings = updatedSettings;
      _logger.d('Privacy settings updated successfully');
    } catch (e) {
      _logger.e('Failed to update privacy settings: $e');
      rethrow;
    }
  }

  /// Export user data in JSON format
  static Future<String> exportUserDataAsJson() async {
    try {
      _logger.d('Starting user data export as JSON');

      final userData = await _collectUserData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(userData);

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mataresit_data_export.json');
      await file.writeAsString(jsonString);

      _logger.d('User data exported as JSON successfully');
      return file.path;
    } catch (e) {
      _logger.e('Failed to export user data as JSON: $e');
      rethrow;
    }
  }

  /// Export user data in CSV format
  static Future<String> exportUserDataAsCsv() async {
    try {
      _logger.d('Starting user data export as CSV');

      final userData = await _collectUserData();
      
      // Create CSV content for receipts
      final receipts = userData['receipts'] as List<dynamic>? ?? [];
      final csvData = <List<dynamic>>[
        ['Date', 'Merchant', 'Amount', 'Currency', 'Category', 'Description'],
        ...receipts.map((receipt) => [
          receipt['date'] ?? '',
          receipt['merchant_name'] ?? '',
          receipt['total_amount'] ?? '',
          receipt['currency'] ?? '',
          receipt['category'] ?? '',
          receipt['description'] ?? '',
        ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mataresit_receipts_export.csv');
      await file.writeAsString(csvString);

      _logger.d('User data exported as CSV successfully');
      return file.path;
    } catch (e) {
      _logger.e('Failed to export user data as CSV: $e');
      rethrow;
    }
  }

  /// Share exported data
  static Future<void> shareExportedData(String filePath, String format) async {
    try {
      _logger.d('Sharing exported data: $filePath');

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Mataresit Data Export ($format)',
        subject: 'Your Mataresit Data Export',
      );

      _logger.d('Data shared successfully');
    } catch (e) {
      _logger.e('Failed to share exported data: $e');
      rethrow;
    }
  }

  /// Collect all user data for export
  static Future<Map<String, dynamic>> _collectUserData() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final userData = <String, dynamic>{
        'export_info': {
          'exported_at': DateTime.now().toIso8601String(),
          'user_id': currentUser.id,
          'email': currentUser.email,
          'format_version': '1.0',
        },
        'profile': {
          'id': currentUser.id,
          'email': currentUser.email,
          'created_at': currentUser.createdAt,
          'last_sign_in': currentUser.lastSignInAt,
        },
      };

      // Fetch receipts
      try {
        final receiptsResponse = await SupabaseService.client
            .from('receipts')
            .select()
            .eq('user_id', currentUser.id);
        userData['receipts'] = receiptsResponse;
      } catch (e) {
        _logger.w('Failed to fetch receipts for export: $e');
        userData['receipts'] = [];
      }

      // Fetch claims
      try {
        final claimsResponse = await SupabaseService.client
            .from('claims')
            .select()
            .eq('user_id', currentUser.id);
        userData['claims'] = claimsResponse;
      } catch (e) {
        _logger.w('Failed to fetch claims for export: $e');
        userData['claims'] = [];
      }

      // Fetch user preferences
      try {
        final preferencesResponse = await SupabaseService.client
            .from('user_preferences')
            .select()
            .eq('user_id', currentUser.id)
            .maybeSingle();
        userData['preferences'] = preferencesResponse;
      } catch (e) {
        _logger.w('Failed to fetch preferences for export: $e');
        userData['preferences'] = null;
      }

      return userData;
    } catch (e) {
      _logger.e('Failed to collect user data: $e');
      rethrow;
    }
  }

  /// Delete old data based on retention settings
  static Future<void> cleanupOldData() async {
    try {
      if (privacySettings.dataRetentionDays == 0 || 
          !privacySettings.autoDeleteOldReceipts) {
        _logger.d('Data cleanup skipped - retention disabled or set to keep forever');
        return;
      }

      _logger.d('Starting data cleanup for retention period: ${privacySettings.dataRetentionDays} days');

      final cutoffDate = DateTime.now().subtract(
        Duration(days: privacySettings.dataRetentionDays),
      );

      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Delete old receipts
      try {
        await SupabaseService.client
            .from('receipts')
            .delete()
            .eq('user_id', currentUser.id)
            .lt('created_at', cutoffDate.toIso8601String());
        
        _logger.d('Old receipts cleaned up successfully');
      } catch (e) {
        _logger.w('Failed to cleanup old receipts: $e');
      }

      // Delete old claims
      try {
        await SupabaseService.client
            .from('claims')
            .delete()
            .eq('user_id', currentUser.id)
            .lt('created_at', cutoffDate.toIso8601String());
        
        _logger.d('Old claims cleaned up successfully');
      } catch (e) {
        _logger.w('Failed to cleanup old claims: $e');
      }

      _logger.d('Data cleanup completed successfully');
    } catch (e) {
      _logger.e('Failed to cleanup old data: $e');
      rethrow;
    }
  }

  /// Get data usage statistics
  static Future<Map<String, dynamic>> getDataUsageStats() async {
    try {
      _logger.d('Fetching data usage statistics');

      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final stats = <String, dynamic>{
        'receipts_count': 0,
        'claims_count': 0,
        'storage_used_mb': 0.0,
        'oldest_receipt_date': null,
        'newest_receipt_date': null,
      };

      // Get receipts count and date range
      try {
        final receiptsResponse = await SupabaseService.client
            .from('receipts')
            .select('id, created_at')
            .eq('user_id', currentUser.id);
        
        stats['receipts_count'] = receiptsResponse.length;
        
        if (receiptsResponse.isNotEmpty) {
          final dates = receiptsResponse
              .map((r) => DateTime.parse(r['created_at']))
              .toList()
            ..sort();
          stats['oldest_receipt_date'] = dates.first.toIso8601String();
          stats['newest_receipt_date'] = dates.last.toIso8601String();
        }
      } catch (e) {
        _logger.w('Failed to fetch receipts stats: $e');
      }

      // Get claims count
      try {
        final claimsResponse = await SupabaseService.client
            .from('claims')
            .select('id')
            .eq('user_id', currentUser.id);
        
        stats['claims_count'] = claimsResponse.length;
      } catch (e) {
        _logger.w('Failed to fetch claims stats: $e');
      }

      return stats;
    } catch (e) {
      _logger.e('Failed to get data usage stats: $e');
      return {};
    }
  }

  /// Clear all user data (for account deletion)
  static Future<void> clearAllUserData() async {
    try {
      _logger.d('Starting complete user data deletion');

      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Delete receipts
      try {
        await SupabaseService.client
            .from('receipts')
            .delete()
            .eq('user_id', currentUser.id);
      } catch (e) {
        _logger.w('Failed to delete receipts: $e');
      }

      // Delete claims
      try {
        await SupabaseService.client
            .from('claims')
            .delete()
            .eq('user_id', currentUser.id);
      } catch (e) {
        _logger.w('Failed to delete claims: $e');
      }

      // Delete user preferences
      try {
        await SupabaseService.client
            .from('user_preferences')
            .delete()
            .eq('user_id', currentUser.id);
      } catch (e) {
        _logger.w('Failed to delete user preferences: $e');
      }

      // Clear privacy settings
      _cachedSettings = const PrivacySettings();
      await SecureStorageService.storePrivacySettings(_cachedSettings!.toJson());

      _logger.d('All user data cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear user data: $e');
      rethrow;
    }
  }
}
