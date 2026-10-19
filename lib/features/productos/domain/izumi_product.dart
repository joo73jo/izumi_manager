class IzumiProduct {
  const IzumiProduct({
    required this.id,
    required this.name,
    required this.collection,
    required this.description,
    required this.priceCents,
    required this.active,
    this.imagePath,
    this.stlPath,
  });

  final int id;
  final String name;
  final String collection;
  final String description;
  final int priceCents;
  final bool active;
  final String? imagePath;
  final String? stlPath;
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.collection,
    required this.description,
    required this.priceCents,
  });

  final String name;
  final String collection;
  final String description;
  final int priceCents;
}
