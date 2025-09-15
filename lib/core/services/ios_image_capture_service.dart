import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_logger.dart';

/// iOS-specific image capture service that bypasses permission_handler issues
/// and relies on image_picker's built-in permission handling
class IOSImageCaptureService {
  static final ImagePicker _picker = ImagePicker();

  /// Capture image from camera with iOS-specific handling
  static Future<File?> captureFromCamera(BuildContext context) async {
    try {
      AppLogger.info('Starting camera capture on iOS');

      // Use image_picker directly - it handles permissions internally on iOS
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1500,
        maxHeight: 1500,
        imageQuality: 80,
      );

      if (image != null) {
        AppLogger.info('Camera capture successful: ${image.path}');
        return File(image.path);
      } else {
        AppLogger.warning('Camera capture cancelled by user');
        return null;
      }
    } catch (e) {
      AppLogger.error('Camera capture failed: $e');
      
      if (context.mounted) {
        await _showErrorDialog(
          context,
          'Camera Error',
          _getCameraErrorMessage(e),
        );
      }
      
      return null;
    }
  }

  /// Select image from gallery with iOS-specific handling
  static Future<File?> selectFromGallery(BuildContext context) async {
    try {
      AppLogger.info('Starting gallery selection on iOS');

      // Use image_picker directly - it handles permissions internally on iOS
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1500,
        maxHeight: 1500,
        imageQuality: 80,
      );

      if (image != null) {
        AppLogger.info('Gallery selection successful: ${image.path}');
        return File(image.path);
      } else {
        AppLogger.warning('Gallery selection cancelled by user');
        return null;
      }
    } catch (e) {
      AppLogger.error('Gallery selection failed: $e');
      
      if (context.mounted) {
        await _showErrorDialog(
          context,
          'Gallery Error',
          _getGalleryErrorMessage(e),
        );
      }
      
      return null;
    }
  }

  /// Select multiple images from gallery
  static Future<List<File>> selectMultipleFromGallery(BuildContext context) async {
    try {
      AppLogger.info('Starting multiple gallery selection on iOS');

      final List<XFile> images = await _picker.pickMultipleMedia(
        imageQuality: 80,
        maxWidth: 1500,
        maxHeight: 1500,
      );

      if (images.isNotEmpty) {
        AppLogger.info('Multiple gallery selection successful: ${images.length} images');
        return images.map((image) => File(image.path)).toList();
      } else {
        AppLogger.warning('Multiple gallery selection cancelled by user');
        return [];
      }
    } catch (e) {
      AppLogger.error('Multiple gallery selection failed: $e');
      
      if (context.mounted) {
        await _showErrorDialog(
          context,
          'Gallery Error',
          _getGalleryErrorMessage(e),
        );
      }
      
      return [];
    }
  }

  /// Get user-friendly camera error message
  static String _getCameraErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Camera access was denied. Please enable camera permissions in Settings > Privacy & Security > Camera > Mataresit App.';
    } else if (errorString.contains('not available') || errorString.contains('unavailable')) {
      return 'Camera is not available on this device or is currently being used by another app.';
    } else if (errorString.contains('channel-error') || errorString.contains('plugin')) {
      return 'Camera service is temporarily unavailable. Please restart the app and try again.';
    } else {
      return 'Unable to access camera. Please check your device settings and try again.';
    }
  }

  /// Get user-friendly gallery error message
  static String _getGalleryErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Photo library access was denied. Please enable photo permissions in Settings > Privacy & Security > Photos > Mataresit App.';
    } else if (errorString.contains('not available') || errorString.contains('unavailable')) {
      return 'Photo library is not available on this device.';
    } else if (errorString.contains('channel-error') || errorString.contains('plugin')) {
      return 'Photo library service is temporarily unavailable. Please restart the app and try again.';
    } else {
      return 'Unable to access photo library. Please check your device settings and try again.';
    }
  }

  /// Show error dialog with iOS-style appearance
  static Future<void> _showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show permission settings dialog
  static Future<void> showPermissionSettingsDialog(
    BuildContext context,
    String permissionType,
  ) async {
    if (!context.mounted) return;

    final title = '$permissionType Permission Required';
    final message = permissionType == 'Camera'
        ? 'Mataresit needs camera access to capture receipt photos. Please enable camera permissions in Settings.'
        : 'Mataresit needs photo library access to select receipt images. Please enable photo permissions in Settings.';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Note: openAppSettings() would require permission_handler
                // For now, we'll just close the dialog and let the user manually go to settings
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }
}
