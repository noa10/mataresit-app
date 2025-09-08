import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/session_info.dart';
import '../services/auth_security_service.dart';

/// State for session management
class SessionManagementState {
  final List<SessionInfo> sessions;
  final bool isLoading;
  final String? error;
  final bool isSigningOut;

  const SessionManagementState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.isSigningOut = false,
  });

  SessionManagementState copyWith({
    List<SessionInfo>? sessions,
    bool? isLoading,
    String? error,
    bool? isSigningOut,
  }) {
    return SessionManagementState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSigningOut: isSigningOut ?? this.isSigningOut,
    );
  }
}

/// Notifier for session management
class SessionManagementNotifier extends StateNotifier<SessionManagementState> {
  SessionManagementNotifier() : super(const SessionManagementState()) {
    _initialize();
  }

  final Logger _logger = Logger();

  /// Initialize session management
  Future<void> _initialize() async {
    await loadSessions();
  }

  /// Load user sessions
  Future<void> loadSessions() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final sessions = await AuthSecurityService.getUserSessions();
      
      state = state.copyWith(
        sessions: sessions,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to load sessions: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sign out from all other sessions
  Future<void> signOutFromOtherSessions() async {
    try {
      state = state.copyWith(isSigningOut: true, error: null);
      
      await AuthSecurityService.signOutFromOtherSessions();
      
      // Reload sessions after signing out
      await loadSessions();
      
      state = state.copyWith(isSigningOut: false);
    } catch (e) {
      _logger.e('Failed to sign out from other sessions: $e');
      state = state.copyWith(
        isSigningOut: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign out from a specific session
  Future<void> signOutFromSession(String sessionId) async {
    try {
      state = state.copyWith(isSigningOut: true, error: null);
      
      await AuthSecurityService.signOutFromSession(sessionId);
      
      // Remove the session from the list
      final updatedSessions = state.sessions
          .where((session) => session.sessionId != sessionId)
          .toList();
      
      state = state.copyWith(
        sessions: updatedSessions,
        isSigningOut: false,
      );
    } catch (e) {
      _logger.e('Failed to sign out from session: $e');
      state = state.copyWith(
        isSigningOut: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get current session
  SessionInfo? get currentSession {
    try {
      return state.sessions.firstWhere((session) => session.isCurrent);
    } catch (e) {
      return null;
    }
  }

  /// Get other sessions (non-current)
  List<SessionInfo> get otherSessions {
    return state.sessions.where((session) => !session.isCurrent).toList();
  }

  /// Get total sessions count
  int get totalSessionsCount {
    return state.sessions.length;
  }

  /// Get other sessions count
  int get otherSessionsCount {
    return otherSessions.length;
  }

  /// Check if there are other active sessions
  bool get hasOtherSessions {
    return otherSessionsCount > 0;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh sessions
  Future<void> refresh() async {
    await loadSessions();
  }
}

/// Provider for session management
final sessionManagementProvider = StateNotifierProvider<SessionManagementNotifier, SessionManagementState>((ref) {
  return SessionManagementNotifier();
});

/// Provider for current sessions list
final currentSessionsProvider = Provider<List<SessionInfo>>((ref) {
  return ref.watch(sessionManagementProvider).sessions;
});

/// Provider for current session
final currentSessionProvider = Provider<SessionInfo?>((ref) {
  final notifier = ref.watch(sessionManagementProvider.notifier);
  return notifier.currentSession;
});

/// Provider for other sessions
final otherSessionsProvider = Provider<List<SessionInfo>>((ref) {
  final notifier = ref.watch(sessionManagementProvider.notifier);
  return notifier.otherSessions;
});

/// Provider for sessions loading state
final sessionsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(sessionManagementProvider).isLoading;
});

/// Provider for sessions error
final sessionsErrorProvider = Provider<String?>((ref) {
  return ref.watch(sessionManagementProvider).error;
});

/// Provider for sign out loading state
final sessionSignOutLoadingProvider = Provider<bool>((ref) {
  return ref.watch(sessionManagementProvider).isSigningOut;
});

/// Provider for other sessions count
final otherSessionsCountProvider = Provider<int>((ref) {
  final notifier = ref.watch(sessionManagementProvider.notifier);
  return notifier.otherSessionsCount;
});

/// Provider for checking if there are other sessions
final hasOtherSessionsProvider = Provider<bool>((ref) {
  final notifier = ref.watch(sessionManagementProvider.notifier);
  return notifier.hasOtherSessions;
});
