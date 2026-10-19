import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/financial_operation_details.dart';
import '../domain/financial_operation_type.dart';

class FinancialOperationsRepository {
  FinancialOperationsRepository(this.database);

  final AppDatabase database;

  Future<void> _ensureAccount(String code, String name, String type) async {
    await database.customStatement(
      'INSERT OR IGNORE INTO financial_accounts '
      '(code, name, type, active) VALUES (?, ?, ?, 1)',
      [code, name, type],
    );
  }

  Future<int> _accountId(String code) async {
    final row = await database
        .customSelect(
          'SELECT id FROM financial_accounts WHERE code = ?',
          variables: [Variable.withString(code)],
        )
        .getSingle();

    return row.read<int>('id');
  }

  Future<void> _ensureDetailsTable() async {
    await database.customStatement('''
      CREATE TABLE IF NOT EXISTS financial_operation_details (
        entry_id INTEGER PRIMARY KEY
          REFERENCES journal_entries(id),
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price_cents INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> register({
    required FinancialOperationType type,
    required String description,
    required int amountCents,
    required FinancialOperationDetails details,
  }) async {
    if (description.trim().isEmpty) {
      throw ArgumentError('La descripci\u00f3n es obligatoria.');
    }

    if (amountCents <= 0 ||
        details.quantity <= 0 ||
        details.unitPriceCents <= 0) {
      throw ArgumentError('Los valores deben ser positivos.');
    }

    if (details.quantity * details.unitPriceCents != amountCents) {
      throw StateError('El total no coincide con la cantidad y el precio.');
    }

    if (details.paymentMethod != 'Banco Izumi') {
      throw StateError('M\u00e9todo de pago no disponible.');
    }

    await database.transaction(() async {
      await _ensureDetailsTable();

      await _ensureAccount('1100', 'Banco Izumi', 'asset');
      await _ensureAccount('1200', 'Inventario', 'asset');
      await _ensureAccount('1500', 'Maquinaria y equipos', 'asset');
      await _ensureAccount('5100', 'Gastos operativos', 'expense');

      final bankId = await _accountId('1100');
      final destinationId = await _accountId(type.accountCode);

      final row = await database
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

      final available = row.read<int>('balance');

      if (amountCents > available) {
        throw StateError('Saldo bancario insuficiente.');
      }

      final timestamp =
          DateTime(
            details.date.year,
            details.date.month,
            details.date.day,
            12,
          ).millisecondsSinceEpoch ~/
          1000;

      await database.customStatement(
        'INSERT INTO journal_entries '
        '(occurred_at, description, reference) VALUES (?, ?, ?)',
        [timestamp, '${type.label}: ${description.trim()}', null],
      );

      final idRow = await database
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      final entryId = idRow.read<int>('id');

      // Debe: inventario, activo o gasto.
      await database.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, ?, 0)',
        [entryId, destinationId, amountCents],
      );

      // Haber: salida del banco.
      await database.customStatement(
        'INSERT INTO journal_lines '
        '(entry_id, account_id, debit_cents, credit_cents) '
        'VALUES (?, ?, 0, ?)',
        [entryId, bankId, amountCents],
      );

      await database.customStatement(
        'INSERT INTO financial_operation_details '
        '(entry_id, category, quantity, unit_price_cents, '
        'payment_method, notes) VALUES (?, ?, ?, ?, ?, ?)',
        [
          entryId,
          details.category,
          details.quantity,
          details.unitPriceCents,
          details.paymentMethod,
          details.notes,
        ],
      );
    });
  }
}
