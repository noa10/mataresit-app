import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_constants.dart';

import '../widgets/processing_timeline_widget.dart';
import '../widgets/processing_logs_widget.dart';
import '../providers/receipt_capture_provider.dart';
import '../providers/receipts_provider.dart';
import '../../../core/guards/subscription_guard.dart';
import '../../../core/services/ios_image_capture_service.dart';
import '../../subscription/widgets/subscription_limits_widget.dart';

class ReceiptCaptureScreen extends ConsumerStatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  ConsumerState<ReceiptCaptureScreen> createState() =>
      _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends ConsumerState<ReceiptCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger();
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    final captureState = ref.watch(receiptCaptureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subscription Limits Display
            const SubscriptionLimitsWidget(
              showUpgradePrompt: true,
              compact: true,
            ),

            const SizedBox(height: AppConstants.largePadding),

            // Image Preview Section
            if (_selectedImage != null) ...[
              Card(
                child: SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Action Buttons for Selected Image
              if (!captureState.isProcessing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cropImage,
                        icon: const Icon(Icons.crop),
                        label: const Text('Crop'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearImage,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.largePadding),

                // Upload Button
                ElevatedButton.icon(
                  onPressed: _uploadReceipt,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload Receipt'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.defaultPadding,
                    ),
                  ),
                ),
              ],

              // Processing Timeline and Logs
              if (captureState.isProcessing ||
                  captureState.processLogs.isNotEmpty) ...[
                const SizedBox(height: AppConstants.largePadding),
                ProcessingTimelineWidget(
                  currentStage: captureState.currentStage,
                  stageHistory: captureState.stageHistory,
                  uploadProgress: captureState.uploadProgress,
                  fileSize: _selectedImage?.lengthSync(),
                  processingMethod: 'ai-vision',
                  modelId: 'gemini-1.5-flash',
                  startTime: captureState.startTime,
                  isProgressUpdating: captureState.isProgressUpdating,
                ),
                // Only show processing logs during active processing, not after completion
                if (captureState.isProcessing)
                  ProcessingLogsWidget(
                    processLogs: captureState.processLogs,
                    currentStage: captureState.currentStage,
                    showDetailedLogs: true,
                    startTime: captureState.startTime,
                  ),
                // Show success message when completed
                if (captureState.currentStage == 'COMPLETE' &&
                    !captureState.isProcessing) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Receipt processed successfully! You can now capture another receipt.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ] else ...[
              // Capture Options
              _buildCaptureOptions(),
            ],

            // Error Display
            if (captureState.error != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildErrorDisplay(captureState.error!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureOptions() {
    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Capture Your Receipt',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Take a photo or select an image from your gallery. Make sure the receipt is well-lit and all text is clearly visible.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.largePadding * 2),

        // Capture Buttons
        Row(
          children: [
            Expanded(
              child: _buildCaptureButton(
                icon: Icons.camera_alt,
                label: 'Take Photo',
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _buildCaptureButton(
                icon: Icons.photo_library,
                label: 'From Gallery',
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.largePadding),

        // Batch Upload Option
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/receipts/batch-upload'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Multiple Receipts'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.defaultPadding,
              ),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppConstants.largePadding),

        // Tips Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text(
                      'Tips for Better Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildTip('Ensure good lighting'),
                _buildTip('Keep the receipt flat'),
                _buildTip('Include all edges of the receipt'),
                _buildTip('Avoid shadows and glare'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(tip, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      File? imageFile;

      // Use iOS-specific service for better error handling and permission management
      if (Platform.isIOS) {
        if (source == ImageSource.camera) {
          imageFile = await IOSImageCaptureService.captureFromCamera(context);
        } else {
          imageFile = await IOSImageCaptureService.selectFromGallery(context);
        }
      } else {
        // Android handling with permission checks
        if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted) {
            _showPermissionDialog('Camera');
            return;
          }
        }

        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1500,
          maxHeight: 1500,
          imageQuality: 80,
        );

        if (image != null) {
          imageFile = File(image.path);
        }
      }

      if (imageFile != null) {
        setState(() {
          _selectedImage = imageFile;
        });
        _logger.i('Image selected successfully: ${imageFile.path}');
      } else {
        _logger.w('Image selection cancelled or failed');
      }
    } catch (e) {
      _logger.e('Image picker failed: $e');

      // Provide more specific error messages
      String errorMessage = 'Failed to pick image';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Camera/Gallery not available. Please restart the app and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please grant camera/gallery access in settings.';
      } else {
        errorMessage = 'Failed to pick image: ${e.toString()}';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      // Processing state is managed by the provider
    }
  }

  Future<void> _cropImage() async {
    if (_selectedImage == null) return;

    try {
      // Processing state is managed by the provider

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _selectedImage!.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to crop image: ${e.toString()}');
    } finally {
      // Processing state is managed by the provider
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _uploadReceipt() async {
    if (_selectedImage == null) return;

    // Check subscription limits before upload
    final canUpload = await SubscriptionGuard.showReceiptLimitDialogIfNeeded(
      context,
      ref,
      additionalReceipts: 1,
    );

    if (!canUpload) {
      return; // User was shown upgrade dialog
    }

    try {
      // Check if widget is still mounted before starting upload
      if (!mounted) return;

      await ref
          .read(receiptCaptureProvider.notifier)
          .uploadReceipt(_selectedImage!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Add a longer delay to ensure database transaction is committed and replicated
        _logger.i('⏳ Waiting for database consistency before refresh...');
        await Future.delayed(const Duration(milliseconds: 1500));

        // Check if widget is still mounted before refreshing
        if (!mounted) return;

        // Refresh the receipts list to show the newly uploaded receipt
        try {
          _logger.i('🔄 Starting receipts list refresh after upload...');
          await ref.read(receiptsProvider.notifier).refresh();
          _logger.i('✅ Receipts list refreshed successfully after upload');

          // Double-check by loading more to ensure the new receipt appears
          await Future.delayed(const Duration(milliseconds: 500));

          // Check mounted again after delay
          if (!mounted) return;

          await ref.read(receiptsProvider.notifier).loadReceipts(refresh: true);
          _logger.i('✅ Secondary refresh completed');
        } catch (refreshError) {
          _logger.e('❌ Failed to refresh receipts list: $refreshError');
          // Don't block navigation if refresh fails, but show a warning
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Receipt uploaded but list refresh failed. Pull to refresh manually.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      _logger.e('Receipt upload failed: $e');

      // Provide more specific error messages based on error type
      String errorMessage = 'Failed to upload receipt';
      if (e.toString().contains('StorageException')) {
        if (e.toString().contains('400')) {
          errorMessage = 'Upload failed: Invalid file or storage configuration. Please try again.';
        } else if (e.toString().contains('401') || e.toString().contains('403')) {
          errorMessage = 'Upload failed: Authentication error. Please log in again.';
        } else if (e.toString().contains('413')) {
          errorMessage = 'Upload failed: File too large. Please use a smaller image.';
        } else {
          errorMessage = 'Upload failed: Storage error. Please check your connection and try again.';
        }
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Upload failed: Network error. Please check your connection and try again.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Upload failed: Request timed out. Please try again.';
      } else {
        errorMessage = 'Upload failed: ${e.toString()}';
      }

      _showErrorSnackBar(errorMessage);
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          'Please grant $permission permission to capture receipts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    // Check if this is a geographic restriction error
    final isGeographicRestriction =
        error.contains('UnsupportedUserLocation') ||
        error.contains('geographic restriction') ||
        error.contains('not available in your region') ||
        error.contains('not available in your current location');

    if (isGeographicRestriction) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange, size: 24),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      'AI Processing Not Available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Gemini AI Vision is not available in your geographic region. This is a restriction by Google.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Available options:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              _buildSolutionOption(
                Icons.vpn_key,
                'Use VPN',
                'Connect to a supported region (US, Europe, etc.)',
              ),
              _buildSolutionOption(
                Icons.edit,
                'Manual Entry',
                'Enter receipt details manually',
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Clear error and continue with manual entry
                        ref.read(receiptCaptureProvider.notifier).clearError();
                        _showManualEntryDialog();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Enter Manually'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Clear error and try again (user might have enabled VPN)
                        ref.read(receiptCaptureProvider.notifier).clearError();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Default error display for other errors
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionOption(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Receipt Entry'),
        content: const Text(
          'Manual receipt entry feature will be available soon. For now, you can:\n\n'
          '• Use a VPN to connect to a supported region\n'
          '• Try the web version of Mataresit\n'
          '• Contact support for assistance',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
