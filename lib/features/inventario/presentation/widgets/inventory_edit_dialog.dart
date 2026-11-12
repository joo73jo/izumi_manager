import 'package:flutter/material.dart';

import '../../domain/inventory_category.dart';
import '../../domain/inventory_item.dart';

class InventoryEditInput {
  const InventoryEditInput({
    required this.name,
    required this.category,
    required this.minimumMillis,
    required this.referenceCostCentsPerKg,
  });

  final String name;
  final InventoryCategory category;
  final int minimumMillis;
  final int? referenceCostCentsPerKg;
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
  late final TextEditingController referenceCost;
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

    referenceCost = TextEditingController(
      text: widget.item.referenceCostCentsPerKg == null
          ? ''
          : (widget.item.referenceCostCentsPerKg! / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    name.dispose();
    minimum.dispose();
    referenceCost.dispose();
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

  int? parseCostCents(String input) {
    final text = input.trim().replaceAll(',', '.');

    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);

    if (match == null) return null;

    final dollars = int.tryParse(match.group(1)!);
    if (dollars == null) return null;

    final fraction = (match.group(2) ?? '').padRight(2, '0');
    final cents = fraction.isEmpty ? 0 : int.parse(fraction);

    return dollars * 100 + cents;
  }

  void save() {
    final parsed = parseMillis(minimum.text);

    if (name.text.trim().isEmpty || parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa el nombre y stock minimo.')),
      );
      return;
    }

    int? costCents;

    if (category == InventoryCategory.filament &&
        referenceCost.text.trim().isNotEmpty) {
      costCents = parseCostCents(referenceCost.text);

      if (costCents == null || costCents <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un costo por kg válido.')),
        );
        return;
      }
    }

    Navigator.pop(
      context,
      InventoryEditInput(
        name: name.text.trim(),
        category: category,
        minimumMillis: parsed,
        referenceCostCentsPerKg: costCents,
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
            if (category == InventoryCategory.filament) ...[
              TextField(
                controller: referenceCost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Costo aproximado por kg (USD)',
                  hintText: 'Ej. 20.00',
                  helperText: 'Referencia únicamente. No registra compras.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
