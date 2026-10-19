class ProductMaterial {
  const ProductMaterial({
    required this.inventoryItemId,
    required this.name,
    required this.unit,
    required this.quantityMillis,
    required this.wastePercent,
  });

  final int inventoryItemId;
  final String name;
  final String unit;
  final int quantityMillis;
  final int wastePercent;

  int get totalConsumptionMillis =>
      (quantityMillis * (100 + wastePercent) + 99) ~/ 100;
}
