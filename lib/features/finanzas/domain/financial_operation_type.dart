enum FinancialOperationType { inventory, expense, asset }

extension FinancialOperationInfo on FinancialOperationType {
  String get label => switch (this) {
    FinancialOperationType.inventory => 'Compra de inventario',
    FinancialOperationType.expense => 'Gasto operativo',
    FinancialOperationType.asset => 'Compra de maquinaria o activo',
  };

  String get accountCode => switch (this) {
    FinancialOperationType.inventory => '1200',
    FinancialOperationType.expense => '5100',
    FinancialOperationType.asset => '1500',
  };
}
