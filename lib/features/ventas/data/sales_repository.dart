import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/sale.dart';

class SalesRepository {
  SalesRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS izumi_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journal_entry_id INTEGER NOT NULL UNIQUE
          REFERENCES journal_entries(id),
        occurred_at INTEGER NOT NULL,
        description TEXT NOT NULL,
        channel TEXT NOT NULL,
        customer_name TEXT NOT NULL DEFAULT '',
        revenue_cents INTEGER NOT NULL
          CHECK(revenue_cents > 0),
        estimated_cost_cents INTEGER NOT NULL
          CHECK(estimated_cost_cents >= 0),
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<int> _accountId(String code) async {
    final row = await db
        .customSelect(
          'SELECT id FROM financial_accounts WHERE code = ?',
          variables: [Variable.withString(code)],
        )
        .getSingle();

    return row.read<int>('id');
  }

  Future<int> _lastId() async {
    final row = await db
        .customSelect('SELECT last_insert_rowid() AS id')
        .getSingle();

    return row.read<int>('id');
  }

  Future<void> register(SaleDraft sale) async {
    if (sale.description.trim().isEmpty) {
      throw ArgumentError('La venta necesita una descripción.');
    }

    if (sale.revenueCents <= 0 || sale.estimatedCostCents < 0) {
      throw ArgumentError('Importes inválidos.');
    }

    if (sale.date.isAfter(DateTime.now())) {
      throw ArgumentError('La fecha no puede ser futura.');
    }

    await db.transaction(() async {
      await initialize();

      await db.customStatement(
        'INSERT OR IGNORE INTO financial_accounts '
        '(code, name, type, active) VALUES (?, ?, ?, 1)',
        ['1100', 'Banco Izumi', 'asset'],
      );

      await db.customStatement(
        'INSERT OR IGNORE INTO financial_accounts '
        '(code, name, type, active) VALUES (?, ?, ?, 1)',
        ['4100', 'Ingresos por ventas', 'income'],
      );

      final bankId = await _accountId('1100');
      final salesId = await _accountId('4100');

      final timestamp =
          DateTime(
            sale.date.year,
            sale.date.month,
            sale.date.day,
            12,
          ).millisecondsSinceEpoch ~/
          1000;

      await db.customStatement(
        'INSERT INTO journal_entries '
        '(occurred_at, description, reference) '
        'VALUES (?, ?, ?)',
        [timestamp, 'Venta: ${sale.description.trim()}', null],
      );

      final entryId = await _lastId();

      // Dinero recibido en el banco.
      await db.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, ?, 0)',
        [entryId, bankId, sale.revenueCents],
      );

      // Ingreso generado por la venta.
      await db.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, 0, ?)',
        [entryId, salesId, sale.revenueCents],
      );

      await db.customStatement(
        'INSERT INTO izumi_sales '
        '(journal_entry_id, occurred_at, description, channel, '
        'customer_name, revenue_cents, estimated_cost_cents, '
        'notes, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          entryId,
          timestamp,
          sale.description.trim(),
          sale.channel.name,
          sale.customerName.trim(),
          sale.revenueCents,
          sale.estimatedCostCents,
          sale.notes.trim(),
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
    });
  }

  Future<List<SaleRecord>> getAll() async {
    await initialize();

    final rows = await db.customSelect('''
      SELECT
        id,
        occurred_at,
        description,
        channel,
        customer_name,
        revenue_cents,
        estimated_cost_cents,
        notes
      FROM izumi_sales
      ORDER BY occurred_at DESC, id DESC
    ''').get();

    return rows.map((row) {
      return SaleRecord(
        id: row.read<int>('id'),
        date: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('occurred_at') * 1000,
        ),
        description: row.read<String>('description'),
        channel: SaleChannel.values.byName(row.read<String>('channel')),
        customerName: row.read<String>('customer_name'),
        revenueCents: row.read<int>('revenue_cents'),
        estimatedCostCents: row.read<int>('estimated_cost_cents'),
        notes: row.read<String>('notes'),
      );
    }).toList();
  }
}
