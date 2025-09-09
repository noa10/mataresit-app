import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/app_logger.dart';
import '../../auth/providers/auth_provider.dart';

/// Profile state
class ProfileState extends Equatable {
  final UserModel? profile;
  final bool isLoading;
  final bool isUpdating;
  final bool isUploadingAvatar;
  final String? error;
  final String? updateError;
  final String? avatarError;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isUpdating = false,
    this.isUploadingAvatar = false,
    this.error,
    this.updateError,
    this.avatarError,
  });

  ProfileState copyWith({
    UserModel? profile,
    bool? isLoading,
    bool? isUpdating,
    bool? isUploadingAvatar,
    String? error,
    String? updateError,
    String? avatarError,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      error: error,
      updateError: updateError,
      avatarError: avatarError,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    isLoading,
    isUpdating,
    isUploadingAvatar,
    error,
    updateError,
    avatarError,
  ];
}

/// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  /// Load user profile
  Future<void> loadProfile(String userId) async {
    try {
      AppLogger.info('Loading profile for user: $userId');
      state = state.copyWith(isLoading: true, error: null);

      final profile = await ProfileService.getUserProfile(userId);

      if (profile != null) {
        AppLogger.info('Profile loaded successfully for user: $userId');
        state = state.copyWith(profile: profile, isLoading: false);
      } else {
        AppLogger.warning('No profile found for user: $userId');
        state = state.copyWith(isLoading: false, error: 'Profile not found');
      }
    } catch (e) {
      AppLogger.error('Error loading profile for user: $userId', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: ${e.toString()}',
      );
    }
  }

  /// Update profile information
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (state.profile == null) {
      AppLogger.warning('Cannot update profile: no profile loaded');
      return false;
    }

    try {
      AppLogger.info('Updating profile for user: ${state.profile!.id}');
      state = state.copyWith(isUpdating: true, updateError: null);

      // Validate data
      final validationErrors = ProfileService.validateProfileData(updates);
      if (validationErrors.isNotEmpty) {
        final errorMessage = validationErrors.values.first;
        state = state.copyWith(isUpdating: false, updateError: errorMessage);
        return false;
      }

      final updatedProfile = await ProfileService.updateUserProfile(
        state.profile!.id,
        updates,
      );

      if (updatedProfile != null) {
        AppLogger.info(
          'Profile updated successfully for user: ${state.profile!.id}',
        );
        state = state.copyWith(profile: updatedProfile, isUpdating: false);
        return true;
      } else {
        AppLogger.warning(
          'Failed to update profile for user: ${state.profile!.id}',
        );
        state = state.copyWith(
          isUpdating: false,
          updateError: 'Failed to update profile',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Error updating profile for user: ${state.profile?.id}',
        e,
      );
      state = state.copyWith(
        isUpdating: false,
        updateError: 'Failed to update profile: ${e.toString()}',
      );
      return false;
    }
  }

  /// Upload avatar from file
  Future<bool> uploadAvatar(File imageFile) async {
    if (state.profile == null) {
      AppLogger.warning('Cannot upload avatar: no profile loaded');
      return false;
    }

    try {
      AppLogger.info('Uploading avatar for user: ${state.profile!.id}');
      state = state.copyWith(isUploadingAvatar: true, avatarError: null);

      final avatarUrl = await ProfileService.uploadAvatar(
        state.profile!.id,
        imageFile,
      );

      if (avatarUrl != null) {
        AppLogger.info(
          'Avatar uploaded successfully for user: ${state.profile!.id}',
        );

        // Update profile with new avatar URL
        final updatedProfile = state.profile!.copyWith(
          avatarUrl: avatarUrl,
          avatarUpdatedAt: DateTime.now(),
        );

        state = state.copyWith(
          profile: updatedProfile,
          isUploadingAvatar: false,
        );
        return true;
      } else {
        AppLogger.warning(
          'Failed to upload avatar for user: ${state.profile!.id}',
        );
        state = state.copyWith(
          isUploadingAvatar: false,
          avatarError: 'Failed to upload avatar',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Error uploading avatar for user: ${state.profile?.id}',
        e,
      );
      state = state.copyWith(
        isUploadingAvatar: false,
        avatarError: 'Failed to upload avatar: ${e.toString()}',
      );
      return false;
    }
  }

  /// Upload avatar from bytes
  Future<bool> uploadAvatarFromBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    if (state.profile == null) {
      AppLogger.warning('Cannot upload avatar: no profile loaded');
      return false;
    }

    try {
      AppLogger.info(
        'Uploading avatar from bytes for user: ${state.profile!.id}',
      );
      state = state.copyWith(isUploadingAvatar: true, avatarError: null);

      final avatarUrl = await ProfileService.uploadAvatarFromBytes(
        state.profile!.id,
        imageBytes,
        fileName,
      );

      if (avatarUrl != null) {
        AppLogger.info(
          'Avatar uploaded from bytes successfully for user: ${state.profile!.id}',
        );

        // Update profile with new avatar URL
        final updatedProfile = state.profile!.copyWith(
          avatarUrl: avatarUrl,
          avatarUpdatedAt: DateTime.now(),
        );

        state = state.copyWith(
          profile: updatedProfile,
          isUploadingAvatar: false,
        );
        return true;
      } else {
        AppLogger.warning(
          'Failed to upload avatar from bytes for user: ${state.profile!.id}',
        );
        state = state.copyWith(
          isUploadingAvatar: false,
          avatarError: 'Failed to upload avatar',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Error uploading avatar from bytes for user: ${state.profile?.id}',
        e,
      );
      state = state.copyWith(
        isUploadingAvatar: false,
        avatarError: 'Failed to upload avatar: ${e.toString()}',
      );
      return false;
    }
  }

  /// Remove avatar
  Future<bool> removeAvatar() async {
    if (state.profile == null) {
      AppLogger.warning('Cannot remove avatar: no profile loaded');
      return false;
    }

    try {
      AppLogger.info('Removing avatar for user: ${state.profile!.id}');
      state = state.copyWith(isUploadingAvatar: true, avatarError: null);

      final success = await ProfileService.removeAvatar(state.profile!.id);

      if (success) {
        AppLogger.info(
          'Avatar removed successfully for user: ${state.profile!.id}',
        );

        // Update profile to remove avatar URL
        final updatedProfile = state.profile!.copyWith(
          avatarUrl: null,
          avatarUpdatedAt: DateTime.now(),
        );

        state = state.copyWith(
          profile: updatedProfile,
          isUploadingAvatar: false,
        );
        return true;
      } else {
        AppLogger.warning(
          'Failed to remove avatar for user: ${state.profile!.id}',
        );
        state = state.copyWith(
          isUploadingAvatar: false,
          avatarError: 'Failed to remove avatar',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Error removing avatar for user: ${state.profile?.id}',
        e,
      );
      state = state.copyWith(
        isUploadingAvatar: false,
        avatarError: 'Failed to remove avatar: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear errors
  void clearErrors() {
    state = state.copyWith(error: null, updateError: null, avatarError: null);
  }

  /// Clear profile (on logout)
  void clearProfile() {
    state = const ProfileState();
  }
}

/// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final notifier = ProfileNotifier();

  // Check current auth state on initialization
  final currentAuthState = ref.read(authProvider);
  if (currentAuthState.isAuthenticated && currentAuthState.user != null) {
    // Load profile immediately if user is already authenticated
    notifier.loadProfile(currentAuthState.user!.id);
  }

  // Listen to auth state changes
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated && next.user != null) {
      // Load profile when user is authenticated
      notifier.loadProfile(next.user!.id);
    } else {
      // Clear profile when user is not authenticated
      notifier.clearProfile();
    }
  });

  return notifier;
});
