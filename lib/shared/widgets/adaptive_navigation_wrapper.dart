import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../core/guards/subscription_guard.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/teams/providers/teams_provider.dart';
import 'notification_center.dart';

/// Shared workspace controls and horizontally scrolling navigation.
class AdaptiveNavigationWrapper extends ConsumerStatefulWidget {
  const AdaptiveNavigationWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdaptiveNavigationWrapper> createState() =>
      _AdaptiveNavigationWrapperState();
}

class _AdaptiveNavigationWrapperState
    extends ConsumerState<AdaptiveNavigationWrapper> {
  static const _destinations = [
    _WorkspaceDestination(
      'navigation.overview',
      AppRoutes.dashboard,
      Icons.dashboard_outlined,
      Icons.dashboard,
    ),
    _WorkspaceDestination(
      'navigation.receipts',
      AppRoutes.receipts,
      Icons.receipt_long_outlined,
      Icons.receipt_long,
    ),
    _WorkspaceDestination(
      'navigation.claims',
      AppRoutes.claims,
      Icons.request_page_outlined,
      Icons.request_page,
    ),
    _WorkspaceDestination(
      'navigation.teams',
      AppRoutes.teams,
      Icons.groups_outlined,
      Icons.groups,
    ),
    _WorkspaceDestination(
      'navigation.settings',
      AppRoutes.settings,
      Icons.settings_outlined,
      Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _destinations.indexWhere(
      (destination) =>
          location == destination.route ||
          location.startsWith('${destination.route}/'),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _WorkspaceHeader(),
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: _LedgerBottomBar(
        destinations: _destinations,
        selectedIndex: selectedIndex,
      ),
    );
  }
}

class _WorkspaceDestination {
  const _WorkspaceDestination(
    this.label,
    this.route,
    this.icon,
    this.selectedIcon,
  );

  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
}

/// Standard bottom menu: five primary destinations with a ledger indicator.
class _LedgerBottomBar extends StatelessWidget {
  const _LedgerBottomBar({
    required this.destinations,
    required this.selectedIndex,
  });

  final List<_WorkspaceDestination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _LedgerBottomBarItem(
                    destination: destinations[index],
                    selected: index == selectedIndex,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerBottomBarItem extends StatelessWidget {
  const _LedgerBottomBarItem({
    required this.destination,
    required this.selected,
  });

  final _WorkspaceDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: selected ? null : () => context.go(destination.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                color: selected ? colors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 20,
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends ConsumerWidget {
  const _WorkspaceHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentTeam = ref.watch(currentTeamProvider).currentTeam;
    final teams = ref.watch(teamsProvider).teams;
    final user = ref.watch(currentUserProvider);
    final name = currentTeam?.name ?? 'navigation.personalWorkspace'.tr();
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? 'M' : trimmedName[0].toUpperCase();
    final userName = user?.fullName ?? user?.email ?? 'M';
    final userInitial = userName.trim().isEmpty
        ? 'M'
        : userName.trim()[0].toUpperCase();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'navigation.switchWorkspace'.tr(),
              onSelected: (value) {
                if (value == '__manage_teams__') {
                  context.go(AppRoutes.teams);
                } else {
                  ref
                      .read(currentTeamProvider.notifier)
                      .switchTeam(value.isEmpty ? null : value);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: '',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('navigation.personalWorkspace'.tr()),
                      ),
                      if (currentTeam == null)
                        const Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
                ...teams.map(
                  (team) => PopupMenuItem(
                    value: team.id,
                    child: Row(
                      children: [
                        Expanded(child: Text(team.name)),
                        if (currentTeam?.id == team.id)
                          const Icon(Icons.check, size: 18),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: '__manage_teams__',
                  child: Text('navigation.teams'.tr()),
                ),
              ],
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.outline),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontFamily: 'InstrumentSerif',
                        fontSize: 16,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat.yMMMM(
                            context.locale.toString(),
                          ).format(DateTime.now()).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_more,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (user?.subscriptionTier != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => context.push('/settings'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.outline),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user!.subscriptionTier!,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ],
          const NotificationCenter(showBadge: true),
          IconButton.filled(
            tooltip: 'navigation.uploadReceipts'.tr(),
            icon: const Icon(Icons.upload_outlined, size: 19),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            onPressed: () async {
              final allowed =
                  await SubscriptionGuard.showReceiptLimitDialogIfNeeded(
                    context,
                    ref,
                    additionalReceipts: 1,
                  );
              if (allowed && context.mounted) {
                context.push(AppRoutes.batchUpload);
              }
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'navigation.profile'.tr(),
            onPressed: () => context.push(AppRoutes.profile),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.primary,
              child: Text(userInitial, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
