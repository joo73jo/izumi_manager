class FinancialOperationDetails {
  const FinancialOperationDetails({
    required this.date,
    required this.category,
    required this.quantity,
    required this.unitPriceCents,
    required this.paymentMethod,
    required this.notes,
  });

  final DateTime date;
  final String category;
  final int quantity;
  final int unitPriceCents;
  final String paymentMethod;
  final String notes;
}
