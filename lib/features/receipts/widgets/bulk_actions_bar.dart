import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/category_model.dart';
import '../providers/receipts_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../services/export_service.dart';
import 'confirmation_dialogs.dart';

/// Widget that displays bulk action buttons when receipts are selected
class BulkActionsBar extends ConsumerStatefulWidget {
  const BulkActionsBar({super.key});

  @override
  ConsumerState<BulkActionsBar> createState() => _BulkActionsBarState();
}

class _BulkActionsBarState extends ConsumerState<BulkActionsBar> {
  String? selectedCategoryId;
  bool isExporting = false;

  @override
  Widget build(BuildContext context) {
    final receiptsState = ref.watch(receiptsProvider);
    final receiptsNotifier = ref.read(receiptsProvider.notifier);
    final categoriesState = ref.watch(categoriesProvider);

    // Only show when in selection mode and items are selected
    if (!receiptsState.isSelectionMode ||
        receiptsState.selectedReceiptIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category assignment section
          Row(
            children: [
              Expanded(
                child: _buildCategoryDropdown(categoriesState.categories),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed:
                    selectedCategoryId != null &&
                        !receiptsState.isPerformingBulkOperation
                    ? () => _assignCategory(receiptsNotifier)
                    : null,
                icon: receiptsState.isPerformingBulkOperation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.label, size: 18),
                label: Text(
                  receiptsState.isPerformingBulkOperation
                      ? 'Assigning...'
                      : 'Assign (${receiptsState.selectedReceiptIds.length})',
                  style: const TextStyle(fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons row
          Row(
            children: [
              // Export dropdown
              Expanded(child: _buildExportDropdown()),

              const SizedBox(width: 12),

              // Delete button
              FilledButton.icon(
                onPressed: !receiptsState.isPerformingBulkOperation
                    ? () => _showDeleteConfirmation(context, receiptsNotifier)
                    : null,
                icon: receiptsState.isPerformingBulkOperation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete, size: 18),
                label: Text(
                  receiptsState.isPerformingBulkOperation
                      ? 'Deleting...'
                      : 'Delete (${receiptsState.selectedReceiptIds.length})',
                  style: const TextStyle(fontSize: 14),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(List<CategoryModel> categories) {
    return DropdownButtonFormField<String>(
      initialValue: selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Select Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Remove Category'),
        ),
        ...categories.map(
          (category) => DropdownMenuItem<String>(
            value: category.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(category.color.replaceFirst('#', '0xFF')),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(category.name)),
              ],
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          selectedCategoryId = value;
        });
      },
      isExpanded: true,
    );
  }

  Widget _buildExportDropdown() {
    return PopupMenuButton<String>(
      onSelected: _handleExport,
      enabled: !isExporting,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, size: 18),
              SizedBox(width: 8),
              Text('Export as PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart, size: 18),
              SizedBox(width: 8),
              Text('Export as Excel'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.text_snippet, size: 18),
              SizedBox(width: 8),
              Text('Export as CSV'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExporting) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              const Text('Exporting...', style: TextStyle(fontSize: 14)),
            ] else ...[
              const Icon(Icons.download, size: 18),
              const SizedBox(width: 8),
              Text(
                'Export (${ref.watch(receiptsProvider).selectedReceiptIds.length})',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  void _assignCategory(ReceiptsNotifier receiptsNotifier) async {
    final currentContext = context;
    final count = ref.read(receiptsProvider).selectedReceiptIds.length;
    final categoriesState = ref.read(categoriesProvider);
    final categoryName = selectedCategoryId != null
        ? categoriesState.categories
              .where((cat) => cat.id == selectedCategoryId)
              .firstOrNull
              ?.name
        : null;

    final confirmed =
        await ConfirmationDialogs.showBulkCategoryAssignmentConfirmation(
          currentContext,
          count,
          categoryName,
        );

    if (confirmed && mounted) {
      await receiptsNotifier.bulkAssignCategory(selectedCategoryId);
      setState(() {
        selectedCategoryId = null;
      });
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ReceiptsNotifier receiptsNotifier,
  ) async {
    final currentContext = context;
    final count = ref.read(receiptsProvider).selectedReceiptIds.length;

    final confirmed = await ConfirmationDialogs.showBulkDeleteConfirmation(
      currentContext,
      count,
    );

    if (confirmed && mounted) {
      await receiptsNotifier.bulkDeleteReceipts();
    }
  }

  void _handleExport(String format) async {
    setState(() {
      isExporting = true;
    });

    try {
      final receiptsState = ref.read(receiptsProvider);
      final selectedReceipts = receiptsState.receipts
          .where(
            (receipt) => receiptsState.selectedReceiptIds.contains(receipt.id),
          )
          .toList();

      switch (format) {
        case 'pdf':
          await ExportService.exportToPDF(selectedReceipts);
          break;
        case 'excel':
          await ExportService.exportToExcel(selectedReceipts);
          break;
        case 'csv':
          await ExportService.exportToCSV(selectedReceipts);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully exported ${selectedReceipts.length} receipts as ${format.toUpperCase()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isExporting = false;
        });
      }
    }
  }
}
