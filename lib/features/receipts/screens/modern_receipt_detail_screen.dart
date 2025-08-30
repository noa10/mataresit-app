import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/enhanced_image_viewer.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/line_item_model.dart';
import '../providers/receipts_provider.dart';
import '../widgets/basic_line_items_widget.dart';
import '../services/receipt_service.dart';
import '../../categories/providers/categories_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../../../shared/models/team_model.dart';

class ModernReceiptDetailScreen extends ConsumerStatefulWidget {
  final String receiptId;

  const ModernReceiptDetailScreen({
    super.key,
    required this.receiptId,
  });

  @override
  ConsumerState<ModernReceiptDetailScreen> createState() => _ModernReceiptDetailScreenState();
}

class _ModernReceiptDetailScreenState extends ConsumerState<ModernReceiptDetailScreen>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  final bool _isImageExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _merchantController = TextEditingController();
  final _totalController = TextEditingController();
  final _taxController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedCurrency;

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

    // Load categories when the screen initializes with team context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTeam = ref.read(currentTeamModelProvider);
      ref.read(categoriesProvider.notifier).loadCategories(teamId: currentTeam?.id);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _merchantController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    _paymentMethodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFormFields(ReceiptModel receipt) {
    _merchantController.text = receipt.merchantName ?? '';
    _totalController.text = receipt.totalAmount?.toString() ?? '';
    _taxController.text = receipt.taxAmount?.toString() ?? '';
    _paymentMethodController.text = receipt.paymentMethod ?? '';
    _notesController.text = receipt.notes ?? '';
    _selectedDate = receipt.transactionDate;
    _selectedCurrency = receipt.currency ?? 'MYR';
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    final receipt = ref.read(receiptProvider(widget.receiptId));
    if (receipt == null) return;

    try {
      // Validate receipt data
      final receiptData = {
        'merchant_name': _merchantController.text.trim(),
        'total_amount': double.tryParse(_totalController.text) ?? 0.0,
        'tax_amount': double.tryParse(_taxController.text) ?? 0.0,
        'transaction_date': _selectedDate?.toIso8601String(),
        'currency': _selectedCurrency ?? 'MYR',
        'payment_method': _paymentMethodController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': ReceiptStatus.active,
      };

      final validationErrors = ReceiptService.validateReceiptData(receiptData);
      if (validationErrors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: ${validationErrors.values.first}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate line items
      final lineItems = receipt.lineItems ?? [];
      for (int i = 0; i < lineItems.length; i++) {
        final itemErrors = ReceiptService.validateLineItem(lineItems[i]);
        if (itemErrors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Line item ${i + 1}: ${itemErrors.values.first}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Saving changes...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Update receipt with line items
      await ReceiptService.updateReceiptWithLineItems(
        receiptId: widget.receiptId,
        receiptData: receiptData,
        lineItems: lineItems,
      );

      // Update local state
      setState(() {
        _isEditing = false;
      });

      // Hide loading and show success
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh the receipt data
      ref.invalidate(receiptProvider(widget.receiptId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // Reset form fields to original values
    final receipt = ref.read(receiptProvider(widget.receiptId));
    if (receipt != null) {
      _initializeFormFields(receipt);
    }
  }

  void _handleLineItemChanged(int index, LineItemModel lineItem) {
    final receipt = ref.read(receiptProvider(widget.receiptId));
    if (receipt == null) return;

    // Update the line items list
    final updatedLineItems = List<LineItemModel>.from(receipt.lineItems ?? []);
    if (index < updatedLineItems.length) {
      updatedLineItems[index] = lineItem;
    }

    // Calculate new totals
    final totals = ReceiptService.calculateReceiptTotals(updatedLineItems);

    // Update controllers with new totals
    _totalController.text = totals['total']!.toStringAsFixed(2);

    // Update the provider state
    ref.invalidate(receiptProvider(widget.receiptId));
  }

  void _handleAddLineItem() {
    final receipt = ref.read(receiptProvider(widget.receiptId));
    if (receipt == null) return;

    final newLineItem = ReceiptService.createNewLineItem(widget.receiptId);
    final updatedLineItems = List<LineItemModel>.from(receipt.lineItems ?? []);
    updatedLineItems.add(newLineItem);

    ref.invalidate(receiptProvider(widget.receiptId));
  }

  void _handleRemoveLineItem(int index) {
    final receipt = ref.read(receiptProvider(widget.receiptId));
    if (receipt == null) return;

    final updatedLineItems = List<LineItemModel>.from(receipt.lineItems ?? []);
    if (index < updatedLineItems.length) {
      updatedLineItems.removeAt(index);
    }

    // Recalculate totals
    final totals = ReceiptService.calculateReceiptTotals(updatedLineItems);

    // Update controllers
    _totalController.text = totals['total']!.toStringAsFixed(2);

    ref.invalidate(receiptProvider(widget.receiptId));
  }

  @override
  Widget build(BuildContext context) {
    final receipt = ref.watch(receiptProvider(widget.receiptId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Listen for team changes and reload categories
    ref.listen<TeamModel?>(currentTeamModelProvider, (previous, next) {
      if (previous?.id != next?.id) {
        // Team changed, reload categories with new team context
        ref.read(categoriesProvider.notifier).loadCategories(teamId: next?.id);
      }
    });

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

    // Initialize form fields when receipt is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isEditing) {
        _initializeFormFields(receipt);
      }
    });

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar with Hero Header
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              title: Text(
                receipt.merchantName ?? 'Receipt Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Receipt Header Info - Simplified for space
                          Flexible(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        receipt.merchantName ?? 'Unnamed Receipt',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              receipt.transactionDate != null
                                                  ? _formatDate(receipt.transactionDate!)
                                                  : 'No date',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${receipt.currency ?? 'MYR'} ${receipt.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.primary,
                                              letterSpacing: -0.25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Status and Category chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusChip(receipt.status),
                                const SizedBox(width: 8),
                                if (receipt.category != null)
                                  _buildCategoryChip(receipt.category!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (_isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelEdit,
                    tooltip: 'Cancel',
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveChanges,
                    tooltip: 'Save',
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _toggleEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Implement share
                    },
                    tooltip: 'Share',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          _showDeleteDialog(context, ref, receipt);
                          break;
                        case 'export':
                          // TODO: Implement export
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download),
                            SizedBox(width: 8),
                            Text('Export'),
                          ],
                        ),
                      ),
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
              ],
            ),

            // Content - Using SliverList for better performance and scrolling
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Receipt Image Section (moved here for better layout)
                  if (receipt.imageUrl != null) ...[
                    _buildReceiptImageSection(receipt, theme, colorScheme),
                    const SizedBox(height: AppConstants.largePadding),
                  ],

                  // Basic Receipt Information Card
                  _buildBasicReceiptCard(receipt, theme, colorScheme),
                  const SizedBox(height: AppConstants.largePadding),

                  // Line Items Section
                  BasicLineItemsWidget(
                    lineItems: receipt.lineItems ?? [],
                    currency: receipt.currency ?? 'MYR',
                    isEditing: _isEditing,
                    onLineItemChanged: (index, lineItem) {
                      _handleLineItemChanged(index, lineItem);
                    },
                    onAddLineItem: () {
                      _handleAddLineItem();
                    },
                    onRemoveLineItem: (index) {
                      _handleRemoveLineItem(index);
                    },
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // Basic Metadata Card
                  _buildBasicMetadataCard(receipt, theme),

                  // Add bottom padding for safe area
                  const SizedBox(height: AppConstants.largePadding),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }









  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                letterSpacing: 0.1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  Widget _buildStatusChip(ReceiptStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case ReceiptStatus.active:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        label = 'Active';
        break;
      case ReceiptStatus.draft:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        label = 'Draft';
        break;
      case ReceiptStatus.archived:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey.shade700;
        label = 'Archived';
        break;
      case ReceiptStatus.deleted:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        label = 'Deleted';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicReceiptCard(ReceiptModel receipt, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Receipt Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            if (_isEditing) ...[
              TextFormField(
                controller: _merchantController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Merchant',
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalController,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Total Amount',
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: colorScheme.primary,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency ?? 'MYR',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: ['MYR', 'USD', 'EUR', 'GBP', 'SGD'].map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(
                            currency,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildDetailRow('Merchant', receipt.merchantName ?? 'Unknown'),
              _buildDetailRow('Total', '${receipt.currency ?? 'MYR'} ${receipt.totalAmount?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Date', receipt.transactionDate != null ? _formatDate(receipt.transactionDate!) : 'No date'),
              if (receipt.paymentMethod != null)
                _buildDetailRow('Payment Method', receipt.paymentMethod!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicMetadataCard(ReceiptModel receipt, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Metadata',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Created', timeago.format(receipt.createdAt)),
            _buildDetailRow('Updated', timeago.format(receipt.updatedAt)),
            _buildDetailRow('Expense', receipt.isExpense ? 'Yes' : 'No'),
            _buildDetailRow('Reimbursable', receipt.isReimbursable ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptImageSection(ReceiptModel receipt, ThemeData theme, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isImageExpanded ? 350 : 200, // Increased heights for better viewing
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: receipt.imageUrl != null
          ? EnhancedImageViewer(
              imageUrl: receipt.imageUrl!,
              title: 'Receipt from ${receipt.merchantName ?? 'Unknown Merchant'}',
              heroTag: 'receipt_${receipt.id}',
              showControls: true,
              enableRotation: true,
              enableFullscreen: true,
              minScale: 0.5,
              maxScale: 4.0,
              initialScale: 1.0,
            )
          : Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No receipt image',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

}
