import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../inventario/data/inventory_repository.dart';

class ProductionTestRecord {
  const ProductionTestRecord({
    required this.id,
    required this.createdAt,
    required this.notes,
    required this.materials,
  });

  final int id;
  final DateTime createdAt;
  final String notes;
  final String materials;
}

class ProductionTestRepository {
  ProductionTestRepository(this.db);

  final AppDatabase db;

  Future<void> initialize() async {
    await InventoryRepository(db).initialize();

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS production_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS production_test_consumption (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_id INTEGER NOT NULL
          REFERENCES production_tests(id),
        inventory_item_id INTEGER NOT NULL
          REFERENCES inventory_items(id),
        quantity_millis INTEGER NOT NULL
          CHECK(quantity_millis > 0)
      )
    ''');
  }

  Future<int> register({
    required Map<int, int> materials,
    String notes = '',
  }) async {
    if (materials.isEmpty || materials.values.any((value) => value <= 0)) {
      throw StateError('Agrega al menos un filamento valido.');
    }

    await initialize();

    return db.transaction(() async {
      for (final entry in materials.entries) {
        final rows = await db
            .customSelect(
              '''
          SELECT name, category, quantity_millis
          FROM inventory_items
          WHERE id = ?
          ''',
              variables: [Variable.withInt(entry.key)],
            )
            .get();

        if (rows.isEmpty) {
          throw StateError('El filamento ya no existe.');
        }

        final row = rows.first;

        if (row.read<String>('category') != 'filament') {
          throw StateError('El material no es un filamento.');
        }

        if (row.read<int>('quantity_millis') < entry.value) {
          throw StateError('Stock insuficiente: ${row.read<String>('name')}');
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await db.customStatement(
        '''
        INSERT INTO production_tests (created_at, notes)
        VALUES (?, ?)
        ''',
        [now, notes.trim()],
      );

      final idRow = await db
          .customSelect('SELECT last_insert_rowid() AS id')
          .getSingle();

      final testId = idRow.read<int>('id');

      for (final entry in materials.entries) {
        await db.customStatement(
          '''
          UPDATE inventory_items
          SET quantity_millis = quantity_millis - ?
          WHERE id = ?
          ''',
          [entry.value, entry.key],
        );

        await db.customStatement(
          '''
          INSERT INTO inventory_stock_movements
            (item_id, quantity_delta_millis, reason, occurred_at)
          VALUES (?, ?, ?, ?)
          ''',
          [entry.key, -entry.value, 'Prueba de impresion #$testId', now],
        );

        await db.customStatement(
          '''
          INSERT INTO production_test_consumption
            (test_id, inventory_item_id, quantity_millis)
          VALUES (?, ?, ?)
          ''',
          [testId, entry.key, entry.value],
        );
      }

      return testId;
    });
  }

  Future<List<ProductionTestRecord>> getAll() async {
    await initialize();

    final rows = await db.customSelect('''
      SELECT
        t.id,
        t.created_at,
        t.notes,
        GROUP_CONCAT(
          i.name || ': ' ||
          RTRIM(
            RTRIM(
              PRINTF('%.3f', c.quantity_millis / 1000.0),
              '0'
            ),
            '.'
          ) || ' ' || i.unit,
          ', '
        ) AS materials
      FROM production_tests t
      JOIN production_test_consumption c
        ON c.test_id = t.id
      JOIN inventory_items i
        ON i.id = c.inventory_item_id
      GROUP BY t.id, t.created_at, t.notes
      ORDER BY t.id DESC
    ''').get();

    return rows.map((row) {
      return ProductionTestRecord(
        id: row.read<int>('id'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('created_at'),
        ),
        notes: row.read<String>('notes'),
        materials: row.read<String>('materials'),
      );
    }).toList();
  }
}

class ProductionTestDialog extends StatefulWidget {
  const ProductionTestDialog({super.key});

  @override
  State<ProductionTestDialog> createState() => _ProductionTestDialogState();
}

class _ProductionTestDialogState extends State<ProductionTestDialog> {
  late final AppDatabase db;
  late final ProductionTestRepository repository;

  final searchController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();

  List<(int, String, String, int)> inventory = [];
  final Map<int, int> materials = {};

  int? selectedId;
  bool showResults = false;
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    repository = ProductionTestRepository(db);
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    quantityController.dispose();
    notesController.dispose();
    db.close();
    super.dispose();
  }

  Future<void> load() async {
    try {
      await repository.initialize();

      final rows = await db.customSelect('''
        SELECT id, name, unit, quantity_millis
        FROM inventory_items
        WHERE category = 'filament'
          AND quantity_millis > 0
        ORDER BY name COLLATE NOCASE
      ''').get();

      inventory = rows.map((row) {
        return (
          row.read<int>('id'),
          row.read<String>('name'),
          row.read<String>('unit'),
          row.read<int>('quantity_millis'),
        );
      }).toList();

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  String number(int millis) {
    return (millis / 1000)
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  int? parseQuantity(String value) {
    final text = value.trim().replaceAll(',', '.');

    final match = RegExp(r'^(\d+)(?:\.(\d{1,3}))?$').firstMatch(text);

    if (match == null) return null;

    final whole = int.tryParse(match.group(1)!);
    final fractional = int.tryParse((match.group(2) ?? '').padRight(3, '0'));

    if (whole == null || fractional == null) {
      return null;
    }

    return whole * 1000 + fractional;
  }

  (int, String, String, int)? itemById(int id) {
    for (final item in inventory) {
      if (item.$1 == id) return item;
    }
    return null;
  }

  int available(int id) {
    return itemById(id)?.$4 ?? 0;
  }

  void message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void addMaterial() {
    final id = selectedId;
    final quantity = parseQuantity(quantityController.text);

    if (id == null || quantity == null || quantity <= 0) {
      message('Selecciona un filamento y una cantidad valida.');
      return;
    }

    final total = (materials[id] ?? 0) + quantity;

    if (total > available(id)) {
      message('No existe suficiente filamento en inventario.');
      return;
    }

    setState(() {
      materials[id] = total;
      selectedId = null;
      searchController.clear();
      quantityController.clear();
      showResults = false;
    });
  }

  Future<void> save() async {
    if (saving) return;

    if (materials.isEmpty) {
      message('Agrega al menos un filamento.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar prueba'),
        content: const Text(
          'Se descontaran los materiales del inventario. '
          'No se creara ningun producto terminado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => saving = true);

    try {
      final id = await repository.register(
        materials: Map.of(materials),
        notes: notesController.text,
      );

      if (!mounted) return;

      message('Prueba #$id registrada correctamente.');
      Navigator.pop(context, true);
    } catch (e) {
      message('No se pudo registrar la prueba: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = searchController.text.toLowerCase().trim();

    final filtered = inventory.where((item) {
      return item.$2.toLowerCase().contains(search);
    }).toList();

    final selected = selectedId == null ? null : itemById(selectedId!);

    return AlertDialog(
      title: const Text('Registrar prueba de impresion'),
      content: SizedBox(
        width: 560,
        height: 520,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? SelectableText(error!)
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registra el material consumido sin crear un producto.',
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: searchController,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: 'Buscar filamento',
                        hintText: 'PLA, PETG, madera...',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: saving
                              ? null
                              : () {
                                  searchController.clear();
                                  setState(() {
                                    selectedId = null;
                                    showResults = true;
                                  });
                                },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      onTap: () {
                        setState(() => showResults = true);
                      },
                      onChanged: (_) {
                        setState(() {
                          selectedId = null;
                          showResults = true;
                        });
                      },
                    ),
                    if (selected != null && !showResults)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Seleccionado: ${selected.$2}',
                          style: const TextStyle(
                            color: Color(0xFF284426),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (showResults) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D9D0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: filtered.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No se encontraron filamentos.'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];

                                  return ListTile(
                                    dense: true,
                                    title: Text(item.$2),
                                    subtitle: Text(
                                      'Disponible: ${number(item.$4)} ${item.$3}',
                                    ),
                                    onTap: saving
                                        ? null
                                        : () {
                                            searchController.text = item.$2;
                                            FocusScope.of(context).unfocus();
                                            setState(() {
                                              selectedId = item.$1;
                                              showResults = false;
                                            });
                                          },
                                  );
                                },
                              ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Cantidad consumida',
                        hintText: 'Ej. 12.5',
                        helperText: selected == null
                            ? 'Selecciona primero un filamento.'
                            : 'Unidad: ${selected.$3}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: saving ? null : addMaterial,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar filamento'),
                    ),
                    const Divider(height: 28),
                    if (materials.isEmpty)
                      const Text('Todavia no hay filamentos agregados.'),
                    for (final entry in materials.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(itemById(entry.key)?.$2 ?? 'Filamento'),
                        subtitle: Text(
                          '${number(entry.value)} '
                          '${itemById(entry.key)?.$3 ?? ''}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Quitar filamento',
                          icon: const Icon(Icons.close),
                          onPressed: saving
                              ? null
                              : () {
                                  setState(() {
                                    materials.remove(entry.key);
                                  });
                                },
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        hintText: 'Calibracion, purga, fallo...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: saving || loading || error != null ? null : save,
          icon: const Icon(Icons.check),
          label: const Text('Registrar prueba'),
        ),
      ],
    );
  }
}
