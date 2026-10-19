import 'package:drift/drift.dart' show Variable;

import '../../../core/database/app_database.dart';

class FinishedSaleAccountingService {
  FinishedSaleAccountingService(this.db);

  final AppDatabase db;

  // Ejecutar dentro de la misma transaccion de venta.
  Future<void> postCostOfSale({
    required int saleId,
    required int productionId,
    required int materialCostCents,
  }) async {
    if (materialCostCents < 0) {
      throw StateError('El costo de venta no puede ser negativo.');
    }

    // Verificar que los materiales de la fabricacion
    // hayan pasado contablemente a productos terminados.
    final origin = await db
        .customSelect(
          '''
      SELECT je.id
      FROM journal_entries je
      WHERE je.reference = ?
      LIMIT 1
      ''',
          variables: [Variable.withString('PRODUCCION-COSTO-$productionId')],
        )
        .get();

    if (origin.isEmpty) {
      throw StateError(
        'La fabricacion #$productionId no tiene registrado '
        'su traspaso contable a productos terminados. '
        'Debe regularizarse antes de venderla.',
      );
    }

    // Confirmar que el costo de la fabricacion
    // coincida con el importe a vender.
    final snapshot = await db
        .customSelect(
          '''
      SELECT known_cost_cents, missing_prices
      FROM production_cost_snapshots
      WHERE production_id = ?
      ''',
          variables: [Variable.withInt(productionId)],
        )
        .get();

    if (snapshot.isEmpty ||
        snapshot.first.read<int>('missing_prices') != 0 ||
        snapshot.first.read<int>('known_cost_cents') != materialCostCents) {
      throw StateError('El costo historico de la fabricacion no coincide.');
    }

    final reference = 'COSTO-VENTA-$saleId';

    final previous = await db
        .customSelect(
          '''
      SELECT id FROM journal_entries
      WHERE reference = ?
      ''',
          variables: [Variable.withString(reference)],
        )
        .get();

    if (previous.isNotEmpty) {
      throw StateError('La venta ya tiene costo contabilizado.');
    }

    final finished = await db.customSelect('''
      SELECT id
      FROM financial_accounts
      WHERE code = '1300'
      LIMIT 1
    ''').get();

    final expenses = await db.customSelect('''
      SELECT id, type
      FROM financial_accounts
      WHERE code = '5100'
      LIMIT 1
    ''').get();

    if (finished.isEmpty || expenses.isEmpty) {
      throw StateError(
        'Faltan las cuentas contables de productos '
        'terminados (1300) o gastos (5100).',
      );
    }

    // Comprobar el valor realmente trasladado a la cuenta 1300.
    final posted = await db
        .customSelect(
          '''
      SELECT COALESCE(SUM(jl.debit_cents), 0) AS cost
      FROM journal_entries je
      JOIN journal_lines jl ON jl.entry_id = je.id
      JOIN financial_accounts a ON a.id = jl.account_id
      WHERE je.reference = ? AND a.code = '1300'
      ''',
          variables: [Variable.withString('PRODUCCION-COSTO-$productionId')],
        )
        .getSingle();

    if (posted.read<int>('cost') != materialCostCents) {
      throw StateError(
        'La valoracion contable de la fabricacion es diferente.',
      );
    }

    final existingCostAccount = await db.customSelect('''
      SELECT id
      FROM financial_accounts
      WHERE code = '5105'
      LIMIT 1
    ''').get();

    int costAccountId;

    if (existingCostAccount.isNotEmpty) {
      costAccountId = existingCostAccount.first.read<int>('id');
    } else {
      await db.customStatement(
        '''
        INSERT INTO financial_accounts
          (code, name, type, active)
        VALUES (?, ?, ?, 1)
      ''',
        [
          '5105',
          'Costo de materiales de macetas vendidas',
          expenses.first.read<String>('type'),
        ],
      );

      final row = await db
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      costAccountId = row.read<int>('id');
    }

    // Costo cero expresamente valorado:
    // no se necesita asiento con importes nulos.
    if (materialCostCents == 0) return;

    final occurredAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.customStatement(
      '''
      INSERT INTO journal_entries
        (occurred_at, description, reference)
      VALUES (?, ?, ?)
    ''',
      [occurredAt, 'Costo de materiales de venta #$saleId', reference],
    );

    final entry = await db
        .customSelect('SELECT last_insert_rowid() AS id')
        .getSingle();

    final entryId = entry.read<int>('id');

    // DEBE: Costo de ventas
    await db.customStatement(
      '''
      INSERT INTO journal_lines
        (entry_id, account_id, debit_cents, credit_cents)
      VALUES (?, ?, ?, 0)
    ''',
      [entryId, costAccountId, materialCostCents],
    );

    // HABER: Inventario de productos terminados
    await db.customStatement(
      '''
      INSERT INTO journal_lines
        (entry_id, account_id, debit_cents, credit_cents)
      VALUES (?, ?, 0, ?)
    ''',
      [entryId, finished.first.read<int>('id'), materialCostCents],
    );
  }
}
