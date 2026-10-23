import '../../../core/database/app_database.dart';

class EssenceRepository {
  EssenceRepository(this.db);

  final AppDatabase db;

  static const sections = [
    'historia',
    'proposito',
    'mision',
    'vision',
    'valores',
    'filosofia',
  ];

  Future<void> init() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS studio_essence (
        section TEXT PRIMARY KEY,
        content TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<Map<String, String>> all() async {
    await init();

    final result = {for (final section in sections) section: ''};

    final rows = await db.customSelect('''
      SELECT section, content
      FROM studio_essence
    ''').get();

    for (final row in rows) {
      final section = row.read<String>('section');

      if (result.containsKey(section)) {
        result[section] = row.read<String>('content');
      }
    }

    return result;
  }

  Future<void> save(String section, String content) async {
    await init();

    if (!sections.contains(section)) {
      throw ArgumentError('Seccion no valida.');
    }

    await db.customStatement(
      '''
      INSERT INTO studio_essence (
        section,
        content,
        updated_at
      )
      VALUES (?, ?, ?)
      ON CONFLICT(section) DO UPDATE SET
        content = excluded.content,
        updated_at = excluded.updated_at
    ''',
      [section, content.trim(), DateTime.now().millisecondsSinceEpoch],
    );
  }
}
