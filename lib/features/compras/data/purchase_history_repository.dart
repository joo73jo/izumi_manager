import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/purchase_history_record.dart';

class PurchaseHistoryRepository {
  PurchaseHistoryRepository(this.db);

  final AppDatabase db;

  Future<List<PurchaseHistoryRecord>> getAll() async {
    final tables = await db.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name = 'purchase_batches'
    ''').get();

    if (tables.isEmpty) return [];

    final purchases = await db.customSelect('''
      SELECT id, description, occurred_at, total_cents
      FROM purchase_batches
      ORDER BY occurred_at DESC, id DESC
    ''').get();

    final result = <PurchaseHistoryRecord>[];

    for (final purchase in purchases) {
      final purchaseId = purchase.read<int>('id');

      final rows = await db
          .customSelect(
            '''
        SELECT i.name, i.unit,
               l.quantity_millis, l.total_cents
        FROM purchase_batch_lines l
        JOIN inventory_items i ON i.id = l.item_id
        WHERE l.purchase_id = ?
        ORDER BY l.id
      ''',
            variables: [Variable.withInt(purchaseId)],
          )
          .get();

      final lines = rows.map((row) {
        return PurchaseHistoryLine(
          name: row.read<String>('name'),
          unit: row.read<String>('unit'),
          quantityMillis: row.read<int>('quantity_millis'),
          totalCents: row.read<int>('total_cents'),
        );
      }).toList();

      result.add(
        PurchaseHistoryRecord(
          id: purchaseId,
          date: DateTime.fromMillisecondsSinceEpoch(
            purchase.read<int>('occurred_at') * 1000,
          ),
          description: purchase.read<String>('description'),
          totalCents: purchase.read<int>('total_cents'),
          lines: lines,
        ),
      );
    }

    return result;
  }
}
