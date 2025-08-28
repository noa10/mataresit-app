import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mataresit_app/core/constants/app_constants.dart';

void main() {
  group('Simple Database Test', () {
    late SupabaseClient supabase;

    setUpAll(() async {
      // Initialize Supabase client directly without Flutter plugins
      supabase = SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
      );
    });

    test('Check receipts and categories data', () async {
      try {
        print('🔍 Testing database connection...');
        
        // Test 1: Check if we can fetch receipts at all
        print('\n📊 Fetching receipts...');
        final receiptsResponse = await supabase
            .from('receipts')
            .select('id, merchant, custom_category_id, predicted_category, user_id')
            .limit(5);

        print('Found ${receiptsResponse.length} receipts:');
        for (final receipt in receiptsResponse) {
          print('  - ID: ${receipt['id']}');
          print('    Merchant: ${receipt['merchant']}');
          print('    User ID: ${receipt['user_id']}');
          print('    Custom Category ID: ${receipt['custom_category_id']}');
          print('    Predicted Category: ${receipt['predicted_category']}');
          print('    ---');
        }

        // Test 2: Check categories
        print('\n🏷️ Fetching categories...');
        final categoriesResponse = await supabase
            .from('custom_categories')
            .select('id, name, color, user_id, team_id')
            .limit(5);

        print('Found ${categoriesResponse.length} categories:');
        for (final category in categoriesResponse) {
          print('  - ID: ${category['id']}');
          print('    Name: ${category['name']}');
          print('    Color: ${category['color']}');
          print('    User ID: ${category['user_id']}');
          print('    Team ID: ${category['team_id']}');
          print('    ---');
        }

        // Test 3: Check join query
        print('\n🔗 Testing join query...');
        final joinResponse = await supabase
            .from('receipts')
            .select('''
              id,
              merchant,
              custom_category_id,
              user_id,
              custom_categories (
                id,
                name,
                color,
                icon
              )
            ''')
            .limit(3);

        print('Join query returned ${joinResponse.length} receipts:');
        for (final receipt in joinResponse) {
          print('  - Receipt ID: ${receipt['id']}');
          print('    Merchant: ${receipt['merchant']}');
          print('    User ID: ${receipt['user_id']}');
          print('    Custom Category ID: ${receipt['custom_category_id']}');
          print('    Category Data: ${receipt['custom_categories']}');
          print('    ---');
        }

        // Test 4: Count receipts with categories vs without
        final allReceipts = await supabase
            .from('receipts')
            .select('id, custom_category_id');

        final withCategories = allReceipts.where((r) => r['custom_category_id'] != null).length;
        final withoutCategories = allReceipts.length - withCategories;

        print('\n📈 Statistics:');
        print('  Total receipts: ${allReceipts.length}');
        print('  With custom_category_id: $withCategories');
        print('  Without custom_category_id: $withoutCategories');

        if (withCategories == 0) {
          print('\n⚠️  WARNING: No receipts have custom_category_id assigned!');
          print('   This explains why all receipts show as "Uncategorized" in Flutter');
        } else {
          print('\n✅ Some receipts have categories assigned');
        }

      } catch (e, stackTrace) {
        print('❌ Error: $e');
        print('Stack trace: $stackTrace');
        fail('Database test failed: $e');
      }
    });
  });
}
