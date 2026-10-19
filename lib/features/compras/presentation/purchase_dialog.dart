import 'package:flutter/material.dart';

import '../../inventario/domain/inventory_item.dart';
import '../domain/purchase_line.dart';
import 'widgets/purchase_line_dialog.dart';

class PurchaseDialog extends StatefulWidget {
  const PurchaseDialog({super.key, required this.items});

  final List<InventoryItem> items;

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  final description = TextEditingController();
  final supplier = TextEditingController();
  final invoiceNumber = TextEditingController();
  final notes = TextEditingController();
  final List<PurchaseLine> lines = [];
  DateTime date = DateTime.now();

  @override
  void dispose() {
    description.dispose();
    supplier.dispose();
    invoiceNumber.dispose();
    notes.dispose();
    super.dispose();
  }

  String money(int cents) {
    return '\$${cents ~/ 100}.'
        '${(cents % 100).toString().padLeft(2, '0')}';
  }

  Future<void> addLine() async {
    final result = await showDialog<PurchaseLine>(
      context: context,
      builder: (_) => PurchaseLineDialog(items: widget.items),
    );

    if (result != null && mounted) {
      setState(() => lines.add(result));
    }
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
    if (description.text.trim().isEmpty || lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega una descripci\u00f3n y materiales.'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      PurchaseDraft(
        date: date,
        description: description.text.trim(),
        lines: List.unmodifiable(lines),
        supplier: supplier.text.trim(),
        invoiceNumber: invoiceNumber.text.trim(),
        notes: notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = PurchaseDraft(
      date: date,
      description: description.text,
      lines: lines,
    );

    return AlertDialog(
      title: const Text('Nueva compra'),
      content: SizedBox(
        width: 580,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'Descripci\u00f3n general',
                hintText: 'Ej. Materiales de octubre',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: supplier,
              decoration: const InputDecoration(
                labelText: 'Proveedor',
                hintText: 'Ej. Hipermarket',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: invoiceNumber,
              decoration: const InputDecoration(
                labelText: 'Numero de comprobante',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: selectDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('${date.day}/${date.month}/${date.year}'),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: addLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar material'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: lines.isEmpty
                  ? const Center(
                      child: Text('Agrega materiales a esta compra.'),
                    )
                  : ListView.builder(
                      itemCount: lines.length,
                      itemBuilder: (context, index) {
                        final line = lines[index];

                        return ListTile(
                          title: Text(line.name),
                          subtitle: Text(
                            '${line.quantityMillis / 1000} '
                            '${line.unit}'
                            '${line.isNew ? ' - Nuevo' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(money(line.totalCents)),
                              IconButton(
                                tooltip: 'Quitar',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() => lines.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              children: [
                const Text(
                  'Total de compra',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  money(draft.totalCents),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF284426),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Pago desde Banco Izumi. El inventario y la '
              'contabilidad se actualizar\u00e1n juntos.',
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
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Registrar compra'),
        ),
      ],
    );
  }
}
