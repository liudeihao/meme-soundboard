import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_constants.dart';
import '../utils/category_l10n.dart';
import '../services/settings_service.dart';

/// 分类选择器组件
class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = SettingsService.instance.allCategories;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          final color = AppConstants.getCategoryColor(category);
          final icon = AppConstants.getCategoryIcon(category);

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withAlpha(77),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(77),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.categoryLabelForStored(category),
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
