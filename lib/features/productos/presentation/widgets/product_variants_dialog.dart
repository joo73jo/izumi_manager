import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../data/product_variants_repository.dart';
import '../../domain/izumi_product.dart';
import '../../domain/product_variant.dart';

class ProductVariantsDialog extends StatefulWidget {
  const ProductVariantsDialog({super.key, required this.product});

  final IzumiProduct product;

  @override
  State<ProductVariantsDialog> createState() => _ProductVariantsDialogState();
}

class _ProductVariantsDialogState extends State<ProductVariantsDialog> {
  late final AppDatabase db;
  late final ProductVariantsRepository repository;
  late Future<List<ProductVariant>> variants;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    repository = ProductVariantsRepository(db);
    variants = repository.getByProduct(widget.product.id);
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  void refresh() {
    setState(() {
      variants = repository.getByProduct(widget.product.id);
    });
  }

  String money(int cents) {
    return '\$${cents ~/ 100}.'
        '${(cents % 100).toString().padLeft(2, '0')}';
  }

  int? parseMoney(String text) {
    final value = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');
    final units = int.tryParse(parts.first);
    if (units == null) return null;

    final decimals = parts.length == 2
        ? int.parse(parts.last.padRight(2, '0'))
        : 0;

    return units * 100 + decimals;
  }

  void showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> editVariant([ProductVariant? variant]) async {
    final name = TextEditingController(text: variant?.name ?? '');
    final price = TextEditingController(
      text: ((variant?.priceCents ?? widget.product.priceCents) / 100)
          .toStringAsFixed(2),
    );

    final result = await showDialog<(String, int)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(variant == null ? 'Nueva variante' : 'Editar variante'),
        content: SizedBox(
          width: 390,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nombre de variante',
                  hintText: 'Ej. Rojo, Verde, Grande',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: price,
                decoration: const InputDecoration(
                  labelText: 'Precio de venta',
                  prefixText: r'$ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final cents = parseMoney(price.text);
              if (name.text.trim().isEmpty || cents == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Revisa los datos.')),
                );
                return;
              }
              Navigator.pop(dialogContext, (name.text.trim(), cents));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    name.dispose();
    price.dispose();

    if (result == null || !mounted) return;

    try {
      if (variant == null) {
        await repository.create(
          productId: widget.product.id,
          name: result.$1,
          priceCents: result.$2,
        );
      } else {
        await repository.update(
          id: variant.id,
          name: result.$1,
          priceCents: result.$2,
        );
      }
      if (mounted) refresh();
    } catch (error) {
      showError(error);
    }
  }

  Future<void> toggle(ProductVariant variant) async {
    try {
      await repository.setActive(variant.id, !variant.active);
      if (mounted) refresh();
    } catch (error) {
      showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Variantes: ${widget.product.name}'),
      content: SizedBox(
        width: 490,
        height: 350,
        child: FutureBuilder<List<ProductVariant>>(
          future: variants,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SelectableText('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;

            if (data.isEmpty) {
              return const Center(
                child: Text('Todav\u00eda no hay variantes.'),
              );
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final variant = data[index];

                return ListTile(
                  title: Text(variant.name),
                  subtitle: Text(
                    '${money(variant.priceCents)}'
                    '${variant.active ? '' : ' - Inactiva'}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => editVariant(variant),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: variant.active ? 'Desactivar' : 'Activar',
                        onPressed: () => toggle(variant),
                        icon: Icon(
                          variant.active
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: () => editVariant(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva variante'),
        ),
      ],
    );
  }
}
