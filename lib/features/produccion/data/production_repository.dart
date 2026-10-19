import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/production_order.dart';

class ProductionRepository {
  ProductionRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS production_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL REFERENCES izumi_products(id),
        variant_id INTEGER NOT NULL REFERENCES product_variants(id),
        created_at INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS production_consumption (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        production_id INTEGER NOT NULL REFERENCES production_orders(id),
        inventory_item_id INTEGER NOT NULL REFERENCES inventory_items(id),
        quantity_millis INTEGER NOT NULL CHECK(quantity_millis > 0),
        waste_percent INTEGER NOT NULL
          CHECK(waste_percent BETWEEN 0 AND 100),
        consumed_millis INTEGER NOT NULL CHECK(consumed_millis > 0)
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS finished_stock (
        variant_id INTEGER PRIMARY KEY REFERENCES product_variants(id),
        quantity INTEGER NOT NULL DEFAULT 0 CHECK(quantity >= 0)
      )
    ''');
  }

  Future<List<ProductionRecord>> getAll() async {
    await initialize();

    final rows = await db.customSelect('''
      SELECT po.id, po.created_at, po.notes,
             p.name AS product_name, v.name AS variant_name
      FROM production_orders po
      JOIN izumi_products p ON p.id = po.product_id
      JOIN product_variants v ON v.id = po.variant_id
      ORDER BY po.id DESC
    ''').get();

    return rows
        .map(
          (row) => ProductionRecord(
            id: row.read<int>('id'),
            productName: row.read<String>('product_name'),
            variantName: row.read<String>('variant_name'),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('created_at'),
            ),
            notes: row.read<String>('notes'),
          ),
        )
        .toList();
  }

  Future<int> getFinishedStock(int variantId) async {
    await initialize();

    final rows = await db
        .customSelect(
          'SELECT quantity FROM finished_stock WHERE variant_id = ?',
          variables: [Variable.withInt(variantId)],
        )
        .get();

    return rows.isEmpty ? 0 : rows.first.read<int>('quantity');
  }
}
