import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Abre la base local en la carpeta de datos de la aplicación.
/// No guardar dentro del proyecto Flutter: los builds pueden reemplazarse.
Future<QueryExecutor> openIzumiDatabase() async {
  final appDirectory = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(p.join(appDirectory.path, 'database'));
  if (!await databaseDirectory.exists()) {
    await databaseDirectory.create(recursive: true);
  }
  final file = File(p.join(databaseDirectory.path, 'izumi.sqlite'));
  return NativeDatabase.createInBackground(file);
}
