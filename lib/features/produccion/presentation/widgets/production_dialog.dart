import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../inventario/data/inventory_repository.dart';
import '../../../productos/data/product_variants_repository.dart';
import '../../data/production_completion_service.dart';
import '../../domain/production_order.dart';

class ProductionDialog extends StatefulWidget {
  const ProductionDialog({super.key});

  @override
  State<ProductionDialog> createState() => _ProductionDialogState();
}

class _ProductionDialogState extends State<ProductionDialog> {
  late final AppDatabase db;

  final quantityController = TextEditingController();
  final wasteController = TextEditingController(text: '0');
  final notesController = TextEditingController();
  final materialSearchController = TextEditingController();

  List<(int, String, String, int)> get filteredInventory {
    final search = materialSearchController.text.trim().toLowerCase();

    return inventory.where((item) {
      return item.$2.toLowerCase().contains(search);
    }).toList();
  }

  List<(int, String)> products = [];
  List<(int, String)> variants = [];
  List<(int, String, String, int)> inventory = [];
  final List<ProductionMaterialInput> materials = [];

  int? productId;
  int? variantId;
  int? materialId;
  bool showMaterialResults = false;

  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    load();
  }

  @override
  void dispose() {
    quantityController.dispose();
    wasteController.dispose();
    notesController.dispose();
    materialSearchController.dispose();
    db.close();
    super.dispose();
  }

  Future<void> load() async {
    try {
      await InventoryRepository(db).initialize();
      await ProductVariantsRepository(db).initialize();

      final productRows = await db.customSelect('''
        SELECT id, name FROM izumi_products
        WHERE active = 1 ORDER BY name COLLATE NOCASE
      ''').get();

      final inventoryRows = await db.customSelect('''
        SELECT id, name, unit, quantity_millis
        FROM inventory_items
        WHERE quantity_millis > 0
          AND category IN (
            'filament',
            'plant',
            'substrate',
            'packaging'
          )
          AND LOWER(category) NOT LIKE '%equipo%'
          AND LOWER(category) NOT LIKE '%herramient%'
          AND LOWER(category) NOT LIKE '%maquinaria%'
          AND LOWER(category) NOT LIKE '%activo%'
          AND LOWER(category) NOT LIKE '%equipment%'
          AND LOWER(category) NOT LIKE '%tool%'
          AND LOWER(category) NOT LIKE '%machine%'
          AND LOWER(name) NOT LIKE 'impresora %'
          AND LOWER(name) NOT LIKE 'secador %'
          AND LOWER(name) NOT LIKE 'regulador %'
          AND LOWER(name) NOT LIKE 'cortadora %'
          AND LOWER(name) NOT LIKE 'calibrador %'
        ORDER BY name COLLATE NOCASE
      ''').get();

      products = productRows
          .map((r) => (r.read<int>('id'), r.read<String>('name')))
          .toList();

      inventory = inventoryRows.map((r) {
        return (
          r.read<int>('id'),
          r.read<String>('name'),
          r.read<String>('unit'),
          r.read<int>('quantity_millis'),
        );
      }).toList();

      productId = products.isEmpty ? null : products.first.$1;
      materialId = null;

      await loadVariants();

      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> loadVariants() async {
    if (productId == null) {
      variants = [];
      variantId = null;
      return;
    }

    final existing = await db
        .customSelect(
          '''
      SELECT id FROM product_variants
      WHERE product_id = ? AND active = 1
      LIMIT 1
      ''',
          variables: [Variable.withInt(productId!)],
        )
        .get();

    if (existing.isEmpty) {
      await db.customStatement(
        '''
        INSERT INTO product_variants
          (product_id, name, price_cents, active)
        VALUES (
          ?,
          'General',
          (SELECT price_cents
           FROM izumi_products WHERE id = ?),
          1
        )
        ON CONFLICT(product_id, name)
        DO UPDATE SET active = 1
        ''',
        [productId!, productId!],
      );
    }

    final rows = await db
        .customSelect(
          '''
      SELECT id, name FROM product_variants
      WHERE product_id = ? AND active = 1
      ORDER BY name COLLATE NOCASE
    ''',
          variables: [Variable.withInt(productId!)],
        )
        .get();

    variants = rows
        .map((r) => (r.read<int>('id'), r.read<String>('name')))
        .toList();

    variantId = variants.isEmpty ? null : variants.first.$1;
  }

  int? parseQuantity(String value) {
    final text = value.trim().replaceAll(',', '.');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,3}))?$').firstMatch(text);

    if (match == null) return null;

    final whole = int.tryParse(match.group(1)!);
    final fractional = int.tryParse(
      (match.group(2) ?? '').padRight(3, '0').isEmpty
          ? '0'
          : (match.group(2) ?? '').padRight(3, '0'),
    );

    if (whole == null || fractional == null) return null;
    return whole * 1000 + fractional;
  }

  String number(int millis) {
    return (millis / 1000)
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String materialName(int id) {
    for (final item in inventory) {
      if (item.$1 == id) return item.$2;
    }
    return 'Material #$id';
  }

  String materialUnit(int id) {
    for (final item in inventory) {
      if (item.$1 == id) return item.$3;
    }
    return '';
  }

  int availableQuantity(int id) {
    for (final item in inventory) {
      if (item.$1 == id) return item.$4;
    }
    return 0;
  }

  void notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void addMaterial() {
    final id = materialId;
    final quantity = parseQuantity(quantityController.text);
    final waste = int.tryParse(wasteController.text.trim());

    if (id == null ||
        quantity == null ||
        quantity <= 0 ||
        waste == null ||
        waste < 0 ||
        waste > 100) {
      notify('Ingresa cantidad y desperdicio v\u00e1lidos.');
      return;
    }

    setState(() {
      materials.add(
        ProductionMaterialInput(
          itemId: id,
          quantityMillis: quantity,
          wastePercent: waste,
        ),
      );
      quantityController.clear();
      wasteController.text = '0';
    });
  }

  Future<void> complete() async {
    if (saving) return;

    if (productId == null || variantId == null) {
      notify('Selecciona un producto y una variante.');
      return;
    }

    if (materials.isEmpty) {
      notify('Agrega al menos un material.');
      return;
    }

    final totals = <int, int>{};

    for (final line in materials) {
      totals.update(
        line.itemId,
        (value) => value + line.consumptionMillis,
        ifAbsent: () => line.consumptionMillis,
      );
    }

    final shortages = totals.entries
        .where((entry) => entry.value > availableQuantity(entry.key))
        .toList();

    if (shortages.isNotEmpty) {
      notify('Stock insuficiente: ${materialName(shortages.first.key)}');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar fabricaci\u00f3n'),
        content: Text(
          'Se fabricar\u00e1 una maceta y se descontar\u00e1n '
          '${totals.length} materiales del inventario.\n\n'
          'Esta operaci\u00f3n quedar\u00e1 registrada.',
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
      final id = await ProductionCompletionService(db).complete(
        ProductionDraft(
          productId: productId!,
          variantId: variantId!,
          materials: List.unmodifiable(materials),
          notes: notesController.text,
        ),
      );

      if (!mounted) return;
      notify('Producci\u00f3n #$id registrada correctamente.');
      Navigator.pop(context, true);
    } catch (e) {
      notify('No se pudo fabricar: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fabricar maceta'),
      content: SizedBox(
        width: 580,
        height: 550,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? SelectableText(error!)
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (products.isEmpty)
                      const Text('Primero crea un producto.')
                    else
                      DropdownButtonFormField<int>(
                        key: ValueKey('product-$productId'),
                        initialValue: productId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Producto',
                          border: OutlineInputBorder(),
                        ),
                        items: products.map((p) {
                          return DropdownMenuItem(
                            value: p.$1,
                            child: Text(p.$2),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (id) async {
                                if (id == null) return;
                                setState(() => productId = id);
                                await loadVariants();
                                if (mounted) setState(() {});
                              },
                      ),
                    const SizedBox(height: 12),
                    if (variants.length > 1)
                      DropdownButtonFormField<int>(
                        key: ValueKey('variant-$productId-$variantId'),
                        initialValue: variantId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Variante',
                          border: OutlineInputBorder(),
                        ),
                        items: variants.map((v) {
                          return DropdownMenuItem(
                            value: v.$1,
                            child: Text(v.$2),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (id) => setState(() => variantId = id),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Materiales utilizados',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (inventory.isEmpty)
                      const Text('Primero registra insumos en Inventario.')
                    else ...[
                      TextField(
                        controller: materialSearchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar material',
                          hintText: 'Ej. PLA, PETG, madera...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: 'Limpiar',
                            icon: const Icon(Icons.clear),
                            onPressed: saving
                                ? null
                                : () {
                                    materialSearchController.clear();
                                    setState(() {
                                      materialId = null;
                                      showMaterialResults = true;
                                    });
                                  },
                          ),
                        ),
                        onTap: () {
                          if (!saving) {
                            setState(() => showMaterialResults = true);
                          }
                        },
                        onChanged: (_) {
                          setState(() {
                            materialId = null;
                            showMaterialResults = true;
                          });
                        },
                      ),
                      if (materialId != null && !showMaterialResults)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Seleccionado: ${materialName(materialId!)}',
                            style: const TextStyle(
                              color: Color(0xFF284426),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (showMaterialResults) ...[
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 210),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD1D9D0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: filteredInventory.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No se encontraron materiales.'),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredInventory.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredInventory[index];
                                    final unit = item.$3 == 'unidad'
                                        ? (item.$4 == 1000
                                              ? 'unidad'
                                              : 'unidades')
                                        : item.$3;
                                    return ListTile(
                                      dense: true,
                                      title: Text(item.$2),
                                      subtitle: Text(
                                        'Stock: ${number(item.$4)} $unit',
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                      ),
                                      onTap: saving
                                          ? null
                                          : () {
                                              materialSearchController.text =
                                                  item.$2;
                                              FocusScope.of(context).unfocus();
                                              setState(() {
                                                materialId = item.$1;
                                                showMaterialResults = false;
                                              });
                                            },
                                    );
                                  },
                                ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                hintText: 'Ej. 100',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: wasteController,
                              decoration: const InputDecoration(
                                labelText: 'Desperdicio %',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: saving ? null : addMaterial,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar material'),
                      ),
                    ],
                    const Divider(height: 26),
                    if (materials.isEmpty)
                      const Text('Todav\u00eda no hay materiales agregados.'),
                    for (var index = 0; index < materials.length; index++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(materialName(materials[index].itemId)),
                        subtitle: Text(
                          '${number(materials[index].quantityMillis)} '
                          '${materialUnit(materials[index].itemId)}'
                          ' + ${materials[index].wastePercent}%'
                          ' = ${number(materials[index].consumptionMillis)} '
                          '${materialUnit(materials[index].itemId)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Quitar de la producci\u00f3n',
                          icon: const Icon(Icons.close),
                          onPressed: saving
                              ? null
                              : () => setState(() => materials.removeAt(index)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
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
          onPressed: saving || loading || error != null ? null : complete,
          icon: const Icon(Icons.check),
          label: const Text('Confirmar producci\u00f3n'),
        ),
      ],
    );
  }
}
