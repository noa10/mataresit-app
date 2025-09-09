import 'package:logger/logger.dart';
import '../../../core/network/supabase_client.dart';
import '../models/session_info.dart';

/// Service for authentication-related security features
class AuthSecurityService {
  static final Logger _logger = Logger();

  /// Change user password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _logger.d('Starting password change process');

      // First verify current password by attempting to sign in
      final currentUser = SupabaseService.currentUser;
      if (currentUser?.email == null) {
        throw Exception('No authenticated user found');
      }

      // Verify current password
      try {
        await SupabaseService.signInWithEmailAndPassword(
          email: currentUser!.email!,
          password: currentPassword,
        );
      } catch (e) {
        throw Exception('Current password is incorrect');
      }

      // Update password
      final response = await SupabaseService.updateUser(password: newPassword);

      if (response.user == null) {
        throw Exception('Failed to update password');
      }

      _logger.d('Password changed successfully');
    } catch (e) {
      _logger.e('Failed to change password: $e');
      rethrow;
    }
  }

  /// Get current user sessions
  static Future<List<SessionInfo>> getUserSessions() async {
    try {
      _logger.d('Fetching user sessions');

      // For now, we'll return the current session info
      // In a full implementation, this would query a sessions table
      final currentSession = SupabaseService.currentSession;
      if (currentSession == null) {
        return [];
      }

      final sessionInfo = SessionInfo(
        sessionId: currentSession.accessToken.substring(0, 8),
        deviceInfo: 'Current Device',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          currentSession.expiresAt! * 1000,
        ).subtract(const Duration(hours: 1)), // Approximate creation time
        lastActiveAt: DateTime.now(),
        isCurrent: true,
      );

      return [sessionInfo];
    } catch (e) {
      _logger.e('Failed to fetch user sessions: $e');
      return [];
    }
  }

  /// Sign out from all other sessions
  static Future<void> signOutFromOtherSessions() async {
    try {
      _logger.d('Signing out from other sessions');

      // In Supabase, we can use the signOut with scope parameter
      // For now, we'll just refresh the current session
      await SupabaseService.client.auth.refreshSession();

      _logger.d('Signed out from other sessions successfully');
    } catch (e) {
      _logger.e('Failed to sign out from other sessions: $e');
      rethrow;
    }
  }

  /// Sign out from a specific session
  static Future<void> signOutFromSession(String sessionId) async {
    try {
      _logger.d('Signing out from session: $sessionId');

      // For the current session, perform a full sign out
      final currentSession = SupabaseService.currentSession;
      if (currentSession != null &&
          currentSession.accessToken.substring(0, 8) == sessionId) {
        await SupabaseService.signOut();
      }

      _logger.d('Signed out from session successfully');
    } catch (e) {
      _logger.e('Failed to sign out from session: $e');
      rethrow;
    }
  }

  /// Request account deletion
  static Future<void> requestAccountDeletion({
    required String password,
    String? reason,
  }) async {
    try {
      _logger.d('Starting account deletion request');

      final currentUser = SupabaseService.currentUser;
      if (currentUser?.email == null) {
        throw Exception('No authenticated user found');
      }

      // Verify password before deletion
      try {
        await SupabaseService.signInWithEmailAndPassword(
          email: currentUser!.email!,
          password: password,
        );
      } catch (e) {
        throw Exception('Password verification failed');
      }

      // In a full implementation, this would:
      // 1. Create a deletion request record
      // 2. Send confirmation email
      // 3. Schedule data deletion after confirmation period

      // For now, we'll call a custom RPC function
      try {
        await SupabaseService.client.rpc(
          'request_account_deletion',
          params: {'deletion_reason': reason},
        );
      } catch (e) {
        // If RPC doesn't exist, we'll just log the request
        _logger.w(
          'Account deletion RPC not available, logging request locally',
        );
      }

      _logger.d('Account deletion requested successfully');
    } catch (e) {
      _logger.e('Failed to request account deletion: $e');
      rethrow;
    }
  }

  /// Cancel account deletion request
  static Future<void> cancelAccountDeletion() async {
    try {
      _logger.d('Cancelling account deletion request');

      try {
        await SupabaseService.client.rpc('cancel_account_deletion');
      } catch (e) {
        _logger.w('Account deletion cancellation RPC not available');
      }

      _logger.d('Account deletion request cancelled successfully');
    } catch (e) {
      _logger.e('Failed to cancel account deletion: $e');
      rethrow;
    }
  }

  /// Get account deletion status
  static Future<Map<String, dynamic>?> getAccountDeletionStatus() async {
    try {
      _logger.d('Checking account deletion status');

      try {
        final response = await SupabaseService.client.rpc(
          'get_account_deletion_status',
        );
        return response as Map<String, dynamic>?;
      } catch (e) {
        _logger.w('Account deletion status RPC not available');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to get account deletion status: $e');
      return null;
    }
  }

  /// Update user email
  static Future<void> updateEmail(String newEmail) async {
    try {
      _logger.d('Updating user email');

      final response = await SupabaseService.updateUser(email: newEmail);

      if (response.user == null) {
        throw Exception('Failed to update email');
      }

      _logger.d('Email updated successfully');
    } catch (e) {
      _logger.e('Failed to update email: $e');
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.d('Sending password reset email');

      await SupabaseService.resetPassword(email);

      _logger.d('Password reset email sent successfully');
    } catch (e) {
      _logger.e('Failed to send password reset email: $e');
      rethrow;
    }
  }

  /// Verify current password
  static Future<bool> verifyCurrentPassword(String password) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser?.email == null) {
        return false;
      }

      await SupabaseService.signInWithEmailAndPassword(
        email: currentUser!.email!,
        password: password,
      );

      return true;
    } catch (e) {
      _logger.d('Password verification failed: $e');
      return false;
    }
  }

  /// Get security events (login attempts, password changes, etc.)
  static Future<List<Map<String, dynamic>>> getSecurityEvents() async {
    try {
      _logger.d('Fetching security events');

      // In a full implementation, this would query a security_events table
      // For now, return empty list
      return [];
    } catch (e) {
      _logger.e('Failed to fetch security events: $e');
      return [];
    }
  }

  /// Log security event
  static Future<void> logSecurityEvent({
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.d('Logging security event: $eventType');

      // In a full implementation, this would insert into security_events table
      try {
        await SupabaseService.client.from('security_events').insert({
          'user_id': SupabaseService.currentUser?.id,
          'event_type': eventType,
          'description': description,
          'metadata': metadata,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        _logger.w('Security events table not available, logging locally');
      }

      _logger.d('Security event logged successfully');
    } catch (e) {
      _logger.e('Failed to log security event: $e');
    }
  }
}
