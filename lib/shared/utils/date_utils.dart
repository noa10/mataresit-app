import 'package:intl/intl.dart';

/// Date range filter options
enum DateFilterOption {
  all,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  last7Days,
  last30Days,
  custom,
}

/// Date range model
class DateRange {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateFilterOption option;

  const DateRange({
    this.startDate,
    this.endDate,
    required this.option,
  });

  DateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
    DateFilterOption? option,
  }) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      option: option ?? this.option,
    );
  }

  bool get isCustom => option == DateFilterOption.custom;
  bool get hasDateRange => startDate != null || endDate != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.option == option;
  }

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode ^ option.hashCode;
}

/// Utility class for date operations
class DateUtils {
  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDisplayFormat = DateFormat('MMM d');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Get current date without time
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get yesterday's date
  static DateTime get yesterday {
    return today.subtract(const Duration(days: 1));
  }

  /// Get start of current week (Monday)
  static DateTime get startOfWeek {
    final now = today;
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  /// Get end of current week (Sunday)
  static DateTime get endOfWeek {
    return startOfWeek.add(const Duration(days: 6));
  }

  /// Get start of current month
  static DateTime get startOfMonth {
    final now = today;
    return DateTime(now.year, now.month, 1);
  }

  /// Get end of current month
  static DateTime get endOfMonth {
    final now = today;
    return DateTime(now.year, now.month + 1, 0);
  }

  /// Get date range for a specific filter option
  static DateRange getDateRangeForOption(DateFilterOption option) {
    switch (option) {
      case DateFilterOption.all:
        return const DateRange(option: DateFilterOption.all);
      case DateFilterOption.today:
        return DateRange(
          startDate: today,
          endDate: today,
          option: DateFilterOption.today,
        );
      case DateFilterOption.yesterday:
        return DateRange(
          startDate: yesterday,
          endDate: yesterday,
          option: DateFilterOption.yesterday,
        );
      case DateFilterOption.thisWeek:
        return DateRange(
          startDate: startOfWeek,
          endDate: endOfWeek,
          option: DateFilterOption.thisWeek,
        );
      case DateFilterOption.thisMonth:
        return DateRange(
          startDate: startOfMonth,
          endDate: endOfMonth,
          option: DateFilterOption.thisMonth,
        );
      case DateFilterOption.last7Days:
        return DateRange(
          startDate: today.subtract(const Duration(days: 6)),
          endDate: today,
          option: DateFilterOption.last7Days,
        );
      case DateFilterOption.last30Days:
        return DateRange(
          startDate: today.subtract(const Duration(days: 29)),
          endDate: today,
          option: DateFilterOption.last30Days,
        );
      case DateFilterOption.custom:
        return const DateRange(option: DateFilterOption.custom);
    }
  }

  /// Get display name for date filter option
  static String getFilterOptionDisplayName(DateFilterOption option) {
    switch (option) {
      case DateFilterOption.all:
        return 'All Time';
      case DateFilterOption.today:
        return 'Today';
      case DateFilterOption.yesterday:
        return 'Yesterday';
      case DateFilterOption.thisWeek:
        return 'This Week';
      case DateFilterOption.thisMonth:
        return 'This Month';
      case DateFilterOption.last7Days:
        return 'Last 7 Days';
      case DateFilterOption.last30Days:
        return 'Last 30 Days';
      case DateFilterOption.custom:
        return 'Custom Range';
    }
  }

  /// Format date for display
  static String formatDisplayDate(DateTime date) {
    final now = today;
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else if (date.year == now.year) {
      return _shortDisplayFormat.format(date);
    } else {
      return _displayFormat.format(date);
    }
  }

  /// Format date for grouping (used as section headers)
  static String formatGroupDate(DateTime date) {
    final now = today;
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE, MMM d').format(date);
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    }
  }

  /// Format date range for display
  static String formatDateRange(DateRange dateRange) {
    if (!dateRange.hasDateRange) {
      return getFilterOptionDisplayName(dateRange.option);
    }

    final start = dateRange.startDate;
    final end = dateRange.endDate;

    if (start == null && end == null) {
      return 'All Time';
    }

    if (start != null && end != null && isSameDay(start, end)) {
      return formatDisplayDate(start);
    }

    final startStr = start != null ? _displayFormat.format(start) : 'Beginning';
    final endStr = end != null ? _displayFormat.format(end) : 'Now';

    return '$startStr - $endStr';
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get date key for grouping (YYYY-MM-DD format)
  static String getDateKey(DateTime date) {
    return _dayFormat.format(date);
  }

  /// Parse date key back to DateTime
  static DateTime parseDateKey(String dateKey) {
    return _dayFormat.parse(dateKey);
  }

  /// Check if date is within range
  static bool isDateInRange(DateTime date, DateRange range) {
    if (!range.hasDateRange) return true;

    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (range.startDate != null && dateOnly.isBefore(range.startDate!)) {
      return false;
    }
    
    if (range.endDate != null && dateOnly.isAfter(range.endDate!)) {
      return false;
    }
    
    return true;
  }

  /// Get relative time string (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get default date range (last 7 days)
  static DateRange get defaultDateRange => getDateRangeForOption(DateFilterOption.last7Days);
}
