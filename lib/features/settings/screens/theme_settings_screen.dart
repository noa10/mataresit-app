import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/theme_model.dart' as theme_model;
import '../../../shared/providers/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('settings.general.theme.title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Current Theme Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Text(
                        'Current Theme',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Row(
                    children: [
                      Chip(
                        label: Text(themeState.config.mode.displayName),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Chip(
                        label: const Text('Ledger'),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Theme Mode Section
          _buildThemeModeSection(
            context,
            themeState,
            themeNotifier,
            authState.user?.id,
          ),

          if (themeState.error != null) ...[
            const SizedBox(height: AppConstants.largePadding),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        themeState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => themeNotifier.clearError(),
                      child: Text('common.buttons.dismiss'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeModeSection(
    BuildContext context,
    ThemeState themeState,
    ThemeNotifier themeNotifier,
    String? userId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Choose how the interface appears',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Theme Mode Buttons
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: theme_model.ThemeMode.values.map((mode) {
                final isSelected = themeState.config.mode == mode;
                final isLoading = themeState.isLoading;

                return FilterChip(
                  selected: isSelected,
                  onSelected: isLoading
                      ? null
                      : (selected) {
                          if (selected) {
                            themeNotifier.updateThemeMode(mode, userId: userId);
                          }
                        },
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getThemeModeIcon(mode), size: 16),
                      const SizedBox(width: AppConstants.smallPadding),
                      Text(mode.displayName),
                    ],
                  ),
                  avatar: isLoading && isSelected
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeModeIcon(theme_model.ThemeMode mode) {
    switch (mode) {
      case theme_model.ThemeMode.light:
        return Icons.light_mode;
      case theme_model.ThemeMode.dark:
        return Icons.dark_mode;
      case theme_model.ThemeMode.auto:
        return Icons.auto_mode;
    }
  }
}
