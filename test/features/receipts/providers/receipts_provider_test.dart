import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mataresit_app/features/receipts/providers/receipts_provider.dart';
import 'package:mataresit_app/shared/utils/date_utils.dart';
import 'package:mataresit_app/shared/models/receipt_model.dart';
import 'package:mataresit_app/shared/models/grouped_receipts.dart';

void main() {
  group('ReceiptsProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should have correct defaults', () {
      final state = container.read(receiptsProvider);
      
      expect(state.receipts, isEmpty);
      expect(state.groupedReceipts, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasMore, true);
      expect(state.currentPage, 0);
      expect(state.dateFilter.option, DateFilterOption.last7Days);
      expect(state.searchQuery, '');
      expect(state.statusFilter, isNull);
      expect(state.isGroupedView, true);
    });

    test('date filter should update correctly', () async {
      final notifier = container.read(receiptsProvider.notifier);
      final todayFilter = AppDateUtils.getDateRangeForOption(DateFilterOption.today);
      
      // This would normally trigger a network call, but we're testing state changes
      // In a real test, you'd mock the Supabase client
      notifier.state = notifier.state.copyWith(dateFilter: todayFilter);
      
      final state = container.read(receiptsProvider);
      expect(state.dateFilter.option, DateFilterOption.today);
    });

    test('search query should update correctly', () {
      final notifier = container.read(receiptsProvider.notifier);
      const searchQuery = 'Starbucks';
      
      notifier.state = notifier.state.copyWith(searchQuery: searchQuery);
      
      final state = container.read(receiptsProvider);
      expect(state.searchQuery, searchQuery);
    });

    test('grouped view toggle should work', () {
      final notifier = container.read(receiptsProvider.notifier);
      final initialGroupedView = container.read(receiptsProvider).isGroupedView;
      
      notifier.toggleGroupedView();
      
      final state = container.read(receiptsProvider);
      expect(state.isGroupedView, !initialGroupedView);
    });

    test('hasActiveFilters should return correct value', () {
      final notifier = container.read(receiptsProvider.notifier);
      
      // Initially should have active filters (default is last7Days)
      expect(container.read(receiptsProvider).hasActiveFilters, true);
      
      // Set to all time filter
      notifier.state = notifier.state.copyWith(
        dateFilter: const DateRange(option: DateFilterOption.all),
      );
      expect(container.read(receiptsProvider).hasActiveFilters, false);
      
      // Add search query
      notifier.state = notifier.state.copyWith(searchQuery: 'test');
      expect(container.read(receiptsProvider).hasActiveFilters, true);
    });

    test('totalAmount calculation should be correct', () {
      final notifier = container.read(receiptsProvider.notifier);
      final mockReceipts = [
        ReceiptModel(
          id: '1',
          userId: 'user1',
          totalAmount: 10.50,
          status: ReceiptStatus.active,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ReceiptModel(
          id: '2',
          userId: 'user1',
          totalAmount: 25.75,
          status: ReceiptStatus.active,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      notifier.state = notifier.state.copyWith(receipts: mockReceipts);
      
      final state = container.read(receiptsProvider);
      expect(state.totalAmount, 36.25);
      expect(state.totalCount, 2);
    });
  });

  group('AppDateUtils Tests', () {
    test('getDateRangeForOption should return correct ranges', () {
      final today = AppDateUtils.getDateRangeForOption(DateFilterOption.today);
      expect(today.option, DateFilterOption.today);
      expect(today.startDate, isNotNull);
      expect(today.endDate, isNotNull);
      expect(AppDateUtils.isSameDay(today.startDate!, today.endDate!), true);

      final last7Days = AppDateUtils.getDateRangeForOption(DateFilterOption.last7Days);
      expect(last7Days.option, DateFilterOption.last7Days);
      expect(last7Days.startDate, isNotNull);
      expect(last7Days.endDate, isNotNull);
      
      final daysDifference = last7Days.endDate!.difference(last7Days.startDate!).inDays;
      expect(daysDifference, 6); // 7 days inclusive
    });

    test('formatDisplayDate should return correct formats', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastWeek = today.subtract(const Duration(days: 7));
      
      expect(AppDateUtils.formatDisplayDate(today), 'Today');
      expect(AppDateUtils.formatDisplayDate(yesterday), 'Yesterday');
      expect(AppDateUtils.formatDisplayDate(lastWeek), contains(RegExp(r'[A-Za-z]{3} \d{1,2}')));
    });

    test('isDateInRange should work correctly', () {
      final range = DateRange(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        option: DateFilterOption.custom,
      );
      
      expect(AppDateUtils.isDateInRange(DateTime(2024, 1, 15), range), true);
      expect(AppDateUtils.isDateInRange(DateTime(2024, 2, 1), range), false);
      expect(AppDateUtils.isDateInRange(DateTime(2023, 12, 31), range), false);
    });
  });

  group('GroupedReceipts Tests', () {
    test('should group receipts correctly by date', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      final receipts = [
        ReceiptModel(
          id: '1',
          userId: 'user1',
          totalAmount: 10.50,
          transactionDate: today,
          status: ReceiptStatus.active,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: today,
          updatedAt: today,
        ),
        ReceiptModel(
          id: '2',
          userId: 'user1',
          totalAmount: 25.75,
          transactionDate: yesterday,
          status: ReceiptStatus.active,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
        ReceiptModel(
          id: '3',
          userId: 'user1',
          totalAmount: 15.00,
          transactionDate: today,
          status: ReceiptStatus.active,
          processingStatus: ProcessingStatus.completed,
          isExpense: true,
          isReimbursable: false,
          createdAt: today,
          updatedAt: today,
        ),
      ];
      
      final grouped = ReceiptGrouper.groupReceiptsByDate(receipts);
      
      expect(grouped.length, 2); // Two different dates
      expect(grouped[0].count, 2); // Today should have 2 receipts
      expect(grouped[1].count, 1); // Yesterday should have 1 receipt
      expect(grouped[0].totalAmount, 25.50); // 10.50 + 15.00
      expect(grouped[1].totalAmount, 25.75);
    });
  });
}
