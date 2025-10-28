import 'package:flutter/material.dart';
import '../models/category.dart' as models;
import '../utils/app_utils.dart';

class FilterChips extends StatelessWidget {
  final List<models.Category> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const FilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            key: const ValueKey('category_all'),
            label: const Text('All'),
            selected: selectedCategory == AppConstants.systemCategoryAll,
            onSelected: (selected) => onCategorySelected(AppConstants.systemCategoryAll),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('category_uncategorized'),
            label: const Text('Uncategorized'),
            selected:
                selectedCategory == AppConstants.uncategorizedCategory,
            onSelected: (selected) =>
                onCategorySelected(AppConstants.uncategorizedCategory),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                key: ValueKey('category_${category.name}'),
                label: Text(category.name),
                selected: selectedCategory == category.name,
                onSelected: (selected) => onCategorySelected(category.name),
                backgroundColor: category.color.withOpacity(0.1),
                selectedColor: category.color.withOpacity(0.3),
                checkmarkColor: category.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
