import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../shared/widgets/app_bar_with_actions.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';
import '../providers/claims_provider.dart';
import '../widgets/claim_list_item.dart';
import '../widgets/claim_filters_widget.dart';
import '../widgets/claim_stats_card.dart';
import '../widgets/create_claim_dialog.dart';
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

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _onClaimTap(ClaimModel claim) {
    ref.read(claimsProvider.notifier).selectClaim(claim);
    context.push('/claims/${claim.id}');
  }

  @override
  Widget build(BuildContext context) {
    final claimsState = ref.watch(claimsProvider);
    final currentTeamState = ref.watch(currentTeamProvider);

    if (currentTeamState.currentTeam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claims')),
        body: const Center(
          child: Text(
            'Please select a team to view claims',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBarWithActions(
        title: 'Claims',
        subtitle: currentTeamState.currentTeam!.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateClaimDialog,
            tooltip: 'New Claim',
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: claimsState.filters.hasFilters
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _toggleFilters,
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(claimsProvider.notifier).loadClaims(refresh: true);
              ref.read(claimsProvider.notifier).loadClaimStats().catchError((
                error,
              ) {
                // Silently ignore stats loading errors for now
                _logger.w(
                  'Stats loading failed (expected if database not set up): $error',
                );
              });
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildScrollableBody(claimsState),
    );
  }

  Widget _buildScrollableBody(ClaimsState claimsState) {
    // If we have claims or are loading, use the custom scroll view
    if (claimsState.claims.isNotEmpty || claimsState.isLoading) {
      return _buildCustomScrollView(claimsState);
    }

    // For empty states and errors, use a simple scrollable column
    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics Card
          if (claimsState.stats != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClaimStatsCard(stats: claimsState.stats!),
            ),

          // Filters
          if (_showFilters)
            ClaimFiltersWidget(
              filters: claimsState.filters,
              onFiltersChanged: (filters) {
                ref.read(claimsProvider.notifier).applyFilters(filters);
              },
              onClearFilters: () {
                ref.read(claimsProvider.notifier).clearFilters();
              },
            ),

          // Claims List (for empty states)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildClaimsList(claimsState),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomScrollView(ClaimsState claimsState) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(claimsProvider.notifier).loadClaims(refresh: true);
        try {
          await ref.read(claimsProvider.notifier).loadClaimStats();
        } catch (error) {
          // Silently ignore stats loading errors for now
          _logger.w(
            'Stats loading failed (expected if database not set up): $error',
          );
        }
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Statistics Card
          if (claimsState.stats != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClaimStatsCard(stats: claimsState.stats!),
              ),
            ),

          // Filters
          if (_showFilters)
            SliverToBoxAdapter(
              child: ClaimFiltersWidget(
                filters: claimsState.filters,
                onFiltersChanged: (filters) {
                  ref.read(claimsProvider.notifier).applyFilters(filters);
                },
                onClearFilters: () {
                  ref.read(claimsProvider.notifier).clearFilters();
                },
              ),
            ),

          // Claims List
          _buildClaimsSliver(claimsState),
        ],
      ),
    );
  }

  Widget _buildClaimsSliver(ClaimsState state) {
    if (state.isLoading && state.claims.isEmpty) {
      return const SliverFillRemaining(
        child: LoadingWidget(message: 'Loading claims...'),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= state.claims.length) {
              // Loading indicator for pagination
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final claim = state.claims[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClaimListItem(
                claim: claim,
                onTap: () => _onClaimTap(claim),
                onEdit: (claim) {
                  // TODO: Show edit dialog
                },
                onSubmit: (claim) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(claimsProvider.notifier).submitClaim(claim.id);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Claim submitted for review'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit claim: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onApprove: (claim) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(claimsProvider.notifier)
                        .approveClaim(ClaimApprovalRequest(claimId: claim.id));
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Claim approved'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to approve claim: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onReject: (claim) async {
                  // TODO: Show rejection dialog with reason
                },
                onDelete: (claim) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(claimsProvider.notifier).deleteClaim(claim.id);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Claim deleted'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete claim: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            );
          },
          childCount: state.claims.length + (state.hasMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildClaimsList(ClaimsState state) {
    if (state.isLoading && state.claims.isEmpty) {
      return const LoadingWidget(message: 'Loading claims...');
    }

    if (state.error != null && state.claims.isEmpty) {
      // Check if this is a database setup issue
      if (state.error!.contains('relation "public.claims" does not exist') ||
          state.error!.contains('get_team_claim_stats') ||
          state.error!.contains('PGRST202')) {
        return _buildDatabaseSetupMessage();
      }

      return AppErrorWidget(
        error: state.error!,
        onRetry: () {
          ref.read(claimsProvider.notifier).clearError();
          ref.read(claimsProvider.notifier).loadClaims(refresh: true);
        },
      );
    }

    if (state.claims.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No Claims Found',
        message: state.filters.hasFilters
            ? 'No claims match your current filters.\nTry adjusting your search criteria.'
            : 'You haven\'t created any claims yet.\nTap the + button to create your first claim.',
        actionLabel: state.filters.hasFilters
            ? 'Clear Filters'
            : 'Create Claim',
        onAction: state.filters.hasFilters
            ? () => ref.read(claimsProvider.notifier).clearFilters()
            : _showCreateClaimDialog,
      );
    }

    // This method is now only used for empty states, errors, and loading
    // The actual claims list is handled by _buildClaimsSliver in CustomScrollView
    return const SizedBox.shrink();
  }

  Widget _buildDatabaseSetupMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Claims Database Setup Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The claims feature requires database tables and functions to be set up in Supabase.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Steps:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Set up the claims table in Supabase\n'
                    '2. Create the necessary RPC functions\n'
                    '3. Configure row-level security policies\n'
                    '4. Refresh this screen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(claimsProvider.notifier).clearError();
                ref.read(claimsProvider.notifier).loadClaims(refresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
