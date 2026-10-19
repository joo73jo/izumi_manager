import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class PurchaseReceipt {
  const PurchaseReceipt({
    required this.id,
    required this.purchaseId,
    required this.filePath,
  });

  final int id;
  final int purchaseId;
  final String filePath;

  String get fileName {
    final parts = filePath.replaceAll('\\', '/').split('/');
    return parts.last;
  }
}

class PurchaseReceiptRepository {
  PurchaseReceiptRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS purchase_receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL
          REFERENCES purchase_batches(id),
        file_path TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<List<PurchaseReceipt>> getByPurchase(int purchaseId) async {
    await initialize();

    final rows = await db
        .customSelect(
          '''
      SELECT id, purchase_id, file_path
      FROM purchase_receipts
      WHERE purchase_id = ?
      ORDER BY id DESC
    ''',
          variables: [Variable.withInt(purchaseId)],
        )
        .get();

    return rows.map((row) {
      return PurchaseReceipt(
        id: row.read<int>('id'),
        purchaseId: row.read<int>('purchase_id'),
        filePath: row.read<String>('file_path'),
      );
    }).toList();
  }

  Future<void> attach({
    required int purchaseId,
    required String filePath,
  }) async {
    await initialize();

    await db.customStatement(
      '''
      INSERT INTO purchase_receipts
      (purchase_id, file_path, created_at)
      VALUES (?, ?, ?)
    ''',
      [purchaseId, filePath, DateTime.now().millisecondsSinceEpoch],
    );
  }
}
