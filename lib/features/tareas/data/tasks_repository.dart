import '../../../core/database/app_database.dart';

class IzumiTask {
  const IzumiTask(this.id, this.title, this.priority, this.done);

  final int id;
  final String title;
  final int priority;
  final bool done;
}

class TasksRepository {
  TasksRepository(this.db);
  final AppDatabase db;

  Future<void> init() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS izumi_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 2,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');
  }

  Future<List<IzumiTask>> all() async {
    await init();
    final rows = await db.customSelect('''
      SELECT id, title, priority, completed
      FROM izumi_tasks
      ORDER BY completed, priority, created_at DESC, id DESC
    ''').get();

    return rows
        .map(
          (r) => IzumiTask(
            r.read<int>('id'),
            r.read<String>('title'),
            r.read<int>('priority'),
            r.read<int>('completed') == 1,
          ),
        )
        .toList();
  }

  Future<void> save(String title, int priority, {int? id}) async {
    await init();
    if (title.trim().isEmpty || priority < 1 || priority > 3) {
      throw ArgumentError('Datos invalidos');
    }
    if (id == null) {
      await db.customStatement(
        '''
        INSERT INTO izumi_tasks(title, priority, created_at)
        VALUES (?, ?, ?)
      ''',
        [title.trim(), priority, DateTime.now().millisecondsSinceEpoch],
      );
    } else {
      await db.customStatement(
        '''
        UPDATE izumi_tasks SET title = ?, priority = ? WHERE id = ?
      ''',
        [title.trim(), priority, id],
      );
    }
  }

  Future<void> toggle(IzumiTask task) async {
    await db.customStatement(
      '''
      UPDATE izumi_tasks
      SET completed = ?, completed_at = ?
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
    await db.customStatement('DELETE FROM izumi_tasks WHERE id = ?', [id]);
  }
}
