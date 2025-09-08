import 'dart:io';
import 'dart:typed_data';
import '../network/supabase_client.dart';
import '../../shared/models/user_model.dart';
import '../services/app_logger.dart';

/// Service for managing user profile operations
class ProfileService {
  static const String _profilesTable = 'profiles';
  static const String _avatarBucket = 'avatars';

  /// Get user profile by ID
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      AppLogger.info('Fetching profile for user: $userId');
      
      final response = await SupabaseService.client
          .from(_profilesTable)
          .select()
          .eq('id', userId)
          .single();

      AppLogger.info('Profile fetched successfully for user: $userId');
      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Error fetching user profile: $userId', e);
      rethrow;
    }
  }

  /// Update user profile
  static Future<UserModel?> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.info('Updating profile for user: $userId');
      
      // Add updated timestamp
      final updateData = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from(_profilesTable)
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      AppLogger.info('Profile updated successfully for user: $userId');
      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error('Error updating user profile: $userId', e);
      rethrow;
    }
  }

  /// Upload avatar image
  static Future<String?> uploadAvatar(String userId, File imageFile) async {
    try {
      AppLogger.info('Uploading avatar for user: $userId');
      
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      // Upload file to Supabase storage
      await SupabaseService.client.storage
          .from(_avatarBucket)
          .upload(filePath, imageFile);

      // Get public URL
      final publicUrl = SupabaseService.client.storage
          .from(_avatarBucket)
          .getPublicUrl(filePath);

      // Update user profile with new avatar URL
      await updateUserProfile(userId, {
        'avatar_url': publicUrl,
        'avatar_updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Avatar uploaded successfully for user: $userId');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading avatar for user: $userId', e);
      rethrow;
    }
  }

  /// Upload avatar from bytes (for web/mobile compatibility)
  static Future<String?> uploadAvatarFromBytes(
    String userId, 
    Uint8List imageBytes, 
    String fileName,
  ) async {
    try {
      AppLogger.info('Uploading avatar from bytes for user: $userId');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/${timestamp}_$fileName';

      // Upload bytes to Supabase storage
      await SupabaseService.client.storage
          .from(_avatarBucket)
          .uploadBinary(filePath, imageBytes);

      // Get public URL
      final publicUrl = SupabaseService.client.storage
          .from(_avatarBucket)
          .getPublicUrl(filePath);

      // Update user profile with new avatar URL
      await updateUserProfile(userId, {
        'avatar_url': publicUrl,
        'avatar_updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Avatar uploaded from bytes successfully for user: $userId');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading avatar from bytes for user: $userId', e);
      rethrow;
    }
  }

  /// Remove avatar
  static Future<bool> removeAvatar(String userId) async {
    try {
      AppLogger.info('Removing avatar for user: $userId');
      
      // Get current profile to find avatar URL
      final profile = await getUserProfile(userId);
      if (profile?.avatarUrl != null) {
        // Extract file path from URL
        final uri = Uri.parse(profile!.avatarUrl!);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3) {
          final filePath = pathSegments.sublist(2).join('/');
          
          // Delete file from storage
          await SupabaseService.client.storage
              .from(_avatarBucket)
              .remove([filePath]);
        }
      }

      // Update profile to remove avatar URL
      await updateUserProfile(userId, {
        'avatar_url': null,
        'avatar_updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('Avatar removed successfully for user: $userId');
      return true;
    } catch (e) {
      AppLogger.error('Error removing avatar for user: $userId', e);
      return false;
    }
  }

  /// Get avatar URL with fallback to Google avatar
  static String? getAvatarUrl(UserModel user) {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return user.avatarUrl;
    }
    if (user.googleAvatarUrl != null && user.googleAvatarUrl!.isNotEmpty) {
      return user.googleAvatarUrl;
    }
    return null;
  }

  /// Get user initials for avatar fallback
  static String getUserInitials(UserModel user) {
    final firstName = user.firstName?.trim() ?? '';
    final lastName = user.lastName?.trim() ?? '';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    } else if (user.email != null && user.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }
    
    return 'U';
  }

  /// Get full name
  static String getFullName(UserModel user) {
    final firstName = user.firstName?.trim() ?? '';
    final lastName = user.lastName?.trim() ?? '';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@')[0];
    }
    
    return 'User';
  }

  /// Validate profile update data
  static Map<String, String> validateProfileData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    
    if (data.containsKey('first_name')) {
      final firstName = data['first_name'] as String?;
      if (firstName != null && firstName.length > 50) {
        errors['first_name'] = 'First name must be 50 characters or less';
      }
    }
    
    if (data.containsKey('last_name')) {
      final lastName = data['last_name'] as String?;
      if (lastName != null && lastName.length > 50) {
        errors['last_name'] = 'Last name must be 50 characters or less';
      }
    }
    
    if (data.containsKey('email')) {
      final email = data['email'] as String?;
      if (email != null && email.isNotEmpty) {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(email)) {
          errors['email'] = 'Please enter a valid email address';
        }
      }
    }
    
    return errors;
  }
}
