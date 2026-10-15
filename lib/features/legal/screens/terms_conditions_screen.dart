import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';

/// Accent slot for a section, resolved against the active [ColorScheme].
enum _Accent { primary, secondary, tertiary, warning }

/// One entry of the terms document.
///
/// Entries with [heading] set render as a section heading without body text,
/// mirroring the web page's group titles (for example
/// "User Accounts and Registration").
class _TermsSection {
  const _TermsSection(this.key, this.icon, this.accent, {this.heading = false});

  final String key;
  final IconData icon;
  final _Accent accent;
  final bool heading;
}

/// Terms of Service screen, mirroring the web app's TermsConditionsPage.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const List<_TermsSection> _sections = [
    _TermsSection('introduction', Icons.info_outline, _Accent.primary),
    _TermsSection(
      'userAccounts',
      Icons.account_circle_outlined,
      _Accent.secondary,
      heading: true,
    ),
    _TermsSection(
      'accountCreation',
      Icons.person_add_alt_outlined,
      _Accent.secondary,
    ),
    _TermsSection('accountSecurity', Icons.lock_outline, _Accent.primary),
    _TermsSection('accountEligibility', Icons.badge_outlined, _Accent.tertiary),
    _TermsSection(
      'subscriptionBilling',
      Icons.credit_card_outlined,
      _Accent.tertiary,
      heading: true,
    ),
    _TermsSection(
      'servicePlans',
      Icons.workspace_premium_outlined,
      _Accent.primary,
    ),
    _TermsSection('billingTerms', Icons.receipt_long_outlined, _Accent.primary),
    _TermsSection(
      'freeTrialAndRefunds',
      Icons.currency_exchange_outlined,
      _Accent.secondary,
    ),
    _TermsSection(
      'serviceFeatures',
      Icons.settings_outlined,
      _Accent.primary,
      heading: true,
    ),
    _TermsSection('aiProcessing', Icons.smart_toy_outlined, _Accent.primary),
    _TermsSection(
      'dataProcessing',
      Icons.cloud_upload_outlined,
      _Accent.secondary,
    ),
    _TermsSection('teamCollaboration', Icons.groups_outlined, _Accent.tertiary),
    _TermsSection(
      'userObligations',
      Icons.how_to_reg_outlined,
      _Accent.tertiary,
      heading: true,
    ),
    _TermsSection(
      'permittedUse',
      Icons.check_circle_outline,
      _Accent.secondary,
    ),
    _TermsSection(
      'prohibitedActivities',
      Icons.block_outlined,
      _Accent.warning,
    ),
    _TermsSection('dataAccuracy', Icons.fact_check_outlined, _Accent.primary),
    _TermsSection(
      'dataHandling',
      Icons.shield_outlined,
      _Accent.secondary,
      heading: true,
    ),
    _TermsSection('dataCollection', Icons.storage_outlined, _Accent.secondary),
    _TermsSection('securityMeasures', Icons.security_outlined, _Accent.primary),
    _TermsSection(
      'thirdPartyIntegrations',
      Icons.hub_outlined,
      _Accent.tertiary,
    ),
    _TermsSection('privacyPolicy', Icons.privacy_tip_outlined, _Accent.primary),
    _TermsSection(
      'disclaimers',
      Icons.warning_amber_outlined,
      _Accent.warning,
      heading: true,
    ),
    _TermsSection('serviceDisclaimers', Icons.error_outline, _Accent.warning),
    _TermsSection(
      'limitationOfLiability',
      Icons.balance_outlined,
      _Accent.warning,
    ),
    _TermsSection(
      'userResponsibilities',
      Icons.person_outline,
      _Accent.primary,
    ),
    _TermsSection('contactInformation', Icons.mail_outline, _Accent.tertiary),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('legal.terms.title'.tr()), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(context),

            ..._sections.map(
              (section) => Padding(
                padding: EdgeInsets.only(
                  top: section.heading
                      ? AppConstants.largePadding
                      : AppConstants.defaultPadding,
                ),
                child: _buildSection(context, section),
              ),
            ),

            const SizedBox(height: AppConstants.largePadding),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 32,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'legal.terms.title'.tr(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'legal.terms.subtitle'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Container(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Text(
              'legal.terms.lastUpdated'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, _TermsSection section) {
    final theme = Theme.of(context);
    final accent = _resolveAccent(theme.colorScheme, section.accent);
    final body = 'legal.terms.sections.${section.key}.body'.tr();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon, color: accent, size: 24),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    'legal.terms.sections.${section.key}.title'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              ...body
                  .split('\n')
                  .where((line) => line.trim().isNotEmpty)
                  .map((line) => _buildBodyLine(context, line, accent)),
            ],
            // The web page highlights this warning above the disclaimers.
            if (section.key == 'disclaimers')
              _buildWarning(context, 'legal.terms.disclaimerNotice'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyLine(BuildContext context, String line, Color accent) {
    final theme = Theme.of(context);

    if (!line.startsWith('• ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
        child: Text(line, style: theme.textTheme.bodyMedium),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(line.substring(2), style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(BuildContext context, String message) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error, size: 20),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  color: scheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'legal.terms.footerTitle'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'legal.terms.versionLine'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Divider(),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'legal.terms.acknowledgement'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveAccent(ColorScheme scheme, _Accent accent) {
    switch (accent) {
      case _Accent.primary:
        return scheme.primary;
      case _Accent.secondary:
        return scheme.secondary;
      case _Accent.tertiary:
        return scheme.tertiary;
      case _Accent.warning:
        return scheme.error;
    }
  }
}
