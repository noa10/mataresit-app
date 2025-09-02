import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application constants and configuration
class AppConstants {
  // App Information
  static const String appName = 'Mataresit';
  static const String appVersion = '1.0.0';
  
  // Supabase Configuration - Use environment variables in production
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://mpmkbtsufihzdelrlszs.supabase.co');
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1wbWtidHN1ZmloemRlbHJsc3pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwMTIzODksImV4cCI6MjA1ODU4ODM4OX0.25ZyBSIl0TQxXFZsaT1R55118Tn8b6Ri8N556gOQyPY');
  static String get supabaseProjectId => dotenv.env['SUPABASE_PROJECT_ID'] ?? const String.fromEnvironment('SUPABASE_PROJECT_ID', defaultValue: 'mpmkbtsufihzdelrlszs');

  // Stripe Configuration - Use environment variables in production
  static const String stripePublicKey = String.fromEnvironment('STRIPE_PUBLIC_KEY', defaultValue: '');
  
  // Stripe Price IDs - Use environment variables in production
  static const String stripeProMonthlyPriceId = String.fromEnvironment('STRIPE_PRO_MONTHLY_PRICE_ID', defaultValue: '');
  static const String stripeProAnnualPriceId = String.fromEnvironment('STRIPE_PRO_ANNUAL_PRICE_ID', defaultValue: '');
  static const String stripeMaxMonthlyPriceId = String.fromEnvironment('STRIPE_MAX_MONTHLY_PRICE_ID', defaultValue: '');
  static const String stripeMaxAnnualPriceId = String.fromEnvironment('STRIPE_MAX_ANNUAL_PRICE_ID', defaultValue: '');
  
  // API Configuration - Use environment variables in production
  static String get geminiApiKey {
    // Try dotenv first, then fall back to const environment variables
    try {
      final envKey = dotenv.env['GEMINI_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // Dotenv not loaded or failed, continue to fallback
    }
    
    // Fallback to compile-time environment variables
    const fallback = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (fallback.isNotEmpty) {
      return fallback;
    }
    
    // Last resort: hardcoded from .env file content
    return 'AIzaSyAqp9qsLx845-084KfR6ipwu1kzPYfz_rw';
  }
  
  static String get openRouterApiKey {
    try {
      final envKey = dotenv.env['OPENROUTER_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    } catch (e) {
      // Dotenv not loaded or failed
    }
    return const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  }

  // AWS Configuration - Use environment variables in production
  static const String awsAccessKeyId = String.fromEnvironment('AWS_ACCESS_KEY_ID', defaultValue: '');
  static const String awsSecretAccessKey = String.fromEnvironment('AWS_SECRET_ACCESS_KEY', defaultValue: '');
  static const String awsRegion = 'ap-southeast-1';
  
  // Real-time Configuration
  static const bool enableRealtime = true;
  static const bool disableRealtime = false;
  static const int realtimeHeartbeatInterval = 30000;
  static const int realtimeMaxRetries = 5;
  static const bool realtimeDebug = true;
  
  // Database Tables
  static const String usersTable = 'users';
  static const String receiptsTable = 'receipts';
  static const String lineItemsTable = 'line_items';
  static const String teamsTable = 'teams';
  static const String teamMembersTable = 'team_members';
  static const String analyticsTable = 'analytics';
  static const String subscriptionsTable = 'subscriptions';
  static const String notificationsTable = 'notifications';
  static const String feedbackTable = 'feedback';
  
  // Storage Buckets
  static const String receiptImagesBucket = 'receipt_images';
  static const String thumbnailsBucket = 'thumbnails';
  static const String profileImagesBucket = 'profile-images';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Image Processing
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;
  static const int thumbnailSize = 200;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingKey = 'onboarding_completed';
  static const String biometricKey = 'biometric_enabled';
  
  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'ms', 'zh'];
  static const String defaultLanguage = 'en';
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred. Please try again.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String logoutSuccessMessage = 'Logout successful!';
  static const String receiptUploadSuccessMessage = 'Receipt uploaded successfully!';
  static const String teamInviteSuccessMessage = 'Team invitation sent successfully!';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  
  // Receipt Processing
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedDocumentFormats = ['pdf'];
  
  // Team Limits
  static const int maxTeamMembers = 50;
  static const int maxTeamsPerUser = 10;
  
  // Subscription Limits
  static const int freeReceiptsLimit = 10;
  static const int proReceiptsLimit = 1000;
  static const int maxReceiptsLimit = -1; // Unlimited
  
  // Notification Types
  static const String receiptProcessedNotification = 'receipt_processed';
  static const String teamInviteNotification = 'team_invite';
  static const String subscriptionNotification = 'subscription';
  static const String systemNotification = 'system';
}
