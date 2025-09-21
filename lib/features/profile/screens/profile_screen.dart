import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_editor.dart';
import '../widgets/profile_preferences.dart';
import '../widgets/profile_security.dart';
import '../widgets/profile_subscription.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        bottom: profileState.profile != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
                  Tab(
                    icon: Icon(Icons.credit_card_outlined),
                    text: 'Subscription',
                  ),
                  Tab(icon: Icon(Icons.settings_outlined), text: 'Preferences'),
                  Tab(icon: Icon(Icons.security_outlined), text: 'Security'),
                ],
                labelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                indicatorColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
      body: _buildBody(profileState, authState),
    );
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

    return Column(
      children: [
        // Profile Header
        ProfileHeader(profile: profileState.profile!),

        const SizedBox(height: AppConstants.defaultPadding),

        // Tab Content
        Expanded(
          child: TabBarView(
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
            ],
          ),
        ),
      ],
    );
  }
}
