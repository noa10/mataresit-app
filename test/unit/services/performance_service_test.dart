import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/core/services/performance_service.dart';

void main() {
  group('PerformanceService', () {
    late File testImageFile;

    setUp(() async {
      // Create a simple test image (1x1 pixel PNG)
      final testImageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x37, 0x6E, 0xF9, 0x24, 0x00, 0x00,
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, // IEND chunk
        0x60, 0x82,
      ]);

      final tempDir = Directory.systemTemp;
      testImageFile = File('${tempDir.path}/test_image.png');
      await testImageFile.writeAsBytes(testImageBytes);
    });

    tearDown(() async {
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
    });

    test(
      'optimizeImageForUpload should handle small files correctly',
      () async {
        // Test with a small file (< 1MB) - should return original
        final result = await PerformanceService.optimizeImageForUpload(
          testImageFile,
        );

        // For small files, it should return the original file
        expect(result.path, equals(testImageFile.path));
      },
    );

    test(
      'optimizeImageForUpload should handle missing files gracefully',
      () async {
        final tempDir = Directory.systemTemp;
        final nonExistentFile = File('${tempDir.path}/non_existent.png');

        // Should not throw an exception and return the original file
        final result = await PerformanceService.optimizeImageForUpload(
          nonExistentFile,
        );
        expect(result.path, equals(nonExistentFile.path));
      },
    );

    test('service methods should not throw exceptions', () async {
      // Test that core methods don't throw exceptions even in test environment

      // Test cleanup functionality
      expect(() async {
        await PerformanceService.cleanupTempFiles();
      }, returnsNormally);

      // Test cache size calculation
      final cacheSize = await PerformanceService.getCacheSize();
      expect(cacheSize, greaterThanOrEqualTo(0));

      // Test memory info
      final memoryInfo = await PerformanceService.getMemoryInfo();
      expect(memoryInfo, isA<Map<String, dynamic>>());
      expect(memoryInfo.containsKey('cacheSize'), isTrue);
      expect(memoryInfo.containsKey('cacheSizeMB'), isTrue);
      expect(memoryInfo.containsKey('timestamp'), isTrue);
    });
  });
}
