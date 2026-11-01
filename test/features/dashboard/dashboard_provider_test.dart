import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/dashboard/providers/dashboard_provider.dart';

void main() {
  test('loads the dashboard summary', () async {
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

    final summary = await container.read(dashboardSummaryProvider.future);
    expect(summary.receiptCount, 1);
    expect(summary.spend, 12);
    expect(summary.recent, hasLength(1));
  });
}
