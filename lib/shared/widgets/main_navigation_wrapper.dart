import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../../core/guards/subscription_guard.dart';


class MainNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends ConsumerState<MainNavigationWrapper> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    NavigationItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Receipts',
      route: AppRoutes.receipts,
    ),
    NavigationItem(
      icon: Icons.request_page_outlined,
      selectedIcon: Icons.request_page,
      label: 'Claims',
      route: AppRoutes.claims,
    ),
    NavigationItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Teams',
      route: AppRoutes.teams,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: AppRoutes.settings,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location.startsWith(_navigationItems[i].route)) {
        setState(() {
          _selectedIndex = i;
        });
        break;
      }
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      context.go(_navigationItems[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 8,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey[600],
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _navigationItems.map((item) {
          final isSelected = _navigationItems.indexOf(item) == _selectedIndex;
          return BottomNavigationBarItem(
            icon: Icon(isSelected ? item.selectedIcon : item.icon),
            label: item.label,
          );
        }).toList(),
      ),
      floatingActionButton: _shouldShowFAB() ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  bool _shouldShowFAB() {
    // Show FAB only on receipts screen
    return _selectedIndex == 1; // Receipts index
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        // Check subscription limits before allowing receipt capture
        final canUpload = await SubscriptionGuard.showReceiptLimitDialogIfNeeded(
          context,
          ref,
          additionalReceipts: 1,
        );

        if (canUpload && mounted) {
          context.push(AppRoutes.receiptCapture);
        }
      },
      tooltip: 'Capture Receipt',
      child: const Icon(Icons.camera_alt),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
