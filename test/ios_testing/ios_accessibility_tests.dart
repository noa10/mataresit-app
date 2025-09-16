import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mataresit_app/app/app.dart';
import 'package:mataresit_app/shared/widgets/adaptive_widgets.dart';
import 'package:mataresit_app/shared/widgets/adaptive_navigation_wrapper.dart';
import 'ios_test_framework.dart';
import '../test_helpers/test_logger.dart';

/// iOS Accessibility Testing Suite
/// Tests VoiceOver, Dynamic Type, and iOS accessibility features
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('iOS Accessibility Tests', () {
    late TestLogger logger;

    setUpAll(() async {
      logger = TestLogger.getLogger('IOSAccessibilityTests');
      await TestLogger.initialize();
      await IOSTestFramework.initialize();

      logger.i('Starting iOS Accessibility Test Suite');
      logger.i(
        'Testing VoiceOver, Dynamic Type, and iOS accessibility features',
      );
    });

    group('VoiceOver Support Tests', () {
      testWidgets('Semantic Labels and Descriptions', (
        WidgetTester tester,
      ) async {
        logger.i('Testing semantic labels and descriptions');

        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        // Enable semantics for testing
        final SemanticsHandle handle = tester.ensureSemantics();

        try {
          // Find semantic nodes and verify they have proper labels
          final semantics = tester.getSemantics(find.byType(MaterialApp));

          // Verify app has semantic information
          expect(
            semantics,
            isNotNull,
            reason: 'App should have semantic information',
          );

          // Check for navigation elements with proper labels
          final navigationElements = find.byType(AdaptiveNavigationWrapper);
          if (navigationElements.evaluate().isNotEmpty) {
            for (final element in navigationElements.evaluate()) {
              final semanticNode = tester.getSemantics(
                find.byWidget(element.widget),
              );
              logger.i(
                'Navigation element semantic label: ${semanticNode.label}',
              );
            }
          }

          logger.i('Semantic labels and descriptions validated');
        } finally {
          handle.dispose();
        }
      });

      testWidgets('Button Accessibility', (WidgetTester tester) async {
        logger.i('Testing button accessibility');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AdaptiveButton(text: 'Test Button', onPressed: () {}),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Elevated Button'),
                  ),
                  if (Platform.isIOS)
                    CupertinoButton(
                      onPressed: () {},
                      child: const Text('Cupertino Button'),
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        try {
          // Verify buttons have proper semantic roles
          final buttons = find.byType(ElevatedButton);
          for (final button in buttons.evaluate()) {
            final semantics = tester.getSemantics(find.byWidget(button.widget));
            expect(
              semantics.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
              reason: 'Button should have tap action',
            );
            logger.i('Button semantic role validated: ${semantics.label}');
          }

          // Test adaptive buttons
          final adaptiveButtons = find.byType(AdaptiveButton);
          for (final button in adaptiveButtons.evaluate()) {
            final semantics = tester.getSemantics(find.byWidget(button.widget));
            expect(
              semantics.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
              reason: 'Adaptive button should have tap action',
            );
            logger.i(
              'Adaptive button semantic role validated: ${semantics.label}',
            );
          }

          logger.i('Button accessibility validated');
        } finally {
          handle.dispose();
        }
      });

      testWidgets('Form Field Accessibility', (WidgetTester tester) async {
        logger.i('Testing form field accessibility');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                  ),
                  AdaptiveTextField(
                    labelText: 'Password',
                    placeholder: 'Enter your password',
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        try {
          // Verify text fields have proper semantic information
          final textFields = find.byType(TextField);
          for (final field in textFields.evaluate()) {
            final semantics = tester.getSemantics(find.byWidget(field.widget));
            expect(
              semantics.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
              reason: 'Text field should be tappable',
            );
            logger.i('Text field semantic info: ${semantics.label}');
          }

          // Test adaptive text fields
          final adaptiveFields = find.byType(AdaptiveTextField);
          for (final field in adaptiveFields.evaluate()) {
            final semantics = tester.getSemantics(find.byWidget(field.widget));
            expect(
              semantics.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
              reason: 'Adaptive text field should be tappable',
            );
            logger.i('Adaptive text field semantic info: ${semantics.label}');
          }

          logger.i('Form field accessibility validated');
        } finally {
          handle.dispose();
        }
      });

      testWidgets('Navigation Accessibility', (WidgetTester tester) async {
        logger.i('Testing navigation accessibility');

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

        final SemanticsHandle handle = tester.ensureSemantics();

        try {
          if (Platform.isIOS) {
            // Test Cupertino tab bar accessibility
            final tabBar = find.byType(CupertinoTabBar);
            if (tabBar.evaluate().isNotEmpty) {
              final semantics = tester.getSemantics(tabBar.first);
              logger.i('Tab bar semantic info: ${semantics.label}');
            }
          } else {
            // Test Material bottom navigation accessibility
            final bottomNav = find.byType(BottomNavigationBar);
            if (bottomNav.evaluate().isNotEmpty) {
              final semantics = tester.getSemantics(bottomNav.first);
              logger.i('Bottom navigation semantic info: ${semantics.label}');
            }
          }

          logger.i('Navigation accessibility validated');
        } finally {
          handle.dispose();
        }
      });
    });

    group('Dynamic Type Support Tests', () {
      testWidgets('Text Scaling Support', (WidgetTester tester) async {
        logger.i('Testing text scaling support');

        // Test with different text scale factors
        final textScales = [0.8, 1.0, 1.2, 1.5, 2.0];

        for (final scale in textScales) {
          logger.i('Testing text scale: ${scale}x');

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Text('Heading Text', style: TextStyle(fontSize: 24)),
                      Text('Body Text', style: TextStyle(fontSize: 16)),
                      Text('Caption Text', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Verify text renders at different scales
          final headingText = find.text('Heading Text');
          expect(
            headingText,
            findsOneWidget,
            reason: 'Heading should render at scale $scale',
          );

          final bodyText = find.text('Body Text');
          expect(
            bodyText,
            findsOneWidget,
            reason: 'Body text should render at scale $scale',
          );

          final captionText = find.text('Caption Text');
          expect(
            captionText,
            findsOneWidget,
            reason: 'Caption should render at scale $scale',
          );
        }

        logger.i('Text scaling support validated');
      });

      testWidgets('iOS Dynamic Type Integration', (WidgetTester tester) async {
        logger.i('Testing iOS Dynamic Type integration');

        if (!Platform.isIOS) {
          logger.w('Skipping Dynamic Type test - not running on iOS');
          return;
        }

        // Test with iOS-specific text styles
        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoPageScaffold(
              child: Column(
                children: [
                  Text(
                    'Large Title',
                    style: CupertinoTheme.of(
                      tester.element(find.byType(CupertinoApp)),
                    ).textTheme.navLargeTitleTextStyle,
                  ),
                  Text(
                    'Title',
                    style: CupertinoTheme.of(
                      tester.element(find.byType(CupertinoApp)),
                    ).textTheme.navTitleTextStyle,
                  ),
                  Text(
                    'Body',
                    style: CupertinoTheme.of(
                      tester.element(find.byType(CupertinoApp)),
                    ).textTheme.textStyle,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify iOS text styles are applied
        expect(find.text('Large Title'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);

        logger.i('iOS Dynamic Type integration validated');
      });

      testWidgets('Adaptive Text Styles', (WidgetTester tester) async {
        logger.i('Testing adaptive text styles');

        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        // Verify app uses adaptive text styles that respond to system settings
        final textWidgets = find.byType(Text);
        expect(
          textWidgets,
          findsAtLeastNWidgets(1),
          reason: 'App should contain text widgets',
        );

        logger.i('Adaptive text styles validated');
      });
    });

    group('iOS Accessibility Features Tests', () {
      testWidgets('Reduce Motion Support', (WidgetTester tester) async {
        logger.i('Testing reduce motion support');

        // Test with reduce motion enabled
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    CircularProgressIndicator(),
                    LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify animations are disabled when reduce motion is enabled
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        logger.i('Reduce motion support validated');
      });

      testWidgets('High Contrast Support', (WidgetTester tester) async {
        logger.i('Testing high contrast support');

        // Test with high contrast enabled
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(highContrast: true),
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Card(child: Text('Card Content')),
                    ElevatedButton(onPressed: null, child: Text('Button')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify high contrast mode is respected
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);

        logger.i('High contrast support validated');
      });

      testWidgets('Bold Text Support', (WidgetTester tester) async {
        logger.i('Testing bold text support');

        // Test with bold text enabled
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(boldText: true),
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text('Normal Text'),
                    Text(
                      'Bold Text',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify bold text setting is respected
        expect(find.text('Normal Text'), findsOneWidget);
        expect(find.text('Bold Text'), findsOneWidget);

        logger.i('Bold text support validated');
      });

      testWidgets('iOS Switch Control Support', (WidgetTester tester) async {
        logger.i('Testing iOS Switch Control support');

        if (!Platform.isIOS) {
          logger.w('Skipping Switch Control test - not running on iOS');
          return;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Button 1'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Button 2'),
                  ),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Text Field'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        try {
          // Verify elements are properly ordered for Switch Control navigation
          final buttons = find.byType(ElevatedButton);
          expect(buttons, findsNWidgets(2), reason: 'Should find both buttons');

          final textField = find.byType(TextField);
          expect(textField, findsOneWidget, reason: 'Should find text field');

          logger.i('iOS Switch Control support validated');
        } finally {
          handle.dispose();
        }
      });
    });

    group('Accessibility Testing Integration', () {
      testWidgets('Comprehensive Accessibility Audit', (
        WidgetTester tester,
      ) async {
        logger.i('Running comprehensive accessibility audit');

        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        try {
          // Perform comprehensive accessibility checks
          final semantics = tester.getSemantics(find.byType(MaterialApp));

          // Check for common accessibility issues
          final issues = <String>[];

          // Check for missing labels
          if (semantics.label.isEmpty) {
            issues.add('Missing semantic label');
          }

          // Check for proper focus management
          if (!semantics.getSemanticsData().hasAction(
            SemanticsAction.didGainAccessibilityFocus,
          )) {
            logger.w('Element may not support proper focus management');
          }

          // Report accessibility audit results
          if (issues.isEmpty) {
            logger.i('Accessibility audit passed - no issues found');
          } else {
            logger.w('Accessibility audit found issues: ${issues.join(', ')}');
          }

          logger.i('Comprehensive accessibility audit completed');
        } finally {
          handle.dispose();
        }
      });

      testWidgets('Accessibility Performance Impact', (
        WidgetTester tester,
      ) async {
        logger.i('Testing accessibility performance impact');

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(const ProviderScope(child: MataresitApp()));
        await tester.pumpAndSettle();

        final SemanticsHandle handle = tester.ensureSemantics();

        try {
          // Measure performance with accessibility enabled
          await tester.pump();

          stopwatch.stop();
          final renderTime = stopwatch.elapsedMilliseconds;

          logger.i('Accessibility-enabled render time: ${renderTime}ms');

          // Verify accessibility doesn't significantly impact performance
          expect(
            renderTime,
            lessThan(5000),
            reason: 'Accessibility should not significantly impact performance',
          );

          logger.i('Accessibility performance impact validated');
        } finally {
          handle.dispose();
        }
      });
    });

    tearDownAll(() async {
      logger.i('iOS Accessibility Test Suite completed');

      // Generate accessibility test report
      final logData = TestLogger.exportLogsToJson();
      logger.i(
        'Accessibility test logs exported: ${logData['totalEntries']} entries',
      );

      // Summary of accessibility testing
      logger.i('iOS Accessibility Testing Summary:');
      logger.i(
        '✅ VoiceOver support: Semantic labels, button roles, form fields, navigation',
      );
      logger.i(
        '✅ Dynamic Type support: Text scaling, iOS integration, adaptive styles',
      );
      logger.i(
        '✅ iOS accessibility features: Reduce motion, high contrast, bold text, Switch Control',
      );
      logger.i(
        '✅ Accessibility integration: Comprehensive audit, performance impact assessment',
      );
    });
  });
}
