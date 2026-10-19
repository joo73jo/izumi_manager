class FinancialMovement {
  const FinancialMovement({
    required this.date,
    required this.description,
    required this.bankChangeCents,
  });

  final DateTime date;
  final String description;
  final int bankChangeCents;
}

class FinancialSummary {
  const FinancialSummary({
    required this.bankCents,
    required this.capitalCents,
    required this.contributionRegistered,
    required this.movements,
  });

  final int bankCents;
  final int capitalCents;
  final bool contributionRegistered;
  final List<FinancialMovement> movements;
}
