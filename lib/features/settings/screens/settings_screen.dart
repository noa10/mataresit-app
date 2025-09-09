import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/profile_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/widgets/subscription_status_card.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/providers/currency_provider.dart';
import '../../../shared/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileProvider);
    final languageState = ref.watch(languageProvider);
    final currencyState = ref.watch(currencyProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
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
                    backgroundImage:
                        profileState.profile != null &&
                            ProfileService.getAvatarUrl(
                                  profileState.profile!,
                                ) !=
                                null
                        ? NetworkImage(
                            ProfileService.getAvatarUrl(profileState.profile!)!,
                          )
                        : null,
                    child:
                        profileState.profile != null &&
                            ProfileService.getAvatarUrl(
                                  profileState.profile!,
                                ) ==
                                null
                        ? Text(
                            ProfileService.getUserInitials(
                              profileState.profile!,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileState.profile != null
                              ? ProfileService.getFullName(
                                  profileState.profile!,
                                )
                              : user?.fullName ?? 'User',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          profileState.profile?.email ?? user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.push('/profile');
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Subscription Section
          const SubscriptionStatusCard(),

          const SizedBox(height: AppConstants.largePadding),

          // Settings Sections
          _buildSettingsSection(context, 'settings.tabs.billing'.tr(), [
            _buildSettingsTile(
              context,
              'common.labels.subscription'.tr(),
              Icons.credit_card_outlined,
              () => context.push('/pricing'),
            ),
            _buildSettingsTile(
              context,
              'common.labels.billing'.tr(),
              Icons.receipt_outlined,
              () => context.push('/billing'),
            ),
          ]),

          const SizedBox(height: AppConstants.largePadding),

          _buildSettingsSection(context, 'Account', [
            _buildSettingsTile(context, 'Profile', Icons.person_outline, () {
              context.push('/profile');
            }),
            _buildSettingsTile(
              context,
              'Security',
              Icons.security_outlined,
              () {
                context.push('/settings/security');
              },
            ),
            _buildSettingsTile(
              context,
              'Notifications',
              Icons.notifications_outlined,
              () {
                context.push('/settings/notifications');
              },
            ),
          ]),

          const SizedBox(height: AppConstants.largePadding),

          _buildSettingsSection(context, 'settings.tabs.general'.tr(), [
            _buildSettingsTile(
              context,
              'settings.general.language.title'.tr(),
              Icons.language_outlined,
              () {
                context.push('/settings/language');
              },
              subtitle: languageState.currentLanguage.name,
            ),
            _buildSettingsTile(
              context,
              'settings.general.theme.title'.tr(),
              Icons.palette_outlined,
              () {
                context.push('/settings/theme');
              },
              subtitle:
                  '${themeState.config.mode.displayName} • ${themeState.config.variant.displayName}',
            ),
            _buildSettingsTile(
              context,
              'settings.general.currency.title'.tr(),
              Icons.attach_money_outlined,
              () {
                context.push('/settings/currency');
              },
              subtitle: currencyState.userPreferredCurrency ?? 'MYR',
            ),
          ]),

          const SizedBox(height: AppConstants.largePadding),

          _buildSettingsSection(context, 'navigation.help'.tr(), [
            _buildSettingsTile(
              context,
              'navigation.help'.tr(),
              Icons.help_outline,
              () {
                context.push('/help');
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
                context.push('/privacy-policy');
              },
            ),
          ]),

          const SizedBox(height: AppConstants.largePadding),

          // Logout Button
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'navigation.logout'.tr(),
                style: const TextStyle(color: Colors.red),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('navigation.logout'.tr()),
        content: Text('common.messages.confirmDelete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.buttons.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: Text('navigation.logout'.tr()),
          ),
        ],
      ),
    );
  }
}
