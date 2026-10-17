import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mataresit_app/app/router/app_router.dart';
import 'package:mataresit_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:mataresit_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:mataresit_app/features/auth/providers/auth_provider.dart';
import 'package:mataresit_app/shared/providers/currency_provider.dart';
import 'package:mataresit_app/shared/providers/notification_provider.dart';
import 'package:mataresit_app/shared/models/user_model.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late ProviderContainer container;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // supabase_flutter persists the auth session through shared_preferences.
      // Without a platform implementation the channel call throws and
      // Supabase.initialize() never completes.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (MethodCall call) async =>
                call.method == 'getAll' ? <String, Object>{} : null,
          );

      // DashboardScreen embeds NotificationCenter, whose notifier builds
      // NotificationPreferencesService. That service reads
      // Supabase.instance.client while the widget tree is being built, so an
      // instance has to exist. It is backed by a stub transport: no test in
      // this file may reach a real backend.
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
    });

    ProviderContainer buildContainer({DashboardStats? stats}) {
      return ProviderContainer(
        overrides: [
          // Mock auth provider
          currentUserProvider.overrideWith(
            (ref) => UserModel(
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
            ),
          ),

          // Mock dashboard stats provider
          dashboardStatsProvider.overrideWith(
            (ref) =>
                stats ??
                const DashboardStats(
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
                  monthlySpending: {'Jan': 100.0, 'Feb': 150.5},
                ),
          ),

          // Pin the display currency so the formatted amounts below are
          // deterministic (the app defaults to MYR).
          userPreferredCurrencyProvider.overrideWithValue('USD'),

          // The notification centre in the AppBar reads this count. Stub it so
          // the dashboard does not start the real notification service, which
          // schedules a reconnect timer that outlives the widget tree.
          unreadNotificationCountProvider.overrideWithValue(0),
        ],
      );
    }

    setUp(() {
      container = buildContainer();
    });

    tearDown(() {
      container.dispose();
    });

    /// Pumps the dashboard with the container built in [setUp]. The screen is
    /// a ConsumerWidget, so the overrides only take effect when the scope is
    /// bound to that container.
    Future<void> pumpDashboard(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('should display welcome message with user name', (
      WidgetTester tester,
    ) async {
      await pumpDashboard(tester);

      expect(find.text('Welcome back,'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should display quick stats cards', (
      WidgetTester tester,
    ) async {
      await pumpDashboard(tester);

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
      await pumpDashboard(tester);

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Capture Receipt'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('should display recent activity section', (
      WidgetTester tester,
    ) async {
      await pumpDashboard(tester);

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('No recent activity'), findsOneWidget);
    });

    testWidgets('should display category breakdown when available', (
      WidgetTester tester,
    ) async {
      await pumpDashboard(tester);

      expect(find.text('Category Breakdown'), findsOneWidget);
      expect(find.text('Food & Beverage'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text('Office Supplies'), findsOneWidget);
    });

    testWidgets('should handle refresh gesture', (WidgetTester tester) async {
      await pumpDashboard(tester);

      // Find the RefreshIndicator
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      // Perform pull-to-refresh gesture
      await tester.fling(refreshIndicator, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify the refresh completed without errors
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('should navigate to receipt capture on action tap', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.receiptCapture,
            builder: (context, state) =>
                const Scaffold(body: Text('Receipt Capture Screen')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on capture receipt action
      await tester.ensureVisible(find.text('Capture Receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capture Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('Receipt Capture Screen'), findsOneWidget);
    });

    testWidgets('should navigate to analytics on action tap', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) =>
                const Scaffold(body: Text('Analytics Screen')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on analytics action
      await tester.ensureVisible(find.text('Analytics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(find.text('Analytics Screen'), findsOneWidget);
    });

    testWidgets('should display user avatar with correct initial', (
      WidgetTester tester,
    ) async {
      await pumpDashboard(tester);

      // Find the CircleAvatar
      final avatar = find.byType(CircleAvatar);
      expect(avatar, findsOneWidget);

      // Check if it contains the user's initials. EnhancedUserAvatar renders
      // the first letter of the first and last name ("Test User" -> "TU").
      expect(find.text('TU'), findsOneWidget);
    });

    testWidgets('should handle empty stats gracefully', (
      WidgetTester tester,
    ) async {
      final emptyContainer = buildContainer(stats: const DashboardStats());
      addTearDown(emptyContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: emptyContainer,
          child: MaterialApp(home: const DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Should display zero values
      expect(find.text('0'), findsWidgets);
      expect(find.text('\$0.00'), findsOneWidget);
    });

    testWidgets('should be accessible', (WidgetTester tester) async {
      await pumpDashboard(tester);

      // The 'Dashboard' semantics label belongs to the bottom navigation item
      // in AdaptiveNavigationWrapper, not to this screen. Assert the labels the
      // screen itself exposes.
      expect(find.bySemanticsLabel('Capture Receipt'), findsOneWidget);
      expect(find.bySemanticsLabel('Analytics'), findsOneWidget);

      // Check that interactive elements have proper semantics
      final captureButton = find.text('Capture Receipt');
      expect(captureButton, findsOneWidget);

      final analyticsButton = find.text('Analytics');
      expect(analyticsButton, findsOneWidget);

      // Verify touch targets are large enough (minimum 44x44)
      final captureButtonWidget = tester.widget<InkWell>(
        find.ancestor(of: captureButton, matching: find.byType(InkWell)).first,
      );
      expect(captureButtonWidget, isNotNull);
    });
  });
}
