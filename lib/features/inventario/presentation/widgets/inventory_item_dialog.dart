import 'package:flutter/material.dart';

import '../../domain/inventory_category.dart';

class InventoryItemInput {
  const InventoryItemInput({
    required this.name,
    required this.category,
    required this.unit,
    required this.quantityMillis,
    required this.minimumMillis,
  });

  final String name;
  final InventoryCategory category;
  final String unit;
  final int quantityMillis;
  final int minimumMillis;
}

class InventoryItemDialog extends StatefulWidget {
  const InventoryItemDialog({super.key});

  @override
  State<InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends State<InventoryItemDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final quantity = TextEditingController(text: '0');
  final minimum = TextEditingController(text: '0');

  InventoryCategory category = InventoryCategory.filament;

  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    minimum.dispose();
    super.dispose();
  }

  int? parseQuantity(String input) {
    final text = input.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(text)) {
      return null;
    }

    final parts = text.split('.');
    final units = int.tryParse(parts.first);
    if (units == null) return null;

    final fraction = parts.length == 2
        ? int.parse(parts.last.padRight(3, '0'))
        : 0;

    return units * 1000 + fraction;
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      InventoryItemInput(
        name: name.text.trim(),
        category: category,
        unit: category.defaultUnit,
        quantityMillis: parseQuantity(quantity.text)!,
        minimumMillis: parseQuantity(minimum.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar material'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nombre del material',
                  hintText: 'Ej. PLA marmol eSUN',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<InventoryCategory>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: InventoryCategory.values.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item.label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: quantity,
                decoration: InputDecoration(
                  labelText: 'Cantidad inicial (${category.defaultUnit})',
                ),
                validator: validateQuantity,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: minimum,
                decoration: InputDecoration(
                  labelText: 'Stock minimo (${category.defaultUnit})',
                ),
                validator: validateQuantity,
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
        FilledButton(onPressed: save, child: const Text('Guardar')),
      ],
    );
  }

  String? validateQuantity(String? value) {
    if (parseQuantity(value ?? '') == null) {
      return 'Cantidad invalida';
    }
    return null;
  }
}
