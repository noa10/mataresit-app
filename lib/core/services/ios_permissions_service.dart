import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../shared/widgets/adaptive_widgets.dart';

/// iOS-specific permission handling service
class IOSPermissionsService {

  /// Request camera permission with iOS-specific UI
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (!Platform.isIOS) {
      // Fallback to standard permission request for non-iOS
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    final status = await Permission.camera.status;
    
    switch (status) {
      case PermissionStatus.granted:
        return true;
        
      case PermissionStatus.denied:
        if (!context.mounted) return false;
        return await _requestPermissionWithDialog(
          context,
          Permission.camera,
          'Camera Access Required',
          'Mataresit needs camera access to capture receipt photos for expense tracking and AI-powered data extraction.',
          'Allow Camera Access',
        );
        
      case PermissionStatus.permanentlyDenied:
        if (!context.mounted) return false;
        return await _showSettingsDialog(
          context,
          'Camera Access Denied',
          'Camera access has been permanently denied. Please enable it in Settings to capture receipt photos.',
        );
        
      case PermissionStatus.restricted:
        if (context.mounted) {
          await _showRestrictedDialog(
            context,
            'Camera Access Restricted',
            'Camera access is restricted on this device. Please check your device restrictions.',
          );
        }
        return false;
        
      default:
        return await _requestPermissionWithDialog(
          context,
          Permission.camera,
          'Camera Access Required',
          'Mataresit needs camera access to capture receipt photos for expense tracking and AI-powered data extraction.',
          'Allow Camera Access',
        );
    }
  }

  /// Request photo library permission with iOS-specific UI
  static Future<bool> requestPhotoLibraryPermission(BuildContext context) async {
    if (!Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    final status = await Permission.photos.status;
    
    switch (status) {
      case PermissionStatus.granted:
        return true;
        
      case PermissionStatus.denied:
        if (!context.mounted) return false;
        return await _requestPermissionWithDialog(
          context,
          Permission.photos,
          'Photo Library Access Required',
          'Mataresit needs photo library access to select receipt images for processing and expense management.',
          'Allow Photo Access',
        );
        
      case PermissionStatus.permanentlyDenied:
        if (!context.mounted) return false;
        return await _showSettingsDialog(
          context,
          'Photo Library Access Denied',
          'Photo library access has been permanently denied. Please enable it in Settings to select receipt photos.',
        );
        
      case PermissionStatus.restricted:
        if (context.mounted) {
          await _showRestrictedDialog(
            context,
            'Photo Library Access Restricted',
            'Photo library access is restricted on this device. Please check your device restrictions.',
          );
        }
        return false;
        
      default:
        return await _requestPermissionWithDialog(
          context,
          Permission.photos,
          'Photo Library Access Required',
          'Mataresit needs photo library access to select receipt images for processing and expense management.',
          'Allow Photo Access',
        );
    }
  }

  /// Request biometric permission (Face ID/Touch ID) with iOS-specific UI
  static Future<bool> requestBiometricPermission(BuildContext context) async {
    if (!Platform.isIOS) {
      // For non-iOS platforms, check if biometric authentication is available
      try {
        final isAvailable = await _checkBiometricAvailability();
        return isAvailable;
      } catch (e) {
        return false;
      }
    }

    // Check if biometric authentication is available
    final isAvailable = await _checkBiometricAvailability();
    if (!isAvailable) {
      if (context.mounted) {
        await _showBiometricUnavailableDialog(context);
      }
      return false;
    }

    // Show permission explanation dialog
    if (!context.mounted) return false;
    return await _showBiometricPermissionDialog(context);
  }

  /// Request notification permission with iOS-specific UI
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    if (!Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    final status = await Permission.notification.status;
    
    switch (status) {
      case PermissionStatus.granted:
        return true;
        
      case PermissionStatus.denied:
        if (!context.mounted) return false;
        return await _requestPermissionWithDialog(
          context,
          Permission.notification,
          'Notification Permission',
          'Enable notifications to receive updates about receipt processing, team activities, and important reminders.',
          'Allow Notifications',
        );
        
      case PermissionStatus.permanentlyDenied:
        if (!context.mounted) return false;
        return await _showSettingsDialog(
          context,
          'Notifications Disabled',
          'Notifications have been disabled. Please enable them in Settings to receive important updates.',
        );
        
      default:
        return await _requestPermissionWithDialog(
          context,
          Permission.notification,
          'Notification Permission',
          'Enable notifications to receive updates about receipt processing, team activities, and important reminders.',
          'Allow Notifications',
        );
    }
  }

  /// Generic permission request with iOS-style dialog
  static Future<bool> _requestPermissionWithDialog(
    BuildContext context,
    Permission permission,
    String title,
    String message,
    String allowButtonText,
  ) async {
    final result = await AdaptiveAlertDialog.show<bool>(
      context: context,
      title: title,
      content: message,
      actions: [
        AdaptiveDialogAction(
          text: 'Not Now',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AdaptiveDialogAction(
          text: allowButtonText,
          isDefault: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (result == true) {
      final status = await permission.request();
      return status.isGranted;
    }

    return false;
  }

  /// Show settings dialog for permanently denied permissions
  static Future<bool> _showSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await AdaptiveAlertDialog.show<bool>(
      context: context,
      title: title,
      content: message,
      actions: [
        AdaptiveDialogAction(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AdaptiveDialogAction(
          text: 'Open Settings',
          isDefault: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (result == true) {
      await openAppSettings();
    }

    return false;
  }

  /// Show restricted permission dialog
  static Future<void> _showRestrictedDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await AdaptiveAlertDialog.show(
      context: context,
      title: title,
      content: message,
      actions: [
        AdaptiveDialogAction(
          text: 'OK',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Check if biometric authentication is available
  static Future<bool> _checkBiometricAvailability() async {
    try {
      // This would typically use local_auth package
      // For now, we'll assume it's available on iOS devices
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Show biometric unavailable dialog
  static Future<void> _showBiometricUnavailableDialog(BuildContext context) async {
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Biometric Authentication Unavailable',
      content: 'Face ID or Touch ID is not available on this device or has not been set up.',
      actions: [
        AdaptiveDialogAction(
          text: 'OK',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Show biometric permission dialog
  static Future<bool> _showBiometricPermissionDialog(BuildContext context) async {
    final biometricType = Platform.isIOS ? 'Face ID or Touch ID' : 'Biometric Authentication';
    
    final result = await AdaptiveAlertDialog.show<bool>(
      context: context,
      title: 'Enable $biometricType',
      content: 'Use $biometricType to secure your financial data and provide quick, secure access to the app.',
      actions: [
        AdaptiveDialogAction(
          text: 'Not Now',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AdaptiveDialogAction(
          text: 'Enable',
          isDefault: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    return result ?? false;
  }

  /// Check all required permissions status
  static Future<Map<String, PermissionStatus>> checkAllPermissions() async {
    return {
      'camera': await Permission.camera.status,
      'photos': await Permission.photos.status,
      'notification': await Permission.notification.status,
    };
  }

  /// Request all required permissions at once
  static Future<Map<String, bool>> requestAllPermissions(BuildContext context) async {
    final results = <String, bool>{};

    results['camera'] = await requestCameraPermission(context);
    if (!context.mounted) return results;

    results['photos'] = await requestPhotoLibraryPermission(context);
    if (!context.mounted) return results;

    results['notification'] = await requestNotificationPermission(context);
    if (!context.mounted) return results;

    results['biometric'] = await requestBiometricPermission(context);

    return results;
  }
}
