import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';
import '../providers/profile_provider.dart';

class ProfilePreferences extends ConsumerStatefulWidget {
  final UserModel profile;

  const ProfilePreferences({super.key, required this.profile});

  @override
  ConsumerState<ProfilePreferences> createState() => _ProfilePreferencesState();
}

class _ProfilePreferencesState extends ConsumerState<ProfilePreferences> {
  late String _selectedLanguage;
  late bool _billingEmailEnabled;
  late bool _autoRenewalEnabled;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.profile.preferredLanguage ?? 'en';
    _billingEmailEnabled = widget.profile.billingEmailEnabled ?? true;
    _autoRenewalEnabled = widget.profile.autoRenewalEnabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language Preferences
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language & Region',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Language',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Spanish')),
                    DropdownMenuItem(value: 'fr', child: Text('French')),
                    DropdownMenuItem(value: 'de', child: Text('German')),
                    DropdownMenuItem(value: 'it', child: Text('Italian')),
                    DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
                  ],
                  onChanged: profileState.isUpdating
                      ? null
                      : (value) {
                          if (value != null && value != _selectedLanguage) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                            _updatePreference('preferred_language', value);
                          }
                        },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.defaultPadding),

        // Notification Preferences
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                SwitchListTile(
                  title: const Text('Billing Email Notifications'),
                  subtitle: const Text(
                    'Receive emails about billing and payments',
                  ),
                  value: _billingEmailEnabled,
                  onChanged: profileState.isUpdating
                      ? null
                      : (value) {
                          setState(() {
                            _billingEmailEnabled = value;
                          });
                          _updatePreference('billing_email_enabled', value);
                        },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.defaultPadding),

        // Subscription Preferences
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                SwitchListTile(
                  title: const Text('Auto-Renewal'),
                  subtitle: const Text(
                    'Automatically renew subscription when it expires',
                  ),
                  value: _autoRenewalEnabled,
                  onChanged: profileState.isUpdating
                      ? null
                      : (value) {
                          setState(() {
                            _autoRenewalEnabled = value;
                          });
                          _updatePreference('auto_renewal_enabled', value);
                        },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.defaultPadding),

        // Theme Preferences
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                ListTile(
                  leading: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Theme'),
                  subtitle: Text(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'Dark Mode'
                        : 'Light Mode',
                  ),
                  trailing: Switch(
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (value) {
                      // TODO: Implement theme switching
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Theme switching will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),

        // Update Status
        if (profileState.isUpdating)
          const Padding(
            padding: EdgeInsets.only(top: AppConstants.defaultPadding),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppConstants.smallPadding),
                  Text('Updating preferences...'),
                ],
              ),
            ),
          ),

        // Error Message
        if (profileState.updateError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.defaultPadding),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.error),
              ),
              child: Text(
                profileState.updateError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    final success = await ref.read(profileProvider.notifier).updateProfile({
      key: value,
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preference updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
