import '../../../core/database/app_database.dart';
import '../domain/izumi_product.dart';

class ProductsRepository {
  ProductsRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS izumi_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        collection TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        price_cents INTEGER NOT NULL
          CHECK(price_cents >= 0),
        active INTEGER NOT NULL DEFAULT 1,
        image_path TEXT,
        stl_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<List<IzumiProduct>> getAll() async {
    await initialize();

    final rows = await db.customSelect('''
      SELECT * FROM izumi_products
      ORDER BY active DESC, name COLLATE NOCASE
    ''').get();

    return rows
        .map(
          (row) => IzumiProduct(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            collection: row.read<String>('collection'),
            description: row.read<String>('description'),
            priceCents: row.read<int>('price_cents'),
            active: row.read<int>('active') == 1,
            imagePath: row.readNullable<String>('image_path'),
            stlPath: row.readNullable<String>('stl_path'),
          ),
        )
        .toList();
  }

  Future<void> create(ProductDraft product) async {
    if (product.name.trim().isEmpty || product.priceCents < 0) {
      throw ArgumentError('Datos del producto inv\u00e1lidos.');
    }

    await initialize();

    await db.customStatement(
      '''
      INSERT INTO izumi_products
      (name, collection, description, price_cents, created_at)
      VALUES (?, ?, ?, ?, ?)
    ''',
      [
        product.name.trim(),
        product.collection.trim(),
        product.description.trim(),
        product.priceCents,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> setActive(int id, bool active) async {
    await db.customStatement(
      'UPDATE izumi_products SET active = ? WHERE id = ?',
      [active ? 1 : 0, id],
    );
  }

  Future<void> update(int id, ProductDraft product) async {
    if (product.name.trim().isEmpty || product.priceCents < 0) {
      throw ArgumentError('Datos del producto inv\u00e1lidos.');
    }

    await db.customStatement(
      '''
      UPDATE izumi_products
      SET name = ?, collection = ?, description = ?,
          price_cents = ?
      WHERE id = ?
    ''',
      [
        product.name.trim(),
        product.collection.trim(),
        product.description.trim(),
        product.priceCents,
        id,
      ],
    );
  }
}
