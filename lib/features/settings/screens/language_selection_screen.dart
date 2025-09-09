import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/constants/app_constants.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.general.language.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              'settings.general.language.description'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Language options
          Expanded(
            child: ListView.builder(
              itemCount: languageNotifier.supportedLanguages.length,
              itemBuilder: (context, index) {
                final language = languageNotifier.supportedLanguages[index];
                final isSelected = languageNotifier.isLanguageSelected(
                  language,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding / 2,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    title: Text(
                      language.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'settings.general.language.options.${language.code}'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : languageState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: languageState.isLoading
                        ? null
                        : () => _changeLanguage(context, ref, language),
                  ),
                );
              },
            ),
          ),

          // Error message
          if (languageState.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppConstants.defaultPadding),
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      languageState.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => languageNotifier.clearError(),
                    child: Text(
                      'common.buttons.close'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    SupportedLanguage language,
  ) async {
    final languageNotifier = ref.read(languageProvider.notifier);

    final success = await languageNotifier.changeLanguage(context, language);

    if (success && context.mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('settings.messages.saved'.tr()),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back after a short delay to allow the language change to take effect
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          context.pop();
        }
      });
    }
  }
}
