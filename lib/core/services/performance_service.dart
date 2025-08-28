import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

/// Service for performance optimizations and background processing
class PerformanceService {
  static final Logger _logger = Logger();
  static const String _dataSyncTask = 'dataSync';
  static const String _cacheCleanupTask = 'cacheCleanup';

  /// Initialize performance service
  static Future<void> initialize() async {
    try {
      // Initialize WorkManager for background tasks
      await Workmanager().initialize(
        _callbackDispatcher,
      );

      // Schedule periodic tasks
      await _schedulePeriodicTasks();

      _logger.i('Performance Service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Performance Service: $e');
      rethrow;
    }
  }

  /// Schedule periodic background tasks
  static Future<void> _schedulePeriodicTasks() async {
    try {
      // Schedule cache cleanup every 24 hours
      await Workmanager().registerPeriodicTask(
        'cacheCleanup',
        _cacheCleanupTask,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          requiresBatteryNotLow: true,
        ),
      );

      // Schedule data sync every 30 minutes when connected
      await Workmanager().registerPeriodicTask(
        'dataSync',
        _dataSyncTask,
        frequency: const Duration(minutes: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );

      _logger.d('Periodic tasks scheduled');
    } catch (e) {
      _logger.e('Failed to schedule periodic tasks: $e');
    }
  }

  /// Compress image in background isolate
  static Future<File> compressImage({
    required File imageFile,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      _logger.d('Starting image compression: ${imageFile.path}');
      
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _compressImageIsolate,
        _ImageCompressionData(
          sendPort: receivePort.sendPort,
          imagePath: imageFile.path,
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
      );

      final result = await receivePort.first as _ImageCompressionResult;
      isolate.kill();

      if (result.error != null) {
        throw Exception(result.error);
      }

      final compressedFile = File(result.compressedPath!);
      _logger.d('Image compression completed: ${compressedFile.path}');
      
      return compressedFile;
    } catch (e) {
      _logger.e('Image compression failed: $e');
      rethrow;
    }
  }

  /// Compress image isolate function
  static void _compressImageIsolate(_ImageCompressionData data) async {
    try {
      final imageBytes = await File(data.imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        data.sendPort.send(_ImageCompressionResult(
          error: 'Failed to decode image',
        ));
        return;
      }

      // Resize if needed
      img.Image processedImage = image;
      if (data.maxWidth != null || data.maxHeight != null) {
        processedImage = img.copyResize(
          image,
          width: data.maxWidth,
          height: data.maxHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress
      final compressedBytes = img.encodeJpg(processedImage, quality: data.quality);
      
      // Save compressed image
      final directory = await getTemporaryDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File('${directory.path}/$fileName');
      await compressedFile.writeAsBytes(compressedBytes);

      data.sendPort.send(_ImageCompressionResult(
        compressedPath: compressedFile.path,
      ));
    } catch (e) {
      data.sendPort.send(_ImageCompressionResult(
        error: e.toString(),
      ));
    }
  }

  /// Optimize image for upload
  static Future<File> optimizeImageForUpload(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      _logger.d('Original image size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Determine compression settings based on file size
      int quality = 85;
      int? maxWidth;
      int? maxHeight;

      if (fileSize > 5 * 1024 * 1024) { // > 5MB
        quality = 70;
        maxWidth = 1920;
        maxHeight = 1920;
      } else if (fileSize > 2 * 1024 * 1024) { // > 2MB
        quality = 80;
        maxWidth = 2048;
        maxHeight = 2048;
      }

      if (quality < 85 || maxWidth != null) {
        final optimizedFile = await compressImage(
          imageFile: imageFile,
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );

        final optimizedSize = await optimizedFile.length();
        _logger.d('Optimized image size: ${(optimizedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        
        return optimizedFile;
      }

      return imageFile;
    } catch (e) {
      _logger.e('Image optimization failed: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  /// Generate thumbnail
  static Future<File> generateThumbnail({
    required File imageFile,
    int size = 200,
  }) async {
    try {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _generateThumbnailIsolate,
        _ThumbnailData(
          sendPort: receivePort.sendPort,
          imagePath: imageFile.path,
          size: size,
        ),
      );

      final result = await receivePort.first as _ThumbnailResult;
      isolate.kill();

      if (result.error != null) {
        throw Exception(result.error);
      }

      return File(result.thumbnailPath!);
    } catch (e) {
      _logger.e('Thumbnail generation failed: $e');
      rethrow;
    }
  }

  /// Generate thumbnail isolate function
  static void _generateThumbnailIsolate(_ThumbnailData data) async {
    try {
      final imageBytes = await File(data.imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        data.sendPort.send(_ThumbnailResult(
          error: 'Failed to decode image',
        ));
        return;
      }

      // Create thumbnail
      final thumbnail = img.copyResize(
        image,
        width: data.size,
        height: data.size,
        interpolation: img.Interpolation.linear,
      );

      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      
      // Save thumbnail
      final directory = await getTemporaryDirectory();
      final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final thumbnailFile = File('${directory.path}/$fileName');
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      data.sendPort.send(_ThumbnailResult(
        thumbnailPath: thumbnailFile.path,
      ));
    } catch (e) {
      data.sendPort.send(_ThumbnailResult(
        error: e.toString(),
      ));
    }
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      int deletedCount = 0;
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          if (fileName.startsWith('compressed_') || 
              fileName.startsWith('thumb_') ||
              fileName.startsWith('temp_')) {
            try {
              await file.delete();
              deletedCount++;
            } catch (e) {
              _logger.w('Failed to delete temp file: ${file.path}');
            }
          }
        }
      }
      
      _logger.i('Cleaned up $deletedCount temporary files');
    } catch (e) {
      _logger.e('Failed to cleanup temp files: $e');
    }
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      
      int totalSize = 0;
      
      // Calculate temp directory size
      totalSize += await _calculateDirectorySize(tempDir);
      
      // Calculate cache directory size
      totalSize += await _calculateDirectorySize(cacheDir);
      
      return totalSize;
    } catch (e) {
      _logger.e('Failed to calculate cache size: $e');
      return 0;
    }
  }

  /// Calculate directory size
  static Future<int> _calculateDirectorySize(Directory directory) async {
    int size = 0;
    try {
      final files = directory.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          size += await file.length();
        }
      }
    } catch (e) {
      _logger.w('Failed to calculate directory size: ${directory.path}');
    }
    return size;
  }

  /// Clear cache
  static Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      
      // Clear temp directory
      await _clearDirectory(tempDir);
      
      // Clear cache directory
      await _clearDirectory(cacheDir);
      
      _logger.i('Cache cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear cache: $e');
    }
  }

  /// Clear directory contents
  static Future<void> _clearDirectory(Directory directory) async {
    try {
      final files = directory.listSync();
      for (final file in files) {
        try {
          await file.delete(recursive: true);
        } catch (e) {
          _logger.w('Failed to delete: ${file.path}');
        }
      }
    } catch (e) {
      _logger.w('Failed to clear directory: ${directory.path}');
    }
  }

  /// Get memory usage info
  static Future<Map<String, dynamic>> getMemoryInfo() async {
    try {
      // This is a simplified version - in a real app you might use
      // platform-specific code to get detailed memory information
      final cacheSize = await getCacheSize();
      
      return {
        'cacheSize': cacheSize,
        'cacheSizeMB': (cacheSize / 1024 / 1024).toStringAsFixed(2),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('Failed to get memory info: $e');
      return {};
    }
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger();
    logger.i('Executing background task: $task');
    
    try {
      switch (task) {
        case 'cacheCleanup':
          await PerformanceService.cleanupTempFiles();
          break;
        case 'dataSync':
          // This would trigger sync service
          logger.d('Background data sync triggered');
          break;
        default:
          logger.w('Unknown background task: $task');
      }
      return Future.value(true);
    } catch (e) {
      logger.e('Background task failed: $e');
      return Future.value(false);
    }
  });
}

/// Data classes for isolate communication
class _ImageCompressionData {
  final SendPort sendPort;
  final String imagePath;
  final int quality;
  final int? maxWidth;
  final int? maxHeight;

  _ImageCompressionData({
    required this.sendPort,
    required this.imagePath,
    required this.quality,
    this.maxWidth,
    this.maxHeight,
  });
}

class _ImageCompressionResult {
  final String? compressedPath;
  final String? error;

  _ImageCompressionResult({this.compressedPath, this.error});
}

class _ThumbnailData {
  final SendPort sendPort;
  final String imagePath;
  final int size;

  _ThumbnailData({
    required this.sendPort,
    required this.imagePath,
    required this.size,
  });
}

class _ThumbnailResult {
  final String? thumbnailPath;
  final String? error;

  _ThumbnailResult({this.thumbnailPath, this.error});
}
