import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Daily expense data structure matching React web version
class DailyExpenseData {
  final String date;
  final double total;
  final List<String> receiptIds;

  const DailyExpenseData({
    required this.date,
    required this.total,
    required this.receiptIds,
  });

  factory DailyExpenseData.fromJson(Map<String, dynamic> json) {
    return DailyExpenseData(
      date: json['date'] as String,
      total: (json['total'] as num).toDouble(),
      receiptIds: List<String>.from(json['receiptIds'] ?? []),
    );
  }
}

/// Category expense data structure matching React web version
class CategoryExpenseData {
  final String category;
  final double totalSpent;

  const CategoryExpenseData({
    required this.category,
    required this.totalSpent,
  });

  factory CategoryExpenseData.fromJson(Map<String, dynamic> json) {
    return CategoryExpenseData(
      category: json['category'] as String,
      totalSpent: (json['total_spent'] as num).toDouble(),
    );
  }
}

/// Receipt summary data structure matching React web version
class ReceiptSummary {
  final String id;
  final String? date;
  final double? total;
  final String? merchant;
  final String? paymentMethod;

  const ReceiptSummary({
    required this.id,
    this.date,
    this.total,
    this.merchant,
    this.paymentMethod,
  });

  factory ReceiptSummary.fromJson(Map<String, dynamic> json) {
    return ReceiptSummary(
      id: json['id'] as String,
      date: json['date'] as String?,
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      merchant: json['merchant'] as String?,
      paymentMethod: json['payment_method'] as String?,
    );
  }
}

/// Enhanced daily expense data with receipt details
class EnhancedDailyExpenseData {
  final String date;
  final double total;
  final List<ReceiptSummary> receipts;

  const EnhancedDailyExpenseData({
    required this.date,
    required this.total,
    required this.receipts,
  });
}

/// Analytics service that mirrors React web version functionality
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Fetch daily expense data with optional date filtering
  /// Mirrors fetchDailyExpenses from React web version
  Future<List<DailyExpenseData>> fetchDailyExpenses({
    String? startDateISO,
    String? endDateISO,
    String? userId,
  }) async {
    try {
      AppLogger.info('🔍 Fetching daily expenses for user: $userId');

      var query = SupabaseService.client
          .from('receipts')
          .select('id, date, total');

      // Add user filter
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Add date filters
      if (startDateISO != null) {
        query = query.gte('date', startDateISO);
      }
      if (endDateISO != null) {
        query = query.lte('date', endDateISO);
      }

      // Order by date for easier processing
      query = query.order('date', ascending: true);

      final response = await query;

      if (response == null) {
        AppLogger.warning('⚠️ No data returned from daily expenses query');
        return [];
      }

      // Aggregate data client-side (matching React implementation)
      final aggregated = <String, Map<String, dynamic>>{};

      for (final item in response as List) {
        // Ensure date is handled correctly (without time part for grouping)
        final dateKey = (item['date'] as String).split('T')[0];
        if (!aggregated.containsKey(dateKey)) {
          aggregated[dateKey] = {'total': 0.0, 'receiptIds': <String>[]};
        }
        aggregated[dateKey]!['total'] = 
            (aggregated[dateKey]!['total'] as double) + ((item['total'] as num?)?.toDouble() ?? 0.0);
        (aggregated[dateKey]!['receiptIds'] as List<String>).add(item['id'] as String);
      }

      final result = aggregated.entries.map((entry) {
        return DailyExpenseData(
          date: entry.key,
          total: entry.value['total'] as double,
          receiptIds: entry.value['receiptIds'] as List<String>,
        );
      }).toList();

      AppLogger.info('✅ Successfully fetched ${result.length} daily expense entries');
      return result;

    } catch (e) {
      AppLogger.error('❌ Error fetching daily expenses', e);
      throw Exception('Could not fetch daily expenses data: $e');
    }
  }

  /// Fetch expenses grouped by category with optional date filtering
  /// Mirrors fetchExpensesByCategory from React web version
  Future<List<CategoryExpenseData>> fetchExpensesByCategory({
    String? startDateISO,
    String? endDateISO,
    String? userId,
  }) async {
    try {
      AppLogger.info('🔍 Fetching category expenses for user: $userId');

      // Query receipts with custom category information (matching React implementation)
      var query = SupabaseService.client
          .from('receipts')
          .select('''
            predicted_category,
            total,
            custom_categories (
              name
            )
          ''');

      // Add user filter
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Add date filters
      if (startDateISO != null) {
        query = query.gte('date', startDateISO);
      }
      if (endDateISO != null) {
        query = query.lte('date', endDateISO);
      }

      final response = await query;

      if (response == null) {
        AppLogger.warning('⚠️ No data returned from category expenses query');
        return [];
      }

      // Aggregate client-side (matching React implementation)
      final aggregated = <String, double>{};
      
      for (final item in response as List) {
        // Priority: custom category name → predicted category → 'Uncategorized'
        final customCategory = item['custom_categories'];
        final categoryKey = (customCategory != null && customCategory['name'] != null)
            ? customCategory['name'] as String
            : (item['predicted_category'] as String?) ?? 'Uncategorized';
        
        if (!aggregated.containsKey(categoryKey)) {
          aggregated[categoryKey] = 0.0;
        }
        aggregated[categoryKey] = aggregated[categoryKey]! + ((item['total'] as num?)?.toDouble() ?? 0.0);
      }

      final result = aggregated.entries.map((entry) {
        return CategoryExpenseData(
          category: entry.key,
          totalSpent: entry.value,
        );
      }).toList();

      AppLogger.info('✅ Successfully fetched ${result.length} category expense entries');
      return result;

    } catch (e) {
      AppLogger.error('❌ Error fetching category expenses', e);
      throw Exception('Could not fetch category expense data: $e');
    }
  }

  /// Fetch detailed receipt summaries for a date range
  /// Mirrors fetchReceiptDetailsForRange from React web version
  Future<List<ReceiptSummary>> fetchReceiptDetailsForRange({
    String? startDateISO,
    String? endDateISO,
    String? userId,
  }) async {
    try {
      AppLogger.info('🔍 Fetching receipt details for range - user: $userId');

      var query = SupabaseService.client
          .from('receipts')
          .select('id, date, total, merchant, payment_method');

      // Add user filter
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Add date filters
      if (startDateISO != null) {
        query = query.gte('date', startDateISO);
      }
      if (endDateISO != null) {
        query = query.lte('date', endDateISO);
      }

      // Order by date for easier processing
      query = query.order('date', ascending: true);

      final response = await query;

      if (response == null) {
        AppLogger.warning('⚠️ No data returned from receipt details query');
        return [];
      }

      final result = (response as List).map((item) {
        return ReceiptSummary.fromJson(item);
      }).toList();

      AppLogger.info('✅ Successfully fetched ${result.length} receipt summaries');
      return result;

    } catch (e) {
      AppLogger.error('❌ Error fetching receipt details for range', e);
      throw Exception('Could not fetch detailed receipts data: $e');
    }
  }

  /// Transform receipt summaries to enhanced daily expense data
  /// Mirrors the select transformation logic from React web version
  List<EnhancedDailyExpenseData> transformToEnhancedDailyData(List<ReceiptSummary> receipts) {
    final grouped = <String, List<ReceiptSummary>>{};

    for (final receipt in receipts) {
      // Ensure date is handled correctly (extract date part)
      final date = (receipt.date ?? '').split('T')[0];
      if (date.isEmpty) continue; // Skip if date is invalid

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(receipt);
    }

    return grouped.entries.map((entry) {
      final total = entry.value.fold<double>(0.0, (sum, receipt) => sum + (receipt.total ?? 0.0));
      return EnhancedDailyExpenseData(
        date: entry.key,
        total: total,
        receipts: entry.value,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Sort by date
  }
}

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
