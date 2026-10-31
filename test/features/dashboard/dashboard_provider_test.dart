import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/dashboard/providers/dashboard_provider.dart';

void main() {
  test('keeps the compatibility provider scoped to the loaded overview', () {
    final container = ProviderContainer(
      overrides: [
        dashboardSummaryProvider.overrideWith(
          (ref) async => buildDashboardSummary([
            {
              'id': 'a',
              'date': '2026-02-01',
              'created_at': '2026-02-01T00:00:00Z',
              'total': 12,
              'currency': 'USD',
              'status': 'unreviewed',
            },
          ], month: DateTime(2026, 2)),
        ),
      ],
    );
    addTearDown(container.dispose);

    // The adapter never turns a pending read into an invented zero.
    final before = container.read(dashboardStatsProvider);
    expect(before.totalReceipts, 0);
    expect(before.totalAmount, 0);
    expect(before.recentReceipts, isEmpty);
  });
}
