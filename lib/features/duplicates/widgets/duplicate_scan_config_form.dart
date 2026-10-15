import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../models/duplicate_models.dart';

/// Scan settings form: which fields join the grouping key and how loosely
/// they are compared.
///
/// Merchant matching is always part of the key, so it is shown locked on.
class DuplicateScanConfigForm extends StatelessWidget {
  final ScanConfig config;
  final ValueChanged<ScanConfig> onChanged;

  const DuplicateScanConfigForm({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'duplicates.config.title'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            SwitchListTile(
              value: true,
              onChanged: null,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('duplicates.config.merchant'.tr()),
              subtitle: Text('duplicates.config.merchantAlwaysOn'.tr()),
            ),
            SwitchListTile(
              value: config.dateEnabled,
              onChanged: (value) =>
                  onChanged(config.copyWith(dateEnabled: value)),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('duplicates.config.date'.tr()),
            ),
            _ToleranceSlider(
              label: 'duplicates.config.dateTolerance'.tr(),
              valueLabel: 'duplicates.config.dateToleranceValue'.tr(
                namedArgs: {'days': '${config.dateToleranceDays}'},
              ),
              value: config.dateToleranceDays.toDouble(),
              min: ScanConfig.minDateToleranceDays.toDouble(),
              max: ScanConfig.maxDateToleranceDays.toDouble(),
              divisions:
                  ScanConfig.maxDateToleranceDays -
                  ScanConfig.minDateToleranceDays,
              enabled: config.dateEnabled,
              onChanged: (value) =>
                  onChanged(config.copyWith(dateToleranceDays: value.round())),
            ),
            SwitchListTile(
              value: config.totalEnabled,
              onChanged: (value) =>
                  onChanged(config.copyWith(totalEnabled: value)),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('duplicates.config.total'.tr()),
            ),
            _ToleranceSlider(
              label: 'duplicates.config.totalTolerance'.tr(),
              valueLabel: config.totalTolerance <= 0
                  ? 'duplicates.config.totalToleranceExact'.tr()
                  : 'duplicates.config.totalToleranceValue'.tr(
                      namedArgs: {
                        'value': config.totalTolerance.toStringAsFixed(2),
                      },
                    ),
              value: config.totalTolerance,
              min: ScanConfig.minTotalTolerance,
              max: ScanConfig.maxTotalTolerance,
              divisions: 100,
              enabled: config.totalEnabled,
              onChanged: (value) =>
                  onChanged(config.copyWith(totalTolerance: value)),
            ),
            SwitchListTile(
              value: config.taxEnabled,
              onChanged: (value) =>
                  onChanged(config.copyWith(taxEnabled: value)),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('duplicates.config.tax'.tr()),
            ),
            SwitchListTile(
              value: config.currencyEnabled,
              onChanged: (value) =>
                  onChanged(config.copyWith(currencyEnabled: value)),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('duplicates.config.currency'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled slider with a value caption.
class _ToleranceSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _ToleranceSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                valueLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
