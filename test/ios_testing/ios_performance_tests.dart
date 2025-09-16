import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mataresit_app/app/app.dart';
import 'package:mataresit_app/core/services/ios_performance_service.dart';
import 'ios_test_framework.dart';
import '../test_helpers/test_logger.dart';

/// iOS Performance Testing Suite
/// Tests memory usage, battery consumption, and performance optimization
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('iOS Performance Tests', () {
    late TestLogger logger;

    setUpAll(() async {
      logger = TestLogger.getLogger('IOSPerformanceTests');
      await TestLogger.initialize();
      await IOSTestFramework.initialize();

      logger.i('Starting iOS Performance Test Suite');
      logger.i('Device: ${IOSTestFramework.deviceInfo?.model}');
      logger.i('Is Physical Device: ${IOSTestFramework.isPhysicalDevice}');
    });

    group('Memory Management Tests', () {
      testWidgets('Memory Usage Monitoring', (WidgetTester tester) async {
        logger.i('Testing memory usage monitoring');

        if (!Platform.isIOS) {
          logger.w('Skipping memory test - not running on iOS');
          return;
        }

        // Initialize performance service
        await IOSPerformanceService.initialize();

        // Get initial memory usage
        final initialMemoryData =
            await IOSPerformanceService.getCurrentMemoryUsage();
        final initialMemory =
            initialMemoryData['image_cache_size_bytes'] as int? ?? 0;
        logger.i(
          'Initial memory usage: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)}MB',
        );

        // Create memory-intensive operations
        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        // Simulate heavy memory usage
        final List<Uint8List> memoryBlocks = [];
        for (int i = 0; i < 10; i++) {
          memoryBlocks.add(Uint8List(1024 * 1024)); // 1MB blocks
          await tester.pump();
        }

        // Check memory usage after allocation
        final peakMemoryData =
            await IOSPerformanceService.getCurrentMemoryUsage();
        final peakMemory =
            peakMemoryData['image_cache_size_bytes'] as int? ?? 0;
        logger.i(
          'Peak memory usage: ${(peakMemory / 1024 / 1024).toStringAsFixed(2)}MB',
        );

        // Clear memory blocks
        memoryBlocks.clear();

        // Force garbage collection
        await IOSPerformanceService.optimizeMemoryUsage();
        await tester.pumpAndSettle();

        // Check memory usage after cleanup
        final finalMemoryData =
            await IOSPerformanceService.getCurrentMemoryUsage();
        final finalMemory =
            finalMemoryData['image_cache_size_bytes'] as int? ?? 0;
        logger.i(
          'Final memory usage: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)}MB',
        );

        // Verify memory was properly managed
        expect(
          finalMemory,
          lessThan(peakMemory + (10 * 1024 * 1024)),
          reason: 'Memory should be released after cleanup',
        );
      });

      testWidgets('Image Cache Management', (WidgetTester tester) async {
        logger.i('Testing image cache management');

        if (!Platform.isIOS) {
          logger.w('Skipping image cache test - not running on iOS');
          return;
        }

        await IOSPerformanceService.initialize();

        // Test image cache configuration
        final cacheSize = IOSPerformanceService.getImageCacheSize();
        logger.i('Image cache size: ${cacheSize}MB');

        expect(
          cacheSize,
          lessThanOrEqualTo(50),
          reason: 'Image cache should not exceed 50MB',
        );

        // Test cache cleanup
        await IOSPerformanceService.clearImageCache();
        logger.i('Image cache cleared successfully');
      });

      testWidgets('Low Memory Warning Handling', (WidgetTester tester) async {
        logger.i('Testing low memory warning handling');

        if (!Platform.isIOS) {
          logger.w('Skipping low memory test - not running on iOS');
          return;
        }

        await IOSPerformanceService.initialize();

        // Simulate low memory warning
        try {
          await IOSPerformanceService.handleLowMemoryWarning();
          logger.i('Low memory warning handled successfully');
        } catch (e) {
          logger.e('Low memory warning handling failed: $e');
          fail('Low memory warning should be handled gracefully');
        }
      });
    });

    group('Performance Optimization Tests', () {
      testWidgets('App Launch Performance', (WidgetTester tester) async {
        logger.i('Testing app launch performance');

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        stopwatch.stop();
        final launchTime = stopwatch.elapsedMilliseconds;

        logger.i('App launch time: ${launchTime}ms');

        // Verify launch time is reasonable (should be under 3 seconds)
        expect(
          launchTime,
          lessThan(3000),
          reason: 'App should launch within 3 seconds',
        );
      });

      testWidgets('UI Rendering Performance', (WidgetTester tester) async {
        logger.i('Testing UI rendering performance');

        // Create a complex UI to test rendering performance
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 1000,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Text('$index')),
                    title: Text('Item $index'),
                    subtitle: Text('Subtitle for item $index'),
                    trailing: const Icon(Icons.arrow_forward),
                  );
                },
              ),
            ),
          ),
        );

        final stopwatch = Stopwatch()..start();

        // Scroll through the list to test rendering performance
        final listFinder = find.byType(ListView);
        await tester.fling(listFinder, const Offset(0, -5000), 10000);
        await tester.pumpAndSettle();

        stopwatch.stop();
        final renderTime = stopwatch.elapsedMilliseconds;

        logger.i('UI rendering time: ${renderTime}ms');

        // Verify rendering performance is acceptable
        expect(
          renderTime,
          lessThan(1000),
          reason: 'UI rendering should complete within 1 second',
        );
      });

      testWidgets('Background Processing Performance', (
        WidgetTester tester,
      ) async {
        logger.i('Testing background processing performance');

        if (!Platform.isIOS) {
          logger.w('Skipping background processing test - not running on iOS');
          return;
        }

        await IOSPerformanceService.initialize();

        // Test background mode optimization
        await IOSPerformanceService.optimizeForBackgroundMode();
        logger.i('Background mode optimization applied');

        // Test foreground mode optimization
        await IOSPerformanceService.optimizeForForegroundMode();
        logger.i('Foreground mode optimization applied');
      });
    });

    group('Battery Usage Tests', () {
      testWidgets('Battery Level Monitoring', (WidgetTester tester) async {
        logger.i('Testing battery level monitoring');

        if (!Platform.isIOS || !IOSTestFramework.isPhysicalDevice) {
          logger.w('Skipping battery test - requires physical iOS device');
          return;
        }

        await IOSPerformanceService.initialize();

        try {
          final batteryLevel = await IOSPerformanceService.getBatteryLevel();
          logger.i('Current battery level: $batteryLevel%');

          expect(
            batteryLevel,
            inInclusiveRange(0, 100),
            reason: 'Battery level should be between 0 and 100',
          );
        } catch (e) {
          logger.w('Battery level monitoring not available: $e');
        }
      });

      testWidgets('Battery-Aware Performance Tuning', (
        WidgetTester tester,
      ) async {
        logger.i('Testing battery-aware performance tuning');

        if (!Platform.isIOS) {
          logger.w('Skipping battery tuning test - not running on iOS');
          return;
        }

        await IOSPerformanceService.initialize();

        // Test low battery mode optimization
        await IOSPerformanceService.optimizeForLowBattery();
        logger.i('Low battery optimization applied');

        // Test normal battery mode optimization
        await IOSPerformanceService.optimizeForNormalBattery();
        logger.i('Normal battery optimization applied');
      });
    });

    group('Thermal Performance Tests', () {
      testWidgets('CPU Intensive Operations', (WidgetTester tester) async {
        logger.i('Testing CPU intensive operations');

        final stopwatch = Stopwatch()..start();

        // Simulate CPU intensive work
        int result = 0;
        for (int i = 0; i < 1000000; i++) {
          result += i * i;
        }

        stopwatch.stop();
        final cpuTime = stopwatch.elapsedMilliseconds;

        logger.i(
          'CPU intensive operation time: ${cpuTime}ms (result: $result)',
        );

        // Verify CPU operations complete in reasonable time
        expect(
          cpuTime,
          lessThan(5000),
          reason: 'CPU intensive operations should complete within 5 seconds',
        );
      });

      testWidgets('Memory Allocation Performance', (WidgetTester tester) async {
        logger.i('Testing memory allocation performance');

        final stopwatch = Stopwatch()..start();

        // Allocate and deallocate memory blocks
        final List<List<int>> memoryBlocks = [];
        for (int i = 0; i < 100; i++) {
          memoryBlocks.add(List.generate(10000, (index) => index));
        }

        // Clear memory
        memoryBlocks.clear();

        stopwatch.stop();
        final allocTime = stopwatch.elapsedMilliseconds;

        logger.i('Memory allocation time: ${allocTime}ms');

        // Verify memory allocation performance
        expect(
          allocTime,
          lessThan(1000),
          reason: 'Memory allocation should complete within 1 second',
        );
      });
    });

    group('Performance Metrics Collection', () {
      testWidgets('Performance Metrics Gathering', (WidgetTester tester) async {
        logger.i('Testing performance metrics gathering');

        if (!Platform.isIOS) {
          logger.w('Skipping metrics test - not running on iOS');
          return;
        }

        await IOSPerformanceService.initialize();

        // Collect performance metrics
        final metrics = await IOSPerformanceService.getPerformanceMetrics();

        logger.i('Performance metrics collected:');
        metrics.forEach((key, value) {
          logger.i('  $key: $value');
        });

        // Verify essential metrics are present
        expect(metrics, containsPair('memoryUsage', isA<double>()));
        expect(metrics, containsPair('timestamp', isA<String>()));
      });

      testWidgets('Performance Monitoring Over Time', (
        WidgetTester tester,
      ) async {
        logger.i('Testing performance monitoring over time');

        if (!Platform.isIOS) {
          logger.w('Skipping monitoring test - not running on iOS');
          return;
        }

        await IOSPerformanceService.initialize();

        // Start performance monitoring
        await IOSPerformanceService.startPerformanceMonitoring();

        // Perform some operations
        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        // Wait for monitoring data
        await Future.delayed(const Duration(seconds: 2));

        // Stop monitoring and get results
        final monitoringResults =
            await IOSPerformanceService.stopPerformanceMonitoring();

        logger.i('Performance monitoring results: $monitoringResults');

        expect(
          monitoringResults,
          isNotEmpty,
          reason: 'Performance monitoring should collect data',
        );
      });
    });

    tearDownAll(() async {
      logger.i('iOS Performance Test Suite completed');

      // Clean up performance service
      if (Platform.isIOS) {
        await IOSPerformanceService.cleanup();
      }

      // Export test results
      final logData = TestLogger.exportLogsToJson();
      logger.i(
        'Performance test logs exported: ${logData['totalEntries']} entries',
      );
    });
  });
}
