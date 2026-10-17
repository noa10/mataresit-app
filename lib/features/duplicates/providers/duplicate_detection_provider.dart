import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../core/network/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../models/duplicate_models.dart';
import '../services/duplicate_detection_service.dart';

/// Duplicate detection state.
class DuplicateDetectionState extends Equatable {
  /// Scan settings; edited by the config form before a scan runs.
  final ScanConfig config;

  /// Result of the most recent scan, or null before the first scan.
  final ScanResult? result;

  final bool isScanning;
  final bool isDeleting;

  /// Last error message, cleared on the next successful action.
  final String? error;

  /// Ids the user has ticked for deletion.
  final Set<String> selectedIds;

  const DuplicateDetectionState({
    this.config = const ScanConfig(),
    this.result,
    this.isScanning = false,
    this.isDeleting = false,
    this.error,
    this.selectedIds = const {},
  });

  DuplicateDetectionState copyWith({
    ScanConfig? config,
    ScanResult? result,
    bool? isScanning,
    bool? isDeleting,
    String? error,
    Set<String>? selectedIds,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return DuplicateDetectionState(
      config: config ?? this.config,
      result: clearResult ? null : (result ?? this.result),
      isScanning: isScanning ?? this.isScanning,
      isDeleting: isDeleting ?? this.isDeleting,
      error: clearError ? null : (error ?? this.error),
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  /// Receipts ticked for deletion.
  int get selectedCount => selectedIds.length;

  bool get hasResult => result != null;

  /// Whether the displayed scan is old enough to warn the user about.
  bool get isResultStale => result?.isStale ?? false;

  @override
  List<Object?> get props => [
    config,
    result,
    isScanning,
    isDeleting,
    error,
    selectedIds,
  ];
}

/// Duplicate detection notifier.
class DuplicateDetectionNotifier
    extends StateNotifier<DuplicateDetectionState> {
  final DuplicateDetectionService _service;
  final Ref _ref;
  final Logger _logger = Logger();

  DuplicateDetectionNotifier(this._service, this._ref)
    : super(const DuplicateDetectionState());

  /// Update the scan settings shown in the config form.
  void updateConfig(ScanConfig config) {
    state = state.copyWith(config: config);
  }

  /// Scan the active workspace for duplicates.
  ///
  /// Re-scans are explicit only: nothing here re-runs automatically after a
  /// delete, so the user keeps the result they acted on.
  Future<void> scan() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    final teamId = _ref.read(currentTeamProvider).currentTeam?.id;

    state = state.copyWith(
      isScanning: true,
      clearError: true,
      selectedIds: const {},
    );

    try {
      final result = await _service.scan(
        config: state.config,
        userId: user.id,
        teamId: teamId,
      );
      state = state.copyWith(isScanning: false, result: result);
      _logger.i(
        'Duplicate scan finished: ${result.groups.length} groups from '
        '${result.scannedCount} receipts',
      );
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }

  /// Tick or untick one receipt.
  void toggleSelection(String receiptId) {
    final selection = {...state.selectedIds};
    if (!selection.remove(receiptId)) {
      selection.add(receiptId);
    }
    state = state.copyWith(selectedIds: selection);
  }

  /// Tick every receipt that a delete may remove (all but the kept one).
  void selectAllDuplicates() {
    final result = state.result;
    if (result == null) return;
    state = state.copyWith(selectedIds: result.deletableReceiptIds.toSet());
  }

  /// Untick everything.
  void clearSelection() {
    state = state.copyWith(selectedIds: const {});
  }

  /// Delete the ticked receipts.
  ///
  /// Returns how many receipts were deleted; `0` means nothing was removed and
  /// [DuplicateDetectionState.error] holds the reason.
  Future<int> deleteSelected() => _delete(state.selectedIds);

  /// Delete every duplicate except the oldest receipt of each group.
  Future<int> deleteAllKeepingOldest() {
    final result = state.result;
    if (result == null) return Future.value(0);
    return _delete(result.deletableReceiptIds.toSet());
  }

  Future<int> _delete(Set<String> ids) async {
    final result = state.result;
    if (result == null || ids.isEmpty || state.isDeleting) return 0;

    state = state.copyWith(isDeleting: true, clearError: true);

    try {
      await _service.deleteReceipts(ids.toList());

      // Drop the deleted receipts from the state we already hold instead of
      // re-scanning, so the list the user acted on stays on screen.
      state = state.copyWith(
        isDeleting: false,
        result: result.withoutReceipts(ids),
        selectedIds: state.selectedIds.difference(ids),
      );
      _logger.i('Deleted ${ids.length} duplicate receipts');
      return ids.length;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      return 0;
    }
  }

  /// Discard the current result and error.
  void reset() {
    state = state.copyWith(clearResult: true, clearError: true);
  }
}

/// Service provider for duplicate detection.
final duplicateDetectionServiceProvider = Provider<DuplicateDetectionService>((
  ref,
) {
  return DuplicateDetectionService(ref.watch(supabaseClientProvider));
});

/// Duplicate detection provider.
final duplicateDetectionProvider =
    StateNotifierProvider<DuplicateDetectionNotifier, DuplicateDetectionState>(
      (ref) => DuplicateDetectionNotifier(
        ref.watch(duplicateDetectionServiceProvider),
        ref,
      ),
    );
