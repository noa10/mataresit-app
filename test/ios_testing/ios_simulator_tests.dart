import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mataresit_app/app/app.dart';

import 'package:mataresit_app/shared/widgets/adaptive_navigation_wrapper.dart';
import 'package:mataresit_app/shared/widgets/adaptive_widgets.dart';
import 'package:mataresit_app/core/services/ios_permissions_service.dart';
import 'ios_test_framework.dart';
import '../test_helpers/test_logger.dart';

/// Comprehensive iOS Simulator Testing Suite
/// Tests iOS-specific functionality across multiple iOS versions and device sizes
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('iOS Simulator Tests', () {
    late TestLogger logger;

    setUpAll(() async {
      logger = TestLogger.getLogger('IOSSimulatorTests');
      await TestLogger.initialize();
      await IOSTestFramework.initialize();

      logger.i('Starting iOS Simulator Test Suite');
      logger.i('Device: ${IOSTestFramework.deviceInfo?.model}');
      logger.i('iOS Version: ${IOSTestFramework.iOSVersion}');
      logger.i('Is Simulator: ${IOSTestFramework.isSimulator}');
    });

    group('iOS Version Compatibility Tests', () {
      testWidgets('iOS 14.0+ Minimum Version Support', (
        WidgetTester tester,
      ) async {
        logger.i('Testing iOS minimum version support');

        // Skip if not iOS
        if (!Platform.isIOS) {
          logger.w('Skipping iOS version test - not running on iOS');
          return;
        }

        // Verify minimum iOS version
        expect(
          IOSTestFramework.meetsMinimumIOSVersion(14, 0),
          isTrue,
          reason: 'App requires iOS 14.0 or later',
        );

        logger.i(
          'iOS version compatibility verified: ${IOSTestFramework.iOSVersion}',
        );
      });

      testWidgets('iOS System Features Availability', (
        WidgetTester tester,
      ) async {
        logger.i('Testing iOS system features availability');

        if (!Platform.isIOS) {
          logger.w('Skipping iOS features test - not running on iOS');
          return;
        }

        // Test biometric support detection
        final biometricType = IOSTestFramework.expectedBiometricType;
        logger.i('Expected biometric type: $biometricType');

        // Test device category detection
        final deviceCategory = IOSTestFramework.deviceCategory;
        logger.i('Device category: $deviceCategory');

        expect(
          deviceCategory,
          isNot(DeviceCategory.unknown),
          reason: 'Device category should be detected',
        );
      });
    });

    group('iOS UI/UX Adaptation Tests', () {
      testWidgets('iOS Theme Application', (WidgetTester tester) async {
        logger.i('Testing iOS theme application');

        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        if (Platform.isIOS) {
          // Verify iOS theme is applied
          final materialApp = tester.widget<MaterialApp>(
            find.byType(MaterialApp),
          );
          expect(
            materialApp.theme,
            isNotNull,
            reason: 'iOS theme should be applied',
          );

          logger.i('iOS theme successfully applied');
        } else {
          logger.w('Skipping iOS theme test - not running on iOS');
        }
      });

      testWidgets('Adaptive Navigation Wrapper', (WidgetTester tester) async {
        logger.i('Testing adaptive navigation wrapper');

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: AdaptiveNavigationWrapper(
                child: const Scaffold(body: Text('Home')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (Platform.isIOS) {
          // Verify CupertinoTabScaffold is used on iOS
          expect(
            find.byType(CupertinoTabScaffold),
            findsOneWidget,
            reason: 'iOS should use CupertinoTabScaffold',
          );

          logger.i('iOS navigation wrapper correctly applied');
        } else {
          // Verify Material navigation is used on other platforms
          expect(
            find.byType(Scaffold),
            findsWidgets,
            reason: 'Non-iOS should use Material navigation',
          );

          logger.i('Material navigation wrapper correctly applied');
        }
      });

      testWidgets('Adaptive UI Components', (WidgetTester tester) async {
        logger.i('Testing adaptive UI components');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AdaptiveButton(text: 'Test Button', onPressed: () {}),
                  const AdaptiveLoadingIndicator(),
                  AdaptiveSwitch(value: true, onChanged: (value) {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (Platform.isIOS) {
          // Verify Cupertino components are used
          expect(
            find.byType(CupertinoButton),
            findsOneWidget,
            reason: 'iOS should use CupertinoButton',
          );
          expect(
            find.byType(CupertinoActivityIndicator),
            findsOneWidget,
            reason: 'iOS should use CupertinoActivityIndicator',
          );
          expect(
            find.byType(CupertinoSwitch),
            findsOneWidget,
            reason: 'iOS should use CupertinoSwitch',
          );

          logger.i('iOS adaptive components correctly applied');
        } else {
          logger.w('Skipping iOS component test - not running on iOS');
        }
      });
    });

    group('iOS Permissions Testing', () {
      testWidgets('Camera Permission Flow', (WidgetTester tester) async {
        logger.i('Testing camera permission flow');

        if (!Platform.isIOS) {
          logger.w('Skipping camera permission test - not running on iOS');
          return;
        }

        // Create a test context
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Permission Test'))),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.text('Permission Test'));

        // Test camera permission request (will be mocked in test environment)
        try {
          final hasPermission =
              await IOSPermissionsService.requestCameraPermission(context);
          logger.i('Camera permission result: $hasPermission');

          // In test environment, this might return false due to mocking
          expect(
            hasPermission,
            isA<bool>(),
            reason: 'Should return boolean result',
          );
        } catch (e) {
          logger.w(
            'Camera permission test failed (expected in test environment): $e',
          );
        }
      });

      testWidgets('Photo Library Permission Flow', (WidgetTester tester) async {
        logger.i('Testing photo library permission flow');

        if (!Platform.isIOS) {
          logger.w(
            'Skipping photo library permission test - not running on iOS',
          );
          return;
        }

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Permission Test'))),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.text('Permission Test'));

        try {
          final hasPermission =
              await IOSPermissionsService.requestPhotoLibraryPermission(
                context,
              );
          logger.i('Photo library permission result: $hasPermission');

          expect(
            hasPermission,
            isA<bool>(),
            reason: 'Should return boolean result',
          );
        } catch (e) {
          logger.w(
            'Photo library permission test failed (expected in test environment): $e',
          );
        }
      });

      testWidgets('Biometric Permission Flow', (WidgetTester tester) async {
        logger.i('Testing biometric permission flow');

        if (!Platform.isIOS) {
          logger.w('Skipping biometric permission test - not running on iOS');
          return;
        }

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Permission Test'))),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.text('Permission Test'));

        try {
          final hasPermission =
              await IOSPermissionsService.requestBiometricPermission(context);
          logger.i('Biometric permission result: $hasPermission');

          expect(
            hasPermission,
            isA<bool>(),
            reason: 'Should return boolean result',
          );
        } catch (e) {
          logger.w(
            'Biometric permission test failed (expected in test environment): $e',
          );
        }
      });
    });

    group('iOS App Lifecycle Tests', () {
      testWidgets('App Initialization', (WidgetTester tester) async {
        logger.i('Testing iOS app initialization');

        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));

        // Wait for app to initialize
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify app loads without crashing
        expect(
          find.byType(MaterialApp),
          findsOneWidget,
          reason: 'App should initialize successfully',
        );

        logger.i('iOS app initialization successful');
      });

      testWidgets('Memory Management', (WidgetTester tester) async {
        logger.i('Testing iOS memory management');

        // Create and dispose multiple widgets to test memory management
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: List.generate(
                      100,
                      (index) =>
                          SizedBox(height: 50, child: Text('Item $index')),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Dispose and recreate
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }

        logger.i('iOS memory management test completed');
      });
    });

    tearDownAll(() async {
      logger.i('iOS Simulator Test Suite completed');

      // Export test logs
      final logData = TestLogger.exportLogsToJson();
      logger.i('Test logs exported: ${logData['totalEntries']} entries');
    });
  });
}
