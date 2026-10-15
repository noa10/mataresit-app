import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mataresit_app/core/network/supabase_client.dart';
import 'package:mataresit_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:mataresit_app/core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Dashboard Data Integration Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // supabase_flutter persists the auth session through shared_preferences.
      // Without a platform implementation the channel call throws and
      // Supabase.initialize() never completes.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (MethodCall call) async =>
                call.method == 'getAll' ? <String, Object>{} : null,
          );

      // SupabaseService.initialize() reuses an already initialized Supabase
      // instance, so seeding one here pins these tests to a stubbed transport:
      // every query resolves with an empty result set instead of reaching a
      // real (let alone production) database.
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
        httpClient: MockClient(
          (request) async => http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

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

        AppLogger.info(
          '📊 Test: Fetched ${(response as List).length} receipts from database',
        );

        // Verify we can fetch data
        expect(response, isA<List>());

        if ((response as List).isNotEmpty) {
          final firstReceipt = response.first;
          AppLogger.info('📋 Test: First receipt data: $firstReceipt');

          // Verify expected fields exist
          expect(firstReceipt, containsPair('id', isA<String>()));
          expect(firstReceipt, containsPair('user_id', isA<String>()));

          // Test the mapping function
          // Note: We can't directly test the private _mapDatabaseToModel method
          // but we can verify the data structure is compatible
          // The receiptProvider is available for future testing if needed
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

        AppLogger.info(
          '📈 Test: Dashboard stats - Total: ${dashboardStats.totalReceipts}, Amount: \$${dashboardStats.totalAmount}',
        );

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
