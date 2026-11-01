import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/line_item_model.dart';
import '../../../shared/models/receipt_model.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/utils/confidence_utils.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/category_display.dart';
import '../../../shared/widgets/enhanced_image_viewer.dart';
import '../../categories/providers/categories_provider.dart';
import '../../claims/widgets/claim_from_receipt_dialog.dart';
import '../../teams/providers/teams_provider.dart';
import '../providers/receipts_provider.dart';
import '../services/embedding_service.dart';
import '../services/receipt_service.dart';
import '../widgets/basic_line_items_widget.dart';

class ModernReceiptDetailScreen extends ConsumerStatefulWidget {
  final String receiptId;

  const ModernReceiptDetailScreen({super.key, required this.receiptId});

  @override
  ConsumerState<ModernReceiptDetailScreen> createState() =>
      _ModernReceiptDetailScreenState();
}

class _ModernReceiptDetailScreenState
    extends ConsumerState<ModernReceiptDetailScreen>
    with TickerProviderStateMixin {
  bool _isEditing = false;
  bool _isUpdatingStatus = false;
  bool _formInitialized = false;
  bool _categoryChanged = false;
  List<LineItemModel>? _editedLineItems;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  // Form controllers
  final _merchantController = TextEditingController();
  final _totalController = TextEditingController();
  final _taxController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedCurrency;
  CategoryModel? _selectedCategory;

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
      ref
          .read(categoriesProvider.notifier)
          .loadCategories(teamId: currentTeam?.id);
    });
  }

  @override
  void didUpdateWidget(covariant ModernReceiptDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receiptId != widget.receiptId) {
      _formInitialized = false;
      _editedLineItems = null;
    }
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
    // Normalize to ISO currency codes so dropdown value always matches items
    _selectedCurrency = CurrencyUtils.normalizeCurrencyCode(receipt.currency);
    _editedLineItems = List<LineItemModel>.from(receipt.lineItems ?? const []);

    // Initialize selected category
    final categoriesState = ref.read(categoriesProvider);
    _categoryChanged = false;
    if (receipt.customCategoryId != null) {
      _selectedCategory = categoriesState.displayCategories
          .where((cat) => cat.id == receipt.customCategoryId)
          .firstOrNull;
    } else {
      _selectedCategory = null;
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    final receiptAsync = ref.read(receiptProvider(widget.receiptId));
    final receipt = receiptAsync.value;
    if (receipt == null) return;

    final effectiveCategory =
        _selectedCategory ??
        (!_categoryChanged
            ? _resolveCategory(
                receipt,
                ref.read(categoriesProvider).displayCategories,
              )
            : null);

    try {
      // Validate receipt data
      final receiptData = {
        'merchant_name': _merchantController.text.trim(),
        'total_amount': double.tryParse(_totalController.text) ?? 0.0,
        'tax_amount': double.tryParse(_taxController.text) ?? 0.0,
        'transaction_date': _selectedDate?.toIso8601String(),
        'currency': CurrencyUtils.normalizeCurrencyCode(_selectedCurrency),
        'payment_method': _paymentMethodController.text.trim(),
        // Note: 'notes' field removed as it doesn't exist in the receipts table
        // Notes should be handled via receipt_comments table in future implementation
        'status': receipt.status.name,
        'custom_category_id': effectiveCategory?.id,
        'category': effectiveCategory?.name,
      };

      final validationErrors = ReceiptService.validateReceiptData(receiptData);
      if (validationErrors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: ${validationErrors.values.first}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      // Validate line items
      final lineItems = _editedLineItems ?? receipt.lineItems ?? [];
      for (int i = 0; i < lineItems.length; i++) {
        final itemErrors = ReceiptService.validateLineItem(lineItems[i]);
        if (itemErrors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Line item ${i + 1}: ${itemErrors.values.first}'),
              backgroundColor: Theme.of(context).colorScheme.error,
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
        final colors = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colors.onPrimary, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Receipt updated successfully')),
              ],
            ),
            backgroundColor: colors.primary,
            action: SnackBarAction(
              label: 'Syncing search...',
              textColor: colors.onPrimary.withValues(alpha: 0.8),
              onPressed: () {
                // Show info about embedding sync
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Search index is being updated in the background',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }

      // Refresh the receipt data from database to show updated values
      ref.invalidate(receiptProvider(widget.receiptId));
      ref.invalidate(refreshReceiptProvider(widget.receiptId));

      // Force refresh to get the latest data
      final refreshed = await ref.read(
        refreshReceiptProvider(widget.receiptId).future,
      );

      if (mounted && refreshed != null) {
        _initializeFormFields(refreshed);
        setState(() {});
      }

      // Trigger embedding synchronization for search index
      // This is handled automatically by ReceiptService, but we can provide user feedback
      if (mounted && EmbeddingService.isEmbeddingSyncEnabled()) {
        // Show a subtle notification that search index is being updated
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Updating search index...'),
                  ],
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _setReviewStatus(ReceiptModel receipt, bool reviewed) async {
    if (_isUpdatingStatus) return;
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final receiptData = {
        'merchant_name': receipt.merchantName ?? '',
        'total_amount': receipt.totalAmount ?? 0.0,
        'tax_amount': receipt.taxAmount ?? 0.0,
        'transaction_date': receipt.transactionDate?.toIso8601String(),
        'currency': CurrencyUtils.normalizeCurrencyCode(receipt.currency),
        'payment_method': receipt.paymentMethod ?? '',
        'custom_category_id': receipt.customCategoryId,
        'category': receipt.category,
        'status': reviewed ? 'reviewed' : 'unreviewed',
      };

      await ReceiptService.updateReceiptWithLineItems(
        receiptId: widget.receiptId,
        receiptData: receiptData,
        lineItems: receipt.lineItems ?? const [],
      );

      ref.invalidate(receiptProvider(widget.receiptId));
      ref.invalidate(refreshReceiptProvider(widget.receiptId));
      await ref.read(refreshReceiptProvider(widget.receiptId).future);

      if (!mounted) return;
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewed ? 'Receipt marked as reviewed' : 'Receipt moved to review',
          ),
          backgroundColor: reviewed ? colors.primary : colors.tertiary,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update receipt: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // Reset form fields to original values
    final receiptAsync = ref.read(receiptProvider(widget.receiptId));
    final receipt = receiptAsync.value;
    if (receipt != null) {
      _initializeFormFields(receipt);
    }
  }

  void _handleLineItemChanged(int index, LineItemModel lineItem) {
    final current = _editedLineItems ?? const <LineItemModel>[];
    if (index < 0 || index >= current.length) return;

    final updatedLineItems = List<LineItemModel>.from(current);
    updatedLineItems[index] = lineItem;
    final totals = ReceiptService.calculateReceiptTotals(updatedLineItems);

    setState(() {
      _editedLineItems = updatedLineItems;
      _totalController.text = totals['total']!.toStringAsFixed(2);
    });
  }

  void _handleAddLineItem() {
    final updatedLineItems = List<LineItemModel>.from(
      _editedLineItems ?? const <LineItemModel>[],
    );
    updatedLineItems.add(ReceiptService.createNewLineItem(widget.receiptId));

    setState(() {
      _editedLineItems = updatedLineItems;
    });
  }

  void _handleRemoveLineItem(int index) {
    final current = _editedLineItems ?? const <LineItemModel>[];
    if (index < 0 || index >= current.length) return;

    final updatedLineItems = List<LineItemModel>.from(current)..removeAt(index);
    final totals = ReceiptService.calculateReceiptTotals(updatedLineItems);

    setState(() {
      _editedLineItems = updatedLineItems;
      _totalController.text = totals['total']!.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptAsync = ref.watch(receiptProvider(widget.receiptId));
    final categories = ref.watch(categoriesProvider).displayCategories;

    // Listen for team changes and reload categories
    ref.listen<TeamModel?>(currentTeamModelProvider, (previous, next) {
      if (previous?.id != next?.id) {
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

        // Initialize form fields once when the receipt is loaded. Re-running
        // this on every frame used to reset a category the user had selected.
        if (!_formInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isEditing && !_formInitialized) {
              _initializeFormFields(receipt);
              setState(() {
                _formInitialized = true;
              });
            }
          });
        }

        // Categories may finish loading after the receipt, so restore the
        // selected category once it becomes available.
        if (!_categoryChanged &&
            _selectedCategory == null &&
            receipt.customCategoryId != null) {
          final matched = _resolveCategory(receipt, categories);
          if (matched != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_categoryChanged && _selectedCategory == null) {
                setState(() {
                  _selectedCategory = matched;
                });
              }
            });
          }
        }

        return _buildReceiptScaffold(context, receipt);
      },
      loading: () => _buildStateScaffold(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
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
              onPressed: () =>
                  ref.invalidate(receiptProvider(widget.receiptId)),
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

  Widget _buildReceiptScaffold(BuildContext context, ReceiptModel receipt) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lineItems =
        _editedLineItems ??
        List<LineItemModel>.from(receipt.lineItems ?? const []);
    final hasConfidence = _hasConfidence(receipt);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildPageHeader(context, receipt)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (receipt.imageUrl != null) ...[
                      _buildReceiptImagePanel(receipt, colors),
                      const SizedBox(height: 12),
                    ],
                    _buildInformationPanel(receipt, theme),
                    const SizedBox(height: 12),
                    if (hasConfidence) ...[
                      _buildConfidencePanel(receipt, theme),
                      const SizedBox(height: 12),
                    ],
                    BasicLineItemsWidget(
                      lineItems: lineItems,
                      currency: receipt.currency ?? 'MYR',
                      isEditing: _isEditing,
                      onLineItemChanged: _handleLineItemChanged,
                      onAddLineItem: _handleAddLineItem,
                      onRemoveLineItem: _handleRemoveLineItem,
                    ),
                    const SizedBox(height: 12),
                    _buildMetadataPanel(receipt, theme),
                    if (!_isEditing) ...[
                      const SizedBox(height: 12),
                      _buildReviewPanel(receipt, theme),
                      const SizedBox(height: 12),
                      _buildCreateClaimPanel(receipt, theme),
                    ],
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, ReceiptModel receipt) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final merchant = receipt.merchantName?.trim();
    final merchantLabel = merchant == null || merchant.isEmpty
        ? 'Unnamed Receipt'
        : merchant;
    final categories = ref.watch(categoriesProvider).displayCategories;
    final category = _resolveCategory(receipt, categories);
    final categoryLabel = category?.name ?? receipt.category?.trim();
    final dateLabel = receipt.transactionDate == null
        ? null
        : _dateFormat.format(receipt.transactionDate!);
    final lede = [
      if (categoryLabel != null && categoryLabel.isNotEmpty) categoryLabel,
      if (dateLabel != null) dateLabel,
    ].join(' · ');

    return Padding(
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
                style: IconButton.styleFrom(foregroundColor: colors.onSurface),
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
                    if (receipt.processingStatus != ProcessingStatus.completed)
                      _ProcessingPill(status: receipt.processingStatus),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatAmount(receipt.totalAmount, receipt.currency),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildHeaderActions(context, receipt),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context, ReceiptModel receipt) {
    final colors = Theme.of(context).colorScheme;

    if (_isEditing) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _cancelEdit,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save'),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _toggleEdit,
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
                _showDeleteDialog(context, receipt);
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
                  Icon(Icons.download_outlined),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: colors.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: colors.error)),
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
                Icon(Icons.more_horiz, size: 18, color: colors.onSurface),
                const SizedBox(width: 8),
                Text(
                  'More',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptImagePanel(ReceiptModel receipt, ColorScheme colors) {
    return Container(
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
        title: 'Receipt from ${receipt.merchantName ?? 'Unknown Merchant'}',
        heroTag: 'receipt_${receipt.id}',
        showControls: true,
        enableRotation: true,
        enableFullscreen: true,
        minScale: 0.5,
        maxScale: 4.0,
        initialScale: 1.0,
      ),
    );
  }

  Widget _buildInformationPanel(ReceiptModel receipt, ThemeData theme) {
    if (_isEditing) {
      return _Panel(
        title: 'Receipt Information',
        meta: (receipt.currency ?? 'MYR').toUpperCase(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  TextFormField(
                    controller: _merchantController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Merchant'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _totalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Amount',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                          ),
                          items:
                              CurrencyConfigs.getSelectableCurrencyCodes(
                                selectedCurrency: _selectedCurrency,
                              ).map((currency) {
                                return DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
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
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _paymentMethodController,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _taxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tax Amount',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            _FieldRow(label: 'Category', child: _buildCategoryWidget(receipt)),
          ],
        ),
      );
    }

    final categories = ref.watch(categoriesProvider).displayCategories;
    final category = _resolveCategory(receipt, categories);
    final Widget categoryValue = category != null
        ? CategoryDisplay(category: category, size: CategoryDisplaySize.small)
        : receipt.category != null && receipt.category!.trim().isNotEmpty
        ? Text(
            receipt.category!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          )
        : CategoryDisplay(category: null, size: CategoryDisplaySize.small);
    final rows = <Widget>[];

    void addRow(String label, Widget value) {
      if (rows.isNotEmpty) {
        rows.add(Divider(height: 1, color: theme.colorScheme.outlineVariant));
      }
      rows.add(_FieldRow(label: label, child: value));
    }

    addRow(
      'Merchant',
      Text(
        receipt.merchantName ?? 'Unknown',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    addRow(
      'Date',
      Text(
        receipt.transactionDate != null
            ? _dateFormat.format(receipt.transactionDate!).toUpperCase()
            : 'No date',
        style: _dataStyle(theme),
      ),
    );
    addRow('Category', categoryValue);
    addRow(
      'Payment Method',
      Text(
        receipt.paymentMethod ?? '—',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
    if (receipt.taxAmount != null) {
      addRow(
        'Tax',
        Text(
          _formatAmount(receipt.taxAmount, receipt.currency),
          style: _dataStyle(theme),
        ),
      );
    }
    addRow(
      'Total',
      Text(
        _formatAmount(receipt.totalAmount, receipt.currency),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontFamily: 'IBMPlexMono',
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
    addRow('Processing', _ProcessingPill(status: receipt.processingStatus));
    if (receipt.receiptNumber != null && receipt.receiptNumber!.isNotEmpty) {
      addRow(
        'Receipt Number',
        Text(receipt.receiptNumber!, style: _dataStyle(theme)),
      );
    }

    return _Panel(
      title: 'Receipt Information',
      meta: (receipt.currency ?? 'MYR').toUpperCase(),
      child: Column(children: rows),
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

  Widget _buildMetadataPanel(ReceiptModel receipt, ThemeData theme) {
    final rows = <Widget>[];

    void addRow(String label, Widget value) {
      if (rows.isNotEmpty) {
        rows.add(Divider(height: 1, color: theme.colorScheme.outlineVariant));
      }
      rows.add(_FieldRow(label: label, child: value));
    }

    addRow(
      'Created',
      Text(timeago.format(receipt.createdAt), style: _bodyStyle(theme)),
    );
    addRow(
      'Updated',
      Text(timeago.format(receipt.updatedAt), style: _bodyStyle(theme)),
    );
    if (receipt.originalFileName != null) {
      addRow(
        'Original File',
        Text(receipt.originalFileName!, style: _bodyStyle(theme)),
      );
    }
    if (receipt.fileSize != null) {
      addRow(
        'File Size',
        Text(_formatFileSize(receipt.fileSize!), style: _dataStyle(theme)),
      );
    }
    addRow(
      'Expense',
      Text(receipt.isExpense ? 'Yes' : 'No', style: _dataStyle(theme)),
    );
    addRow(
      'Reimbursable',
      Text(receipt.isReimbursable ? 'Yes' : 'No', style: _dataStyle(theme)),
    );

    return _Panel(
      title: 'Metadata',
      child: Column(children: rows),
    );
  }

  Widget _buildReviewPanel(ReceiptModel receipt, ThemeData theme) {
    final colors = theme.colorScheme;
    final reviewed = receipt.status == ReceiptStatus.reviewed;

    return _Panel(
      title: 'Review',
      meta: receipt.status.displayName.toUpperCase(),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reviewed
                  ? 'This receipt has been reviewed.'
                  : 'Approve this receipt once the extracted details look right.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: reviewed
                  ? OutlinedButton.icon(
                      onPressed: _isUpdatingStatus
                          ? null
                          : () => _setReviewStatus(receipt, false),
                      icon: _isUpdatingStatus
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            )
                          : const Icon(Icons.undo, size: 18),
                      label: const Text('Move to review'),
                    )
                  : FilledButton.icon(
                      onPressed: _isUpdatingStatus
                          ? null
                          : () => _setReviewStatus(receipt, true),
                      icon: _isUpdatingStatus
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateClaimPanel(ReceiptModel receipt, ThemeData theme) {
    return _Panel(
      title: 'Create Expense Claim',
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert this receipt into an expense claim for reimbursement.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCreateClaimDialog(receipt),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Create Claim'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClaimDialog(ReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => ClaimFromReceiptDialog(
        receipt: receipt,
        onClaimCreated: () {
          // Optionally refresh data or show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Claim created successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatAmount(double? amount, String? currency) {
    return CurrencyUtils.formatCurrencySafe(amount, currency);
  }

  bool _hasConfidence(ReceiptModel receipt) {
    return (receipt.aiSuggestions?.containsKey('confidence') ?? false) ||
        (receipt.confidenceScores?.isNotEmpty ?? false);
  }

  CategoryModel? _resolveCategory(
    ReceiptModel receipt,
    List<CategoryModel> categories,
  ) {
    CategoryModel? category;
    if (receipt.customCategoryId != null) {
      category = categories
          .where((cat) => cat.id == receipt.customCategoryId)
          .firstOrNull;

      // If category not found by ID, try to find by name (case-insensitive)
      if (category == null && receipt.category != null) {
        category = categories
            .where(
              (cat) =>
                  cat.name.toLowerCase() == receipt.category!.toLowerCase(),
            )
            .firstOrNull;
      }
    }
    return category;
  }

  void _showDeleteDialog(BuildContext context, ReceiptModel receipt) {
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

  Widget _buildCategoryWidget(ReceiptModel receipt) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch the categories state to ensure they're loaded
        final categoriesState = ref.watch(categoriesProvider);

        if (_isEditing) {
          // Show category selector button that opens a modal
          return InkWell(
            onTap: () => _showCategorySelector(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedCategory != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _parseColor(_selectedCategory!.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _selectedCategory!.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Select category...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }

        // Show category display in view mode
        final category = _resolveCategory(
          receipt,
          categoriesState.displayCategories,
        );
        return CategoryDisplay(
          category: category,
          size: CategoryDisplaySize.small,
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      final cleanColor = colorString.replaceFirst('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  void _showCategorySelector(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.read(categoriesProvider);
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Select Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),

            // Categories list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                children: [
                  // Uncategorized option
                  _buildCategoryModalItem(
                    context: context,
                    category: null,
                    isSelected: _selectedCategory == null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _categoryChanged = true;
                      });
                      Navigator.pop(context);
                    },
                  ),

                  // Category items
                  ...categoriesState.displayCategories.map(
                    (category) => _buildCategoryModalItem(
                      context: context,
                      category: category,
                      isSelected: _selectedCategory?.id == category.id,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                          _categoryChanged = true;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryModalItem({
    required BuildContext context,
    required CategoryModel? category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (category != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _parseColor(category.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(category.name, style: theme.textTheme.bodyMedium),
              ),
              if (category.receiptCount != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${category.receiptCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ] else ...[
              Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uncategorized',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 20, color: colorScheme.primary),
            ],
          ],
        ),
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
