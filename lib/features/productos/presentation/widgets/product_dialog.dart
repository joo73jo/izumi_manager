import 'package:flutter/material.dart';

import '../../domain/izumi_product.dart';

class ProductDialog extends StatefulWidget {
  const ProductDialog({super.key, this.product});

  final IzumiProduct? product;

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final collection = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();

  @override
  void initState() {
    super.initState();

    final product = widget.product;
    if (product != null) {
      name.text = product.name;
      collection.text = product.collection;
      description.text = product.description;
      price.text = (product.priceCents / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    name.dispose();
    collection.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  int? parsePrice(String text) {
    final value = text.trim().replaceAll(',', '.');

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

  void save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      ProductDraft(
        name: name.text.trim(),
        collection: collection.text.trim(),
        description: description.text.trim(),
        priceCents: parsePrice(price.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? 'Nuevo producto' : 'Editar producto',
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej. Maceta Sakura',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: collection,
                  decoration: const InputDecoration(
                    labelText: 'Colecci\u00f3n',
                    hintText: 'Ej. Minimalista',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: price,
                  decoration: const InputDecoration(
                    labelText: 'Precio de venta',
                    prefixText: r'$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => parsePrice(value ?? '') == null
                      ? 'Precio inv\u00e1lido'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripci\u00f3n',
                    border: OutlineInputBorder(),
                  ),
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
