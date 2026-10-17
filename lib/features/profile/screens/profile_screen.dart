import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_editor.dart';
import '../widgets/profile_preferences.dart';
import '../widgets/profile_rewards.dart';
import '../widgets/profile_security.dart';
import '../widgets/profile_subscription.dart';

/// Tab order, used to resolve a `?tab=` query parameter to an index.
enum ProfileTab {
  profile,
  subscription,
  preferences,
  security,
  rewards;

  /// Index of [name] in the tab bar, defaulting to the first tab so an unknown
  /// or absent value never selects a tab that does not exist.
  static int indexOf(String? name) {
    if (name == null) return 0;
    final match = ProfileTab.values.where((t) => t.name == name);
    return match.isEmpty ? 0 : match.first.index;
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  /// Which tab to open on. Supplied by the router from `?tab=`, so a link such
  /// as `/profile?tab=rewards` lands on Rewards rather than the first tab.
  final int initialTab;

  const ProfileScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ProfileTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, ProfileTab.values.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(body: _buildBody(profileState, authState));
  }

  Widget _buildBody(ProfileState profileState, AuthState authState) {
    if (profileState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      );
    }

    if (profileState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              profileState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (authState.user != null) {
                  ref
                      .read(profileProvider.notifier)
                      .loadProfile(authState.user!.id);
                }
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (profileState.profile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Profile not found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          // App Bar with title
          SliverAppBar(
            title: const Text('Profile'),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
            floating: true,
            snap: true,
            pinned: false,
          ),

          // Profile Header as a sliver
          SliverToBoxAdapter(
            child: Column(
              children: [
                ProfileHeader(profile: profileState.profile!),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                // Five tabs no longer fit side by side on a phone, so the bar
                // scrolls instead of overflowing.
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  const Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
                  const Tab(
                    icon: Icon(Icons.credit_card_outlined),
                    text: 'Subscription',
                  ),
                  const Tab(
                    icon: Icon(Icons.settings_outlined),
                    text: 'Preferences',
                  ),
                  const Tab(
                    icon: Icon(Icons.security_outlined),
                    text: 'Security',
                  ),
                  Tab(
                    icon: const Icon(Icons.emoji_events_outlined),
                    text: 'gamification.tabs.rewards'.tr(),
                  ),
                ],
                labelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                indicatorColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          // Profile Info Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: ProfileInfoEditor(profile: profileState.profile!),
          ),

          // Subscription Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: ProfileSubscription(profile: profileState.profile!),
          ),

          // Preferences Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: ProfilePreferences(profile: profileState.profile!),
          ),

          // Security Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: ProfileSecurity(profile: profileState.profile!),
          ),

          // Rewards Tab — owns its own scrolling so the pull-to-refresh and the
          // badge grid share one scrollable.
          const ProfileRewards(),
        ],
      ),
    );
  }
}

// Custom delegate for the persistent tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
