import 'package:drift/drift.dart' show Variable;

import '../../../core/database/app_database.dart';

class ProductionMaterialCost {
  const ProductionMaterialCost({
    required this.name,
    required this.unit,
    required this.quantityMillis,
    required this.wastePercent,
    required this.consumedMillis,
    required this.estimatedCostCents,
  });

  final String name;
  final String unit;
  final int quantityMillis;
  final int wastePercent;
  final int consumedMillis;
  final int? estimatedCostCents;
}

class ProductionCostReport {
  const ProductionCostReport(this.materials);

  final List<ProductionMaterialCost> materials;

  bool get complete =>
      materials.isNotEmpty &&
      materials.every((m) => m.estimatedCostCents != null);

  int get knownCostCents => materials.fold(
    0,
    (total, material) => total + (material.estimatedCostCents ?? 0),
  );

  int get missingPrices =>
      materials.where((material) => material.estimatedCostCents == null).length;
}

class ProductionCostRepository {
  ProductionCostRepository(this.db);

  final AppDatabase db;

  Future<ProductionCostReport> forProduction(int productionId) async {
    final tableExists = await db.customSelect('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table' AND name = 'purchase_batch_lines'
    ''').get();

    final hasPurchases = tableExists.isNotEmpty;

    final purchasesJoin = hasPurchases
        ? '''
          LEFT JOIN (
            SELECT item_id,
                   SUM(quantity_millis) AS purchased_millis,
                   SUM(total_cents) AS purchased_cents
            FROM purchase_batch_lines
            WHERE quantity_millis > 0
            GROUP BY item_id
          ) prices ON prices.item_id = pc.inventory_item_id
        '''
        : '';

    final purchaseColumns = hasPurchases
        ? '''
          prices.purchased_millis AS purchased_millis,
          prices.purchased_cents AS purchased_cents
        '''
        : '''
          NULL AS purchased_millis,
          NULL AS purchased_cents
        ''';

    final rows = await db
        .customSelect(
          '''
      SELECT
        COALESCE(i.name, 'Material eliminado') AS material_name,
        COALESCE(i.unit, '') AS unit,
        pc.quantity_millis,
        pc.waste_percent,
        pc.consumed_millis,
        $purchaseColumns
      FROM production_consumption pc
      LEFT JOIN inventory_items i
        ON i.id = pc.inventory_item_id
      $purchasesJoin
      WHERE pc.production_id = ?
      ORDER BY pc.id
    ''',
          variables: [Variable.withInt(productionId)],
        )
        .get();

    final materials = <ProductionMaterialCost>[];

    for (final row in rows) {
      final purchasedMillis = row.readNullable<int>('purchased_millis');
      final purchasedCents = row.readNullable<int>('purchased_cents');
      final consumedMillis = row.read<int>('consumed_millis');

      int? cost;

      if (purchasedMillis != null &&
          purchasedMillis > 0 &&
          purchasedCents != null) {
        // Costo promedio ponderado de las compras registradas.
        cost =
            (consumedMillis * purchasedCents + purchasedMillis ~/ 2) ~/
            purchasedMillis;
      }

      materials.add(
        ProductionMaterialCost(
          name: row.read<String>('material_name'),
          unit: row.read<String>('unit'),
          quantityMillis: row.read<int>('quantity_millis'),
          wastePercent: row.read<int>('waste_percent'),
          consumedMillis: consumedMillis,
          estimatedCostCents: cost,
        ),
      );
    }

    return ProductionCostReport(materials);
  }
}
