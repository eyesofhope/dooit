import 'package:flutter/material.dart';
import '../models/category.dart' as models;

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
            label: const Text('All'),
            selected: selectedCategory == 'All',
            onSelected: (selected) => onCategorySelected('All'),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
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
