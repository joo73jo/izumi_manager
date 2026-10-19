import 'package:flutter/material.dart';

import '../../domain/inventory_item.dart';

class InventoryPurchaseInput {
  const InventoryPurchaseInput({
    required this.quantityMillis,
    required this.totalCents,
  });

  final int quantityMillis;
  final int totalCents;
}

class InventoryPurchaseDialog extends StatefulWidget {
  const InventoryPurchaseDialog({super.key, required this.item});

  final InventoryItem item;

  @override
  State<InventoryPurchaseDialog> createState() =>
      _InventoryPurchaseDialogState();
}

class _InventoryPurchaseDialogState extends State<InventoryPurchaseDialog> {
  final formKey = GlobalKey<FormState>();
  final quantity = TextEditingController();
  final total = TextEditingController();

  @override
  void dispose() {
    quantity.dispose();
    total.dispose();
    super.dispose();
  }

  int? parseAmount(String input, int precision) {
    final value = input.trim().replaceAll(',', '.');

    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(value);

    if (match == null) return null;

    final decimals = match.group(2) ?? '';

    if (decimals.length > precision) return null;

    final whole = int.tryParse(match.group(1)!);
    final fraction = int.tryParse(
      decimals.padRight(precision, '0').isEmpty
          ? '0'
          : decimals.padRight(precision, '0'),
    );

    if (whole == null || fraction == null) return null;

    var factor = 1;
    for (var i = 0; i < precision; i++) {
      factor *= 10;
    }

    return whole * factor + fraction;
  }

  String? validateQuantity(String? value) {
    final result = parseAmount(value ?? '', 3);
    return result == null || result <= 0 ? 'Cantidad no valida' : null;
  }

  String? validateMoney(String? value) {
    final result = parseAmount(value ?? '', 2);
    return result == null || result <= 0 ? 'Importe no valido' : null;
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      InventoryPurchaseInput(
        quantityMillis: parseAmount(quantity.text, 3)!,
        totalCents: parseAmount(total.text, 2)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar compra'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF284426),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: quantity,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cantidad (${widget.item.unit})',
                  hintText: 'Ej. 1000',
                  border: const OutlineInputBorder(),
                ),
                validator: validateQuantity,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: total,
                decoration: const InputDecoration(
                  labelText: 'Total pagado',
                  prefixText: r'$ ',
                  hintText: 'Ej. 24.00',
                  border: OutlineInputBorder(),
                ),
                validator: validateMoney,
              ),
              const SizedBox(height: 14),
              const Text(
                'Forma de pago: Banco Izumi',
                style: TextStyle(color: Colors.black54),
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
        FilledButton(onPressed: save, child: const Text('Registrar compra')),
      ],
    );
  }
}
