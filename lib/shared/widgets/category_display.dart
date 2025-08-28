import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// Widget to display a category badge with color and name
class CategoryDisplay extends StatelessWidget {
  final CategoryModel? category;
  final bool showCount;
  final CategoryDisplaySize size;

  const CategoryDisplay({
    super.key,
    this.category,
    this.showCount = false,
    this.size = CategoryDisplaySize.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      return _buildUncategorizedBadge(context);
    }

    return _buildCategoryBadge(context, category!);
  }

  Widget _buildUncategorizedBadge(BuildContext context) {
    final theme = Theme.of(context);
    final sizeConfig = _getSizeConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeConfig.horizontalPadding,
        vertical: sizeConfig.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(sizeConfig.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag,
            size: sizeConfig.iconSize,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: sizeConfig.spacing),
          Text(
            'Uncategorized',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: sizeConfig.fontSize,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context, CategoryModel category) {
    final theme = Theme.of(context);
    final sizeConfig = _getSizeConfig();

    // Parse the hex color from the category
    Color categoryColor;
    try {
      final colorString = category.color.replaceFirst('#', '');
      categoryColor = Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      categoryColor = theme.colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeConfig.horizontalPadding,
        vertical: sizeConfig.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(sizeConfig.borderRadius),
        border: Border.all(
          color: Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: sizeConfig.colorIndicatorSize,
            height: sizeConfig.colorIndicatorSize,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: sizeConfig.spacing),
          Flexible(
            child: Text(
              category.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: sizeConfig.fontSize,
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showCount && category.receiptCount != null) ...[
            SizedBox(width: sizeConfig.spacing),
            Text(
              '(${category.receiptCount})',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: sizeConfig.fontSize * 0.9,
                color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _CategorySizeConfig _getSizeConfig() {
    switch (size) {
      case CategoryDisplaySize.small:
        return const _CategorySizeConfig(
          fontSize: 10,
          horizontalPadding: 6,
          verticalPadding: 2,
          iconSize: 10,
          colorIndicatorSize: 6,
          spacing: 4,
          borderRadius: 8,
        );
      case CategoryDisplaySize.medium:
        return const _CategorySizeConfig(
          fontSize: 12,
          horizontalPadding: 8,
          verticalPadding: 4,
          iconSize: 12,
          colorIndicatorSize: 8,
          spacing: 6,
          borderRadius: 10,
        );
      case CategoryDisplaySize.large:
        return const _CategorySizeConfig(
          fontSize: 14,
          horizontalPadding: 10,
          verticalPadding: 6,
          iconSize: 14,
          colorIndicatorSize: 10,
          spacing: 8,
          borderRadius: 12,
        );
    }
  }
}

enum CategoryDisplaySize {
  small,
  medium,
  large,
}

class _CategorySizeConfig {
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double colorIndicatorSize;
  final double spacing;
  final double borderRadius;

  const _CategorySizeConfig({
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.colorIndicatorSize,
    required this.spacing,
    required this.borderRadius,
  });
}

/// Helper widget for category selection in forms
class CategorySelector extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel?> onCategorySelected;
  final String? placeholder;
  final bool enabled;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
    this.placeholder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CategoryModel?>(
      initialValue: selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        hintText: placeholder ?? 'Select a category',
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<CategoryModel?>(
          value: null,
          child: Text('Uncategorized'),
        ),
        ...categories.map((category) => DropdownMenuItem<CategoryModel?>(
              value: category,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(category.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (category.receiptCount != null)
                    Text(
                      '(${category.receiptCount})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            )),
      ],
      onChanged: enabled ? onCategorySelected : null,
    );
  }

  Color _parseColor(String colorString) {
    try {
      final cleanColor = colorString.replaceFirst('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}
