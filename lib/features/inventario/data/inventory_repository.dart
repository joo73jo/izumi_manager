import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/inventory_category.dart';
import '../domain/inventory_item.dart';

class InventoryRepository {
  InventoryRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity_millis INTEGER NOT NULL DEFAULT 0,
        minimum_millis INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS inventory_stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL REFERENCES inventory_items(id),
        quantity_delta_millis INTEGER NOT NULL,
        reason TEXT NOT NULL,
        occurred_at INTEGER NOT NULL
      )
    ''');
  }

  Future<List<InventoryItem>> getAll() async {
    final rows = await db
        .customSelect('SELECT * FROM inventory_items ORDER BY category, name')
        .get();

    return rows.map((row) {
      return InventoryItem(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        category: InventoryCategory.values.byName(row.read<String>('category')),
        unit: row.read<String>('unit'),
        quantityMillis: row.read<int>('quantity_millis'),
        minimumMillis: row.read<int>('minimum_millis'),
      );
    }).toList();
  }

  Future<void> addItem({
    required String name,
    required InventoryCategory category,
    required String unit,
    required int quantityMillis,
    required int minimumMillis,
  }) async {
    if (name.trim().isEmpty || unit.trim().isEmpty) {
      throw ArgumentError('Nombre y unidad obligatorios.');
    }

    if (quantityMillis < 0 || minimumMillis < 0) {
      throw ArgumentError('Las cantidades no pueden ser negativas.');
    }

    await db.transaction(() async {
      await db.customStatement(
        '''
        INSERT INTO inventory_items
        (name, category, unit, quantity_millis, minimum_millis)
        VALUES (?, ?, ?, ?, ?)
      ''',
        [
          name.trim(),
          category.name,
          unit.trim(),
          quantityMillis,
          minimumMillis,
        ],
      );

      final row = await db
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      final id = row.read<int>('id');

      if (quantityMillis > 0) {
        await db.customStatement(
          '''
          INSERT INTO inventory_stock_movements
          (item_id, quantity_delta_millis, reason, occurred_at)
          VALUES (?, ?, ?, ?)
        ''',
          [
            id,
            quantityMillis,
            'Existencia inicial',
            DateTime.now().millisecondsSinceEpoch,
          ],
        );
      }
    });
  }

  Future<void> adjustStock({
    required int itemId,
    required int deltaMillis,
    required String reason,
  }) async {
    if (deltaMillis == 0 || reason.trim().isEmpty) {
      throw ArgumentError('Movimiento no valido.');
    }

    await db.transaction(() async {
      final rows = await db
          .customSelect(
            'SELECT quantity_millis FROM inventory_items WHERE id = ?',
            variables: [Variable.withInt(itemId)],
          )
          .get();

      if (rows.isEmpty) throw StateError('Material inexistente.');

      final current = rows.first.read<int>('quantity_millis');
      final updated = current + deltaMillis;

      if (updated < 0) {
        throw StateError('Inventario insuficiente.');
      }

      await db.customStatement(
        '''
        UPDATE inventory_items
        SET quantity_millis = ?
        WHERE id = ?
      ''',
        [updated, itemId],
      );

      await db.customStatement(
        '''
        INSERT INTO inventory_stock_movements
        (item_id, quantity_delta_millis, reason, occurred_at)
        VALUES (?, ?, ?, ?)
      ''',
        [
          itemId,
          deltaMillis,
          reason.trim(),
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
    });
  }

  Future<void> updateItemDetails({
    required int id,
    required String name,
    required InventoryCategory category,
    required int minimumMillis,
  }) async {
    if (name.trim().isEmpty || minimumMillis < 0) {
      throw ArgumentError('Nombre o stock minimo invalido.');
    }

    await initialize();

    await db.transaction(() async {
      final rows = await db
          .customSelect(
            'SELECT category, unit, quantity_millis '
            'FROM inventory_items WHERE id = ?',
            variables: [Variable.withInt(id)],
          )
          .get();

      if (rows.isEmpty) {
        throw StateError('El material ya no existe.');
      }

      final oldUnit = rows.first.read<String>('unit');
      final stock = rows.first.read<int>('quantity_millis');
      final newUnit = category.defaultUnit;

      // No convertir gramos a unidades ni viceversa.
      if (oldUnit != newUnit) {
        if (stock != 0 || await _hasExternalMovement(id)) {
          throw StateError(
            'No se puede cambiar la unidad de un material '
            'con existencias o movimientos. '
            'Corrige primero las existencias.',
          );
        }
      }

      await db.customStatement(
        '''
        UPDATE inventory_items
        SET name = ?, category = ?, unit = ?, minimum_millis = ?
        WHERE id = ?
      ''',
        [name.trim(), category.name, newUnit, minimumMillis, id],
      );
    });
  }

  Future<bool> _hasExternalMovement(int id) async {
    final rows = await db
        .customSelect(
          '''
      SELECT 1
      FROM inventory_stock_movements
      WHERE item_id = ?
        AND reason <> 'Existencia inicial'
      LIMIT 1
    ''',
          variables: [Variable.withInt(id)],
        )
        .get();

    return rows.isNotEmpty;
  }

  // Comprueba todas las tablas existentes que referencian materiales.
  // No depende de que SQLite tenga las foreign keys activadas.
  Future<String?> _referencedBy(int id) async {
    final tables = await db.customSelect('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
        AND name NOT IN (
          'inventory_items',
          'inventory_stock_movements'
        )
    ''').get();

    for (final tableRow in tables) {
      final table = tableRow.read<String>('name');
      final safeTable = table.replaceAll('"', '""');

      final columns = await db
          .customSelect('PRAGMA table_info("$safeTable")')
          .get();

      for (final columnRow in columns) {
        final column = columnRow.read<String>('name');

        if (column != 'item_id' && column != 'inventory_item_id') {
          continue;
        }

        final safeColumn = column.replaceAll('"', '""');

        final references = await db
            .customSelect(
              'SELECT 1 FROM "$safeTable" '
              'WHERE "$safeColumn" = ? LIMIT 1',
              variables: [Variable.withInt(id)],
            )
            .get();

        if (references.isNotEmpty) {
          return table;
        }
      }
    }

    return null;
  }

  Future<void> deleteIfUnused(int id) async {
    await initialize();

    await db.transaction(() async {
      final item = await db
          .customSelect(
            'SELECT id FROM inventory_items WHERE id = ?',
            variables: [Variable.withInt(id)],
          )
          .get();

      if (item.isEmpty) {
        throw StateError('El material ya no existe.');
      }

      if (await _hasExternalMovement(id)) {
        throw StateError(
          'No se puede eliminar: tiene movimientos de inventario.',
        );
      }

      final relatedTable = await _referencedBy(id);

      if (relatedTable != null) {
        throw StateError(
          'No se puede eliminar: el material tiene registros '
          'relacionados en $relatedTable.',
        );
      }

      // Se permiten movimientos exclusivamente de existencia inicial.
      await db.customStatement(
        '''
        DELETE FROM inventory_stock_movements
        WHERE item_id = ? AND reason = 'Existencia inicial'
      ''',
        [id],
      );

      await db.customStatement('DELETE FROM inventory_items WHERE id = ?', [
        id,
      ]);
    });
  }
}
