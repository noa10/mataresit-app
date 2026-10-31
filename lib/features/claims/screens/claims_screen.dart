import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../providers/claims_provider.dart';
import '../widgets/claim_list_item.dart';
import '../widgets/claim_filters_widget.dart';
import '../widgets/claim_stats_card.dart';
import '../widgets/create_claim_dialog.dart';
import '../widgets/claim_rejection_dialog.dart';
import '../../teams/providers/teams_provider.dart';

class ClaimsScreen extends ConsumerStatefulWidget {
  const ClaimsScreen({super.key});

  @override
  ConsumerState<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends ConsumerState<ClaimsScreen> {
  final ScrollController _scrollController = ScrollController();
  final Logger _logger = Logger();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load claims when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(claimsProvider.notifier).loadClaims(refresh: true);
      // Load stats but don't fail if it doesn't work
      ref.read(claimsProvider.notifier).loadClaimStats().catchError((error) {
        // Silently ignore stats loading errors for now
        _logger.w(
          'Stats loading failed (expected if database not set up): $error',
        );
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(claimsProvider.notifier).loadMoreClaims();
    }
  }

  void _showCreateClaimDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateClaimDialog(
        onClaimCreated: () {
          ref.read(claimsProvider.notifier).loadClaims(refresh: true);
        },
      ),
    );
  }

  void _showRejectionDialog(ClaimModel claim) {
    showDialog(
      context: context,
      builder: (context) => ClaimRejectionDialog(
        claim: claim,
        onClaimRejected: () {
          ref.read(claimsProvider.notifier).loadClaims(refresh: true);
        },
      ),
    );
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _onClaimTap(ClaimModel claim) {
    ref.read(claimsProvider.notifier).selectClaim(claim);
    context.push('/claims/${claim.id}');
  }

  Future<void> _refresh() async {
    await ref.read(claimsProvider.notifier).loadClaims(refresh: true);
    try {
      await ref.read(claimsProvider.notifier).loadClaimStats();
    } catch (error) {
      // Silently ignore stats loading errors for now
      _logger.w(
        'Stats loading failed (expected if database not set up): $error',
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isError ? colors.onError : colors.onPrimary),
        ),
        backgroundColor: isError ? colors.error : colors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimsState = ref.watch(claimsProvider);
    final currentTeamState = ref.watch(currentTeamProvider);

    if (currentTeamState.currentTeam == null) {
      return Scaffold(
        body: Column(
          children: [
            _buildPageHeader(claimsState, hasTeam: false),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Please select a team to view claims'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildPageHeader(
            claimsState,
            hasTeam: true,
            teamName: currentTeamState.currentTeam!.name,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (claimsState.stats != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: ClaimStatsCard(stats: claimsState.stats!),
                      ),
                    ),
                  if (_showFilters)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: ClaimFiltersWidget(
                          filters: claimsState.filters,
                          onFiltersChanged: (filters) {
                            ref
                                .read(claimsProvider.notifier)
                                .applyFilters(filters);
                          },
                          onClearFilters: () {
                            ref.read(claimsProvider.notifier).clearFilters();
                          },
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    sliver: _buildClaimPanel(claimsState),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(
    ClaimsState claimsState, {
    required bool hasTeam,
    String? teamName,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLAIMS LEDGER',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Claims',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFamily: 'InstrumentSerif',
                        fontSize: 32,
                        height: 1.05,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasTeam
                          ? 'Review and approve expense claims for $teamName.'
                          : 'Select a team to review and approve expense claims.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasTeam)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    ref.read(claimsProvider.notifier).loadClaims(refresh: true);
                    ref.read(claimsProvider.notifier).loadClaimStats().catchError((
                      error,
                    ) {
                      _logger.w(
                        'Stats loading failed (expected if database not set up): $error',
                      );
                    });
                  },
                  tooltip: 'Refresh',
                ),
            ],
          ),
          if (hasTeam) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _showCreateClaimDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Claim'),
                ),
                OutlinedButton.icon(
                  onPressed: _toggleFilters,
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    size: 18,
                  ),
                  label: Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
                  style: claimsState.filters.hasFilters
                      ? OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                        )
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClaimPanel(ClaimsState state) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedSliver(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: _buildPanelHeader(state)),
          SliverToBoxAdapter(child: _buildStatusTabs(state)),
          SliverToBoxAdapter(
            child: Divider(height: 1, color: colors.outlineVariant),
          ),
          if (state.isLoading && state.claims.isEmpty)
            SliverToBoxAdapter(child: _panelBody(_buildLoadingState()))
          else if (state.error != null && state.claims.isEmpty)
            SliverToBoxAdapter(
              child: _panelBody(
                _isSetupError(state.error!)
                    ? _buildDatabaseSetupMessage()
                    : _buildErrorState(state.error!),
              ),
            )
          else if (state.claims.isEmpty)
            SliverToBoxAdapter(child: _panelBody(_buildEmptyState(state)))
          else ...[
            SliverList.separated(
              itemCount: state.claims.length,
              itemBuilder: (context, index) {
                final claim = state.claims[index];
                return ClaimListItem(
                  claim: claim,
                  isFirst: index == 0,
                  isLast: index == state.claims.length - 1 && !state.hasMore,
                  onTap: () => _onClaimTap(claim),
                  onEdit: (claim) {
                    // TODO: Show edit dialog
                  },
                  onSubmit: (claim) async {
                    try {
                      await ref
                          .read(claimsProvider.notifier)
                          .submitClaim(claim.id);
                      if (mounted) {
                        _showSnackBar('Claim submitted for review');
                      }
                    } catch (e) {
                      if (mounted) {
                        _showSnackBar(
                          'Failed to submit claim: $e',
                          isError: true,
                        );
                      }
                    }
                  },
                  onApprove: (claim) async {
                    try {
                      await ref
                          .read(claimsProvider.notifier)
                          .approveClaim(
                            ClaimApprovalRequest(claimId: claim.id),
                          );
                      if (mounted) {
                        _showSnackBar('Claim approved');
                      }
                    } catch (e) {
                      if (mounted) {
                        _showSnackBar(
                          'Failed to approve claim: $e',
                          isError: true,
                        );
                      }
                    }
                  },
                  onReject: _showRejectionDialog,
                  onDelete: (claim) async {
                    try {
                      await ref
                          .read(claimsProvider.notifier)
                          .deleteClaim(claim.id);
                      if (mounted) {
                        _showSnackBar('Claim deleted');
                      }
                    } catch (e) {
                      if (mounted) {
                        _showSnackBar(
                          'Failed to delete claim: $e',
                          isError: true,
                        );
                      }
                    }
                  },
                );
              },
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: colors.outlineVariant),
            ),
            if (state.hasMore)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(9),
                    ),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _panelBody(Widget child) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
      ),
      child: child,
    );
  }

  Widget _buildPanelHeader(ClaimsState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = state.claims.length;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Text(
            'Claims',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            count == 1 ? '1 claim' : '$count claims',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs(ClaimsState state) {
    final colors = Theme.of(context).colorScheme;
    final tabs = <({String label, ClaimStatus? status})>[
      (label: 'All', status: null),
      for (final status in ClaimStatus.values)
        (label: _statusTabLabel(status), status: status),
    ];

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _StatusTab(
                  label: tab.label,
                  selected: state.filters.status == tab.status,
                  onTap: () => _applyStatusFilter(tab.status),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _applyStatusFilter(ClaimStatus? status) {
    final current = ref.read(claimsProvider).filters;
    if (current.status == status) return;
    ref
        .read(claimsProvider.notifier)
        .applyFilters(
          ClaimFilters(
            status: status,
            priority: current.priority,
            claimantId: current.claimantId,
            dateFrom: current.dateFrom,
            dateTo: current.dateTo,
            amountMin: current.amountMin,
            amountMax: current.amountMax,
            category: current.category,
          ),
        );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading claims...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ClaimsState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasFilters = state.filters.hasFilters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 34,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No Claims Found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'No claims match your current filters.\nTry adjusting your search criteria.'
                : 'You haven\'t created any claims yet.\nTap the + button to create your first claim.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (hasFilters)
            OutlinedButton(
              onPressed: () => ref.read(claimsProvider.notifier).clearFilters(),
              child: const Text('Clear Filters'),
            )
          else
            FilledButton.icon(
              onPressed: _showCreateClaimDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Claim'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 34, color: colors.error),
          const SizedBox(height: 12),
          Text(
            'Couldn\'t load claims',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(claimsProvider.notifier).clearError();
              ref.read(claimsProvider.notifier).loadClaims(refresh: true);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  bool _isSetupError(String error) =>
      error.contains('relation "public.claims" does not exist') ||
      error.contains('get_team_claim_stats') ||
      error.contains('PGRST202');

  Widget _buildDatabaseSetupMessage() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          Icon(Icons.construction, size: 40, color: colors.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(
            'Claims Database Setup Required',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The claims feature requires database tables and functions to be set up in Supabase.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Steps:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '1. Set up the claims table in Supabase\n'
                  '2. Create the necessary RPC functions\n'
                  '3. Configure row-level security policies\n'
                  '4. Refresh this screen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref.read(claimsProvider.notifier).clearError();
              ref.read(claimsProvider.notifier).loadClaims(refresh: true);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  static String _statusTabLabel(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.draft:
        return 'Draft';
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.underReview:
        return 'Under review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.paid:
        return 'Paid';
    }
  }
}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = StadiumBorder(
      side: BorderSide(
        color: selected ? colors.onSurface : colors.outlineVariant,
      ),
    );

    return Material(
      color: selected ? colors.onSurface : Colors.transparent,
      shape: border,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: border,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: selected ? colors.surface : colors.onSurfaceVariant,
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
