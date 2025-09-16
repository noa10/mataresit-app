import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'ios_permissions_service.dart';
import 'ios_simulator_detection_service.dart';

/// iOS-specific file picker service that provides optimized file selection
/// for receipt images and documents with proper permission handling
class IOSFilePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Pick multiple images from iOS photo library with proper permissions
  static Future<List<File>> pickMultipleImages(BuildContext context) async {
    if (!Platform.isIOS) {
      return _pickMultipleImagesGeneric();
    }

    // iOS Simulator compatibility: Use generic file picker
    if (IOSSimulatorDetectionService.isIOSSimulator) {
      debugPrint(
        '🔍 iOS_FILE_PICKER: Using generic file picker for iOS Simulator',
      );
      return _pickMultipleImagesGeneric();
    }

    try {
      // Request photo library permission (skip in simulator)
      final hasPermission =
          await IOSPermissionsService.requestPhotoLibraryPermission(context);
      if (!hasPermission) {
        return [];
      }

      // Use image picker for better iOS photo library integration
      final List<XFile> images = await _imagePicker.pickMultipleMedia(
        imageQuality: 80,
        maxWidth: 1500,
        maxHeight: 1500,
      );

      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images on iOS: $e');
      // Fallback to generic picker if iOS-specific picker fails
      return _pickMultipleImagesGeneric();
    }
  }

  /// Pick single image from camera with iOS-specific handling
  static Future<File?> pickImageFromCamera(BuildContext context) async {
    try {
      // iOS Simulator compatibility: Camera might not work properly
      if (IOSSimulatorDetectionService.isIOSSimulator) {
        debugPrint(
          '🔍 iOS_FILE_PICKER: Camera access in iOS Simulator - using fallback',
        );
        // In simulator, we can still try the camera but with better error handling
      }

      // Request camera permission
      bool hasPermission;
      if (Platform.isIOS && !IOSSimulatorDetectionService.isIOSSimulator) {
        hasPermission = await IOSPermissionsService.requestCameraPermission(
          context,
        );
      } else {
        hasPermission = true; // Skip permission request in simulator
      }

      if (!hasPermission) {
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1500,
        maxHeight: 1500,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick single image from gallery with iOS-specific handling
  static Future<File?> pickImageFromGallery(BuildContext context) async {
    try {
      // Request photo library permission for iOS (skip in simulator)
      if (Platform.isIOS && !IOSSimulatorDetectionService.isIOSSimulator) {
        final hasPermission =
            await IOSPermissionsService.requestPhotoLibraryPermission(context);
        if (!hasPermission) {
          return null;
        }
      } else if (IOSSimulatorDetectionService.isIOSSimulator) {
        debugPrint(
          '🔍 iOS_FILE_PICKER: Skipping permission request in iOS Simulator',
        );
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1500,
        maxHeight: 1500,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick files using the file picker (for documents, PDFs, etc.)
  static Future<List<File>> pickFiles({
    FileType type = FileType.image,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error picking files: $e');
      return [];
    }
  }

  /// Show iOS-specific file selection options
  static Future<List<File>> showFileSelectionOptions(
    BuildContext context,
  ) async {
    if (!Platform.isIOS) {
      return _pickMultipleImagesGeneric();
    }

    final List<File>? result = await showModalBottomSheet<List<File>>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Receipt Images',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                subtitle: const Text(
                  'Select multiple images from your photo library',
                ),
                onTap: () async {
                  final files = await pickMultipleImages(context);
                  if (context.mounted) {
                    Navigator.pop(context, files);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo with your camera'),
                onTap: () async {
                  final file = await pickImageFromCamera(context);
                  if (context.mounted) {
                    Navigator.pop(context, file != null ? [file] : <File>[]);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Files'),
                subtitle: const Text('Browse files and documents'),
                onTap: () async {
                  final files = await pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                    allowMultiple: true,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, files);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    return result ?? [];
  }

  /// Generic multiple image picker for non-iOS platforms
  static Future<List<File>> _pickMultipleImagesGeneric() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error picking multiple images (generic): $e');
      return [];
    }
  }

  /// Capture multiple photos sequentially
  static Future<List<File>> captureMultiplePhotos(BuildContext context) async {
    final List<File> capturedFiles = [];
    bool continueTaking = true;

    while (continueTaking) {
      if (!context.mounted) break;

      try {
        final file = await pickImageFromCamera(context);

        if (file != null) {
          capturedFiles.add(file);

          if (!context.mounted) break;

          // Ask if user wants to take another photo
          final takeAnother = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Photo Captured'),
                content: Text(
                  'Successfully captured ${capturedFiles.length} photo${capturedFiles.length == 1 ? '' : 's'}. Take another photo?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Done'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Take Another'),
                  ),
                ],
              );
            },
          );

          continueTaking = takeAnother ?? false;
        } else {
          continueTaking = false;
        }
      } catch (e) {
        continueTaking = false;
        debugPrint('Error capturing photo: $e');
      }
    }

    return capturedFiles;
  }
}
