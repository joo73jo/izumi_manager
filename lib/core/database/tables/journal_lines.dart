import 'package:drift/drift.dart';

import 'financial_accounts.dart';
import 'journal_entries.dart';

/// Debe y haber en centavos enteros, para evitar errores de punto flotante.
class JournalLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer().references(JournalEntries, #id)();
  IntColumn get accountId => integer().references(FinancialAccounts, #id)();
  IntColumn get debitCents => integer().withDefault(const Constant(0))();
  IntColumn get creditCents => integer().withDefault(const Constant(0))();
}
