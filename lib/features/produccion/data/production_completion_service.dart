import 'production_accounting_service.dart';
import 'production_cost_snapshot_repository.dart';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/production_order.dart';
import 'production_repository.dart';

class ProductionCompletionService {
  ProductionCompletionService(this.db);

  final AppDatabase db;

  Future<int> complete(ProductionDraft draft) async {
    final isTestProduction = RegExp(
      r'^prueba\b',
      caseSensitive: false,
    ).hasMatch(draft.notes.trim());

    if (draft.materials.isEmpty) {
      throw StateError('Agrega al menos un material.');
    }

    // Consolidar materiales repetidos antes de descontar.
    final consumption = <int, int>{};

    for (final material in draft.materials) {
      if (material.quantityMillis <= 0 ||
          material.wastePercent < 0 ||
          material.wastePercent > 100) {
        throw ArgumentError('Cantidad o desperdicio no valido.');
      }

      consumption.update(
        material.itemId,
        (value) => value + material.consumptionMillis,
        ifAbsent: () => material.consumptionMillis,
      );
    }

    await ProductionRepository(db).initialize();
    await ProductionCostSnapshotRepository(db).initialize();

    return db.transaction(() async {
      final variants = await db
          .customSelect(
            '''
        SELECT id FROM product_variants
        WHERE id = ? AND product_id = ? AND active = 1
      ''',
            variables: [
              Variable.withInt(draft.variantId),
              Variable.withInt(draft.productId),
            ],
          )
          .get();

      if (variants.isEmpty) {
        throw StateError('La variante no pertenece al producto activo.');
      }

      // Verificar todas las existencias antes de descontar.
      for (final entry in consumption.entries) {
        final rows = await db
            .customSelect(
              '''
          SELECT name, quantity_millis
          FROM inventory_items
          WHERE id = ?
        ''',
              variables: [Variable.withInt(entry.key)],
            )
            .get();

        if (rows.isEmpty) {
          throw StateError('Uno de los materiales ya no existe.');
        }

        final row = rows.first;

        if (row.read<int>('quantity_millis') < entry.value) {
          throw StateError('Stock insuficiente: ${row.read<String>('name')}');
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await db.customStatement(
        '''
        INSERT INTO production_orders
          (product_id, variant_id, created_at, notes)
        VALUES (?, ?, ?, ?)
      ''',
        [draft.productId, draft.variantId, now, draft.notes.trim()],
      );

      final idRow = await db
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      final productionId = idRow.read<int>('id');

      for (final entry in consumption.entries) {
        await db.customStatement(
          '''
          UPDATE inventory_items
          SET quantity_millis = quantity_millis - ?
          WHERE id = ?
        ''',
          [entry.value, entry.key],
        );

        await db.customStatement(
          '''
          INSERT INTO inventory_stock_movements
            (item_id, quantity_delta_millis, reason, occurred_at)
          VALUES (?, ?, ?, ?)
        ''',
          [entry.key, -entry.value, 'Produccion #$productionId', now],
        );
      }

      for (final material in draft.materials) {
        await db.customStatement(
          '''
          INSERT INTO production_consumption
            (production_id, inventory_item_id,
             quantity_millis, waste_percent, consumed_millis)
          VALUES (?, ?, ?, ?, ?)
        ''',
          [
            productionId,
            material.itemId,
            material.quantityMillis,
            material.wastePercent,
            material.consumptionMillis,
          ],
        );
      }

      if (!isTestProduction) {
        await db.customStatement(
          '''
          INSERT INTO finished_stock (variant_id, quantity)
          VALUES (?, 1)
          ON CONFLICT(variant_id)
          DO UPDATE SET quantity = quantity + 1
        ''',
          [draft.variantId],
        );
      }

      await ProductionCostSnapshotRepository(db).capture(productionId);

      if (!isTestProduction) {
        await ProductionAccountingService(db)
            .transferMaterialsToFinishedGoods(productionId);
      }

      return productionId;
    });
  }
}
