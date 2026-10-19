import 'package:flutter/material.dart';

import '../../domain/sale.dart';

class SaleDialog extends StatefulWidget {
  const SaleDialog({super.key});

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  final formKey = GlobalKey<FormState>();

  final description = TextEditingController();
  final customer = TextEditingController();
  final revenue = TextEditingController();
  final cost = TextEditingController(text: '0');
  final notes = TextEditingController();

  SaleChannel channel = SaleChannel.direct;
  DateTime date = DateTime.now();

  @override
  void dispose() {
    description.dispose();
    customer.dispose();
    revenue.dispose();
    cost.dispose();
    notes.dispose();
    super.dispose();
  }

  int? parseMoney(String input) {
    final value = input.trim().replaceAll(',', '.');

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;

    final fraction = parts.length == 2
        ? int.parse(parts.last.padRight(2, '0'))
        : 0;

    return whole * 100 + fraction;
  }

  String money(int cents) {
    return '\$${cents ~/ 100}.'
        '${(cents % 100).toString().padLeft(2, '0')}';
  }

  Future<void> selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() => date = selected);
    }
  }

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      SaleDraft(
        date: date,
        description: description.text.trim(),
        channel: channel,
        customerName: customer.text.trim(),
        revenueCents: parseMoney(revenue.text)!,
        estimatedCostCents: parseMoney(cost.text)!,
        notes: notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = parseMoney(revenue.text) ?? 0;
    final expense = parseMoney(cost.text) ?? 0;

    return AlertDialog(
      title: const Text('Registrar venta'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Producto o concepto',
                    hintText: 'Ej. Maceta Sakura',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Campo obligatorio'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: customer,
                  decoration: const InputDecoration(
                    labelText: 'Cliente (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<SaleChannel>(
                  initialValue: channel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Canal de venta',
                    border: OutlineInputBorder(),
                  ),
                  items: SaleChannel.values.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => channel = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: selectDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('${date.day}/${date.month}/${date.year}'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: revenue,
                  decoration: const InputDecoration(
                    labelText: 'Total cobrado',
                    prefixText: r'$ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final amount = parseMoney(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Importe inv\u00e1lido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: cost,
                  decoration: const InputDecoration(
                    labelText: 'Costo estimado de producci\u00f3n',
                    prefixText: r'$ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => parseMoney(value ?? '') == null
                      ? 'Importe inv\u00e1lido'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EFE8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Ganancia estimada')),
                      Text(
                        money(income - expense),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF284426),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Registrar solamente ventas cobradas en Banco Izumi. '
                  'El costo estimado no descuenta inventario '
                  'ni genera reparto autom\u00e1tico.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: save, child: const Text('Registrar venta')),
      ],
    );
  }
}
