import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/analytics/providers/analytics_provider.dart';

void main() {
  test('folds categories beyond the palette into an Other slice', () {
    final spending = <String, double>{
      for (var index = 0; index < 10; index++)
        'Category ${index + 1}': (10 - index).toDouble(),
    };
    final container = ProviderContainer(
      overrides: [
        analyticsDataProvider.overrideWithValue(
          AnalyticsData(
            categorySpending: spending,
            totalSpending: spending.values.fold(0, (sum, value) => sum + value),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final chart = container.read(categoryPieChartProvider);

    expect(chart.sections, hasLength(8));
    expect(chart.entries, hasLength(8));
    expect(chart.entries.last.label, 'Other');
    expect(chart.entries.last.value, 6);
    expect(
      chart.entries.fold<double>(0, (sum, entry) => sum + entry.value),
      spending.values.fold<double>(0, (sum, value) => sum + value),
    );
  });
}
