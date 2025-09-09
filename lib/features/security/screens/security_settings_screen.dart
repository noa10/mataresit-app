import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';

/// Main security settings screen - hub for all security features
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Authentication & Account Security Section
          _buildSectionHeader('Authentication & Account Security'),
          const SizedBox(height: 8),
          _buildSecurityCard(
            context,
            icon: Icons.lock_outline,
            title: 'Password',
            subtitle: 'Change your account password',
            onTap: () => context.push(AppRoutes.passwordChange),
          ),
          _buildSecurityCard(
            context,
            icon: Icons.security,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            onTap: () => context.push(AppRoutes.twoFactorAuth),
          ),
          _buildSecurityCard(
            context,
            icon: Icons.devices,
            title: 'Session Management',
            subtitle: 'Manage your active sessions',
            onTap: () => context.push(AppRoutes.sessionManagement),
          ),

          const SizedBox(height: 24),

          // Privacy Controls Section
          _buildSectionHeader('Privacy Controls'),
          const SizedBox(height: 8),
          _buildSecurityCard(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Settings',
            subtitle: 'Control your data and privacy preferences',
            onTap: () => context.push(AppRoutes.privacyControls),
          ),

          const SizedBox(height: 24),

          // Security Features Section
          _buildSectionHeader('Security Features'),
          const SizedBox(height: 8),
          _buildSecurityCard(
            context,
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Use fingerprint or face unlock',
            onTap: () {
              // This will be handled in the main security settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Biometric settings available in main security screen',
                  ),
                ),
              );
            },
          ),
          _buildSecurityCard(
            context,
            icon: Icons.pin,
            title: 'App Lock & PIN',
            subtitle: 'Set up PIN for app access',
            onTap: () {
              // This will be handled in the main security settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'PIN settings available in main security screen',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Danger Zone Section
          _buildSectionHeader('Danger Zone'),
          const SizedBox(height: 8),
          _buildSecurityCard(
            context,
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            onTap: () => context.push(AppRoutes.accountDeletion),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSecurityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
