class ProductionMaterialInput {
  const ProductionMaterialInput({
    required this.itemId,
    required this.quantityMillis,
    required this.wastePercent,
  });

  final int itemId;
  final int quantityMillis;
  final int wastePercent;

  int get consumptionMillis =>
      (quantityMillis * (100 + wastePercent) + 99) ~/ 100;
}

class ProductionDraft {
  const ProductionDraft({
    required this.productId,
    required this.variantId,
    required this.materials,
    this.notes = '',
  });

  final int productId;
  final int variantId;
  final List<ProductionMaterialInput> materials;
  final String notes;
}

class ProductionRecord {
  const ProductionRecord({
    required this.id,
    required this.productName,
    required this.variantName,
    required this.createdAt,
    required this.notes,
  });

  final int id;
  final String productName;
  final String variantName;
  final DateTime createdAt;
  final String notes;
}
