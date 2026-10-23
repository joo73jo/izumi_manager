import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class IzumiCollection {
  const IzumiCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.concept,
  });

  final int id;
  final String name;
  final String description;
  final String concept;
}

class CollectionsRepository {
  CollectionsRepository(this.db);

  final AppDatabase db;

  Future<void> init() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS studio_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE,
        description TEXT NOT NULL DEFAULT '',
        concept TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<List<IzumiCollection>> all() async {
    await init();

    final rows = await db.customSelect('''
      SELECT id, name, description, concept
      FROM studio_collections
      ORDER BY name COLLATE NOCASE
    ''').get();

    return rows
        .map(
          (row) => IzumiCollection(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            description: row.read<String>('description'),
            concept: row.read<String>('concept'),
          ),
        )
        .toList();
  }

  Future<void> save({
    int? id,
    required String name,
    required String description,
    required String concept,
  }) async {
    await init();

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('El nombre es obligatorio.');
    }

    await db.transaction(() async {
      if (id == null) {
        await db.customStatement(
          '''
          INSERT INTO studio_collections
          (name, description, concept, created_at)
          VALUES (?, ?, ?, ?)
        ''',
          [
            cleanName,
            description.trim(),
            concept.trim(),
            DateTime.now().millisecondsSinceEpoch,
          ],
        );
      } else {
        final previous = await db
            .customSelect(
              'SELECT name FROM studio_collections WHERE id = ?',
              variables: [Variable.withInt(id)],
            )
            .get();

        if (previous.isEmpty) {
          throw StateError('La colección no existe.');
        }

        final previousName = previous.first.read<String>('name');

        await db.customStatement(
          '''
          UPDATE studio_collections
          SET name = ?, description = ?, concept = ?
          WHERE id = ?
        ''',
          [cleanName, description.trim(), concept.trim(), id],
        );

        await db.customStatement(
          '''
          UPDATE izumi_products
          SET collection = ?
          WHERE LOWER(TRIM(collection)) = LOWER(TRIM(?))
        ''',
          [cleanName, previousName],
        );
      }
    });
  }

  Future<void> delete(int id) async {
    await init();

    await db.transaction(() async {
      final rows = await db
          .customSelect(
            'SELECT name FROM studio_collections WHERE id = ?',
            variables: [Variable.withInt(id)],
          )
          .get();

      if (rows.isEmpty) return;

      final name = rows.first.read<String>('name');

      final products = await db
          .customSelect(
            '''
        SELECT COUNT(*) AS total
        FROM izumi_products
        WHERE LOWER(TRIM(collection)) = LOWER(TRIM(?))
        ''',
            variables: [Variable.withString(name)],
          )
          .get();

      if (products.first.read<int>('total') > 0) {
        throw StateError('Primero reasigna los productos de esta colección.');
      }

      await db.customStatement('DELETE FROM studio_collections WHERE id = ?', [
        id,
      ]);
    });
  }
}
