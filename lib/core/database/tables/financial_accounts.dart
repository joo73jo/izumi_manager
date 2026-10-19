import 'package:drift/drift.dart';

/// Catálogo contable. Los montos nunca se guardan como double.
class FinancialAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // asset, liability, equity, income, expense
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}
