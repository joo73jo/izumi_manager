import 'dart:io';

import 'package:path/path.dart' as p;

import 'product_variants_dialog.dart';
import 'product_materials_dialog.dart';
import '../../data/product_folder_service.dart';

import 'package:flutter/material.dart';

import '../../domain/izumi_product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onToggle,
  });

  final IzumiProduct product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final price = (product.priceCents / 100).toStringAsFixed(2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductPhoto(productId: product.id, productName: product.name),
            const SizedBox(height: 14),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              product.collection.isEmpty
                  ? 'Sin colecci\u00f3n'
                  : product.collection,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              '\$$price',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF284426),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Chip(label: Text(product.active ? 'Activo' : 'Inactivo')),
                const Spacer(),
                IconButton(
                  tooltip: 'Abrir carpeta del producto',
                  icon: const Icon(Icons.folder_open_outlined),
                  onPressed: () async {
                    try {
                      await ProductFolderService().openFolder(
                        product.id,
                        product.name,
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$error')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Materiales de produccion',
                  icon: const Icon(Icons.science_outlined),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ProductMaterialsDialog(product: product),
                  ),
                ),
                IconButton(
                  tooltip: 'Variantes del producto',
                  icon: const Icon(Icons.palette_outlined),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ProductVariantsDialog(product: product),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: product.active ? 'Desactivar' : 'Activar',
                  onPressed: onToggle,
                  icon: Icon(
                    product.active
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({required this.productId, required this.productName});

  final int productId;
  final String productName;

  Future<File?> _findPhoto() async {
    final folder = await ProductFolderService().getFolder(
      productId,
      productName,
    );

    final photos = Directory(p.join(folder.path, 'Fotografias'));

    if (!await photos.exists()) return null;

    final files = await photos
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) {
          final extension = p.extension(file.path).toLowerCase();
          return ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
        })
        .toList();

    if (files.isEmpty) return null;

    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );

    return files.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _findPhoto(),
      builder: (context, snapshot) {
        return Container(
          height: 110,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EFE8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: snapshot.hasData && snapshot.data != null
              ? Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(),
                )
              : _placeholder(),
        );
      },
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.local_florist_outlined,
        color: Color(0xFF284426),
        size: 40,
      ),
    );
  }
}
