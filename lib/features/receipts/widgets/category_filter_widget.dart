import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/category_model.dart';

import '../../categories/providers/categories_provider.dart';
import '../providers/receipts_provider.dart';

/// Widget for filtering receipts by categories
class CategoryFilterWidget extends ConsumerStatefulWidget {
  final VoidCallback? onFilterChanged;

  const CategoryFilterWidget({
    super.key,
    this.onFilterChanged,
  });

  @override
  ConsumerState<CategoryFilterWidget> createState() => _CategoryFilterWidgetState();
}

class _CategoryFilterWidgetState extends ConsumerState<CategoryFilterWidget> {
  @override
  Widget build(BuildContext context) {
    final receiptsState = ref.watch(receiptsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final categories = categoriesState.categories;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // All categories chip
            FilterChip(
              label: const Text('All'),
              selected: receiptsState.categoryFilters.isEmpty,
              onSelected: (selected) => _onCategoryToggle(null, selected),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
            // Individual category chips
            ...categories.map((category) => _buildCategoryChip(category)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(CategoryModel category) {
    final receiptsState = ref.watch(receiptsProvider);
    final isSelected = receiptsState.categoryFilters.contains(category.id);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _parseColor(category.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(category.name),
          if (category.receiptCount != null && category.receiptCount! > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${category.receiptCount}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => _onCategoryToggle(category.id, selected),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _onCategoryToggle(String? categoryId, bool selected) {
    if (categoryId == null) {
      // "All" was selected - clear all category filters
      ref.read(receiptsProvider.notifier).setCategoryFilters([]);
    } else {
      // Individual category was toggled
      if (selected) {
        ref.read(receiptsProvider.notifier).addCategoryFilter(categoryId);
      } else {
        ref.read(receiptsProvider.notifier).removeCategoryFilter(categoryId);
      }
    }
    widget.onFilterChanged?.call();
  }

  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      String hexColor = colorString.replaceAll('#', '');
      
      // Add alpha if not present
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      // Fallback to a default color if parsing fails
      return Theme.of(context).colorScheme.primary;
    }
  }
}

/// Compact version of category filter for use in filter bars
class CompactCategoryFilterWidget extends ConsumerWidget {
  final VoidCallback? onFilterChanged;

  const CompactCategoryFilterWidget({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsState = ref.watch(receiptsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final categories = categoriesState.categories;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCount = receiptsState.categoryFilters.length;
    final hasSelection = selectedCount > 0;

    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasSelection 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(20),
          color: hasSelection 
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 16,
              color: hasSelection 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              hasSelection ? 'Categories ($selectedCount)' : 'Categories',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: hasSelection 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        // All categories option
        PopupMenuItem<String>(
          value: 'all',
          child: Row(
            children: [
              Icon(
                receiptsState.categoryFilters.isEmpty 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('All Categories'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Individual categories
        ...categories.map((category) => PopupMenuItem<String>(
          value: category.id,
          child: Row(
            children: [
              Icon(
                receiptsState.categoryFilters.contains(category.id)
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _parseColor(category.color, context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(category.name)),
              if (category.receiptCount != null && category.receiptCount! > 0)
                Text(
                  '${category.receiptCount}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        )),
      ],
      onSelected: (value) {
        if (value == 'all') {
          ref.read(receiptsProvider.notifier).setCategoryFilters([]);
        } else {
          final isSelected = receiptsState.categoryFilters.contains(value);
          if (isSelected) {
            ref.read(receiptsProvider.notifier).removeCategoryFilter(value);
          } else {
            ref.read(receiptsProvider.notifier).addCategoryFilter(value);
          }
        }
        onFilterChanged?.call();
      },
    );
  }

  Color _parseColor(String colorString, BuildContext context) {
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Theme.of(context).colorScheme.primary;
    }
  }
}
