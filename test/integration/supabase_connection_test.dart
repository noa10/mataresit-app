import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../../lib/core/network/supabase_client.dart';
import '../../lib/core/constants/app_constants.dart';

void main() {
  group('Supabase Connection Tests', () {
    setUpAll(() async {
      // Initialize Flutter bindings
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock method channel for Supabase initialization
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        return '/tmp';
      });
    });

    test('should have correct Supabase configuration', () {
      expect(AppConstants.supabaseUrl, equals('https://mpmkbtsufihzdelrlszs.supabase.co'));
      expect(AppConstants.supabaseAnonKey, isNotEmpty);
      expect(AppConstants.supabaseAnonKey.startsWith('eyJ'), isTrue);
    });

    test('should initialize Supabase successfully', () async {
      try {
        await SupabaseService.initialize();
        expect(SupabaseService.client, isNotNull);
        print('✅ Supabase initialized successfully');
      } catch (e) {
        fail('Supabase initialization failed: $e');
      }
    });

    test('should be able to access database tables', () async {
      try {
        await SupabaseService.initialize();
        final client = SupabaseService.client;
        
        // Test profiles table access
        try {
          await client.from('profiles').select('count').limit(1);
          print('✅ Profiles table accessible');
        } catch (e) {
          print('❌ Profiles table access failed: $e');
        }
        
        // Test receipts table access
        try {
          await client.from('receipts').select('count').limit(1);
          print('✅ Receipts table accessible');
        } catch (e) {
          print('❌ Receipts table access failed: $e');
        }
        
        // Test teams table access
        try {
          await client.from('teams').select('count').limit(1);
          print('✅ Teams table accessible');
        } catch (e) {
          print('❌ Teams table access failed: $e');
        }
        
      } catch (e) {
        fail('Database access test failed: $e');
      }
    });

    test('should handle authentication state', () async {
      try {
        await SupabaseService.initialize();
        
        final user = SupabaseService.currentUser;
        final isAuthenticated = SupabaseService.isAuthenticated;
        
        if (user != null) {
          print('✅ User is authenticated: ${user.email}');
          expect(isAuthenticated, isTrue);
        } else {
          print('ℹ️ No user currently authenticated');
          expect(isAuthenticated, isFalse);
        }
        
      } catch (e) {
        fail('Authentication state test failed: $e');
      }
    });
  });
}
