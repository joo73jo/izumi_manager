class PurchaseHistoryLine {
  const PurchaseHistoryLine({
    required this.name,
    required this.quantityMillis,
    required this.unit,
    required this.totalCents,
  });

  final String name;
  final int quantityMillis;
  final String unit;
  final int totalCents;
}

class PurchaseHistoryRecord {
  const PurchaseHistoryRecord({
    required this.id,
    required this.date,
    required this.description,
    required this.totalCents,
    required this.lines,
  });

  final int id;
  final DateTime date;
  final String description;
  final int totalCents;
  final List<PurchaseHistoryLine> lines;
}
