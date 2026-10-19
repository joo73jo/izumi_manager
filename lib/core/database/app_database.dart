import 'package:drift/drift.dart';

import 'database_connection.dart';
import 'tables/financial_accounts.dart';
import 'tables/journal_entries.dart';
import 'tables/journal_lines.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [FinancialAccounts, JournalEntries, JournalLines])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static LazyDatabase _openConnection() {
    return LazyDatabase(openIzumiDatabase);
  }

  @override
  int get schemaVersion => 1;
}
