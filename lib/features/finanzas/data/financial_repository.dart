import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/financial_summary.dart';

class FinancialRepository {
  FinancialRepository(this.db);

  final AppDatabase db;

  static const bankCode = '1100';
  static const capitalCode = '3100';
  static const contributionRef = 'APORTE-PAUL-INICIAL-2026';

  Future<void> initialize() async {
    await db.transaction(() async {
      await db.customStatement(
        'INSERT OR IGNORE INTO financial_accounts '
        '(code, name, type, active) VALUES (?, ?, ?, 1)',
        [bankCode, 'Banco Izumi', 'asset'],
      );

      await db.customStatement(
        'INSERT OR IGNORE INTO financial_accounts '
        '(code, name, type, active) VALUES (?, ?, ?, 1)',
        [capitalCode, 'Capital aportado por Paul', 'equity'],
      );
    });
  }

  Future<int> accountId(String code) async {
    final row = await db
        .customSelect(
          'SELECT id FROM financial_accounts WHERE code = ?',
          variables: [Variable.withString(code)],
        )
        .getSingle();

    return row.read<int>('id');
  }

  Future<bool> contributionExists() async {
    final rows = await db
        .customSelect(
          'SELECT id FROM journal_entries WHERE reference = ? LIMIT 1',
          variables: [Variable.withString(contributionRef)],
        )
        .get();

    return rows.isNotEmpty;
  }

  Future<void> registerPaulContribution() async {
    await db.transaction(() async {
      if (await contributionExists()) {
        throw StateError('El aporte de Paul ya fue registrado.');
      }

      final bankId = await accountId(bankCode);
      final capitalId = await accountId(capitalCode);

      await db.customStatement(
        'INSERT INTO journal_entries '
        '(occurred_at, description, reference) VALUES (?, ?, ?)',
        [
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'Aporte inicial de Paul',
          contributionRef,
        ],
      );

      final row = await db
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      final entryId = row.read<int>('id');

      await db.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, ?, ?)',
        [entryId, bankId, 200000, 0],
      );

      await db.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, ?, ?)',
        [entryId, capitalId, 0, 200000],
      );
    });
  }

  Future<int> balance(String code) async {
    final rows = await db
        .customSelect(
          '''
      SELECT a.type,
        COALESCE(SUM(l.debit_cents), 0) AS debit,
        COALESCE(SUM(l.credit_cents), 0) AS credit
      FROM financial_accounts a
      LEFT JOIN journal_lines l ON l.account_id = a.id
      WHERE a.code = ?
      GROUP BY a.id
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

  Future<List<FinancialMovement>> movements() async {
    final rows = await db
        .customSelect(
          '''
      SELECT e.occurred_at, e.description,
        SUM(l.debit_cents - l.credit_cents) AS change_cents
      FROM journal_entries e
      JOIN journal_lines l ON l.entry_id = e.id
      JOIN financial_accounts a ON a.id = l.account_id
      WHERE a.code = ?
      GROUP BY e.id
      ORDER BY e.occurred_at DESC, e.id DESC
      LIMIT 50
    ''',
          variables: [Variable.withString(bankCode)],
        )
        .get();

    return rows
        .map(
          (row) => FinancialMovement(
            date: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('occurred_at') * 1000,
            ),
            description: row.read<String>('description'),
            bankChangeCents: row.read<int>('change_cents'),
          ),
        )
        .toList();
  }

  Future<FinancialSummary> loadSummary() async {
    return FinancialSummary(
      bankCents: await balance(bankCode),
      capitalCents: await balance(capitalCode),
      contributionRegistered: await contributionExists(),
      movements: await movements(),
    );
  }
}
