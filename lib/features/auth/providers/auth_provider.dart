import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/sync_service.dart';
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
      AppLogger.info('🔧 Initializing authentication state...');
      AppLogger.debug(
        '🔍 Initial auth state: isLoading=${state.isLoading}, isAuthenticated=${state.isAuthenticated}',
      );

      // Check if Supabase is initialized with retry logic
      if (!SupabaseService.isInitialized) {
        AppLogger.warning('⚠️ Supabase not yet initialized, waiting...');

        // Wait with exponential backoff
        const maxRetries = 10;
        int retryCount = 0;

        while (!SupabaseService.isInitialized && retryCount < maxRetries) {
          final waitTime = Duration(
            milliseconds: 100 * (1 << retryCount),
          ); // Exponential backoff
          AppLogger.debug(
            '🔄 Waiting ${waitTime.inMilliseconds}ms for Supabase initialization (attempt ${retryCount + 1}/$maxRetries)',
          );
          await Future.delayed(waitTime);
          retryCount++;
        }

        if (!SupabaseService.isInitialized) {
          AppLogger.error(
            '❌ Supabase still not initialized after $maxRetries attempts',
          );
          state = state.copyWith(
            isLoading: false,
            error: 'Supabase initialization failed after multiple attempts',
            isAuthenticated: false,
          );
          AppLogger.debug(
            '🔍 Auth state after Supabase failure: isLoading=${state.isLoading}, isAuthenticated=${state.isAuthenticated}',
          );
          return;
        } else {
          AppLogger.info(
            '✅ Supabase initialization completed after $retryCount retries',
          );
        }
      }

      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        AppLogger.info('✅ Found existing user session: ${currentUser.email}');
        AppLogger.debug('🔍 About to load user profile for: ${currentUser.id}');
        await _loadUserProfile(currentUser.id);
      } else {
        AppLogger.info('ℹ️ No existing user session found');
        // No user is logged in, set loading to false
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        AppLogger.debug(
          '🔍 Auth state after no session: isLoading=${state.isLoading}, isAuthenticated=${state.isAuthenticated}',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Authentication initialization failed', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Initialization failed: ${e.toString()}',
        isAuthenticated: false,
      );
      AppLogger.debug(
        '🔍 Auth state after error: isLoading=${state.isLoading}, isAuthenticated=${state.isAuthenticated}',
      );
    }

    // Listen to auth state changes (only if Supabase is initialized)
    if (SupabaseService.isInitialized) {
      SupabaseService.authStateStream.listen((authState) {
        AppLogger.info('🔄 Auth state change detected: ${authState.event}');
        if (authState.event == AuthChangeEvent.signedIn) {
          final user = authState.session?.user;
          if (user != null) {
            AppLogger.info(
              '👤 User signed in via auth state change: ${user.email}',
            );
            _loadUserProfile(user.id);
          } else {
            AppLogger.warning('⚠️ SignedIn event but no user in session');
          }
        } else if (authState.event == AuthChangeEvent.signedOut) {
          AppLogger.info('👋 User signed out');
          state = const AuthState(isLoading: false, isAuthenticated: false);
        }
      });
    } else {
      AppLogger.warning(
        '⚠️ Cannot set up auth state listener - Supabase not initialized',
      );
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      AppLogger.debug('🔍 _loadUserProfile called for userId: $userId');
      state = state.copyWith(isLoading: true, error: null);
      AppLogger.debug(
        '🔍 Auth state set to loading: isLoading=${state.isLoading}, isAuthenticated=${state.isAuthenticated}',
      );

      // Try to get user profile from database
      Map<String, dynamic>? profileData;
      try {
        AppLogger.debug('🔍 Attempting to fetch user profile from database...');
        profileData = await SupabaseService.getUserProfile(userId);
        AppLogger.debug(
          '🔍 Profile data fetched: ${profileData != null ? 'SUCCESS' : 'NULL'}',
        );
      } catch (e) {
        AppLogger.warning('Database error loading profile', e);
      }

      // If profile exists, use it
      if (profileData != null) {
        try {
          AppLogger.info('Profile data found for user $userId, parsing...');
          AppLogger.debug('Profile data: $profileData');
          final user = UserModel.fromJson(profileData);
          AppLogger.info('Successfully parsed profile for user: ${user.email}');
          state = state.copyWith(
            user: user,
            isLoading: false,
            isAuthenticated: true,
          );
          AppLogger.debug(
            '🔍 Auth state after successful profile load: isLoading=${state.isLoading}, isAuthenticated=${state.isAuthenticated}',
          );
          return;
        } catch (e, stackTrace) {
          AppLogger.error('Error parsing profile data for user $userId', e);
          AppLogger.debug('Profile data that failed to parse: $profileData');
          AppLogger.debug('Stack trace: $stackTrace');
          // Continue to profile creation fallback
        }
      } else {
        AppLogger.info(
          'No profile data found for user $userId, will create new profile',
        );
      }

      // If no profile exists, try to create one from auth data
      final authUser = SupabaseService.currentUser;
      if (authUser != null) {
        try {
          // Extract user data from auth metadata
          final fullName = authUser.userMetadata?['full_name'] as String?;
          final nameParts = fullName?.split(' ') ?? [];

          final firstName =
              authUser.userMetadata?['given_name'] as String? ??
              (nameParts.isNotEmpty ? nameParts.first : null);
          final lastName =
              authUser.userMetadata?['family_name'] as String? ??
              (nameParts.length > 1 ? nameParts.skip(1).join(' ') : null);
          final googleAvatarUrl =
              authUser.userMetadata?['avatar_url'] as String?;

          // Try to create profile in database
          try {
            AppLogger.info(
              'Creating new profile in database for user: ${authUser.email}',
            );
            profileData = await SupabaseService.createUserProfile(
              userId: authUser.id,
              email: authUser.email,
              firstName: firstName,
              lastName: lastName,
              googleAvatarUrl: googleAvatarUrl,
              preferredLanguage: 'en',
            );

            if (profileData != null) {
              AppLogger.info(
                'Successfully created profile in database for user: ${authUser.email}',
              );
              final user = UserModel.fromJson(profileData);
              state = state.copyWith(
                user: user,
                isLoading: false,
                isAuthenticated: true,
              );
              return;
            } else {
              AppLogger.warning(
                'Profile creation returned null for user: ${authUser.email}',
              );
            }
          } catch (e, stackTrace) {
            AppLogger.error(
              'Failed to create profile in database for user: ${authUser.email}',
              e,
            );
            AppLogger.debug('Profile creation error stack trace: $stackTrace');
          }

          // If database creation fails, create minimal user from auth data
          final minimalUser = UserModel(
            id: authUser.id,
            email: authUser.email,
            firstName: firstName,
            lastName: lastName,
            googleAvatarUrl: googleAvatarUrl,
            subscriptionTier: 'free',
            subscriptionStatus: 'active',
            receiptsUsedThisMonth: 0,
            preferredLanguage: 'en',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          state = state.copyWith(
            user: minimalUser,
            isLoading: false,
            isAuthenticated: true,
          );

          // Trigger data migration for first-time users
          _triggerDataMigration(authUser.id);
        } catch (e) {
          AppLogger.error('Error creating user from auth data', e);
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to create user profile',
            isAuthenticated: false,
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User not found',
          isAuthenticated: false,
        );
      }
    } catch (e) {
      AppLogger.error('Unexpected error in _loadUserProfile', e);
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
      AppLogger.info('🔐 Starting sign-in process for: $email');
      state = state.copyWith(isLoading: true, error: null);

      final response = await SupabaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        AppLogger.info(
          '✅ Supabase authentication successful for: ${response.user!.email}',
        );
        AppLogger.info('🔄 Loading user profile for ID: ${response.user!.id}');
        await _loadUserProfile(response.user!.id);
      } else {
        AppLogger.warning('❌ Sign in failed - no user returned from Supabase');
        state = state.copyWith(
          isLoading: false,
          error: 'Sign in failed - no user returned',
        );
      }
    } on AuthException catch (e) {
      AppLogger.error('❌ Supabase authentication error: ${e.message}', e);
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      AppLogger.error('❌ Unexpected sign-in error', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: ${e.toString()}',
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
        state = state.copyWith(isLoading: false, error: 'Sign up failed');
      }
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
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

    await SupabaseService.updateUserProfile(
      userId: user.id,
      updates: profileData,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await SupabaseService.signOut();
      state = const AuthState(isLoading: false, isAuthenticated: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Sign out failed');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await SupabaseService.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Password reset failed');
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (state.user != null) {
        try {
          await SupabaseService.updateUserProfile(
            userId: state.user!.id,
            updates: {...data, 'updated_at': DateTime.now().toIso8601String()},
          );
        } catch (e) {
          AppLogger.warning('Failed to update profile in database', e);
          // Continue anyway - update local state
        }

        await _loadUserProfile(state.user!.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Profile update failed');
    }
  }

  /// Trigger data migration from offline storage to Supabase
  void _triggerDataMigration(String userId) {
    // Run migration in background without blocking UI
    Future.microtask(() async {
      try {
        AppLogger.info('Triggering data migration for user: $userId');
        await SyncService.migrateUserDataToSupabase(userId);
        AppLogger.info('Data migration completed for user: $userId');
      } catch (e) {
        AppLogger.warning('Data migration failed for user: $userId', e);
        // Don't fail authentication if migration fails
      }
    });
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
