import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/enhanced_image_viewer.dart';
import '../providers/receipts_provider.dart';
import '../../../shared/models/receipt_model.dart';
import '../../categories/providers/categories_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../../shared/models/team_model.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptDetailScreen({
    super.key,
    required this.receiptId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(receiptId));

    // Load categories when the widget is first built with team context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTeam = ref.read(currentTeamModelProvider);
      ref.read(categoriesProvider.notifier).loadCategories(teamId: currentTeam?.id);
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
          return Scaffold(
            appBar: AppBar(
              title: const Text('Receipt Details'),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Receipt not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildReceiptDetails(context, ref, receipt);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Receipt Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Receipt Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Error loading receipt: $error',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptDetails(BuildContext context, WidgetRef ref, ReceiptModel receipt) {

    return Scaffold(
      appBar: AppBar(
        title: Text(receipt.merchantName ?? 'Receipt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog(context, ref, receipt);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Image with Enhanced Viewer
            if (receipt.imageUrl != null) ...[
              Card(
                child: SizedBox(
                  height: 300,
                  child: EnhancedImageViewer(
                    imageUrl: receipt.imageUrl!,
                    title: 'Receipt from ${receipt.merchantName ?? 'Unknown Merchant'}',
                    heroTag: 'receipt_${receipt.id}',
                    showControls: true,
                    enableRotation: true,
                    enableFullscreen: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    initialScale: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.largePadding),
            ],

            // Receipt Details
            _buildDetailSection(
              context,
              'Receipt Information',
              [
                _buildDetailRow('Merchant', receipt.merchantName ?? 'Unknown'),
                if (receipt.totalAmount != null)
                  _buildDetailRow('Total Amount', '\$${receipt.totalAmount!.toStringAsFixed(2)}'),
                if (receipt.transactionDate != null)
                  _buildDetailRow('Date', _formatDate(receipt.transactionDate!)),
                if (receipt.category != null)
                  _buildDetailRow('Category', receipt.category!),
                if (receipt.paymentMethod != null)
                  _buildDetailRow('Payment Method', receipt.paymentMethod!),
                _buildDetailRow('Status', receipt.status.displayName),
                _buildDetailRow('Processing Status', receipt.processingStatus.displayName),
              ],
            ),

            const SizedBox(height: AppConstants.largePadding),

            // Additional Details
            if (receipt.description != null || 
                receipt.notes != null ||
                receipt.receiptNumber != null) ...[
              _buildDetailSection(
                context,
                'Additional Information',
                [
                  if (receipt.receiptNumber != null)
                    _buildDetailRow('Receipt Number', receipt.receiptNumber!),
                  if (receipt.description != null)
                    _buildDetailRow('Description', receipt.description!),
                  if (receipt.notes != null)
                    _buildDetailRow('Notes', receipt.notes!),
                ],
              ),
              const SizedBox(height: AppConstants.largePadding),
            ],

            // Metadata
            _buildDetailSection(
              context,
              'Metadata',
              [
                _buildDetailRow('Created', timeago.format(receipt.createdAt)),
                _buildDetailRow('Updated', timeago.format(receipt.updatedAt)),
                if (receipt.originalFileName != null)
                  _buildDetailRow('Original File', receipt.originalFileName!),
                if (receipt.fileSize != null)
                  _buildDetailRow('File Size', _formatFileSize(receipt.fileSize!)),
                _buildDetailRow('Expense', receipt.isExpense ? 'Yes' : 'No'),
                _buildDetailRow('Reimbursable', receipt.isReimbursable ? 'Yes' : 'No'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: Text('Are you sure you want to delete the receipt from ${receipt.merchantName ?? 'Unknown Merchant'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(receiptsProvider.notifier).deleteReceipt(receipt.id);
              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
