import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../services/claim_service.dart';
import '../../teams/providers/teams_provider.dart';

/// Claims state
class ClaimsState extends Equatable {
  final List<ClaimModel> claims;
  final ClaimModel? selectedClaim;
  final ClaimFilters filters;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final ClaimStats? stats;

  const ClaimsState({
    this.claims = const [],
    this.selectedClaim,
    this.filters = const ClaimFilters(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
    this.stats,
  });

  ClaimsState copyWith({
    List<ClaimModel>? claims,
    ClaimModel? selectedClaim,
    ClaimFilters? filters,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? currentPage,
    ClaimStats? stats,
  }) {
    return ClaimsState(
      claims: claims ?? this.claims,
      selectedClaim: selectedClaim ?? this.selectedClaim,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      stats: stats ?? this.stats,
    );
  }

  ClaimsState clearError() {
    return copyWith(error: null);
  }

  ClaimsState clearSelectedClaim() {
    return copyWith(selectedClaim: null);
  }

  @override
  List<Object?> get props => [
        claims,
        selectedClaim,
        filters,
        isLoading,
        isLoadingMore,
        error,
        hasMore,
        currentPage,
        stats,
      ];
}

/// Claims notifier
class ClaimsNotifier extends StateNotifier<ClaimsState> {
  final ClaimService _claimService;
  final Ref _ref;
  static const int _pageSize = 20;

  ClaimsNotifier(this._claimService, this._ref) : super(const ClaimsState());

  /// Load claims for current team
  Future<void> loadClaims({bool refresh = false}) async {
    final currentTeam = _ref.read(currentTeamProvider);
    if (currentTeam == null) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
        hasMore: true,
      );
    } else if (state.isLoading || state.isLoadingMore) {
      return; // Already loading
    } else {
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final offset = refresh ? 0 : state.claims.length;
      final claims = await _claimService.getTeamClaims(
        currentTeam.id,
        filters: state.filters.hasFilters ? state.filters : null,
        limit: _pageSize,
        offset: offset,
      );

      if (refresh) {
        state = state.copyWith(
          claims: claims,
          isLoading: false,
          isLoadingMore: false,
          hasMore: claims.length == _pageSize,
          currentPage: 1,
        );
      } else {
        state = state.copyWith(
          claims: [...state.claims, ...claims],
          isLoadingMore: false,
          hasMore: claims.length == _pageSize,
          currentPage: state.currentPage + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Load more claims (pagination)
  Future<void> loadMoreClaims() async {
    if (!state.hasMore || state.isLoadingMore) return;
    await loadClaims(refresh: false);
  }

  /// Apply filters
  Future<void> applyFilters(ClaimFilters filters) async {
    state = state.copyWith(filters: filters);
    await loadClaims(refresh: true);
  }

  /// Clear filters
  Future<void> clearFilters() async {
    state = state.copyWith(filters: const ClaimFilters());
    await loadClaims(refresh: true);
  }

  /// Select a claim
  void selectClaim(ClaimModel claim) {
    state = state.copyWith(selectedClaim: claim);
  }

  /// Clear selected claim
  void clearSelectedClaim() {
    state = state.clearSelectedClaim();
  }

  /// Create a new claim
  Future<String> createClaim(CreateClaimRequest request) async {
    try {
      final claimId = await _claimService.createClaim(request);
      
      // Refresh claims list to include the new claim
      await loadClaims(refresh: true);
      
      return claimId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update a claim
  Future<void> updateClaim(String claimId, UpdateClaimRequest request) async {
    try {
      await _claimService.updateClaim(claimId, request);
      
      // Update the claim in the local state
      final updatedClaims = state.claims.map((claim) {
        if (claim.id == claimId) {
          return claim.copyWith(
            title: request.title ?? claim.title,
            description: request.description ?? claim.description,
            amount: request.amount ?? claim.amount,
            currency: request.currency ?? claim.currency,
            category: request.category ?? claim.category,
            priority: request.priority ?? claim.priority,
            attachments: request.attachments ?? claim.attachments,
            updatedAt: DateTime.now(),
          );
        }
        return claim;
      }).toList();

      state = state.copyWith(claims: updatedClaims);

      // Also update selected claim if it's the one being updated
      if (state.selectedClaim?.id == claimId) {
        final updatedClaim = updatedClaims.firstWhere((c) => c.id == claimId);
        state = state.copyWith(selectedClaim: updatedClaim);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Submit a claim for review
  Future<void> submitClaim(String claimId) async {
    try {
      await _claimService.submitClaim(claimId);
      
      // Update the claim status in local state
      final updatedClaims = state.claims.map((claim) {
        if (claim.id == claimId) {
          return claim.copyWith(
            status: ClaimStatus.pending,
            submittedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        return claim;
      }).toList();

      state = state.copyWith(claims: updatedClaims);

      // Also update selected claim if it's the one being submitted
      if (state.selectedClaim?.id == claimId) {
        final updatedClaim = updatedClaims.firstWhere((c) => c.id == claimId);
        state = state.copyWith(selectedClaim: updatedClaim);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Approve a claim
  Future<void> approveClaim(ClaimApprovalRequest request) async {
    try {
      await _claimService.approveClaim(request);
      
      // Update the claim status in local state
      final updatedClaims = state.claims.map((claim) {
        if (claim.id == request.claimId) {
          return claim.copyWith(
            status: ClaimStatus.approved,
            approvedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        return claim;
      }).toList();

      state = state.copyWith(claims: updatedClaims);

      // Also update selected claim if it's the one being approved
      if (state.selectedClaim?.id == request.claimId) {
        final updatedClaim = updatedClaims.firstWhere((c) => c.id == request.claimId);
        state = state.copyWith(selectedClaim: updatedClaim);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Reject a claim
  Future<void> rejectClaim(ClaimRejectionRequest request) async {
    try {
      await _claimService.rejectClaim(request);
      
      // Update the claim status in local state
      final updatedClaims = state.claims.map((claim) {
        if (claim.id == request.claimId) {
          return claim.copyWith(
            status: ClaimStatus.rejected,
            rejectionReason: request.rejectionReason,
            updatedAt: DateTime.now(),
          );
        }
        return claim;
      }).toList();

      state = state.copyWith(claims: updatedClaims);

      // Also update selected claim if it's the one being rejected
      if (state.selectedClaim?.id == request.claimId) {
        final updatedClaim = updatedClaims.firstWhere((c) => c.id == request.claimId);
        state = state.copyWith(selectedClaim: updatedClaim);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Delete a claim
  Future<void> deleteClaim(String claimId) async {
    try {
      await _claimService.deleteClaim(claimId);
      
      // Remove the claim from local state
      final updatedClaims = state.claims.where((claim) => claim.id != claimId).toList();
      state = state.copyWith(claims: updatedClaims);

      // Clear selected claim if it's the one being deleted
      if (state.selectedClaim?.id == claimId) {
        state = state.clearSelectedClaim();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Load claim statistics
  Future<void> loadClaimStats() async {
    final currentTeam = _ref.read(currentTeamProvider);
    if (currentTeam == null) return;

    try {
      final stats = await _claimService.getTeamClaimStats(currentTeam.id);
      state = state.copyWith(stats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }
}

/// Claims provider
final claimsProvider = StateNotifierProvider<ClaimsNotifier, ClaimsState>((ref) {
  final claimService = ref.watch(claimServiceProvider);
  return ClaimsNotifier(claimService, ref);
});

/// Provider for getting a specific claim by ID
final claimByIdProvider = FutureProvider.family<ClaimModel?, String>((ref, claimId) async {
  final claimService = ref.watch(claimServiceProvider);
  return await claimService.getClaimById(claimId);
});

/// Provider for claim audit trail
final claimAuditTrailProvider = FutureProvider.family<List<ClaimAuditTrailModel>, String>((ref, claimId) async {
  final claimService = ref.watch(claimServiceProvider);
  return await claimService.getClaimAuditTrail(claimId);
});
