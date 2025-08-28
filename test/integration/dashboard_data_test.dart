import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/core/network/supabase_client.dart';
import '../../lib/features/receipts/providers/receipts_provider.dart';
import '../../lib/features/dashboard/providers/dashboard_provider.dart';
import '../../lib/core/services/app_logger.dart';

void main() {
  group('Dashboard Data Integration Tests', () {
    setUpAll(() async {
      // Initialize Supabase
      await SupabaseService.initialize();
    });

    test('Should fetch real receipts from Supabase', () async {
      // Create a provider container
      final container = ProviderContainer();
      
      try {
        // Test direct Supabase query
        final response = await SupabaseService.client
            .from('receipts')
            .select()
            .limit(5);

        AppLogger.info('📊 Test: Fetched ${(response as List).length} receipts from database');
        
        // Verify we can fetch data
        expect(response, isA<List>());
        
        if ((response as List).isNotEmpty) {
          final firstReceipt = response.first;
          AppLogger.info('📋 Test: First receipt data: $firstReceipt');
          
          // Verify expected fields exist
          expect(firstReceipt, containsPair('id', isA<String>()));
          expect(firstReceipt, containsPair('user_id', isA<String>()));
          
          // Test the mapping function
          final receiptProvider = container.read(receiptsProvider.notifier);
          // Note: We can't directly test the private _mapDatabaseToModel method
          // but we can verify the data structure is compatible
        }
        
      } catch (e) {
        AppLogger.error('❌ Test failed to fetch receipts', e);
        fail('Failed to fetch receipts: $e');
      } finally {
        container.dispose();
      }
    });

    test('Should calculate dashboard stats correctly', () async {
      final container = ProviderContainer();
      
      try {
        // This will trigger the receipts provider to load data
        final dashboardStats = container.read(dashboardStatsProvider);
        
        AppLogger.info('📈 Test: Dashboard stats - Total: ${dashboardStats.totalReceipts}, Amount: \$${dashboardStats.totalAmount}');
        
        // Verify stats structure
        expect(dashboardStats.totalReceipts, isA<int>());
        expect(dashboardStats.totalAmount, isA<double>());
        expect(dashboardStats.thisMonthReceipts, isA<int>());
        expect(dashboardStats.recentReceipts, isA<List>());
        
      } catch (e) {
        AppLogger.error('❌ Test failed to calculate dashboard stats', e);
        fail('Failed to calculate dashboard stats: $e');
      } finally {
        container.dispose();
      }
    });

    test('Should handle empty database gracefully', () async {
      final container = ProviderContainer();
      
      try {
        // Test with potentially empty results
        final response = await SupabaseService.client
            .from('receipts')
            .select()
            .eq('user_id', 'non-existent-user-id')
            .limit(1);

        expect(response, isA<List>());
        expect((response as List).isEmpty, isTrue);
        
        AppLogger.info('✅ Test: Empty database query handled correctly');
        
      } catch (e) {
        AppLogger.error('❌ Test failed to handle empty database', e);
        fail('Failed to handle empty database: $e');
      } finally {
        container.dispose();
      }
    });
  });
}
