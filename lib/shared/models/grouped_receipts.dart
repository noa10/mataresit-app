import 'package:equatable/equatable.dart';
import 'receipt_model.dart';

/// Model for receipts grouped by date
class GroupedReceipts extends Equatable {
  final String dateKey; // YYYY-MM-DD format
  final DateTime date;
  final String displayName; // "Today", "Yesterday", "Jan 15, 2025", etc.
  final List<ReceiptModel> receipts;
  final double totalAmount;
  final int count;

  const GroupedReceipts({
    required this.dateKey,
    required this.date,
    required this.displayName,
    required this.receipts,
    required this.totalAmount,
    required this.count,
  });

  /// Create grouped receipts from a list of receipts for a specific date
  factory GroupedReceipts.fromReceipts({
    required String dateKey,
    required DateTime date,
    required String displayName,
    required List<ReceiptModel> receipts,
  }) {
    final totalAmount = receipts.fold<double>(
      0.0,
      (sum, receipt) => sum + (receipt.totalAmount ?? 0.0),
    );

    return GroupedReceipts(
      dateKey: dateKey,
      date: date,
      displayName: displayName,
      receipts: receipts,
      totalAmount: totalAmount,
      count: receipts.length,
    );
  }

  /// Create empty group for a date
  factory GroupedReceipts.empty({
    required String dateKey,
    required DateTime date,
    required String displayName,
  }) {
    return GroupedReceipts(
      dateKey: dateKey,
      date: date,
      displayName: displayName,
      receipts: const [],
      totalAmount: 0.0,
      count: 0,
    );
  }

  /// Check if group is empty
  bool get isEmpty => receipts.isEmpty;

  /// Check if group is not empty
  bool get isNotEmpty => receipts.isNotEmpty;

  /// Get formatted total amount
  String getFormattedTotal([String currency = 'MYR']) {
    return '$currency ${totalAmount.toStringAsFixed(2)}';
  }

  /// Copy with new values
  GroupedReceipts copyWith({
    String? dateKey,
    DateTime? date,
    String? displayName,
    List<ReceiptModel>? receipts,
    double? totalAmount,
    int? count,
  }) {
    return GroupedReceipts(
      dateKey: dateKey ?? this.dateKey,
      date: date ?? this.date,
      displayName: displayName ?? this.displayName,
      receipts: receipts ?? this.receipts,
      totalAmount: totalAmount ?? this.totalAmount,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
        dateKey,
        date,
        displayName,
        receipts,
        totalAmount,
        count,
      ];
}

/// Helper class for grouping receipts by date
class ReceiptGrouper {
  /// Group receipts by date
  static List<GroupedReceipts> groupReceiptsByDate(
    List<ReceiptModel> receipts, {
    bool sortDescending = true,
  }) {
    if (receipts.isEmpty) return [];

    // Group receipts by date key
    final Map<String, List<ReceiptModel>> groupedMap = {};
    
    for (final receipt in receipts) {
      final transactionDate = receipt.transactionDate ?? receipt.createdAt;
      final dateKey = _getDateKey(transactionDate);
      
      groupedMap.putIfAbsent(dateKey, () => []).add(receipt);
    }

    // Convert to GroupedReceipts list
    final List<GroupedReceipts> groupedList = [];
    
    for (final entry in groupedMap.entries) {
      final dateKey = entry.key;
      final receiptsForDate = entry.value;
      final date = _parseDateKey(dateKey);
      final displayName = _formatGroupDate(date);
      
      // Sort receipts within each group by time (newest first)
      receiptsForDate.sort((a, b) {
        final dateA = a.transactionDate ?? a.createdAt;
        final dateB = b.transactionDate ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      
      groupedList.add(GroupedReceipts.fromReceipts(
        dateKey: dateKey,
        date: date,
        displayName: displayName,
        receipts: receiptsForDate,
      ));
    }

    // Sort groups by date
    groupedList.sort((a, b) {
      return sortDescending 
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date);
    });

    return groupedList;
  }

  /// Get date key in YYYY-MM-DD format
  static String _getDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse date key back to DateTime
  static DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Format date for group display
  static String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(dateOnly).inDays;
      
      if (difference < 7) {
        // Show day name for recent dates
        const dayNames = [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
          'Friday', 'Saturday', 'Sunday'
        ];
        final dayName = dayNames[date.weekday - 1];
        return '$dayName, ${_formatShortDate(date)}';
      } else if (date.year == now.year) {
        // Same year, show month and day
        return _formatShortDate(date);
      } else {
        // Different year, show full date
        return _formatFullDate(date);
      }
    }
  }

  /// Format short date (MMM d)
  static String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Format full date (MMM d, yyyy)
  static String _formatFullDate(DateTime date) {
    return '${_formatShortDate(date)}, ${date.year}';
  }
}
