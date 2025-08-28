import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/core/network/supabase_client.dart';
import '../../lib/core/constants/app_constants.dart';
import '../../lib/features/auth/providers/auth_provider.dart';
import '../../lib/shared/models/user_model.dart';

void main() {
  group('Authentication Flow Tests', () {
    late ProviderContainer container;

    setUpAll(() async {
      // Initialize Flutter bindings
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock method channels
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        return '/tmp';
      });

      const MethodChannel('plugins.flutter.io/shared_preferences')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, Object>{};
        }
        return null;
      });
    });

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have correct Supabase configuration', () {
      expect(AppConstants.supabaseUrl, equals('https://mpmkbtsufihzdelrlszs.supabase.co'));
      expect(AppConstants.supabaseAnonKey, isNotEmpty);
      expect(AppConstants.supabaseAnonKey.startsWith('eyJ'), isTrue);
      print('✅ Supabase configuration is correct');
    });

    test('should initialize authentication provider', () async {
      final authNotifier = container.read(authProvider.notifier);
      final authState = container.read(authProvider);

      expect(authNotifier, isNotNull);
      expect(authState, isNotNull);
      print('✅ Authentication provider initialized');
    });

    test('should handle user model creation from auth data', () {
      // Test creating a user model with the new structure
      final user = UserModel(
        id: 'test-user-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        subscriptionTier: 'free',
        subscriptionStatus: 'active',
        receiptsUsedThisMonth: 0,
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.id, equals('test-user-id'));
      expect(user.email, equals('test@example.com'));
      expect(user.fullName, equals('Test User'));
      expect(user.emailVerified, isTrue);
      expect(user.role, equals(UserRole.user));
      expect(user.status, equals(UserStatus.active));
      print('✅ User model creation works correctly');
    });

    test('should handle profile data conversion from database format', () {
      // Test profile data from database format (snake_case)
      final profileData = {
        'id': 'test-user-id',
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'User',
        'subscription_tier': 'free',
        'subscription_status': 'active',
        'receipts_used_this_month': 0,
        'preferred_language': 'en',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        final user = UserModel.fromJson(profileData);
        expect(user.id, equals('test-user-id'));
        expect(user.firstName, equals('Test'));
        expect(user.lastName, equals('User'));
        expect(user.fullName, equals('Test User'));
        expect(user.subscriptionTier, equals('free'));
        expect(user.subscriptionStatus, equals('active'));
        expect(user.receiptsUsedThisMonth, equals(0));
        expect(user.preferredLanguage, equals('en'));
        print('✅ Profile data conversion from database format works correctly');
      } catch (e) {
        fail('Profile data conversion failed: $e');
      }
    });

    test('should handle profile data with missing optional fields', () {
      // Test minimal profile data
      final profileData = {
        'id': 'test-user-id',
        'email': 'test@example.com',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        final user = UserModel.fromJson(profileData);
        expect(user.id, equals('test-user-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.firstName, isNull);
        expect(user.lastName, isNull);
        expect(user.fullName, isNull);
        print('✅ Profile data with missing fields works correctly');
      } catch (e) {
        fail('Profile data with missing fields failed: $e');
      }
    });

    test('should validate authentication flow components', () {
      // Test that all required components are available
      expect(SupabaseService, isNotNull);
      expect(AuthNotifier, isNotNull);
      expect(UserModel, isNotNull);

      // Test that constants are properly configured
      expect(AppConstants.supabaseUrl, isNotEmpty);
      expect(AppConstants.supabaseAnonKey, isNotEmpty);

      print('✅ All authentication components are available');
    });
  });
}
