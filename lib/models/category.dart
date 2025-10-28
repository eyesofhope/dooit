import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int colorValue;

  Category({required this.name, required this.colorValue});

  Color get color => Color(colorValue);

  set color(Color color) {
    colorValue = color.value;
  }

  Category copyWith({String? name, int? colorValue}) {
    return Category(
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  String toString() {
    return 'Category{name: $name, color: ${color.toString()}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  // Default categories
  static List<Category> getDefaultCategories() {
    return [
      Category(name: 'General', colorValue: Colors.blue.value),
      Category(name: 'Work', colorValue: Colors.orange.value),
      Category(name: 'Personal', colorValue: Colors.green.value),
      Category(name: 'Shopping', colorValue: Colors.purple.value),
      Category(name: 'Health', colorValue: Colors.red.value),
      Category(name: 'Education', colorValue: Colors.indigo.value),
    ];
  }
}
