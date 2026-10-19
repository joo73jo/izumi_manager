import 'inventory_category.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantityMillis,
    required this.minimumMillis,
  });

  final int id;
  final String name;
  final InventoryCategory category;
  final String unit;

  // 1000 unidades internas equivalen a una unidad visible.
  final int quantityMillis;
  final int minimumMillis;

  double get quantity => quantityMillis / 1000;
  double get minimum => minimumMillis / 1000;
  bool get lowStock => quantityMillis <= minimumMillis;
}
