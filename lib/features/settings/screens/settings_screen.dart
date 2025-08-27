import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Navigate to profile edit
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Settings Sections
          _buildSettingsSection(
            context,
            'Account',
            [
              _buildSettingsTile(
                context,
                'Profile',
                Icons.person_outline,
                () {
                  // TODO: Navigate to profile
                },
              ),
              _buildSettingsTile(
                context,
                'Security',
                Icons.security_outlined,
                () {
                  // TODO: Navigate to security
                },
              ),
              _buildSettingsTile(
                context,
                'Notifications',
                Icons.notifications_outlined,
                () {
                  // TODO: Navigate to notifications
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          _buildSettingsSection(
            context,
            'Preferences',
            [
              _buildSettingsTile(
                context,
                'Language',
                Icons.language_outlined,
                () {
                  // TODO: Navigate to language
                },
              ),
              _buildSettingsTile(
                context,
                'Theme',
                Icons.palette_outlined,
                () {
                  // TODO: Navigate to theme
                },
              ),
              _buildSettingsTile(
                context,
                'Currency',
                Icons.attach_money_outlined,
                () {
                  // TODO: Navigate to currency
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          _buildSettingsSection(
            context,
            'Support',
            [
              _buildSettingsTile(
                context,
                'Help Center',
                Icons.help_outline,
                () {
                  // TODO: Navigate to help
                },
              ),
              _buildSettingsTile(
                context,
                'Contact Us',
                Icons.contact_support_outlined,
                () {
                  // TODO: Navigate to contact
                },
              ),
              _buildSettingsTile(
                context,
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                () {
                  // TODO: Navigate to privacy
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Logout Button
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                _showLogoutDialog(context, ref);
              },
            ),
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // App Version
          Center(
            child: Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppConstants.defaultPadding),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
