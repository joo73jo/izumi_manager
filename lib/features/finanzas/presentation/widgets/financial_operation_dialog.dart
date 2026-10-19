import 'package:flutter/material.dart';

import '../../domain/financial_operation_details.dart';
import '../../domain/financial_operation_type.dart';

class FinancialOperationInput {
  const FinancialOperationInput({
    required this.type,
    required this.description,
    required this.amountCents,
    required this.details,
  });

  final FinancialOperationType type;
  final String description;
  final int amountCents;
  final FinancialOperationDetails details;
}

class FinancialOperationDialog extends StatefulWidget {
  const FinancialOperationDialog({super.key});

  @override
  State<FinancialOperationDialog> createState() =>
      _FinancialOperationDialogState();
}

class _FinancialOperationDialogState extends State<FinancialOperationDialog> {
  final keyForm = GlobalKey<FormState>();
  final description = TextEditingController();
  final category = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unitPrice = TextEditingController();
  final notes = TextEditingController();

  FinancialOperationType type = FinancialOperationType.expense;
  DateTime date = DateTime.now();

  @override
  void dispose() {
    description.dispose();
    category.dispose();
    quantity.dispose();
    unitPrice.dispose();
    notes.dispose();
    super.dispose();
  }

  int? parseMoney(String text) {
    final value = text.trim().replaceAll(',', '.');

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');
    final units = int.tryParse(parts.first);

    if (units == null) return null;

    final cents = parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0;

    return units * 100 + cents;
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
    if (!keyForm.currentState!.validate()) return;

    final count = int.parse(quantity.text.trim());
    final cents = parseMoney(unitPrice.text)!;
    final total = count * cents;

    Navigator.pop(
      context,
      FinancialOperationInput(
        type: type,
        description: description.text.trim(),
        amountCents: total,
        details: FinancialOperationDetails(
          date: date,
          category: category.text.trim(),
          quantity: count,
          unitPriceCents: cents,
          paymentMethod: 'Banco Izumi',
          notes: notes.text.trim(),
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool requiredField = true,
    String? hint,
    int lines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (requiredField && (value == null || value.trim().isEmpty)) {
          return 'Campo obligatorio';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = int.tryParse(quantity.text) ?? 0;
    final cents = parseMoney(unitPrice.text) ?? 0;
    final total = count * cents;

    return AlertDialog(
      title: const Text('Nuevo movimiento'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: keyForm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<FinancialOperationType>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento',
                    border: OutlineInputBorder(),
                  ),
                  items: FinancialOperationType.values
                      .where((item) => item != FinancialOperationType.inventory)
                      .map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => type = value);
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: selectDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Fecha: ${date.day}/${date.month}/${date.year}'),
                ),
                const SizedBox(height: 14),
                field(
                  description,
                  'Descripci\u00f3n',
                  hint: 'Ej. PLA m\u00e1rmol eSUN',
                ),
                const SizedBox(height: 14),
                field(category, 'Categor\u00eda', hint: 'Ej. Filamentos'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final number = int.tryParse(value ?? '');
                          if (number == null || number <= 0) {
                            return 'Cantidad inv\u00e1lida';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: unitPrice,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Precio unitario',
                          prefixText: r'$ ',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final result = parseMoney(value ?? '');
                          if (result == null || result <= 0) {
                            return 'Precio inv\u00e1lido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Total: ${money(total)}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF284426),
                  ),
                ),
                const SizedBox(height: 14),
                const InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'M\u00e9todo de pago',
                    border: OutlineInputBorder(),
                  ),
                  child: Text('Banco Izumi'),
                ),
                const SizedBox(height: 14),
                field(notes, 'Observaciones', requiredField: false, lines: 2),
                const SizedBox(height: 12),
                const Text(
                  'Las compras se registran contablemente. '
                  'El inventario f\u00edsico se conectar\u00e1 '
                  'en una etapa posterior.',
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
        FilledButton(onPressed: save, child: const Text('Guardar')),
      ],
    );
  }
}
