import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/core/network/supabase_client.dart';
import 'package:mataresit_app/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Database Debug Tests', () {
    setUpAll(() async {
      // Initialize Supabase for testing
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
    });

    test('Check receipts table structure and data', () async {
      try {
        // First, let's check what columns exist in the receipts table
        print('🔍 Checking receipts table structure...');
        
        final response = await SupabaseService.client
            .from('receipts')
            .select('*')
            .limit(3);

        print('📊 Sample receipts data:');
        for (final receipt in response) {
          print('Receipt ID: ${receipt['id']}');
          print('  - merchant: ${receipt['merchant']}');
          print('  - custom_category_id: ${receipt['custom_category_id']}');
          print('  - predicted_category: ${receipt['predicted_category']}');
          print('  - user_id: ${receipt['user_id']}');
          print('  - total: ${receipt['total']}');
          print('---');
        }

        // Now let's check the custom_categories table
        print('🏷️ Checking custom_categories table...');
        
        final categoriesResponse = await SupabaseService.client
            .from('custom_categories')
            .select('*')
            .limit(5);

        print('📊 Sample categories data:');
        for (final category in categoriesResponse) {
          print('Category ID: ${category['id']}');
          print('  - name: ${category['name']}');
          print('  - color: ${category['color']}');
          print('  - user_id: ${category['user_id']}');
          print('  - team_id: ${category['team_id']}');
          print('---');
        }

        // Test the join query that should work
        print('🔗 Testing join query...');
        
        final joinResponse = await SupabaseService.client
            .from('receipts')
            .select('''
              id,
              merchant,
              custom_category_id,
              predicted_category,
              custom_categories (
                id,
                name,
                color,
                icon
              )
            ''')
            .limit(3);

        print('📊 Join query results:');
        for (final receipt in joinResponse) {
          print('Receipt ID: ${receipt['id']}');
          print('  - merchant: ${receipt['merchant']}');
          print('  - custom_category_id: ${receipt['custom_category_id']}');
          print('  - custom_categories: ${receipt['custom_categories']}');
          print('---');
        }

      } catch (e) {
        print('❌ Error: $e');
        fail('Database query failed: $e');
      }
    });

    test('Check if receipts have category assignments', () async {
      try {
        // Count receipts with and without custom_category_id
        final allReceipts = await SupabaseService.client
            .from('receipts')
            .select('id, custom_category_id');

        final withCategories = allReceipts.where((r) => r['custom_category_id'] != null).length;
        final withoutCategories = allReceipts.length - withCategories;

        print('📊 Receipt category statistics:');
        print('  - Total receipts: ${allReceipts.length}');
        print('  - With custom_category_id: $withCategories');
        print('  - Without custom_category_id: $withoutCategories');

        if (withCategories == 0) {
          print('⚠️  WARNING: No receipts have custom_category_id assigned!');
          print('   This explains why all receipts show as "Uncategorized"');
        }

      } catch (e) {
        print('❌ Error checking category assignments: $e');
      }
    });
  });
}
