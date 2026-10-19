import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/inventory_history.dart';

class InventoryHistoryRepository {
  InventoryHistoryRepository(this.database);

  final AppDatabase database;

  Future<InventoryHistory> load(int itemId) async {
    final movementRows = await database
        .customSelect(
          '''
      SELECT occurred_at, reason, quantity_delta_millis
      FROM inventory_stock_movements
      WHERE item_id = ?
      ORDER BY occurred_at DESC, id DESC
    ''',
          variables: [Variable.withInt(itemId)],
        )
        .get();

    // Compatible con los movimientos existentes en milisegundos.
    final movements = movementRows.map((row) {
      return InventoryHistoryEntry(
        date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('occurred_at')),
        reason: row.read<String>('reason'),
        quantityMillis: row.read<int>('quantity_delta_millis'),
      );
    }).toList();

    // La tabla de compras se creó en el paso anterior.
    // Si todavía no existe, el historial físico sigue funcionando.
    final exists = await database.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name = 'inventory_purchases'
    ''').get();

    if (exists.isEmpty) {
      return InventoryHistory(movements: movements, purchases: const []);
    }

    final purchaseRows = await database
        .customSelect(
          '''
      SELECT created_at, quantity_millis, total_cents
      FROM inventory_purchases
      WHERE item_id = ?
      ORDER BY created_at DESC, id DESC
    ''',
          variables: [Variable.withInt(itemId)],
        )
        .get();

    final purchases = purchaseRows.map((row) {
      return InventoryPurchaseRecord(
        date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
        quantityMillis: row.read<int>('quantity_millis'),
        totalCents: row.read<int>('total_cents'),
      );
    }).toList();

    return InventoryHistory(movements: movements, purchases: purchases);
  }
}
