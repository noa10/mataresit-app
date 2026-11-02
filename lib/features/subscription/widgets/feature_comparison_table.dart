import 'package:flutter/material.dart';
import '../../../core/config/subscription_config.dart';
import '../../../shared/utils/currency_utils.dart';

/// Feature comparison table widget
/// Shows a detailed comparison of features across all tiers.
class FeatureComparisonTable extends StatelessWidget {
  final SubscriptionTier currentTier;
  final BillingInterval billingInterval;

  const FeatureComparisonTable({
    super.key,
    required this.currentTier,
    required this.billingInterval,
  });

  static const Map<int, TableColumnWidth> _columnWidths = {
    0: FlexColumnWidth(2.1),
    1: FlexColumnWidth(1),
    2: FlexColumnWidth(1),
    3: FlexColumnWidth(1),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Feature Comparison',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ALL PLANS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    letterSpacing: 1,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          _buildHeader(context),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          for (final group in _getGroups()) _buildGroup(context, group),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Table(
      columnWidths: _columnWidths,
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Text(
                'FEATURE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            for (final tier in SubscriptionTier.values)
              _buildTierHeader(context, tier),
          ],
        ),
      ],
    );
  }

  Widget _buildTierHeader(BuildContext context, SubscriptionTier tier) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCurrent = tier == currentTier;
    final price = PricingInfo.getPrice(tier, billingInterval);

    return Container(
      color: isCurrent ? colors.primaryContainer : null,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getTierName(tier).toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: isCurrent
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price == 0
                ? 'FREE'
                : CurrencyUtils.formatCurrency(price, 'MYR', precision: 0),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              letterSpacing: 0.2,
              color: isCurrent ? colors.onPrimaryContainer : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    ({String label, List<FeatureItem> items}) group,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: colors.surfaceContainerLow,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Text(
            group.label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Table(
          columnWidths: _columnWidths,
          children: [
            for (final feature in group.items)
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                    child: Text(
                      feature.name,
                      maxLines: 2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ),
                  for (final tier in SubscriptionTier.values)
                    _buildFeatureCell(context, _getFeatureValue(feature, tier)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCell(BuildContext context, FeatureValue value) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget child;
    switch (value.type) {
      case FeatureValueType.boolean:
        child = value.boolValue!
            ? Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: colors.onPrimaryContainer,
                ),
              )
            : Text(
                '—',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              );
        break;
      case FeatureValueType.text:
        child = Text(
          value.textValue!,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'IBMPlexMono',
            fontSize: 9.5,
            letterSpacing: 0.2,
            color: colors.onSurface,
          ),
        );
        break;
      case FeatureValueType.number:
        child = Text(
          value.numberValue == -1 ? 'Unlimited' : value.numberValue.toString(),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.onSurface,
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Center(child: child),
    );
  }

  List<({String label, List<FeatureItem> items})> _getGroups() {
    return [
      (
        label: 'Limits',
        items: [
          FeatureItem('Monthly Receipts', FeatureType.monthlyReceipts),
          FeatureItem('Storage Limit', FeatureType.storageLimit),
          FeatureItem('Data Retention', FeatureType.dataRetention),
        ],
      ),
      (
        label: 'Usage',
        items: [
          FeatureItem('Batch Upload Limit', FeatureType.batchUploadLimit),
          FeatureItem('Team Members', FeatureType.teamMembers),
        ],
      ),
      (
        label: 'Features',
        items: [
          FeatureItem('Version Control', FeatureType.versionControl),
          FeatureItem('Custom Branding', FeatureType.customBranding),
          FeatureItem('API Access', FeatureType.apiAccess),
          FeatureItem('Integrations', FeatureType.integrations),
        ],
      ),
      (
        label: 'Support',
        items: [FeatureItem('Support Level', FeatureType.supportLevel)],
      ),
    ];
  }

  FeatureValue _getFeatureValue(FeatureItem feature, SubscriptionTier tier) {
    final limits = TierConfig.getLimits(tier);

    switch (feature.type) {
      case FeatureType.monthlyReceipts:
        return FeatureValue.number(limits.monthlyReceipts);
      case FeatureType.storageLimit:
        if (limits.storageLimitMB == -1) {
          return FeatureValue.number(-1);
        }
        return FeatureValue.text(
          '${(limits.storageLimitMB / 1024).toStringAsFixed(0)}GB',
        );
      case FeatureType.dataRetention:
        return FeatureValue.text('${limits.retentionDays} days');
      case FeatureType.batchUploadLimit:
        return FeatureValue.number(limits.batchUploadLimit);
      case FeatureType.teamMembers:
        return FeatureValue.number(limits.features.maxUsers);
      case FeatureType.versionControl:
        return FeatureValue.boolean(limits.features.versionControl);
      case FeatureType.customBranding:
        return FeatureValue.boolean(limits.features.customBranding);
      case FeatureType.apiAccess:
        return FeatureValue.boolean(limits.features.apiAccess);
      case FeatureType.integrations:
        return FeatureValue.text(limits.features.integrations.toUpperCase());
      case FeatureType.supportLevel:
        return FeatureValue.text(limits.features.supportLevel.toUpperCase());
    }
  }

  String _getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.max:
        return 'Max';
    }
  }
}

// Helper classes for feature comparison
class FeatureItem {
  final String name;
  final FeatureType type;

  FeatureItem(this.name, this.type);
}

enum FeatureType {
  monthlyReceipts,
  storageLimit,
  dataRetention,
  batchUploadLimit,
  teamMembers,
  versionControl,
  customBranding,
  apiAccess,
  integrations,
  supportLevel,
}

class FeatureValue {
  final FeatureValueType type;
  final bool? boolValue;
  final String? textValue;
  final int? numberValue;

  FeatureValue.boolean(this.boolValue)
    : type = FeatureValueType.boolean,
      textValue = null,
      numberValue = null;

  FeatureValue.text(this.textValue)
    : type = FeatureValueType.text,
      boolValue = null,
      numberValue = null;

  FeatureValue.number(this.numberValue)
    : type = FeatureValueType.number,
      boolValue = null,
      textValue = null;
}

enum FeatureValueType { boolean, text, number }
