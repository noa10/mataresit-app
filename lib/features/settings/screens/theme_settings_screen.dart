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
      appBar: AppBar(
        title: Text('settings.general.theme.title'.tr()),
      ),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Row(
                    children: [
                      Chip(
                        label: Text(themeState.config.mode.displayName),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Chip(
                        label: Text(themeState.config.variant.displayName),
                        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Theme Mode Section
          _buildThemeModeSection(context, themeState, themeNotifier, authState.user?.id),

          const SizedBox(height: AppConstants.largePadding),

          // Theme Variant Section
          _buildThemeVariantSection(context, themeState, themeNotifier, authState.user?.id),

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  onSelected: isLoading ? null : (selected) {
                    if (selected) {
                      themeNotifier.updateThemeMode(mode, userId: userId);
                    }
                  },
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getThemeModeIcon(mode),
                        size: 16,
                      ),
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

  Widget _buildThemeVariantSection(
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
              'Theme Variant',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Choose your preferred color scheme',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Theme Variant Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.defaultPadding,
                mainAxisSpacing: AppConstants.defaultPadding,
                childAspectRatio: 1.2,
              ),
              itemCount: theme_model.ThemeVariant.values.length,
              itemBuilder: (context, index) {
                final variant = theme_model.ThemeVariant.values[index];
                final definition = theme_model.ThemeVariantDefinition.getDefinition(variant);
                final isSelected = themeState.config.variant == variant;
                final isLoading = themeState.isLoading;
                
                return GestureDetector(
                  onTap: isLoading ? null : () {
                    themeNotifier.updateThemeVariant(variant, userId: userId);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.05)
                        : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  variant.displayName,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isLoading && isSelected)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            variant.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // Color Preview
                          Row(
                            children: [
                              _buildColorPreview(definition.preview.primaryColor),
                              const SizedBox(width: 4),
                              _buildColorPreview(definition.preview.secondaryColor),
                              const SizedBox(width: 4),
                              _buildColorPreview(definition.preview.accentColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreview(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
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
