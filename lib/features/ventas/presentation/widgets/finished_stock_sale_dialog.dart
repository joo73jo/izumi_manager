import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../data/finished_stock_sale_repository.dart';

class FinishedStockSaleDialog extends StatefulWidget {
  const FinishedStockSaleDialog({super.key});

  @override
  State<FinishedStockSaleDialog> createState() =>
      _FinishedStockSaleDialogState();
}

class _FinishedStockSaleDialogState extends State<FinishedStockSaleDialog> {
  late final AppDatabase db;
  late final FinishedStockSaleRepository repository;
  late Future<List<SaleableVariant>> variantsFuture;

  final price = TextEditingController();
  final customer = TextEditingController();
  final notes = TextEditingController();

  int? selectedId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    repository = FinishedStockSaleRepository(db);
    variantsFuture = repository.availableVariants();
  }

  @override
  void dispose() {
    price.dispose();
    customer.dispose();
    notes.dispose();
    db.close();
    super.dispose();
  }

  int? moneyToCents(String raw) {
    final value = raw.trim().replaceAll(',', '.');

    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');
    final dollars = int.tryParse(parts.first);
    final cents = parts.length == 2
        ? int.tryParse(parts.last.padRight(2, '0'))
        : 0;

    if (dollars == null || cents == null) return null;
    return dollars * 100 + cents;
  }

  String dollars(int cents) => (cents / 100).toStringAsFixed(2);

  void notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> confirm() async {
    if (saving || selectedId == null) return;

    final revenue = moneyToCents(price.text);
    if (revenue == null || revenue <= 0) {
      notify('Ingresa un precio de venta valido.');
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar venta'),
        content: const Text(
          'Se vendera una maceta, se descontara del stock '
          'y se registrara el ingreso en Banco Izumi.\n\n'
          'El costo se obtendra automaticamente de '
          'su fabricacion historica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar venta'),
          ),
        ],
      ),
    );

    if (accepted != true || !mounted) return;
    setState(() => saving = true);

    try {
      await repository.registerSale(
        variantId: selectedId!,
        revenueCents: revenue,
        customerName: customer.text,
        notes: notes.text,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      notify('No se pudo registrar la venta: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vender maceta del stock'),
      content: SizedBox(
        width: 480,
        child: FutureBuilder<List<SaleableVariant>>(
          future: variantsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SelectableText('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final variants = snapshot.data!;

            if (variants.isEmpty) {
              return const Text('No hay macetas terminadas disponibles.');
            }

            final current = variants.any((v) => v.id == selectedId)
                ? selectedId!
                : variants.first.id;

            if (selectedId != current) {
              selectedId = current;
              price.text = dollars(
                variants.firstWhere((v) => v.id == current).priceCents,
              );
            }

            final chosen = variants.firstWhere((v) => v.id == current);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey(current),
                    initialValue: current,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto y variante',
                      border: OutlineInputBorder(),
                    ),
                    items: variants.map((variant) {
                      return DropdownMenuItem(
                        value: variant.id,
                        child: Text(
                          '${variant.productName} - ${variant.variantName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: saving
                        ? null
                        : (id) {
                            if (id == null) return;
                            final item = variants.firstWhere((v) => v.id == id);
                            setState(() {
                              selectedId = id;
                              price.text = dollars(item.priceCents);
                            });
                          },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Disponibles: ${chosen.available} unidades'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: price,
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta (USD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customer,
                    decoration: const InputDecoration(
                      labelText: 'Cliente (opcional)',
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
                  const Text(
                    'Costo de materiales: automatico, '
                    'segun la fabricacion registrada.',
                    style: TextStyle(color: Color(0xFF284426), fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : confirm,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Registrar venta'),
        ),
      ],
    );
  }
}
