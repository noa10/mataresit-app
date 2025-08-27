import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/user_model.dart';

/// Authentication state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Authentication notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _initializeAuth();
  }

  /// Initialize authentication state
  void _initializeAuth() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        await _loadUserProfile(currentUser.id);
      } else {
        // No user is logged in, set loading to false
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Initialization failed: ${e.toString()}',
        isAuthenticated: false,
      );
    }

    // Listen to auth state changes
    SupabaseService.authStateStream.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn) {
        final user = authState.session?.user;
        if (user != null) {
          _loadUserProfile(user.id);
        }
      } else if (authState.event == AuthChangeEvent.signedOut) {
        state = const AuthState(isLoading: false, isAuthenticated: false);
      }
    });
  }

  /// Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Try to get user profile from database
      try {
        final profileData = await SupabaseService.getUserProfile(userId);
        if (profileData != null) {
          final user = UserModel.fromJson(profileData);
          state = state.copyWith(
            user: user,
            isLoading: false,
            isAuthenticated: true,
          );
          return;
        }
      } catch (e) {
        // Database table might not exist or other database error
        AppLogger.warning('Database error loading profile', e);
      }
      
      // If no profile exists or database error, create minimal user from auth data
      final authUser = SupabaseService.currentUser;
      if (authUser != null) {
        final minimalUser = UserModel(
          id: authUser.id,
          email: authUser.email ?? '',
          fullName: authUser.userMetadata?['full_name'],
          emailVerified: authUser.emailConfirmedAt != null,
          phoneVerified: authUser.phoneConfirmedAt != null,
          role: UserRole.user,
          status: UserStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        state = state.copyWith(
          user: minimalUser,
          isLoading: false,
          isAuthenticated: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User not found',
          isAuthenticated: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await SupabaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign in failed',
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await SupabaseService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        // Try to create user profile in database, but don't fail if it doesn't work
        try {
          await _createUserProfile(response.user!, fullName);
        } catch (e) {
          AppLogger.warning('Failed to create user profile in database', e);
          // Continue anyway - we'll use minimal user data
        }
        
        await _loadUserProfile(response.user!.id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign up failed',
        );
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  /// Create user profile in database
  Future<void> _createUserProfile(User user, String? fullName) async {
    final profileData = {
      'id': user.id,
      'email': user.email,
      'full_name': fullName ?? user.userMetadata?['full_name'],
      'avatar_url': user.userMetadata?['avatar_url'],
      'email_verified': user.emailConfirmedAt != null,
      'phone_verified': user.phoneConfirmedAt != null,
      'role': 'user',
      'status': 'active',
      'language': 'en',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'last_login_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.updateUserProfile(user.id, profileData);
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await SupabaseService.signOut();
      state = const AuthState(isLoading: false, isAuthenticated: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out failed',
      );
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await SupabaseService.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password reset failed',
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      if (state.user != null) {
        try {
          await SupabaseService.updateUserProfile(state.user!.id, {
            ...data,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          AppLogger.warning('Failed to update profile in database', e);
          // Continue anyway - update local state
        }
        
        await _loadUserProfile(state.user!.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Profile update failed',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
