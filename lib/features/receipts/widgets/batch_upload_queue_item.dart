import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../models/batch_upload_models.dart';
import '../../../core/constants/app_constants.dart';

class BatchUploadQueueItem extends StatefulWidget {
  final BatchUploadItem item;
  final void Function(String itemId)? onRemove;
  final void Function(String itemId)? onRetry;
  final void Function(String itemId)? onViewReceipt;

  const BatchUploadQueueItem({
    super.key,
    required this.item,
    this.onRemove,
    this.onRetry,
    this.onViewReceipt,
  });

  @override
  State<BatchUploadQueueItem> createState() => _BatchUploadQueueItemState();
}

class _BatchUploadQueueItemState extends State<BatchUploadQueueItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            _buildMainContent(),
            if (_showLogs && widget.item.processingLogs.isNotEmpty)
              _buildLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFileIcon(),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.fileName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormattedFileSize(widget.item.fileSize),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusIcon(),
              const SizedBox(width: AppConstants.smallPadding),
              _buildActionButtons(),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          _buildProgressSection(),
        ],
      ),
    );
  }

  Widget _buildFileIcon() {
    final extension = path.extension(widget.item.fileName).toLowerCase();
    IconData iconData;
    Color iconColor;

    switch (extension) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.item.status) {
      case BatchUploadItemStatus.queued:
        return Icon(
          Icons.schedule,
          color: Theme.of(context).colorScheme.outline,
          size: 20,
        );
      case BatchUploadItemStatus.uploading:
      case BatchUploadItemStatus.processing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case BatchUploadItemStatus.completed:
        return Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        );
      case BatchUploadItemStatus.failed:
        return Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: 20,
        );
      case BatchUploadItemStatus.cancelled:
        return Icon(
          Icons.cancel,
          color: Theme.of(context).colorScheme.outline,
          size: 20,
        );
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show logs button
        if (widget.item.processingLogs.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() {
                _showLogs = !_showLogs;
              });
            },
            icon: Icon(
              _showLogs ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            tooltip: _showLogs ? 'Hide logs' : 'Show logs',
          ),

        // Retry button for failed uploads
        if (widget.item.status == BatchUploadItemStatus.failed &&
            widget.onRetry != null)
          IconButton(
            onPressed: () => widget.onRetry!(widget.item.id),
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Retry upload',
          ),

        // View receipt button for completed uploads
        if (widget.item.status == BatchUploadItemStatus.completed &&
            widget.item.receiptId != null &&
            widget.onViewReceipt != null)
          IconButton(
            onPressed: () => widget.onViewReceipt!(widget.item.receiptId!),
            icon: const Icon(Icons.visibility, size: 20),
            tooltip: 'View receipt',
          ),

        // Remove button for queued items
        if (widget.item.status == BatchUploadItemStatus.queued &&
            widget.onRemove != null)
          IconButton(
            onPressed: () => widget.onRemove!(widget.item.id),
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Remove from queue',
          ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.item.stageDescription,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.item.isActive)
              Text(
                '${widget.item.progress}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: widget.item.progress / 100,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.2),
          color: _getProgressColor(),
        ),
        if (widget.item.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          'Processing Logs (${widget.item.processingLogs.length})',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        initiallyExpanded: _showLogs,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.item.processingLogs.length,
              itemBuilder: (context, index) {
                final log = widget.item.processingLogs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    switch (widget.item.status) {
      case BatchUploadItemStatus.completed:
        return Theme.of(context).colorScheme.primary;
      case BatchUploadItemStatus.failed:
        return Theme.of(context).colorScheme.error;
      case BatchUploadItemStatus.cancelled:
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getFormattedFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
