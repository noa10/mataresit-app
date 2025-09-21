import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';
import 'app_logger.dart';

/// Service for handling Google authentication across different platforms
/// Uses native Google Sign-In on mobile platforms and web OAuth on web
class GoogleAuthService {
  static GoogleSignIn? _googleSignIn;
  
  /// Initialize Google Sign-In with platform-specific configuration
  static GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn != null) return _googleSignIn!;

    if (kIsWeb) {
      // Web configuration - uses web client ID
      _googleSignIn = GoogleSignIn(
        clientId: '835461278848-85lf9ffh18kk22u1qm9bln7v8q64ku15.apps.googleusercontent.com',
      );
    } else if (Platform.isIOS) {
      // iOS configuration - uses iOS client ID and server client ID
      _googleSignIn = GoogleSignIn(
        clientId: '835461278848-elj0ll0vlcr9hv3d1b44iuu1a7otj9qo.apps.googleusercontent.com',
        serverClientId: '835461278848-85lf9ffh18kk22u1qm9bln7v8q64ku15.apps.googleusercontent.com',
      );
    } else if (Platform.isMacOS) {
      // macOS configuration - same as iOS, uses native Google Sign-In
      _googleSignIn = GoogleSignIn(
        clientId: '835461278848-elj0ll0vlcr9hv3d1b44iuu1a7otj9qo.apps.googleusercontent.com',
        serverClientId: '835461278848-85lf9ffh18kk22u1qm9bln7v8q64ku15.apps.googleusercontent.com',
      );
    } else if (Platform.isAndroid) {
      // Android configuration - server client ID is sufficient
      _googleSignIn = GoogleSignIn(
        serverClientId: '835461278848-85lf9ffh18kk22u1qm9bln7v8q64ku15.apps.googleusercontent.com',
      );
    } else {
      // Fallback for other platforms (Windows, Linux, etc.)
      _googleSignIn = GoogleSignIn();
    }

    return _googleSignIn!;
  }
  
  /// Sign in with Google using the appropriate method for the current platform
  static Future<void> signInWithGoogle() async {
    try {
      AppLogger.info('🔐 Starting Google Sign-In for platform: ${_getPlatformName()}');

      if (kIsWeb) {
        // Use web-based OAuth for web platform
        await _signInWithWebOAuth();
      } else if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
        // Use native Google Sign-In for mobile and macOS platforms
        await _signInWithNativeGoogle();
      } else {
        // Fallback to web OAuth for other desktop platforms (Windows, Linux)
        await _signInWithWebOAuth();
      }
    } catch (e) {
      AppLogger.error('❌ Google Sign-In failed: $e');
      rethrow;
    }
  }
  
  /// Native Google Sign-In for mobile platforms
  static Future<void> _signInWithNativeGoogle() async {
    try {
      AppLogger.info('📱 Using native Google Sign-In');
      
      final GoogleSignIn googleSignIn = _getGoogleSignIn();
      
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        AppLogger.warning('⚠️ User cancelled Google Sign-In');
        return;
      }
      
      AppLogger.info('✅ Google Sign-In successful for user: ${googleUser.email}');
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;
      
      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }
      
      AppLogger.info('🔑 Google tokens obtained, signing in with Supabase');
      
      // Sign in with Supabase using Google tokens
      await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      AppLogger.info('✅ Supabase authentication successful');
      
    } catch (e) {
      AppLogger.error('❌ Native Google Sign-In failed: $e');
      rethrow;
    }
  }
  
  /// Web-based OAuth for web and fallback platforms
  static Future<void> _signInWithWebOAuth() async {
    try {
      AppLogger.info('🌐 Using web-based OAuth');
      
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : SupabaseService.oauthRedirectUri,
      );
      
      AppLogger.info('✅ Web OAuth initiated');
      
    } catch (e) {
      AppLogger.error('❌ Web OAuth failed: $e');
      rethrow;
    }
  }
  
  /// Sign out from Google and Supabase
  static Future<void> signOut() async {
    try {
      AppLogger.info('🚪 Signing out from Google and Supabase');

      // Sign out from Google if using native sign-in
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS)) {
        final GoogleSignIn googleSignIn = _getGoogleSignIn();
        await googleSignIn.signOut();
        AppLogger.info('✅ Google Sign-Out successful');
      }

      // Sign out from Supabase
      await SupabaseService.client.auth.signOut();
      AppLogger.info('✅ Supabase Sign-Out successful');

    } catch (e) {
      AppLogger.error('❌ Sign-Out failed: $e');
      rethrow;
    }
  }
  
  /// Get current platform name for logging
  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
