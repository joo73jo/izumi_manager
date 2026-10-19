import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class InventoryPurchaseRepository {
  InventoryPurchaseRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS inventory_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        journal_entry_id INTEGER NOT NULL UNIQUE,
        quantity_millis INTEGER NOT NULL,
        total_cents INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (item_id) REFERENCES inventory_items(id),
        FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
      )
    ''');
  }

  Future<int> _accountId(String code) async {
    final rows = await db
        .customSelect(
          'SELECT id FROM financial_accounts WHERE code = ?',
          variables: [Variable.withString(code)],
        )
        .get();

    if (rows.isEmpty) {
      throw StateError('Cuenta contable $code no encontrada.');
    }

    return rows.first.read<int>('id');
  }

  Future<void> registerPurchase({
    required int itemId,
    required int quantityMillis,
    required int totalCents,
  }) async {
    if (quantityMillis <= 0 || totalCents <= 0) {
      throw ArgumentError('La cantidad y el importe deben ser positivos.');
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
        ['1200', 'Inventario', 'asset'],
      );

      final bankId = await _accountId('1100');
      final inventoryAccountId = await _accountId('1200');

      final itemRows = await db
          .customSelect(
            'SELECT name FROM inventory_items WHERE id = ?',
            variables: [Variable.withInt(itemId)],
          )
          .get();

      if (itemRows.isEmpty) {
        throw StateError('El material no existe.');
      }

      final name = itemRows.first.read<String>('name');

      final balanceRow = await db
          .customSelect(
            '''
        SELECT COALESCE(
          SUM(debit_cents - credit_cents), 0
        ) AS balance
        FROM journal_lines
        WHERE account_id = ?
      ''',
            variables: [Variable.withInt(bankId)],
          )
          .getSingle();

      if (balanceRow.read<int>('balance') < totalCents) {
        throw StateError('Saldo bancario insuficiente.');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final description = 'Compra de inventario: $name';

      await db.customStatement(
        'INSERT INTO journal_entries '
        '(occurred_at, description, reference) VALUES (?, ?, ?)',
        [now ~/ 1000, description, null],
      );

      final row = await db
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      final entryId = row.read<int>('id');

      // Debe: aumenta el valor del inventario.
      await db.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, ?, 0)',
        [entryId, inventoryAccountId, totalCents],
      );

      // Haber: disminuye el banco.
      await db.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, 0, ?)',
        [entryId, bankId, totalCents],
      );

      await db.customStatement(
        'UPDATE inventory_items '
        'SET quantity_millis = quantity_millis + ? '
        'WHERE id = ?',
        [quantityMillis, itemId],
      );

      await db.customStatement(
        'INSERT INTO inventory_stock_movements '
        '(item_id, quantity_delta_millis, reason, occurred_at) '
        'VALUES (?, ?, ?, ?)',
        [itemId, quantityMillis, description, now],
      );

      await db.customStatement(
        'INSERT INTO inventory_purchases '
        '(item_id, journal_entry_id, quantity_millis, '
        'total_cents, created_at) VALUES (?, ?, ?, ?, ?)',
        [itemId, entryId, quantityMillis, totalCents, now],
      );
    });
  }
}
