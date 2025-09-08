import 'package:flutter/material.dart';
import '../../../core/config/subscription_config.dart';

/// Feature comparison table widget
/// Shows a detailed comparison of features across all tiers
class FeatureComparisonTable extends StatelessWidget {
  final SubscriptionTier currentTier;
  final BillingInterval billingInterval;

  const FeatureComparisonTable({
    super.key,
    required this.currentTier,
    required this.billingInterval,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: _buildComparisonTable(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    final features = _getFeatureList();
    
    return DataTable(
      columnSpacing: 18,
      headingRowHeight: 50,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 40,
      columns: [
        const DataColumn(
          label: Text(
            'Feature',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        _buildTierColumn(context, SubscriptionTier.free),
        _buildTierColumn(context, SubscriptionTier.pro),
        _buildTierColumn(context, SubscriptionTier.max),
      ],
      rows: features.map((feature) => _buildFeatureRow(context, feature)).toList(),
    );
  }

  DataColumn _buildTierColumn(BuildContext context, SubscriptionTier tier) {
    final isCurrentTier = tier == currentTier;
    final tierName = _getTierName(tier);
    final price = PricingInfo.getPrice(tier, billingInterval);

    return DataColumn(
      label: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: BoxDecoration(
          color: isCurrentTier
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isCurrentTier
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTierIcon(tier),
                  size: 12,
                  color: _getTierColor(context, tier),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    tierName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: isCurrentTier
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              price == 0 ? 'Free' : '\$${price.toStringAsFixed(0)}/${billingInterval.value}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isCurrentTier
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isCurrentTier)
              Text(
                'Current',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildFeatureRow(BuildContext context, FeatureItem feature) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            feature.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        _buildFeatureCell(context, feature, SubscriptionTier.free),
        _buildFeatureCell(context, feature, SubscriptionTier.pro),
        _buildFeatureCell(context, feature, SubscriptionTier.max),
      ],
    );
  }

  DataCell _buildFeatureCell(BuildContext context, FeatureItem feature, SubscriptionTier tier) {
    final value = _getFeatureValue(feature, tier);
    
    return DataCell(
      Center(
        child: _buildFeatureValue(context, value),
      ),
    );
  }

  Widget _buildFeatureValue(BuildContext context, FeatureValue value) {
    switch (value.type) {
      case FeatureValueType.boolean:
        return Icon(
          value.boolValue! ? Icons.check_circle : Icons.cancel,
          color: value.boolValue! ? Colors.green : Colors.red,
          size: 20,
        );
      case FeatureValueType.text:
        return Text(
          value.textValue!,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        );
      case FeatureValueType.number:
        return Text(
          value.numberValue == -1 ? 'Unlimited' : value.numberValue.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        );
    }
  }

  List<FeatureItem> _getFeatureList() {
    return [
      FeatureItem('Monthly Receipts', FeatureType.monthlyReceipts),
      FeatureItem('Storage Limit', FeatureType.storageLimit),
      FeatureItem('Data Retention', FeatureType.dataRetention),
      FeatureItem('Batch Upload Limit', FeatureType.batchUploadLimit),
      FeatureItem('Team Members', FeatureType.teamMembers),
      FeatureItem('Version Control', FeatureType.versionControl),
      FeatureItem('Custom Branding', FeatureType.customBranding),
      FeatureItem('API Access', FeatureType.apiAccess),
      FeatureItem('Integrations', FeatureType.integrations),
      FeatureItem('Support Level', FeatureType.supportLevel),
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
        return FeatureValue.text('${(limits.storageLimitMB / 1024).toStringAsFixed(0)}GB');
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

  IconData _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.upload;
      case SubscriptionTier.pro:
        return Icons.flash_on;
      case SubscriptionTier.max:
        return Icons.workspace_premium;
    }
  }

  Color _getTierColor(BuildContext context, SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.green;
      case SubscriptionTier.pro:
        return Theme.of(context).colorScheme.primary;
      case SubscriptionTier.max:
        return Colors.purple;
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

enum FeatureValueType {
  boolean,
  text,
  number,
}
