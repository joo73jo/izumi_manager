class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.priceCents,
    required this.active,
  });

  final int id;
  final int productId;
  final String name;
  final int priceCents;
  final bool active;
}
