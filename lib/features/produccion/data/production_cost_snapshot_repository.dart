import 'package:drift/drift.dart' show Variable;

import '../../../core/database/app_database.dart';

class ProductionCostSnapshot {
  const ProductionCostSnapshot({
    required this.productionId,
    required this.knownCostCents,
    required this.missingPrices,
  });

  final int productionId;
  final int knownCostCents;
  final int missingPrices;

  bool get complete => missingPrices == 0;
}

class ProductionCostSnapshotRepository {
  ProductionCostSnapshotRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS production_cost_snapshots (
        production_id INTEGER PRIMARY KEY
          REFERENCES production_orders(id),
        known_cost_cents INTEGER NOT NULL,
        missing_prices INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS production_material_cost_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        production_id INTEGER NOT NULL
          REFERENCES production_orders(id),
        inventory_item_id INTEGER NOT NULL,
        material_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        consumed_millis INTEGER NOT NULL,
        cost_cents INTEGER,
        CHECK(cost_cents IS NULL OR cost_cents >= 0)
      )
    ''');
  }

  Future<ProductionCostSnapshot?> get(int productionId) async {
    await initialize();

    final rows = await db
        .customSelect(
          '''
      SELECT production_id, known_cost_cents, missing_prices
      FROM production_cost_snapshots
      WHERE production_id = ?
      ''',
          variables: [Variable.withInt(productionId)],
        )
        .get();

    if (rows.isEmpty) return null;

    final row = rows.first;

    return ProductionCostSnapshot(
      productionId: row.read<int>('production_id'),
      knownCostCents: row.read<int>('known_cost_cents'),
      missingPrices: row.read<int>('missing_prices'),
    );
  }

  // Este metodo se ejecuta dentro de la transaccion de produccion.
  Future<void> capture(int productionId) async {
    final existing = await db
        .customSelect(
          '''
      SELECT production_id
      FROM production_cost_snapshots
      WHERE production_id = ?
      ''',
          variables: [Variable.withInt(productionId)],
        )
        .get();

    if (existing.isNotEmpty) {
      throw StateError('Esta produccion ya tiene un costo historico.');
    }

    // Verificar si existe historial de compras.
    final tables = await db.customSelect('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name = 'purchase_batch_lines'
    ''').get();

    final hasPurchaseTable = tables.isNotEmpty;

    final priceColumns = hasPurchaseTable
        ? '''
          prices.purchased_millis AS purchased_millis,
          prices.purchased_cents AS purchased_cents
        '''
        : '''
          NULL AS purchased_millis,
          NULL AS purchased_cents
        ''';

    final priceJoin = hasPurchaseTable
        ? '''
          LEFT JOIN (
            SELECT
              item_id,
              SUM(quantity_millis) AS purchased_millis,
              SUM(total_cents) AS purchased_cents
            FROM purchase_batch_lines
            WHERE quantity_millis > 0
            GROUP BY item_id
          ) prices
            ON prices.item_id = pc.inventory_item_id
        '''
        : '';

    final rows = await db
        .customSelect(
          '''
      SELECT
        pc.inventory_item_id,
        COALESCE(i.name, 'Material eliminado') AS material_name,
        COALESCE(i.unit, '') AS unit,
        pc.consumed_millis,
        $priceColumns
      FROM production_consumption pc
      LEFT JOIN inventory_items i
        ON i.id = pc.inventory_item_id
      $priceJoin
      WHERE pc.production_id = ?
      ORDER BY pc.id
      ''',
          variables: [Variable.withInt(productionId)],
        )
        .get();

    if (rows.isEmpty) {
      throw StateError('La produccion no tiene materiales registrados.');
    }

    var totalCents = 0;
    var missingPrices = 0;

    for (final row in rows) {
      final used = row.read<int>('consumed_millis');
      final purchased = row.readNullable<int>('purchased_millis');
      final paid = row.readNullable<int>('purchased_cents');

      int? materialCost;

      if (purchased != null && purchased > 0 && paid != null && paid >= 0) {
        materialCost = (used * paid + purchased ~/ 2) ~/ purchased;

        totalCents += materialCost;
      } else {
        missingPrices++;
      }

      await db.customStatement(
        '''
        INSERT INTO production_material_cost_snapshots
          (
            production_id,
            inventory_item_id,
            material_name,
            unit,
            consumed_millis,
            cost_cents
          )
        VALUES (?, ?, ?, ?, ?, ?)
      ''',
        [
          productionId,
          row.read<int>('inventory_item_id'),
          row.read<String>('material_name'),
          row.read<String>('unit'),
          used,
          materialCost,
        ],
      );
    }

    await db.customStatement(
      '''
      INSERT INTO production_cost_snapshots
        (
          production_id,
          known_cost_cents,
          missing_prices,
          created_at
        )
      VALUES (?, ?, ?, ?)
    ''',
      [
        productionId,
        totalCents,
        missingPrices,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }
}
