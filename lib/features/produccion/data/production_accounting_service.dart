import 'package:drift/drift.dart' show Variable;

import '../../../core/database/app_database.dart';
import 'production_cost_snapshot_repository.dart';

class ProductionAccountingService {
  ProductionAccountingService(this.db);

  final AppDatabase db;

  // Ejecutar dentro de la transaccion de produccion.
  Future<void> transferMaterialsToFinishedGoods(int productionId) async {
    final snapshot = await ProductionCostSnapshotRepository(db)
        .get(productionId);

    if (snapshot == null) {
      throw StateError('La fabricacion no tiene costo historico.');
    }

    if (!snapshot.complete) {
      throw StateError(
        'Hay ${snapshot.missingPrices} material(es) '
        'sin precio de compra. Registra sus costos '
        'antes de confirmar la produccion.',
      );
    }

    final reference = 'PRODUCCION-COSTO-$productionId';

    final previous = await db
        .customSelect(
          '''
      SELECT id
      FROM journal_entries
      WHERE reference = ?
      ''',
          variables: [Variable.withString(reference)],
        )
        .get();

    if (previous.isNotEmpty) {
      throw StateError('Esta produccion ya tiene un movimiento contable.');
    }

    final materialsAccount = await db.customSelect('''
      SELECT id, type
      FROM financial_accounts
      WHERE code = '1200'
      LIMIT 1
    ''').get();

    if (materialsAccount.isEmpty) {
      throw StateError(
        'Falta la cuenta contable de Inventario (1200). '
        'Primero registra los materiales desde Compras.',
      );
    }

    final rawMaterialsAccountId = materialsAccount.first.read<int>('id');

    // Mantener la misma clasificacion contable
    // que utiliza la cuenta de inventario existente.
    final assetType = materialsAccount.first.read<String>('type');

    final finishedAccount = await db.customSelect('''
      SELECT id
      FROM financial_accounts
      WHERE code = '1300'
      LIMIT 1
    ''').get();

    int finishedAccountId;

    if (finishedAccount.isNotEmpty) {
      finishedAccountId = finishedAccount.first.read<int>('id');
    } else {
      await db.customStatement(
        '''
        INSERT INTO financial_accounts
          (code, name, type, active)
        VALUES (?, ?, ?, 1)
      ''',
        ['1300', 'Inventario de productos terminados', assetType],
      );

      final row = await db
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      finishedAccountId = row.read<int>('id');
    }

    final cents = snapshot.knownCostCents;

    // Un costo de cero, expresamente valorado,
    // no necesita asiento con valores nulos.
    if (cents == 0) return;

    final occurredAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.customStatement(
      '''
      INSERT INTO journal_entries
        (occurred_at, description, reference)
      VALUES (?, ?, ?)
    ''',
      [
        occurredAt,
        'Materiales transferidos a maceta terminada #$productionId',
        reference,
      ],
    );

    final entry = await db
        .customSelect('SELECT last_insert_rowid() AS id')
        .getSingle();

    final entryId = entry.read<int>('id');

    // DEBE: Inventario de macetas terminadas
    await db.customStatement(
      '''
      INSERT INTO journal_lines
        (entry_id, account_id, debit_cents, credit_cents)
      VALUES (?, ?, ?, 0)
    ''',
      [entryId, finishedAccountId, cents],
    );

    // HABER: Inventario de materiales
    await db.customStatement(
      '''
      INSERT INTO journal_lines
        (entry_id, account_id, debit_cents, credit_cents)
      VALUES (?, ?, 0, ?)
    ''',
      [entryId, rawMaterialsAccountId, cents],
    );
  }
}
