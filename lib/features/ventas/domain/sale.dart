enum SaleChannel {
  whatsapp,
  instagram,
  website,
  direct;

  String get label => switch (this) {
    whatsapp => 'WhatsApp',
    instagram => 'Instagram',
    website => 'Tienda web',
    direct => 'Venta directa',
  };
}

class SaleDraft {
  const SaleDraft({
    required this.date,
    required this.description,
    required this.channel,
    required this.revenueCents,
    required this.estimatedCostCents,
    this.customerName = '',
    this.notes = '',
  });

  final DateTime date;
  final String description;
  final SaleChannel channel;
  final int revenueCents;
  final int estimatedCostCents;
  final String customerName;
  final String notes;
}

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.date,
    required this.description,
    required this.channel,
    required this.revenueCents,
    required this.estimatedCostCents,
    required this.customerName,
    required this.notes,
  });

  final int id;
  final DateTime date;
  final String description;
  final SaleChannel channel;
  final int revenueCents;
  final int estimatedCostCents;
  final String customerName;
  final String notes;

  int get estimatedGrossProfitCents => revenueCents - estimatedCostCents;
}
