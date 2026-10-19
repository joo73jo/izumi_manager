class InventoryHistoryEntry {
  const InventoryHistoryEntry({
    required this.date,
    required this.reason,
    required this.quantityMillis,
  });

  final DateTime date;
  final String reason;
  final int quantityMillis;
}

class InventoryPurchaseRecord {
  const InventoryPurchaseRecord({
    required this.date,
    required this.quantityMillis,
    required this.totalCents,
  });

  final DateTime date;
  final int quantityMillis;
  final int totalCents;
}

class InventoryHistory {
  const InventoryHistory({required this.movements, required this.purchases});

  final List<InventoryHistoryEntry> movements;
  final List<InventoryPurchaseRecord> purchases;

  int get purchasedQuantityMillis =>
      purchases.fold(0, (sum, p) => sum + p.quantityMillis);

  int get purchasedTotalCents =>
      purchases.fold(0, (sum, p) => sum + p.totalCents);

  double? get averagePurchaseCost {
    if (purchasedQuantityMillis == 0) return null;

    // USD por unidad de medida del material.
    return purchasedTotalCents * 10 / purchasedQuantityMillis;
  }
}
