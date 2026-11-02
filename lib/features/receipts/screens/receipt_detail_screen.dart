import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/utils/confidence_utils.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/enhanced_image_viewer.dart';
import '../../categories/providers/categories_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../providers/receipts_provider.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(receiptId));

    // Load categories when the widget is first built with team context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTeam = ref.read(currentTeamModelProvider);
      ref
          .read(categoriesProvider.notifier)
          .loadCategories(teamId: currentTeam?.id);
    });

    // Listen for team changes and reload categories
    ref.listen<TeamModel?>(currentTeamModelProvider, (previous, next) {
      if (previous?.id != next?.id) {
        // Team changed, reload categories with new team context
        ref.read(categoriesProvider.notifier).loadCategories(teamId: next?.id);
      }
    });

    return receiptAsync.when(
      data: (receipt) {
        if (receipt == null) {
          return _buildStateScaffold(
            context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Receipt not found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return _buildReceiptDetails(context, ref, receipt);
      },
      loading: () => _buildStateScaffold(
        context,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading receipt...'),
          ],
        ),
      ),
      error: (error, stack) => _buildStateScaffold(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading receipt: $error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(receiptProvider(receiptId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateScaffold(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      foregroundColor: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RECEIPT', style: _eyebrowStyle(theme)),
                        const SizedBox(height: 4),
                        Text(
                          'Receipt Details',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontFamily: 'InstrumentSerif',
                            fontSize: 30,
                            height: 1.05,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptDetails(
    BuildContext context,
    WidgetRef ref,
    ReceiptModel receipt,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('dd MMM yyyy');
    final merchant = receipt.merchantName?.trim();
    final merchantLabel = merchant == null || merchant.isEmpty
        ? 'Unknown Merchant'
        : merchant;
    final dateLabel = receipt.transactionDate == null
        ? null
        : dateFormat.format(receipt.transactionDate!).toUpperCase();
    final lede = [
      if (receipt.category != null && receipt.category!.trim().isNotEmpty)
        receipt.category!.trim(),
      if (dateLabel != null) dateLabel,
    ].join(' · ');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          tooltip: 'Back',
                          style: IconButton.styleFrom(
                            foregroundColor: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        _MonogramTile(name: merchantLabel),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RECEIPT', style: _eyebrowStyle(theme)),
                              const SizedBox(height: 4),
                              Text(
                                merchantLabel,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontFamily: 'InstrumentSerif',
                                  fontSize: 30,
                                  height: 1.05,
                                  color: colors.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (lede.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  lede,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _StatusPill(status: receipt.status),
                              if (receipt.processingStatus !=
                                  ProcessingStatus.completed)
                                _ProcessingPill(
                                  status: receipt.processingStatus,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyUtils.formatCurrencySafe(
                            receipt.totalAmount,
                            receipt.currency,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontFamily: 'IBMPlexMono',
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement edit
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement share
                          },
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: const Text('Share'),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'More actions',
                          onSelected: (value) {
                            switch (value) {
                              case 'delete':
                                _showDeleteDialog(context, ref, receipt);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: colors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: colors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border.all(color: colors.outline),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.more_horiz,
                                  size: 18,
                                  color: colors.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'More',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Receipt Image with Enhanced Viewer
                    if (receipt.imageUrl != null) ...[
                      Container(
                        height: 260,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.outlineVariant),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: EnhancedImageViewer(
                          imageUrl: receipt.imageUrl!,
                          title:
                              'Receipt from ${receipt.merchantName ?? 'Unknown Merchant'}',
                          heroTag: 'receipt_${receipt.id}',
                          showControls: true,
                          enableRotation: true,
                          enableFullscreen: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          initialScale: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Receipt Details
                    _Panel(
                      title: 'Receipt Information',
                      meta: (receipt.currency ?? 'MYR').toUpperCase(),
                      child: Column(
                        children: [
                          _FieldRow(
                            label: 'Merchant',
                            child: Text(
                              receipt.merchantName ?? 'Unknown',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (receipt.totalAmount != null) ...[
                            Divider(height: 1, color: colors.outlineVariant),
                            _FieldRow(
                              label: 'Total Amount',
                              child: Text(
                                CurrencyUtils.formatCurrencySafe(
                                  receipt.totalAmount,
                                  receipt.currency,
                                ),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'IBMPlexMono',
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                          if (receipt.transactionDate != null) ...[
                            Divider(height: 1, color: colors.outlineVariant),
                            _FieldRow(
                              label: 'Date',
                              child: Text(
                                dateFormat
                                    .format(receipt.transactionDate!)
                                    .toUpperCase(),
                                style: _dataStyle(theme),
                              ),
                            ),
                          ],
                          if (receipt.category != null) ...[
                            Divider(height: 1, color: colors.outlineVariant),
                            _FieldRow(
                              label: 'Category',
                              child: Text(
                                receipt.category!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                          if (receipt.paymentMethod != null) ...[
                            Divider(height: 1, color: colors.outlineVariant),
                            _FieldRow(
                              label: 'Payment Method',
                              child: Text(
                                receipt.paymentMethod!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                          Divider(height: 1, color: colors.outlineVariant),
                          _FieldRow(
                            label: 'Status',
                            child: _StatusPill(status: receipt.status),
                          ),
                          Divider(height: 1, color: colors.outlineVariant),
                          _FieldRow(
                            label: 'Processing Status',
                            child: _ProcessingPill(
                              status: receipt.processingStatus,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (receipt.description != null ||
                        receipt.notes != null ||
                        receipt.receiptNumber != null) ...[
                      const SizedBox(height: 12),
                      _Panel(
                        title: 'Additional Information',
                        child: Column(
                          children: [
                            if (receipt.receiptNumber != null)
                              _FieldRow(
                                label: 'Receipt Number',
                                child: Text(
                                  receipt.receiptNumber!,
                                  style: _dataStyle(theme),
                                ),
                              ),
                            if (receipt.description != null) ...[
                              if (receipt.receiptNumber != null)
                                Divider(
                                  height: 1,
                                  color: colors.outlineVariant,
                                ),
                              _FieldRow(
                                label: 'Description',
                                child: Text(
                                  receipt.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                            if (receipt.notes != null) ...[
                              if (receipt.receiptNumber != null ||
                                  receipt.description != null)
                                Divider(
                                  height: 1,
                                  color: colors.outlineVariant,
                                ),
                              _FieldRow(
                                label: 'Notes',
                                child: Text(
                                  receipt.notes!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    if (_hasConfidence(receipt)) ...[
                      const SizedBox(height: 12),
                      _buildConfidencePanel(receipt, theme),
                    ],

                    const SizedBox(height: 12),

                    // Metadata
                    _Panel(
                      title: 'Metadata',
                      child: Column(
                        children: [
                          _FieldRow(
                            label: 'Created',
                            child: Text(
                              timeago.format(receipt.createdAt),
                              style: _bodyStyle(theme),
                            ),
                          ),
                          Divider(height: 1, color: colors.outlineVariant),
                          _FieldRow(
                            label: 'Updated',
                            child: Text(
                              timeago.format(receipt.updatedAt),
                              style: _bodyStyle(theme),
                            ),
                          ),
                          if (receipt.originalFileName != null) ...[
                            Divider(height: 1, color: colors.outlineVariant),
                            _FieldRow(
                              label: 'Original File',
                              child: Text(
                                receipt.originalFileName!,
                                style: _bodyStyle(theme),
                              ),
                            ),
                          ],
                          if (receipt.fileSize != null) ...[
                            Divider(height: 1, color: colors.outlineVariant),
                            _FieldRow(
                              label: 'File Size',
                              child: Text(
                                _formatFileSize(receipt.fileSize!),
                                style: _dataStyle(theme),
                              ),
                            ),
                          ],
                          Divider(height: 1, color: colors.outlineVariant),
                          _FieldRow(
                            label: 'Expense',
                            child: Text(
                              receipt.isExpense ? 'Yes' : 'No',
                              style: _dataStyle(theme),
                            ),
                          ),
                          Divider(height: 1, color: colors.outlineVariant),
                          _FieldRow(
                            label: 'Reimbursable',
                            child: Text(
                              receipt.isReimbursable ? 'Yes' : 'No',
                              style: _dataStyle(theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidencePanel(ReceiptModel receipt, ThemeData theme) {
    final colors = theme.colorScheme;
    final score = ConfidenceUtils.calculateAggregateConfidence(receipt);
    final color = score >= 80
        ? colors.primary
        : score >= 60
        ? colors.tertiary
        : colors.error;

    return _Panel(
      title: 'Confidence',
      meta: 'AI EXTRACTION',
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.round()}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    ConfidenceUtils.getConfidenceLabel(score),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colors.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggregate confidence across the merchant, date, total, tax and payment method.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasConfidence(ReceiptModel receipt) {
    return (receipt.aiSuggestions?.containsKey('confidence') ?? false) ||
        (receipt.confidenceScores?.isNotEmpty ?? false);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ReceiptModel receipt,
  ) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: Text(
          'Are you sure you want to delete the receipt from ${receipt.merchantName ?? 'Unknown Merchant'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(receiptsProvider.notifier)
                  .deleteReceipt(receipt.id);
              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Receipt deleted successfully'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}

TextStyle _eyebrowStyle(ThemeData theme) {
  return theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        letterSpacing: 1.4,
      ) ??
      const TextStyle(fontSize: 10, letterSpacing: 1.4);
}

TextStyle _dataStyle(ThemeData theme) {
  return theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'IBMPlexMono',
        color: theme.colorScheme.onSurface,
      ) ??
      const TextStyle();
}

TextStyle _bodyStyle(ThemeData theme) {
  return theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ) ??
      const TextStyle();
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, this.meta, required this.child});

  final String title;
  final String? meta;
  final Widget child;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      if (meta != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          child,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 1,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MonogramTile extends StatelessWidget {
  const _MonogramTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length > 1
        ? '${words[0].characters.first}${words[1].characters.first}'
        : words[0].characters.take(2).toString();

    return ExcludeSemantics(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          initials.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reviewed = status == ReceiptStatus.reviewed;

    return _Pill(
      label: status.displayName,
      foreground: reviewed
          ? colors.onPrimaryContainer
          : colors.onTertiaryContainer,
      background: reviewed ? colors.primaryContainer : colors.tertiaryContainer,
    );
  }
}

class _ProcessingPill extends StatelessWidget {
  const _ProcessingPill({required this.status});

  final ProcessingStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final failed = status == ProcessingStatus.failed;
    final completed = status == ProcessingStatus.completed;

    return _Pill(
      label: status.displayName,
      foreground: failed
          ? colors.onErrorContainer
          : completed
          ? colors.onSurfaceVariant
          : colors.onTertiaryContainer,
      background: failed
          ? colors.errorContainer
          : completed
          ? colors.surfaceContainerHighest
          : colors.tertiaryContainer,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
