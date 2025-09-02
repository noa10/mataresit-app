import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load claims when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(claimsProvider.notifier).loadClaims(refresh: true);
      ref.read(claimsProvider.notifier).loadClaimStats();
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
    final currentTeam = ref.watch(currentTeamProvider);

    if (currentTeam == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Claims'),
        ),
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
        subtitle: currentTeam.name,
        actions: [
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
              ref.read(claimsProvider.notifier).loadClaimStats();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
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

          // Claims List
          Expanded(
            child: _buildClaimsList(claimsState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClaimDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
    );
  }

  Widget _buildClaimsList(ClaimsState state) {
    if (state.isLoading && state.claims.isEmpty) {
      return const LoadingWidget(message: 'Loading claims...');
    }

    if (state.error != null && state.claims.isEmpty) {
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
        actionLabel: state.filters.hasFilters ? 'Clear Filters' : 'Create Claim',
        onAction: state.filters.hasFilters
            ? () => ref.read(claimsProvider.notifier).clearFilters()
            : _showCreateClaimDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(claimsProvider.notifier).loadClaims(refresh: true);
        await ref.read(claimsProvider.notifier).loadClaimStats();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: state.claims.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.claims.length) {
            // Loading indicator for pagination
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
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
                try {
                  await ref.read(claimsProvider.notifier).submitClaim(claim.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Claim submitted for review'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit claim: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              onApprove: (claim) async {
                try {
                  await ref.read(claimsProvider.notifier).approveClaim(
                    ClaimApprovalRequest(claimId: claim.id),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Claim approved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Claim'),
                    content: const Text(
                      'Are you sure you want to delete this claim? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await ref.read(claimsProvider.notifier).deleteClaim(claim.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Claim deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete claim: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}
