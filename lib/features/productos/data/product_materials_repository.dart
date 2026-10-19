import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/product_material.dart';

class ProductMaterialsRepository {
  ProductMaterialsRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS product_materials (
        product_id INTEGER NOT NULL
          REFERENCES izumi_products(id),
        inventory_item_id INTEGER NOT NULL
          REFERENCES inventory_items(id),
        quantity_millis INTEGER NOT NULL
          CHECK(quantity_millis > 0),
        waste_percent INTEGER NOT NULL DEFAULT 0
          CHECK(waste_percent BETWEEN 0 AND 100),
        PRIMARY KEY (product_id, inventory_item_id)
      )
    ''');
  }

  Future<List<ProductMaterial>> getByProduct(int productId) async {
    await initialize();

    final rows = await db
        .customSelect(
          '''
      SELECT pm.inventory_item_id, i.name, i.unit,
             pm.quantity_millis, pm.waste_percent
      FROM product_materials pm
      JOIN inventory_items i
        ON i.id = pm.inventory_item_id
      WHERE pm.product_id = ?
      ORDER BY i.name COLLATE NOCASE
    ''',
          variables: [Variable.withInt(productId)],
        )
        .get();

    return rows
        .map(
          (row) => ProductMaterial(
            inventoryItemId: row.read<int>('inventory_item_id'),
            name: row.read<String>('name'),
            unit: row.read<String>('unit'),
            quantityMillis: row.read<int>('quantity_millis'),
            wastePercent: row.read<int>('waste_percent'),
          ),
        )
        .toList();
  }

  Future<void> saveMaterial({
    required int productId,
    required int inventoryItemId,
    required int quantityMillis,
    required int wastePercent,
  }) async {
    if (quantityMillis <= 0 || wastePercent < 0 || wastePercent > 100) {
      throw ArgumentError('Cantidad o desperdicio no valido.');
    }

    await initialize();

    final item = await db
        .customSelect(
          'SELECT id FROM inventory_items WHERE id = ?',
          variables: [Variable.withInt(inventoryItemId)],
        )
        .get();

    if (item.isEmpty) {
      throw StateError('El material ya no existe.');
    }

    await db.customStatement(
      '''
      INSERT INTO product_materials
        (product_id, inventory_item_id, quantity_millis, waste_percent)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(product_id, inventory_item_id)
      DO UPDATE SET
        quantity_millis = excluded.quantity_millis,
        waste_percent = excluded.waste_percent
    ''',
      [productId, inventoryItemId, quantityMillis, wastePercent],
    );
  }

  Future<void> removeMaterial({
    required int productId,
    required int inventoryItemId,
  }) async {
    await db.customStatement(
      '''
      DELETE FROM product_materials
      WHERE product_id = ? AND inventory_item_id = ?
    ''',
      [productId, inventoryItemId],
    );
  }
}
