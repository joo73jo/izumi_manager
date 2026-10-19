import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../inventario/data/inventory_repository.dart';
import '../../../inventario/domain/inventory_item.dart';
import '../../data/product_materials_repository.dart';
import '../../domain/izumi_product.dart';
import '../../domain/product_material.dart';

class ProductMaterialsDialog extends StatefulWidget {
  const ProductMaterialsDialog({super.key, required this.product});

  final IzumiProduct product;

  @override
  State<ProductMaterialsDialog> createState() => _ProductMaterialsDialogState();
}

class _ProductMaterialsDialogState extends State<ProductMaterialsDialog> {
  late final AppDatabase db;
  late final InventoryRepository inventory;
  late final ProductMaterialsRepository recipes;

  final quantity = TextEditingController();
  final waste = TextEditingController(text: '0');

  List<InventoryItem> available = [];
  List<ProductMaterial> assigned = [];
  int? selectedId;
  bool loading = true;
  bool saving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    inventory = InventoryRepository(db);
    recipes = ProductMaterialsRepository(db);
    load();
  }

  @override
  void dispose() {
    quantity.dispose();
    waste.dispose();
    db.close();
    super.dispose();
  }

  Future<void> load() async {
    try {
      await inventory.initialize();
      final items = await inventory.getAll();
      final materials = await recipes.getByProduct(widget.product.id);

      if (!mounted) return;

      setState(() {
        available = items;
        assigned = materials;
        selectedId = items.isEmpty ? null : items.first.id;
        loading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = error.toString();
      });
    }
  }

  int? parseQuantity(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,3}))?$').firstMatch(normalized);

    if (match == null) return null;

    final whole = int.tryParse(match.group(1)!);
    final decimals = int.tryParse(
      (match.group(2) ?? '').padRight(3, '0').isEmpty
          ? '0'
          : (match.group(2) ?? '').padRight(3, '0'),
    );

    if (whole == null || decimals == null) return null;
    return whole * 1000 + decimals;
  }

  String displayQuantity(int millis) {
    return (millis / 1000)
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  void showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> save() async {
    if (saving || selectedId == null) return;

    final amount = parseQuantity(quantity.text);
    final percent = int.tryParse(waste.text.trim());

    if (amount == null ||
        amount <= 0 ||
        percent == null ||
        percent < 0 ||
        percent > 100) {
      showError('Revisa la cantidad y el desperdicio (0 a 100%).');
      return;
    }

    setState(() => saving = true);

    try {
      await recipes.saveMaterial(
        productId: widget.product.id,
        inventoryItemId: selectedId!,
        quantityMillis: amount,
        wastePercent: percent,
      );

      final updated = await recipes.getByProduct(widget.product.id);

      if (!mounted) return;

      quantity.clear();
      waste.text = '0';
      setState(() => assigned = updated);
    } catch (error) {
      showError(error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> remove(int inventoryItemId) async {
    try {
      await recipes.removeMaterial(
        productId: widget.product.id,
        inventoryItemId: inventoryItemId,
      );

      final updated = await recipes.getByProduct(widget.product.id);
      if (mounted) setState(() => assigned = updated);
    } catch (error) {
      showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Materiales: ${widget.product.name}'),
      content: SizedBox(
        width: 520,
        child: loading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : errorMessage != null
            ? SelectableText(errorMessage!)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Materiales necesarios para fabricar una unidad.',
                    ),
                    const SizedBox(height: 16),
                    for (final material in assigned)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(material.name),
                        subtitle: Text(
                          '${displayQuantity(material.quantityMillis)} '
                          '${material.unit} + '
                          '${material.wastePercent}% desperdicio',
                        ),
                        trailing: IconButton(
                          tooltip: 'Quitar material',
                          icon: const Icon(Icons.close),
                          onPressed: saving
                              ? null
                              : () => remove(material.inventoryItemId),
                        ),
                      ),
                    const Divider(),
                    if (available.isEmpty)
                      const Text('Primero registra materiales en Inventario.')
                    else ...[
                      DropdownButtonFormField<int>(
                        key: ValueKey(selectedId),
                        initialValue: selectedId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Material del inventario',
                          border: OutlineInputBorder(),
                        ),
                        items: available.map((item) {
                          return DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.name} (${item.unit})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                setState(() => selectedId = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quantity,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad por maceta',
                          hintText: 'Ej. 180',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: waste,
                        decoration: const InputDecoration(
                          labelText: 'Desperdicio estimado (%)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: saving ? null : save,
                          icon: const Icon(Icons.add),
                          label: const Text('Guardar material'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
