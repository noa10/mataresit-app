import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-specific logger for iOS testing framework
class TestLogger {
  final String tag;
  static final Map<String, TestLogger> _loggers = {};
  static final List<TestLogEntry> _logs = [];
  static bool _enableFileLogging = true;
  static String? _logFilePath;

  TestLogger._(this.tag);

  /// Get or create a logger for the given tag
  static TestLogger getLogger(String tag) {
    return _loggers.putIfAbsent(tag, () => TestLogger._(tag));
  }

  /// Initialize test logging with optional file output
  static Future<void> initialize({bool enableFileLogging = true}) async {
    _enableFileLogging = enableFileLogging;

    if (_enableFileLogging) {
      try {
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
        _logFilePath = 'test_logs/ios_test_$timestamp.log';

        // Create logs directory if it doesn't exist
        final logDir = Directory('test_logs');
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }

        // Create log file
        final logFile = File(_logFilePath!);
        await logFile.writeAsString('iOS Test Log - ${DateTime.now()}\n');

        info('TestLogger', 'Test logging initialized: $_logFilePath');
      } catch (e) {
        debugPrint('Failed to initialize file logging: $e');
        _enableFileLogging = false;
      }
    }
  }

  /// Log info message
  void i(String message) {
    _log(LogLevel.info, tag, message);
  }

  /// Log debug message
  void d(String message) {
    _log(LogLevel.debug, tag, message);
  }

  /// Log warning message
  void w(String message) {
    _log(LogLevel.warning, tag, message);
  }

  /// Log error message
  void e(String message) {
    _log(LogLevel.error, tag, message);
  }

  /// Log verbose message
  void v(String message) {
    _log(LogLevel.verbose, tag, message);
  }

  /// Static logging methods for convenience
  static void info(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  static void debug(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }

  static void warning(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }

  static void error(String tag, String message) {
    _log(LogLevel.error, tag, message);
  }

  static void verbose(String tag, String message) {
    _log(LogLevel.verbose, tag, message);
  }

  /// Internal logging implementation
  static void _log(LogLevel level, String tag, String message) {
    final timestamp = DateTime.now();
    final entry = TestLogEntry(
      timestamp: timestamp,
      level: level,
      tag: tag,
      message: message,
    );

    _logs.add(entry);

    // Console output
    final formattedMessage =
        '[${_formatTimestamp(timestamp)}] ${level.prefix} $tag: $message';

    switch (level) {
      case LogLevel.error:
        debugPrint('\x1B[31m$formattedMessage\x1B[0m'); // Red
        break;
      case LogLevel.warning:
        debugPrint('\x1B[33m$formattedMessage\x1B[0m'); // Yellow
        break;
      case LogLevel.info:
        debugPrint('\x1B[32m$formattedMessage\x1B[0m'); // Green
        break;
      case LogLevel.debug:
        debugPrint('\x1B[36m$formattedMessage\x1B[0m'); // Cyan
        break;
      case LogLevel.verbose:
        debugPrint('\x1B[37m$formattedMessage\x1B[0m'); // White
        break;
    }

    // File output
    if (_enableFileLogging && _logFilePath != null) {
      _writeToFile(formattedMessage);
    }
  }

  /// Write log entry to file
  static void _writeToFile(String message) {
    try {
      final logFile = File(_logFilePath!);
      logFile.writeAsStringSync('$message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  /// Format timestamp for logging
  static String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Get all log entries
  static List<TestLogEntry> get logs => List.unmodifiable(_logs);

  /// Get logs for specific tag
  static List<TestLogEntry> getLogsForTag(String tag) {
    return _logs.where((entry) => entry.tag == tag).toList();
  }

  /// Get logs for specific level
  static List<TestLogEntry> getLogsForLevel(LogLevel level) {
    return _logs.where((entry) => entry.level == level).toList();
  }

  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
  }

  /// Export logs to JSON
  static Map<String, dynamic> exportLogsToJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'totalEntries': _logs.length,
      'logs': _logs.map((entry) => entry.toJson()).toList(),
    };
  }

  /// Get log file path
  static String? get logFilePath => _logFilePath;
}

/// Log levels
enum LogLevel {
  verbose('V'),
  debug('D'),
  info('I'),
  warning('W'),
  error('E');

  const LogLevel(this.prefix);
  final String prefix;
}

/// Log entry data structure
class TestLogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;

  const TestLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'tag': tag,
      'message': message,
    };
  }

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] ${level.prefix} $tag: $message';
  }
}

// Simple test to validate TestLogger functionality
void main() {
  group('TestLogger', () {
    test('should create logger instance', () {
      final logger = TestLogger.getLogger('TestTag');
      expect(logger.tag, equals('TestTag'));
    });

    test('should log messages without errors', () {
      final logger = TestLogger.getLogger('TestLogger');

      // These should not throw exceptions
      expect(() => logger.i('Info message'), returnsNormally);
      expect(() => logger.d('Debug message'), returnsNormally);
      expect(() => logger.w('Warning message'), returnsNormally);
      expect(() => logger.e('Error message'), returnsNormally);
      expect(() => logger.v('Verbose message'), returnsNormally);
    });

    test('should handle static logging methods', () {
      // These should not throw exceptions
      expect(() => TestLogger.info('Tag', 'Info message'), returnsNormally);
      expect(() => TestLogger.debug('Tag', 'Debug message'), returnsNormally);
      expect(
        () => TestLogger.warning('Tag', 'Warning message'),
        returnsNormally,
      );
      expect(() => TestLogger.error('Tag', 'Error message'), returnsNormally);
      expect(
        () => TestLogger.verbose('Tag', 'Verbose message'),
        returnsNormally,
      );
    });
  });
}
