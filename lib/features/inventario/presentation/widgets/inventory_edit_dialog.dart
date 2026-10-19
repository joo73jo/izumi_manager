import 'package:flutter/material.dart';

import '../../domain/inventory_category.dart';
import '../../domain/inventory_item.dart';

class InventoryEditInput {
  const InventoryEditInput({
    required this.name,
    required this.category,
    required this.minimumMillis,
  });

  final String name;
  final InventoryCategory category;
  final int minimumMillis;
}

class InventoryEditDialog extends StatefulWidget {
  const InventoryEditDialog({super.key, required this.item});

  final InventoryItem item;

  @override
  State<InventoryEditDialog> createState() => _InventoryEditDialogState();
}

class _InventoryEditDialogState extends State<InventoryEditDialog> {
  late final TextEditingController name;
  late final TextEditingController minimum;
  late InventoryCategory category;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.item.name);
    minimum = TextEditingController(
      text: (widget.item.minimumMillis / 1000)
          .toStringAsFixed(3)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), ''),
    );
    category = widget.item.category;
  }

  @override
  void dispose() {
    name.dispose();
    minimum.dispose();
    super.dispose();
  }

  int? parseMillis(String input) {
    final match = RegExp(r'^(\d+)(?:[,.](\d{1,3}))?$').firstMatch(input.trim());

    if (match == null) return null;

    final whole = int.tryParse(match.group(1)!);
    final part = int.tryParse(
      (match.group(2) ?? '').padRight(3, '0').isEmpty
          ? '0'
          : (match.group(2) ?? '').padRight(3, '0'),
    );

    if (whole == null || part == null) return null;
    return whole * 1000 + part;
  }

  void save() {
    final parsed = parseMillis(minimum.text);

    if (name.text.trim().isEmpty || parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa el nombre y stock minimo.')),
      );
      return;
    }

    Navigator.pop(
      context,
      InventoryEditInput(
        name: name.text.trim(),
        category: category,
        minimumMillis: parsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar material'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InventoryCategory>(
              initialValue: category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: InventoryCategory.values.map((value) {
                return DropdownMenuItem(value: value, child: Text(value.label));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minimum,
              decoration: InputDecoration(
                labelText: 'Stock minimo (${category.defaultUnit})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'La cantidad actual se cambia desde Ajustar existencias.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: save, child: const Text('Guardar cambios')),
      ],
    );
  }
}
