import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/team_model.dart';
import '../../features/categories/providers/categories_provider.dart';
import '../../features/teams/providers/teams_provider.dart';

/// Enhanced category selector that matches React app functionality
/// Provides search, visual consistency, and proper Supabase integration
class EnhancedCategorySelector extends ConsumerStatefulWidget {
  final CategoryModel? selectedCategory;
  final ValueChanged<CategoryModel?> onCategorySelected;
  final String? placeholder;
  final bool enabled;
  final bool allowCreate;
  final String? label;
  final bool showReceiptCount;

  const EnhancedCategorySelector({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.placeholder,
    this.enabled = true,
    this.allowCreate = true,
    this.label,
    this.showReceiptCount = true,
  });

  @override
  ConsumerState<EnhancedCategorySelector> createState() => _EnhancedCategorySelectorState();
}

class _EnhancedCategorySelectorState extends ConsumerState<EnhancedCategorySelector> {
  final TextEditingController _searchController = TextEditingController();
  bool _isOpen = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load categories when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTeam = ref.read(currentTeamModelProvider);
      ref.read(categoriesProvider.notifier).loadCategories(teamId: currentTeam?.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> categories) {
    if (_searchQuery.isEmpty) {
      return categories;
    }
    
    return categories.where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Listen for team changes and reload categories
    ref.listen<TeamModel?>(currentTeamModelProvider, (previous, next) {
      if (previous?.id != next?.id) {
        ref.read(categoriesProvider.notifier).loadCategories(teamId: next?.id);
      }
    });

    final filteredCategories = _getFilteredCategories(categoriesState.displayCategories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Category selector button
        InkWell(
          onTap: widget.enabled ? () {
            setState(() {
              _isOpen = !_isOpen;
            });
          } : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _isOpen
                    ? colorScheme.primary
                    : colorScheme.outline,
                width: _isOpen ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: widget.enabled
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.selectedCategory != null
                      ? Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _parseColor(widget.selectedCategory!.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.selectedCategory!.name,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.placeholder ?? 'Select category...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: colorScheme.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        ),

        // Dropdown content - simplified and constrained
        if (_isOpen) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field - compact
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search categ...',
                      prefixIcon: const Icon(Icons.search, size: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      isDense: true,
                    ),
                    style: theme.textTheme.bodySmall,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Categories list - scrollable
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      // Uncategorized option
                      _buildCategoryItem(
                        context: context,
                        category: null,
                        isSelected: widget.selectedCategory == null,
                        onTap: () {
                          widget.onCategorySelected(null);
                          setState(() {
                            _isOpen = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      ),

                      // Category items
                      ...filteredCategories.map((category) => _buildCategoryItem(
                        context: context,
                        category: category,
                        isSelected: widget.selectedCategory?.id == category.id,
                        onTap: () {
                          widget.onCategorySelected(category);
                          setState(() {
                            _isOpen = false;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required CategoryModel? category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
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
                child: Text(
                  category.name,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showReceiptCount && category.receiptCount != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category.receiptCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ] else ...[
              Icon(
                Icons.remove_circle_outline,
                size: 12,
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
              Icon(
                Icons.check,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }



  Color _parseColor(String colorString) {
    try {
      final cleanColor = colorString.replaceFirst('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
