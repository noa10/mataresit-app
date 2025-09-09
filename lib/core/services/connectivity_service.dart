import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Service for managing network connectivity and offline/online states
class ConnectivityService {
  static final Logger _logger = Logger();
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Stream of connectivity status (true = online, false = offline)
  static Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  static bool _isOnline = false;
  static bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  static Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityStatus,
        onError: (error) {
          _logger.e('Connectivity stream error: $error');
        },
      );

      _logger.i('Connectivity Service initialized');
    } catch (e) {
      _logger.e('Failed to initialize Connectivity Service: $e');
      rethrow;
    }
  }

  /// Update connectivity status
  static void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Check if any connection type indicates online status
    _isOnline = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    _logger.d('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');

    // Notify listeners
    _connectivityController.add(_isOnline);

    // Trigger sync when coming back online
    if (!wasOnline && _isOnline) {
      _logger.i('Device came back online - triggering sync');
      _onConnectivityRestored();
    }
  }

  /// Handle connectivity restoration
  static void _onConnectivityRestored() {
    // This will be called by the sync service
    // We'll implement this in the sync service
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _subscription?.cancel();
    await _connectivityController.close();
  }

  /// Check if device has internet connectivity (with actual network test)
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }

      // TODO: Add actual internet connectivity test (ping a reliable server)
      // For now, we'll assume connectivity means internet access
      return true;
    } catch (e) {
      _logger.e('Failed to check internet connection: $e');
      return false;
    }
  }
}

/// Connectivity state
class ConnectivityState {
  final bool isOnline;
  final ConnectivityResult connectionType;
  final DateTime lastOnline;

  const ConnectivityState({
    required this.isOnline,
    required this.connectionType,
    required this.lastOnline,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    ConnectivityResult? connectionType,
    DateTime? lastOnline,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      connectionType: connectionType ?? this.connectionType,
      lastOnline: lastOnline ?? this.lastOnline,
    );
  }
}

/// Connectivity notifier
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  StreamSubscription<bool>? _subscription;

  ConnectivityNotifier()
    : super(
        ConnectivityState(
          isOnline: ConnectivityService.isOnline,
          connectionType: ConnectivityResult.none,
          lastOnline: DateTime.now(),
        ),
      ) {
    _initializeConnectivity();
  }

  void _initializeConnectivity() {
    _subscription = ConnectivityService.connectivityStream.listen((isOnline) {
      state = state.copyWith(
        isOnline: isOnline,
        lastOnline: isOnline ? DateTime.now() : state.lastOnline,
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Connectivity provider
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier();
    });

/// Simple online status provider
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});
