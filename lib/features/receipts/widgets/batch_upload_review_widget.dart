import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/batch_upload_models.dart';
import '../../../core/constants/app_constants.dart';
import 'receipt_browser_modal.dart';

class BatchUploadReviewWidget extends StatefulWidget {
  final BatchUploadState batchState;
  final VoidCallback onClose;
  final VoidCallback onReset;
  final VoidCallback? onRetryFailed;
  final VoidCallback? onViewAllReceipts;

  const BatchUploadReviewWidget({
    super.key,
    required this.batchState,
    required this.onClose,
    required this.onReset,
    this.onRetryFailed,
    this.onViewAllReceipts,
  });

  @override
  State<BatchUploadReviewWidget> createState() =>
      _BatchUploadReviewWidgetState();
}

class _BatchUploadReviewWidgetState extends State<BatchUploadReviewWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.batchState.completedItems.isNotEmpty ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildCompletedTab(), _buildFailedTab()],
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildHeader() {
    final successRate = widget.batchState.successRate;
    final completedCount = widget.batchState.completedCount;
    final failedCount = widget.batchState.failedCount;
    final totalCount = widget.batchState.totalItems;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                successRate >= 100 ? Icons.check_circle : Icons.info,
                color: successRate >= 100
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                size: 32,
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Upload Complete',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '$completedCount of $totalCount files processed successfully',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Successful',
                  completedCount.toString(),
                  Theme.of(context).colorScheme.primary,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: _buildStatCard(
                  'Failed',
                  failedCount.toString(),
                  Theme.of(context).colorScheme.error,
                  Icons.error_outline,
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: _buildStatCard(
                  'Success Rate',
                  '${successRate.toStringAsFixed(0)}%',
                  Theme.of(context).colorScheme.secondary,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(
          text: 'Completed (${widget.batchState.completedCount})',
          icon: const Icon(Icons.check_circle_outline, size: 20),
        ),
        Tab(
          text: 'Failed (${widget.batchState.failedCount})',
          icon: const Icon(Icons.error_outline, size: 20),
        ),
      ],
    );
  }

  Widget _buildCompletedTab() {
    final completedItems = widget.batchState.completedItems;

    if (completedItems.isEmpty) {
      return _buildEmptyState(
        'No Completed Uploads',
        'No files were successfully processed.',
        Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: completedItems.length,
      itemBuilder: (context, index) {
        final item = completedItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          child: ListTile(
            leading: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(item.fileName),
            subtitle: Text(
              'Processed successfully',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            trailing: item.receiptId != null
                ? IconButton(
                    onPressed: () {
                      // Navigate to receipt detail
                      context.push('/receipts/${item.receiptId}');
                    },
                    icon: const Icon(Icons.visibility),
                    tooltip: 'View receipt',
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildFailedTab() {
    final failedItems = widget.batchState.failedItems;

    if (failedItems.isEmpty) {
      return _buildEmptyState(
        'No Failed Uploads',
        'All files were processed successfully!',
        Icons.celebration,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: failedItems.length,
      itemBuilder: (context, index) {
        final item = failedItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          child: ExpansionTile(
            leading: Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(item.fileName),
            subtitle: Text(
              item.error ?? 'Processing failed',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            children: [
              if (item.processingLogs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Logs:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: item.processingLogs.length,
                          itemBuilder: (context, logIndex) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                item.processingLogs[logIndex],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontFamily: 'monospace'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Retry failed button
          if (widget.batchState.failedItems.isNotEmpty &&
              widget.onRetryFailed != null)
            TextButton.icon(
              onPressed: widget.onRetryFailed,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Failed'),
            ),

          const Spacer(),

          // View all receipts button
          if (widget.batchState.completedItems.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                // Use callback if provided, otherwise show modal directly
                if (widget.onViewAllReceipts != null) {
                  widget.onViewAllReceipts!();
                } else {
                  // Get all completed receipt IDs
                  final receiptIds = widget.batchState.completedItems
                      .where((item) => item.receiptId != null)
                      .map((item) => item.receiptId!)
                      .toList();

                  if (receiptIds.isNotEmpty) {
                    // Show receipt browser modal
                    showDialog(
                      context: context,
                      builder: (context) => ReceiptBrowserModal(
                        receiptIds: receiptIds,
                        title: 'Uploaded Receipts (${receiptIds.length})',
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    );
                  } else {
                    // Fallback to receipts list if no receipt IDs found
                    context.push('/receipts');
                  }
                }
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Results'),
            ),

          const SizedBox(width: AppConstants.smallPadding),

          // Start new batch button
          ElevatedButton.icon(
            onPressed: widget.onReset,
            icon: const Icon(Icons.add),
            label: const Text('New Batch'),
          ),
        ],
      ),
    );
  }
}
