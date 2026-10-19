import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/product_variant.dart';

class ProductVariantsRepository {
  ProductVariantsRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS product_variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL
          REFERENCES izumi_products(id),
        name TEXT NOT NULL COLLATE NOCASE,
        price_cents INTEGER NOT NULL CHECK(price_cents >= 0),
        active INTEGER NOT NULL DEFAULT 1,
        UNIQUE(product_id, name)
      )
    ''');
  }

  Future<List<ProductVariant>> getByProduct(int productId) async {
    await initialize();

    final rows = await db
        .customSelect(
          '''
      SELECT id, product_id, name, price_cents, active
      FROM product_variants
      WHERE product_id = ?
      ORDER BY active DESC, name COLLATE NOCASE
    ''',
          variables: [Variable.withInt(productId)],
        )
        .get();

    return rows
        .map(
          (row) => ProductVariant(
            id: row.read<int>('id'),
            productId: row.read<int>('product_id'),
            name: row.read<String>('name'),
            priceCents: row.read<int>('price_cents'),
            active: row.read<int>('active') == 1,
          ),
        )
        .toList();
  }

  Future<void> create({
    required int productId,
    required String name,
    required int priceCents,
  }) async {
    if (name.trim().isEmpty || priceCents < 0) {
      throw ArgumentError('Datos de variante inv\u00e1lidos.');
    }

    await initialize();

    await db.customStatement(
      '''
      INSERT INTO product_variants
      (product_id, name, price_cents)
      VALUES (?, ?, ?)
    ''',
      [productId, name.trim(), priceCents],
    );
  }

  Future<void> update({
    required int id,
    required String name,
    required int priceCents,
  }) async {
    if (name.trim().isEmpty || priceCents < 0) {
      throw ArgumentError('Datos inv\u00e1lidos.');
    }

    await db.customStatement(
      '''
      UPDATE product_variants
      SET name = ?, price_cents = ?
      WHERE id = ?
    ''',
      [name.trim(), priceCents, id],
    );
  }

  Future<void> setActive(int id, bool active) async {
    await db.customStatement(
      'UPDATE product_variants SET active = ? WHERE id = ?',
      [active ? 1 : 0, id],
    );
  }
}
