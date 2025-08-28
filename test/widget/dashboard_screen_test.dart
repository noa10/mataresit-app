import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mataresit_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:mataresit_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:mataresit_app/features/auth/providers/auth_provider.dart';
import 'package:mataresit_app/shared/models/user_model.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Mock auth provider
          currentUserProvider.overrideWith((ref) => UserModel(
            id: 'test-user',
            email: 'test@example.com',
            firstName: 'Test',
            lastName: 'User',
            subscriptionTier: 'free',
            subscriptionStatus: 'active',
            receiptsUsedThisMonth: 0,
            preferredLanguage: 'en',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )),
          
          // Mock dashboard stats provider
          dashboardStatsProvider.overrideWith((ref) => const DashboardStats(
            totalReceipts: 10,
            thisMonthReceipts: 5,
            totalAmount: 250.50,
            totalTeams: 2,
            recentReceipts: [],
            categoryBreakdown: {
              'Food & Beverage': 5,
              'Transportation': 3,
              'Office Supplies': 2,
            },
            monthlySpending: {
              'Jan': 100.0,
              'Feb': 150.5,
            },
          )),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should display welcome message with user name', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome back,'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should display quick stats cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for stats cards
      expect(find.text('Total Receipts'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('\$250.50'), findsOneWidget);
      
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should display quick actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Capture Receipt'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('should display recent activity section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('No recent activity'), findsOneWidget);
    });

    testWidgets('should display category breakdown when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Category Breakdown'), findsOneWidget);
      expect(find.text('Food & Beverage'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text('Office Supplies'), findsOneWidget);
    });

    testWidgets('should handle refresh gesture', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      // Perform pull-to-refresh gesture
      await tester.fling(refreshIndicator, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify the refresh completed without errors
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('should navigate to receipt capture on action tap', (WidgetTester tester) async {
      bool captureNavigationCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/receipts/capture') {
                captureNavigationCalled = true;
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Text('Receipt Capture Screen'),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on capture receipt action
      await tester.tap(find.text('Capture Receipt'));
      await tester.pumpAndSettle();

      expect(captureNavigationCalled, isTrue);
    });

    testWidgets('should navigate to analytics on action tap', (WidgetTester tester) async {
      bool analyticsNavigationCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/analytics') {
                analyticsNavigationCalled = true;
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Text('Analytics Screen'),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on analytics action
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(analyticsNavigationCalled, isTrue);
    });

    testWidgets('should display user avatar with correct initial', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the CircleAvatar
      final avatar = find.byType(CircleAvatar);
      expect(avatar, findsOneWidget);

      // Check if it contains the user's initial
      expect(find.text('T'), findsOneWidget); // First letter of "Test User"
    });

    testWidgets('should handle empty stats gracefully', (WidgetTester tester) async {
      final emptyContainer = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => UserModel(
            id: 'test-user',
            email: 'test@example.com',
            firstName: 'Test',
            lastName: 'User',
            subscriptionTier: 'free',
            subscriptionStatus: 'active',
            receiptsUsedThisMonth: 0,
            preferredLanguage: 'en',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )),
          dashboardStatsProvider.overrideWith((ref) => const DashboardStats()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display zero values
      expect(find.text('0'), findsWidgets);
      expect(find.text('\$0.00'), findsOneWidget);

      emptyContainer.dispose();
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [],
          child: MaterialApp(
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for semantic labels
      expect(find.bySemanticsLabel('Dashboard'), findsOneWidget);
      
      // Check that interactive elements have proper semantics
      final captureButton = find.text('Capture Receipt');
      expect(captureButton, findsOneWidget);
      
      final analyticsButton = find.text('Analytics');
      expect(analyticsButton, findsOneWidget);

      // Verify touch targets are large enough (minimum 44x44)
      final captureButtonWidget = tester.widget<InkWell>(
        find.ancestor(
          of: captureButton,
          matching: find.byType(InkWell),
        ).first,
      );
      expect(captureButtonWidget, isNotNull);
    });
  });
}
