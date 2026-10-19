import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/capital_overview.dart';

class CapitalOverviewRepository {
  CapitalOverviewRepository(this.db);

  final AppDatabase db;

  Future<int> balance(String code) async {
    final rows = await db
        .customSelect(
          '''
      SELECT
        a.type,
        COALESCE(SUM(l.debit_cents), 0) AS debit,
        COALESCE(SUM(l.credit_cents), 0) AS credit
      FROM financial_accounts a
      LEFT JOIN journal_lines l ON l.account_id = a.id
      WHERE a.code = ?
      GROUP BY a.id, a.type
    ''',
          variables: [Variable.withString(code)],
        )
        .get();

    if (rows.isEmpty) return 0;

    final row = rows.first;
    final debit = row.read<int>('debit');
    final credit = row.read<int>('credit');
    final type = row.read<String>('type');

    return type == 'asset' || type == 'expense'
        ? debit - credit
        : credit - debit;
  }

  Future<CapitalOverview> load() async {
    return CapitalOverview(
      contributionCents: await balance('3100'),
      bankCents: await balance('1100'),
      inventoryCents: await balance('1200'),
      equipmentCents: await balance('1500'),
      expensesCents: await balance('5100'),
    );
  }
}
