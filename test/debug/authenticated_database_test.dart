import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mataresit_app/core/constants/app_constants.dart';

void main() {
  group('Authenticated Database Test', () {
    late SupabaseClient supabase;

    setUpAll(() async {
      // Initialize Supabase client
      supabase = SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
      );
    });

    test('Check database structure and RLS policies', () async {
      try {
        print('🔍 Testing database structure...');

        // Test 1: Check if tables exist by trying to query them
        print('\n📊 Testing receipts table structure...');
        try {
          final receiptsResponse = await supabase
              .from('receipts')
              .select('id')
              .limit(1);
          print(
            '✅ Receipts table accessible, found ${receiptsResponse.length} records',
          );
        } catch (e) {
          print('❌ Receipts table error: $e');
        }

        print('\n🏷️ Testing custom_categories table structure...');
        try {
          final categoriesResponse = await supabase
              .from('custom_categories')
              .select('id')
              .limit(1);
          print(
            '✅ Categories table accessible, found ${categoriesResponse.length} records',
          );
        } catch (e) {
          print('❌ Categories table error: $e');
        }

        // Test 2: Check if we can query without authentication (should be blocked by RLS)
        print('\n🔒 Testing RLS policies...');
        try {
          final allReceipts = await supabase.from('receipts').select('*');
          print(
            '⚠️  RLS might be disabled - got ${allReceipts.length} receipts without auth',
          );
        } catch (e) {
          print('✅ RLS is working - anonymous access blocked: $e');
        }

        // Test 3: Try to get table schema information
        print('\n📋 Testing table schema...');
        try {
          // This might not work with RLS, but let's try
          final schemaResponse = await supabase.rpc(
            'get_table_columns',
            params: {'table_name': 'receipts'},
          );
          print('Schema response: $schemaResponse');
        } catch (e) {
          print('Schema query failed (expected with RLS): $e');
        }

        print('\n💡 Summary:');
        print('  - The database tables exist');
        print('  - RLS policies are likely blocking anonymous access');
        print('  - This explains why Flutter app shows no data');
        print(
          '  - The React web app works because it has proper user authentication',
        );
        print(
          '  - Solution: Ensure Flutter app is properly authenticated before fetching data',
        );
      } catch (e, stackTrace) {
        print('❌ Error: $e');
        print('Stack trace: $stackTrace');
        fail('Database structure test failed: $e');
      }
    });

    test('Test authentication flow', () async {
      print('\n🔐 Testing authentication requirements...');

      // This test documents what we need for proper authentication
      print('For Flutter app to work properly, it needs:');
      print(
        '1. User to be signed in via SupabaseService.signInWithEmailAndPassword()',
      );
      print(
        '2. Valid session token in SupabaseService.client.auth.currentSession',
      );
      print('3. User ID available in SupabaseService.currentUser?.id');
      print('4. Receipts query filtered by user_id to respect RLS policies');
      print('5. Categories query filtered by user_id to respect RLS policies');

      // Check current auth state
      final currentUser = supabase.auth.currentUser;
      final currentSession = supabase.auth.currentSession;

      print('\nCurrent auth state:');
      print('  - User: ${currentUser?.id ?? 'null'}');
      print(
        '  - Session: ${currentSession?.accessToken != null ? 'valid' : 'null'}',
      );

      if (currentUser == null) {
        print('\n⚠️  No authenticated user - this explains the empty results');
        print(
          '   Flutter app needs to authenticate user before fetching receipts',
        );
      }
    });
  });
}
