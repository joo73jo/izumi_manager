import 'dart:io';

import 'package:path/path.dart' as p;

class ProductFolderService {
  static const root = r'D:\izumi_app\Izumi_Datos\Productos';

  String _safeName(String name) {
    final clean = name
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[. ]+$'), '');

    return clean.isEmpty ? 'Producto' : clean;
  }

  Future<Directory> getFolder(int id, String name) async {
    final parent = Directory(root);
    await parent.create(recursive: true);

    final prefix = '${id.toString().padLeft(4, '0')}_';

    await for (final entity in parent.list(followLinks: false)) {
      if (entity is Directory && p.basename(entity.path).startsWith(prefix)) {
        return entity;
      }
    }

    return Directory(p.join(parent.path, '$prefix${_safeName(name)}'));
  }

  Future<Directory> ensureFolder(int id, String name) async {
    final folder = await getFolder(id, name);

    await folder.create(recursive: true);

    for (final subfolder in ['STL', 'Fotografias', 'Documentos']) {
      await Directory(p.join(folder.path, subfolder)).create(recursive: true);
    }

    return folder;
  }

  Future<void> openFolder(int id, String name) async {
    final folder = await ensureFolder(id, name);

    final result = await Process.run('explorer.exe', [folder.path]);

    if (result.exitCode != 0) {
      throw FileSystemException('No se pudo abrir la carpeta', folder.path);
    }
  }
}
