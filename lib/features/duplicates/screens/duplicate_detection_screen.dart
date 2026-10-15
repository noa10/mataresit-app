import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/duplicate_models.dart';
import '../providers/duplicate_detection_provider.dart';
import '../services/duplicate_detection_service.dart';
import '../widgets/duplicate_group_card.dart';
import '../widgets/duplicate_scan_config_form.dart';

/// Duplicate receipt detection: configure a scan, review the groups it finds
/// and delete the receipts that should not be kept.
class DuplicateDetectionScreen extends ConsumerStatefulWidget {
  const DuplicateDetectionScreen({super.key});

  @override
  ConsumerState<DuplicateDetectionScreen> createState() =>
      _DuplicateDetectionScreenState();
}

class _DuplicateDetectionScreenState
    extends ConsumerState<DuplicateDetectionScreen> {
  /// Translate the grouping-key tokens of a scan result into the active
  /// locale.
  ///
  /// The tokens are read from the result (not from the live config), so the
  /// label keeps describing the scan the user is looking at even when the
  /// settings form is edited afterwards.
  String _criteriaLabel(String matchCriteria) => matchCriteria
      .split(' + ')
      .map((field) => 'duplicates.criteria.$field'.tr())
      .join(' + ');

  Future<void> _handleScan() async {
    await ref.read(duplicateDetectionProvider.notifier).scan();
  }

  Future<bool> _confirmDelete(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: theme.colorScheme.error),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(child: Text('duplicates.confirm.title'.tr())),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'duplicates.confirm.message'.tr(namedArgs: {'count': '$count'}),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'duplicates.confirm.warning'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('duplicates.confirm.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: Text('duplicates.confirm.confirm'.tr()),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _delete({required bool keepOldest}) async {
    final state = ref.read(duplicateDetectionProvider);
    final result = state.result;
    if (result == null) return;

    final count = keepOldest ? result.deletableCount : state.selectedCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('duplicates.nothingSelected'.tr())),
      );
      return;
    }

    if (!await _confirmDelete(count) || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(duplicateDetectionProvider.notifier);

    final deleted = keepOldest
        ? await notifier.deleteAllKeepingOldest()
        : await notifier.deleteSelected();

    if (!mounted) return;

    if (deleted > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'duplicates.delete.success'.tr(namedArgs: {'count': '$deleted'}),
          ),
        ),
      );
    } else {
      final error =
          ref.read(duplicateDetectionProvider).error ??
          'duplicates.delete.failed'.tr();
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duplicateDetectionProvider);

    return Scaffold(
      appBar: AppBar(title: Text('duplicates.title'.tr())),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DuplicateScanConfigForm(
                    config: state.config,
                    onChanged: ref
                        .read(duplicateDetectionProvider.notifier)
                        .updateConfig,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  LoadingButton(
                    onPressed: _handleScan,
                    text: state.hasResult
                        ? 'duplicates.scan.rescan'.tr()
                        : 'duplicates.scan.button'.tr(),
                    isLoading: state.isScanning,
                    icon: const Icon(Icons.search),
                  ),
                  if (state.isScanning) ...[
                    const SizedBox(height: AppConstants.defaultPadding),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          ..._resultSlivers(state),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppConstants.largePadding),
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(state),
    );
  }

  List<Widget> _resultSlivers(DuplicateDetectionState state) {
    final result = state.result;

    if (result == null) {
      if (state.isScanning) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingWidget(message: 'duplicates.scan.scanning'.tr()),
          ),
        ];
      }

      if (state.error != null) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppErrorWidget(
              error: state.error!,
              title: 'duplicates.error.title'.tr(),
              onRetry: _handleScan,
            ),
          ),
        ];
      }

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Icons.content_copy_outlined,
            title: 'duplicates.initial.title'.tr(),
            message: 'duplicates.initial.message'.tr(),
            actionLabel: 'duplicates.scan.button'.tr(),
            onAction: _handleScan,
          ),
        ),
      ];
    }

    if (!result.hasGroups) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: Icons.verified_outlined,
            title: 'duplicates.empty.title'.tr(),
            message: 'duplicates.empty.message'.tr(),
            actionLabel: 'duplicates.scan.rescan'.tr(),
            onAction: _handleScan,
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(child: _summary(state, result)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
        ),
        sliver: SliverList.builder(
          itemCount: result.groups.length,
          itemBuilder: (context, index) => DuplicateGroupCard(
            group: result.groups[index],
            index: index + 1,
            criteriaLabel: _criteriaLabel(result.groups[index].matchCriteria),
            selectedIds: state.selectedIds,
            onToggleReceipt: ref
                .read(duplicateDetectionProvider.notifier)
                .toggleSelection,
          ),
        ),
      ),
    ];
  }

  Widget _summary(DuplicateDetectionState state, ScanResult result) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        0,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'duplicates.results.title'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'duplicates.results.scanned'.tr(
              namedArgs: {'count': '${result.scannedCount}'},
            ),
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'duplicates.results.matchOn'.tr(
              namedArgs: {
                'criteria': _criteriaLabel(result.groups.first.matchCriteria),
              },
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          _statLine(
            'duplicates.results.totalDuplicates'.tr(
              namedArgs: {'count': '${result.totalDuplicates}'},
            ),
            theme.colorScheme.onSurfaceVariant,
          ),
          _statLine(
            'duplicates.results.deletableCount'.tr(
              namedArgs: {'count': '${result.deletableCount}'},
            ),
            theme.colorScheme.primary,
          ),
          if (state.error != null)
            _notice(
              icon: Icons.error_outline,
              message: state.error!,
              color: theme.colorScheme.error,
            ),
          if (state.isResultStale)
            _notice(
              icon: Icons.schedule,
              message: 'duplicates.results.stale'.tr(),
              color: theme.colorScheme.tertiary,
            ),
          if (result.wasCapped)
            _notice(
              icon: Icons.filter_alt_off_outlined,
              message: 'duplicates.results.capped'.tr(
                namedArgs: {
                  'max': '${DuplicateDetectionService.scanMaxReceipts}',
                },
              ),
              color: theme.colorScheme.error,
            ),
          if (result.skippedNoMerchant > 0)
            _notice(
              icon: Icons.help_outline,
              message: 'duplicates.results.skippedNoMerchant'.tr(
                namedArgs: {'count': '${result.skippedNoMerchant}'},
              ),
              color: theme.colorScheme.tertiary,
            ),
        ],
      ),
    );
  }

  Widget _statLine(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky bar with the selection actions; hidden when nothing to act on.
  Widget? _actionBar(DuplicateDetectionState state) {
    final result = state.result;
    if (result == null || !result.hasGroups) return null;

    final theme = Theme.of(context);
    final notifier = ref.read(duplicateDetectionProvider.notifier);
    final busy = state.isDeleting;

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'duplicates.selectedCount'.tr(
                        namedArgs: {'count': '${state.selectedCount}'},
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : notifier.selectAllDuplicates,
                    child: Text('duplicates.selectAll'.tr()),
                  ),
                  TextButton(
                    onPressed: busy || state.selectedCount == 0
                        ? null
                        : notifier.clearSelection,
                    child: Text('duplicates.clearSelection'.tr()),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              FilledButton.icon(
                onPressed: busy || state.selectedCount == 0
                    ? null
                    : () => _delete(keepOldest: false),
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text('duplicates.deleteSelected'.tr()),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              OutlinedButton.icon(
                onPressed: busy || result.deletableCount == 0
                    ? null
                    : () => _delete(keepOldest: true),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text('duplicates.deleteAllKeepOldest'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
