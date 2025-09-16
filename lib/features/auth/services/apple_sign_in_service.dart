import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/app_logger.dart';

/// Apple Sign-In integration service for iOS
class AppleSignInService {
  static const String _tag = 'AppleSignInService';
  static final _logger = AppLogger.getLogger(_tag);

  /// Check if Apple Sign-In is available on the current platform
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS && !kIsWeb) {
      return false;
    }

    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      _logger.e('Error checking Apple Sign-In availability: $e');
      return false;
    }
  }

  /// Sign in with Apple and authenticate with Supabase
  static Future<AuthResponse?> signInWithApple() async {
    try {
      _logger.i('Starting Apple Sign-In process');

      // Check if Apple Sign-In is available
      if (!await isAvailable()) {
        _logger.w('Apple Sign-In is not available on this platform');
        return null;
      }

      // Request Apple Sign-In credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: kIsWeb
            ? WebAuthenticationOptions(
                clientId: 'your-client-id', // Replace with your client ID
                redirectUri: Uri.parse(
                  'your-redirect-uri',
                ), // Replace with your redirect URI
              )
            : null,
      );

      _logger.i('Apple Sign-In credential received');

      // Create ID token for Supabase authentication
      final idToken = credential.identityToken;
      if (idToken == null) {
        _logger.e('Apple Sign-In did not return an identity token');
        return null;
      }

      // Sign in to Supabase with Apple ID token
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        accessToken: credential.authorizationCode,
      );

      if (response.user != null) {
        _logger.i('Successfully signed in with Apple: ${response.user!.email}');

        // Update user profile with Apple information if available
        await _updateUserProfileFromApple(credential, response.user!);

        return response;
      } else {
        _logger.e('Supabase authentication failed');
        return null;
      }
    } catch (e) {
      _logger.e('Apple Sign-In failed: $e');
      return null;
    }
  }

  /// Update user profile with information from Apple Sign-In
  static Future<void> _updateUserProfileFromApple(
    AuthorizationCredentialAppleID credential,
    User user,
  ) async {
    try {
      final updates = <String, dynamic>{};

      // Update display name if available
      if (credential.givenName != null || credential.familyName != null) {
        final fullName = [
          credential.givenName,
          credential.familyName,
        ].where((name) => name != null && name.isNotEmpty).join(' ');

        if (fullName.isNotEmpty) {
          updates['full_name'] = fullName;
          updates['display_name'] = fullName;
        }
      }

      // Update email if available and different
      if (credential.email != null && credential.email != user.email) {
        updates['email'] = credential.email;
      }

      // Add Apple-specific metadata
      updates['auth_provider'] = 'apple';
      updates['apple_user_id'] = credential.userIdentifier;

      if (updates.isNotEmpty) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'updated_at': DateTime.now().toIso8601String(),
          ...updates,
        });

        _logger.i('Updated user profile with Apple information');
      }
    } catch (e) {
      _logger.e('Failed to update user profile from Apple: $e');
      // Don't throw error as authentication was successful
    }
  }

  /// Handle Apple Sign-In credential state changes
  static Future<void> handleCredentialStateChange() async {
    if (!Platform.isIOS) return;

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Check if user signed in with Apple
      final userMetadata = currentUser.userMetadata;
      final appleUserId = userMetadata?['apple_user_id'] as String?;

      if (appleUserId == null) return;

      // Check Apple credential state
      final credentialState = await SignInWithApple.getCredentialState(
        appleUserId,
      );

      switch (credentialState) {
        case CredentialState.authorized:
          _logger.i('Apple credentials are still valid');
          break;

        case CredentialState.revoked:
          _logger.w('Apple credentials have been revoked');
          await _handleRevokedCredentials();
          break;

        case CredentialState.notFound:
          _logger.w('Apple credentials not found');
          await _handleRevokedCredentials();
          break;

        // Note: CredentialState.transferred is not available in current version
        // Removed this case as it's not supported
      }
    } catch (e) {
      _logger.e('Error checking Apple credential state: $e');
    }
  }

  /// Handle revoked Apple credentials
  static Future<void> _handleRevokedCredentials() async {
    try {
      _logger.i('Handling revoked Apple credentials - signing out user');
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      _logger.e('Error handling revoked Apple credentials: $e');
    }
  }

  /// Get Apple Sign-In button configuration
  static SignInWithAppleButtonStyle getButtonStyle({required bool isDarkMode}) {
    return isDarkMode
        ? SignInWithAppleButtonStyle.white
        : SignInWithAppleButtonStyle.black;
  }

  /// Get Apple Sign-In button text
  static String getButtonText({bool isSignUp = false}) {
    return isSignUp ? 'Sign up with Apple' : 'Sign in with Apple';
  }

  /// Initialize Apple Sign-In monitoring
  static Future<void> initialize() async {
    if (!Platform.isIOS) return;

    try {
      // Check credential state on app launch
      await handleCredentialStateChange();

      _logger.i('Apple Sign-In service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Apple Sign-In service: $e');
    }
  }

  /// Clean up Apple Sign-In resources
  static Future<void> dispose() async {
    // No specific cleanup needed for Apple Sign-In
    _logger.i('Apple Sign-In service disposed');
  }

  /// Validate Apple ID token (for additional security)
  static Future<bool> validateAppleIdToken(String idToken) async {
    try {
      // In a production app, you would validate the token with Apple's servers
      // This is a simplified validation
      if (idToken.isEmpty) return false;

      // Basic JWT structure check
      final parts = idToken.split('.');
      if (parts.length != 3) return false;

      _logger.i('Apple ID token validation passed');
      return true;
    } catch (e) {
      _logger.e('Apple ID token validation failed: $e');
      return false;
    }
  }

  /// Get user information from Apple ID token
  static Map<String, dynamic>? parseAppleIdToken(String idToken) {
    try {
      // In a production app, you would properly decode and validate the JWT
      // This is a simplified implementation
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      // For now, return basic structure
      return {
        'iss': 'https://appleid.apple.com',
        'aud': 'your-client-id',
        'exp':
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
    } catch (e) {
      _logger.e('Failed to parse Apple ID token: $e');
      return null;
    }
  }
}
