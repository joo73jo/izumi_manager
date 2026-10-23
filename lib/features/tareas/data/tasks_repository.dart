import '../../../core/database/app_database.dart';

class IzumiTask {
  const IzumiTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.done,
    required this.observations,
    required this.createdAt,
    required this.completedAt,
  });

  final int id;
  final String title;
  final int priority;
  final bool done;
  final String observations;
  final DateTime createdAt;
  final DateTime? completedAt;
}

class TasksRepository {
  TasksRepository(this.db);

  final AppDatabase db;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS izumi_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 2,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        observations TEXT NOT NULL DEFAULT ''
      )
    ''');

    final columns = await db
        .customSelect('PRAGMA table_info(izumi_tasks)')
        .get();

    final hasObservations = columns.any(
      (row) => row.read<String>('name') == 'observations',
    );

    if (!hasObservations) {
      await db.customStatement('''
        ALTER TABLE izumi_tasks
        ADD COLUMN observations TEXT NOT NULL DEFAULT ''
      ''');
    }

    _initialized = true;
  }

  Future<List<IzumiTask>> all() async {
    await init();

    final rows = await db.customSelect('''
      SELECT
        id,
        title,
        priority,
        completed,
        created_at,
        completed_at,
        observations
      FROM izumi_tasks
      ORDER BY completed ASC,
               priority ASC,
               created_at DESC,
               id DESC
    ''').get();

    return rows.map((row) {
      final completedAt = row.readNullable<int>('completed_at');

      return IzumiTask(
        id: row.read<int>('id'),
        title: row.read<String>('title'),
        priority: row.read<int>('priority'),
        done: row.read<int>('completed') == 1,
        observations: row.read<String>('observations'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('created_at'),
        ),
        completedAt: completedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(completedAt),
      );
    }).toList();
  }

  Future<void> save(
    String title,
    int priority, {
    int? id,
    String observations = '',
  }) async {
    await init();

    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty || priority < 1 || priority > 3) {
      throw ArgumentError('Datos invalidos de la actividad.');
    }

    if (id == null) {
      await db.customStatement(
        '''
        INSERT INTO izumi_tasks (
          title,
          priority,
          created_at,
          observations
        )
        VALUES (?, ?, ?, ?)
      ''',
        [
          cleanTitle,
          priority,
          DateTime.now().millisecondsSinceEpoch,
          observations.trim(),
        ],
      );
    } else {
      await db.customStatement(
        '''
        UPDATE izumi_tasks
        SET title = ?,
            priority = ?,
            observations = ?
        WHERE id = ?
      ''',
        [cleanTitle, priority, observations.trim(), id],
      );
    }
  }

  Future<void> updateObservations(int id, String observations) async {
    await init();

    await db.customStatement(
      '''
      UPDATE izumi_tasks
      SET observations = ?
      WHERE id = ?
    ''',
      [observations.trim(), id],
    );
  }

  Future<void> toggle(IzumiTask task) async {
    await init();

    await db.customStatement(
      '''
      UPDATE izumi_tasks
      SET completed = ?,
          completed_at = ?
      WHERE id = ?
    ''',
      [
        task.done ? 0 : 1,
        task.done ? null : DateTime.now().millisecondsSinceEpoch,
        task.id,
      ],
    );
  }

  Future<void> delete(int id) async {
    await init();

    await db.customStatement('DELETE FROM izumi_tasks WHERE id = ?', [id]);
  }
}
