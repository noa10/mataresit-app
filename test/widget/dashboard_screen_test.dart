import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mataresit_app/app/router/app_router.dart';
import 'package:mataresit_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:mataresit_app/features/dashboard/screens/dashboard_screen.dart';

DashboardSummary summary({bool truncated = false}) => buildDashboardSummary(
  [
    {
      'id': 'review-1',
      'merchant': 'Coffee shop',
      'date': '2026-02-20',
      'created_at': '2026-02-20T10:00:00Z',
      'total': 25,
      'tax': 2,
      'currency': 'MYR',
      'status': 'unreviewed',
      'predicted_category': 'Food',
      'confidence_scores': {'overall': .7},
    },
    {
      'id': 'foreign-1',
      'merchant': 'Hotel',
      'date': '2026-02-10',
      'created_at': '2026-02-10T10:00:00Z',
      'total': 100,
      'tax': 10,
      'currency': 'USD',
      'status': 'reviewed',
    },
  ],
  month: DateTime(2026, 2),
  truncated: truncated,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Future<DashboardSummary> Function() load) => ProviderScope(
    overrides: [dashboardSummaryProvider.overrideWith((ref) => load())],
    child: const MaterialApp(home: DashboardScreen()),
  );

  testWidgets('shows loading and then factual overview sections', (
    tester,
  ) async {
    final result = Completer<DashboardSummary>();
    await tester.pumpWidget(wrap(() => result.future));
    expect(find.text('Loading overview…'), findsOneWidget);
    expect(find.text('Spend'), findsNothing);

    result.complete(summary());
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Spend'), findsOneWidget);
    expect(find.text('MYR 25.00'), findsWidgets);
    expect(find.text('+1 receipt in other currencies'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('70% confidence'), findsOneWidget);
    expect(find.text('Recent receipts'), findsOneWidget);
    expect(find.text('Coffee shop'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows error and retries without a false empty state', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      wrap(() async {
        calls++;
        if (calls == 1) throw StateError('failed');
        return summary();
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overview unavailable'), findsOneWidget);
    expect(
      find.text(
        'No receipts are dated this month. New receipts appear here once their date is saved.',
      ),
      findsNothing,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('MYR 25.00'), findsWidgets);
  });

  testWidgets('labels capped summaries as partial', (tester) async {
    await tester.pumpWidget(wrap(() async => summary(truncated: true)));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Totals and review counts are partial.'),
      findsOneWidget,
    );
  });

  testWidgets('opens receipt detail and refreshes when returning', (
    tester,
  ) async {
    var calls = 0;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/receipts/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) async {
            calls++;
            return summary();
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Coffee shop').first);
    await tester.tap(find.text('Coffee shop').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail review-1'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('keeps the capture and explore routes accessible', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        for (final path in [
          AppRoutes.receiptCapture,
          AppRoutes.search,
          AppRoutes.analytics,
          AppRoutes.missions,
          AppRoutes.leaderboard,
          AppRoutes.duplicates,
          AppRoutes.settings,
        ])
          GoRoute(
            path: path,
            builder: (context, state) => Scaffold(body: Text('Route $path')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith((ref) async => summary()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final routes = <String, String>{
      'Capture receipt': AppRoutes.receiptCapture,
      'search.title': AppRoutes.search,
      'Analytics': AppRoutes.analytics,
      'gamification.missions.title': AppRoutes.missions,
      'gamification.leaderboard.title': AppRoutes.leaderboard,
      'duplicates.title': AppRoutes.duplicates,
      'navigation.settings': AppRoutes.settings,
    };
    for (final entry in routes.entries) {
      final target = find.text(entry.key).first;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text('Route ${entry.value}'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('fits a narrow phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap(() async => summary()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('MYR 25.00'), findsWidgets);
  });
}
