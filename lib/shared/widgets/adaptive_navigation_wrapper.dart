import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../../core/guards/subscription_guard.dart';

/// Adaptive navigation wrapper that uses platform-specific navigation patterns
class AdaptiveNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AdaptiveNavigationWrapper({super.key, required this.child});

  @override
  ConsumerState<AdaptiveNavigationWrapper> createState() =>
      _AdaptiveNavigationWrapperState();
}

class _AdaptiveNavigationWrapperState
    extends ConsumerState<AdaptiveNavigationWrapper> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      cupertinoIcon: CupertinoIcons.chart_bar_alt_fill,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    NavigationItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      cupertinoIcon: CupertinoIcons.doc_text_fill,
      label: 'Receipts',
      route: AppRoutes.receipts,
    ),
    NavigationItem(
      icon: Icons.request_page_outlined,
      selectedIcon: Icons.request_page,
      cupertinoIcon: CupertinoIcons.folder_fill,
      label: 'Claims',
      route: AppRoutes.claims,
    ),
    NavigationItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      cupertinoIcon: CupertinoIcons.group_solid,
      label: 'Teams',
      route: AppRoutes.teams,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      cupertinoIcon: CupertinoIcons.settings_solid,
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
      // Add haptic feedback for iOS
      if (Platform.isIOS) {
        HapticFeedback.selectionClick();
      }
      context.go(_navigationItems[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🔍 ADAPTIVE NAVIGATION DEBUG: Platform.isIOS = ${Platform.isIOS}, Platform.isMacOS = ${Platform.isMacOS}',
    );

    if (Platform.isIOS) {
      // Use proper Cupertino navigation for iOS
      debugPrint(
        '🔍 ADAPTIVE NAVIGATION DEBUG: iOS detected - building Cupertino navigation',
      );
      return _buildCupertinoNavigation();
    }

    if (Platform.isMacOS) {
      // Use macOS-style navigation
      debugPrint(
        '🔍 ADAPTIVE NAVIGATION DEBUG: macOS detected - building macOS navigation',
      );
      return _buildMacOSNavigation();
    }

    debugPrint('🔍 ADAPTIVE NAVIGATION DEBUG: Building Material navigation');
    return _buildMaterialNavigation();
  }

  /// Build iOS-style navigation using Scaffold with CupertinoTabBar
  /// This approach is more compatible with GoRouter than CupertinoTabScaffold
  Widget _buildCupertinoNavigation() {
    debugPrint('🔍 iOS NAVIGATION DEBUG: Building Cupertino navigation');

    try {
      // Get theme colors with safe fallbacks for iOS
      final materialTheme = Theme.of(context);
      final colorScheme = materialTheme.colorScheme;

      // Use proper iOS-style colors
      final backgroundColor = colorScheme.surface.withValues(alpha: 0.9);
      final activeColor = colorScheme.primary;
      final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.6);

      debugPrint(
        '🔍 iOS NAVIGATION DEBUG: Theme colors resolved - backgroundColor: $backgroundColor, activeColor: $activeColor',
      );

      final scaffold = Scaffold(
        backgroundColor: materialTheme.scaffoldBackgroundColor,
        body: widget.child,
        bottomNavigationBar: CupertinoTabBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: backgroundColor,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          iconSize: 24.0,
          items: _navigationItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == _selectedIndex;
            return BottomNavigationBarItem(
              icon: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: isSelected ? 26.0 : 24.0,
                key: ValueKey('cupertino_icon_${item.route}'),
                color: isSelected ? activeColor : inactiveColor,
              ),
              label: item.label,
            );
          }).toList(),
        ),
        floatingActionButton: _shouldShowFAB()
            ? _buildFloatingActionButton()
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );

      debugPrint(
        '🔍 iOS NAVIGATION DEBUG: Cupertino navigation built successfully',
      );
      return scaffold;
    } catch (e, stackTrace) {
      debugPrint(
        '🔍 iOS NAVIGATION ERROR: Failed to build Cupertino navigation: $e',
      );
      debugPrint('🔍 iOS NAVIGATION ERROR: Stack trace: $stackTrace');

      // Fallback to Material navigation for iOS if Cupertino fails
      debugPrint(
        '🔍 iOS NAVIGATION DEBUG: Falling back to Material navigation for iOS',
      );
      return _buildMaterialNavigationForIOS();
    }
  }

  /// Build Material Design navigation for Android
  Widget _buildMaterialNavigation() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 8,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        backgroundColor: colorScheme.surface,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        items: _navigationItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == _selectedIndex;
          return BottomNavigationBarItem(
            icon: Icon(
              isSelected ? item.selectedIcon : item.icon,
              key: ValueKey('material_icon_${item.route}'),
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            label: item.label,
          );
        }).toList(),
      ),
      floatingActionButton: _shouldShowFAB()
          ? _buildFloatingActionButton()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Build Material Design navigation for iOS as fallback
  /// Used when Cupertino navigation fails to render
  Widget _buildMaterialNavigationForIOS() {
    debugPrint('🔍 iOS FALLBACK DEBUG: Building Material navigation for iOS');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 0, // iOS-style flat design
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _navigationItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == _selectedIndex;
          return BottomNavigationBarItem(
            icon: Icon(
              isSelected ? item.selectedIcon : item.icon,
              key: ValueKey('ios_fallback_icon_${item.route}'),
            ),
            label: item.label,
          );
        }).toList(),
      ),
      // No FAB for iOS fallback to maintain iOS design consistency
    );
  }

  /// Build macOS-style navigation
  Widget _buildMacOSNavigation() {
    debugPrint('🔍 macOS NAVIGATION DEBUG: Building macOS navigation');

    try {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            items: _navigationItems
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Icon(item.icon, size: 22),
                    activeIcon: Icon(item.selectedIcon, size: 22),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        ),
        floatingActionButton: _shouldShowFAB()
            ? _buildFloatingActionButton()
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '🔍 macOS NAVIGATION ERROR: Failed to build macOS navigation: $e',
      );
      debugPrint('🔍 macOS NAVIGATION ERROR: Stack trace: $stackTrace');

      // Fallback to Material navigation for macOS if custom navigation fails
      debugPrint(
        '🔍 macOS NAVIGATION DEBUG: Falling back to Material navigation for macOS',
      );
      return _buildMaterialNavigation();
    }
  }

  bool _shouldShowFAB() {
    // Show FAB only on receipts screen and only on Android and macOS
    // iOS uses different patterns for primary actions
    return !Platform.isIOS && _selectedIndex == 1; // Receipts index
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        // Check subscription limits before allowing receipt capture
        final canUpload =
            await SubscriptionGuard.showReceiptLimitDialogIfNeeded(
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
  final IconData cupertinoIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.cupertinoIcon,
    required this.label,
    required this.route,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationItem &&
          runtimeType == other.runtimeType &&
          route == other.route;

  @override
  int get hashCode => route.hashCode;
}
