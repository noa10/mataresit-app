import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/receipts_provider.dart';

/// Widget that displays the selection mode toggle and selection counter
class SelectionModeBar extends ConsumerWidget {
  const SelectionModeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final receiptsNotifier = ref.read(receiptsProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection mode toggle button
          FilledButton.icon(
            onPressed: receiptsNotifier.toggleSelectionMode,
            icon: Icon(
              receiptsState.isSelectionMode ? Icons.close : Icons.checklist,
              size: 18,
            ),
            label: Text(
              receiptsState.isSelectionMode ? 'Cancel' : 'Select',
              style: const TextStyle(fontSize: 14),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: receiptsState.isSelectionMode
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: receiptsState.isSelectionMode
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
          ),

          const SizedBox(width: 16),

          // Selection counter (only show when in selection mode)
          if (receiptsState.isSelectionMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${receiptsNotifier.selectedCount} selected',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Select all / Deselect all button
            if (receiptsState.receipts.isNotEmpty)
              TextButton(
                onPressed: receiptsNotifier.isAllSelected
                    ? receiptsNotifier.clearSelection
                    : receiptsNotifier.selectAllReceipts,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  receiptsNotifier.isAllSelected
                      ? 'Deselect All'
                      : 'Select All',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],

          const Spacer(),

          // View mode toggle (existing functionality)
          if (!receiptsState.isSelectionMode) ...[
            IconButton(
              onPressed: receiptsNotifier.toggleGroupedView,
              icon: Icon(
                receiptsState.isGroupedView
                    ? Icons.view_list
                    : Icons.view_agenda,
                size: 20,
              ),
              tooltip: receiptsState.isGroupedView
                  ? 'Switch to flat view'
                  : 'Switch to grouped view',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact version of selection mode bar for smaller screens
class CompactSelectionModeBar extends ConsumerWidget {
  const CompactSelectionModeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final receiptsNotifier = ref.read(receiptsProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection mode toggle
          IconButton.filled(
            onPressed: receiptsNotifier.toggleSelectionMode,
            icon: Icon(
              receiptsState.isSelectionMode ? Icons.close : Icons.checklist,
              size: 18,
            ),
            style: IconButton.styleFrom(
              backgroundColor: receiptsState.isSelectionMode
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: receiptsState.isSelectionMode
                  ? Theme.of(context).colorScheme.onError
                  : Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(36, 36),
            ),
          ),

          const SizedBox(width: 12),

          // Selection info
          if (receiptsState.isSelectionMode) ...[
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${receiptsNotifier.selectedCount} selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (receiptsState.receipts.isNotEmpty)
                    TextButton(
                      onPressed: receiptsNotifier.isAllSelected
                          ? receiptsNotifier.clearSelection
                          : receiptsNotifier.selectAllReceipts,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 28),
                      ),
                      child: Text(
                        receiptsNotifier.isAllSelected ? 'None' : 'All',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const Spacer(),
            // View mode toggle for non-selection mode
            IconButton(
              onPressed: receiptsNotifier.toggleGroupedView,
              icon: Icon(
                receiptsState.isGroupedView
                    ? Icons.view_list
                    : Icons.view_agenda,
                size: 18,
              ),
              tooltip: receiptsState.isGroupedView
                  ? 'Flat view'
                  : 'Grouped view',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Selection mode bar that adapts to screen size
class AdaptiveSelectionModeBar extends StatelessWidget {
  const AdaptiveSelectionModeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use compact version on smaller screens
        if (constraints.maxWidth < 600) {
          return const CompactSelectionModeBar();
        }
        return const SelectionModeBar();
      },
    );
  }
}
