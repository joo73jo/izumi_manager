import 'package:flutter/material.dart';

import '../../../inventario/domain/inventory_category.dart';
import '../../../inventario/domain/inventory_item.dart';
import '../../domain/purchase_line.dart';

class PurchaseLineDialog extends StatefulWidget {
  const PurchaseLineDialog({super.key, required this.items});

  final List<InventoryItem> items;

  @override
  State<PurchaseLineDialog> createState() => _PurchaseLineDialogState();
}

class _PurchaseLineDialogState extends State<PurchaseLineDialog> {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final total = TextEditingController();

  bool newMaterial = false;
  int? selectedId;
  InventoryCategory category = InventoryCategory.filament;

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      selectedId = widget.items.first.id;
    } else {
      newMaterial = true;
    }
  }

  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    total.dispose();
    super.dispose();
  }

  int? parseAmount(String text, int decimals) {
    final input = text.trim().replaceAll(',', '.');
    final parts = input.split('.');

    if (parts.length > 2 ||
        parts.first.isEmpty ||
        !RegExp(r'^\d+$').hasMatch(parts.first)) {
      return null;
    }

    if (parts.length == 2 &&
        (parts.last.isEmpty ||
            parts.last.length > decimals ||
            !RegExp(r'^\d+$').hasMatch(parts.last))) {
      return null;
    }

    final whole = int.tryParse(parts.first);
    if (whole == null) return null;

    final fraction = parts.length == 2
        ? int.parse(parts.last.padRight(decimals, '0'))
        : 0;

    final factor = decimals == 3 ? 1000 : 100;
    return whole * factor + fraction;
  }

  void save() {
    final qty = parseAmount(quantity.text, 3);
    final price = parseAmount(total.text, 2);

    if (qty == null || qty <= 0 || price == null || price <= 0) {
      showError('Ingresa cantidad e importe v\u00e1lidos.');
      return;
    }

    if (newMaterial && name.text.trim().isEmpty) {
      showError('Ingresa el nombre del material.');
      return;
    }

    final existing = newMaterial
        ? null
        : widget.items.where((item) => item.id == selectedId).firstOrNull;

    if (!newMaterial && existing == null) {
      showError('Selecciona un material.');
      return;
    }

    Navigator.pop(
      context,
      PurchaseLine(
        inventoryItemId: existing?.id,
        name: existing?.name ?? name.text.trim(),
        category: existing?.category ?? category,
        unit: existing?.unit ?? category.defaultUnit,
        quantityMillis: qty,
        totalCents: price,
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.items
        .where((item) => item.id == selectedId)
        .firstOrNull;

    final unit = newMaterial
        ? category.defaultUnit
        : existing?.unit ?? 'unidad';

    return AlertDialog(
      title: const Text('Material de la compra'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Crear material nuevo'),
                value: newMaterial,
                onChanged: (value) {
                  setState(() => newMaterial = value);
                },
              ),
              const SizedBox(height: 10),
              if (newMaterial) ...[
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del material',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InventoryCategory>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categor\u00eda',
                    border: OutlineInputBorder(),
                  ),
                  items: InventoryCategory.values.map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => category = value);
                    }
                  },
                ),
              ] else
                DropdownButtonFormField<int>(
                  key: ValueKey(selectedId),
                  initialValue: selectedId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Material existente',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.items.map((item) {
                    return DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedId = value);
                  },
                ),
              const SizedBox(height: 14),
              TextField(
                controller: quantity,
                decoration: InputDecoration(
                  labelText: 'Cantidad ($unit)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: total,
                decoration: const InputDecoration(
                  labelText: 'Importe total',
                  prefixText: r'$ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: save, child: const Text('Agregar a compra')),
      ],
    );
  }
}
