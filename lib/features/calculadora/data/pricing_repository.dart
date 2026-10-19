import 'package:drift/drift.dart' show Variable;

import '../../../core/database/app_database.dart';
import '../../inventario/data/inventory_repository.dart';

class PricingMaterial {
  const PricingMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.stockMillis,
    required this.purchasedMillis,
    required this.purchasedCents,
  });

  final int id;
  final String name;
  final String unit;
  final int stockMillis;
  final int purchasedMillis;
  final int purchasedCents;

  bool get hasPrice => purchasedMillis > 0;

  int costFor(int consumedMillis) =>
      (consumedMillis * purchasedCents + purchasedMillis ~/ 2) ~/
      purchasedMillis;
}

class PricingRepository {
  PricingRepository(this.db);

  final AppDatabase db;

  Future<List<PricingMaterial>> getMaterials() async {
    await InventoryRepository(db).initialize();

    final tables = await db.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name = 'purchase_batch_lines'
    ''').get();

    final join = tables.isEmpty
        ? ''
        : '''
          LEFT JOIN (
            SELECT item_id,
              SUM(quantity_millis) AS purchased_millis,
              SUM(total_cents) AS purchased_cents
            FROM purchase_batch_lines
            WHERE quantity_millis > 0
            GROUP BY item_id
          ) prices ON prices.item_id = i.id
        ''';

    final columns = tables.isEmpty
        ? '0 AS purchased_millis, 0 AS purchased_cents'
        : '''
          COALESCE(prices.purchased_millis, 0) AS purchased_millis,
          COALESCE(prices.purchased_cents, 0) AS purchased_cents
        ''';

    final rows = await db.customSelect('''
      SELECT i.id, i.name, i.unit, i.quantity_millis,
             $columns
      FROM inventory_items i
      $join
      ORDER BY i.name COLLATE NOCASE
    ''').get();

    return rows
        .map(
          (row) => PricingMaterial(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            unit: row.read<String>('unit'),
            stockMillis: row.read<int>('quantity_millis'),
            purchasedMillis: row.read<int>('purchased_millis'),
            purchasedCents: row.read<int>('purchased_cents'),
          ),
        )
        .toList();
  }

  Future<bool> itemExists(int id) async {
    final rows = await db
        .customSelect(
          'SELECT id FROM inventory_items WHERE id = ?',
          variables: [Variable.withInt(id)],
        )
        .get();

    return rows.isNotEmpty;
  }
}
