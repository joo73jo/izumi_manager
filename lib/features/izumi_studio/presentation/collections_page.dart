import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../productos/data/products_repository.dart';
import '../../productos/domain/izumi_product.dart';
import '../data/collections_repository.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  static const green = Color(0xFF284426);

  late final AppDatabase db;
  late final CollectionsRepository repository;
  late Future<List<IzumiCollection>> collections;

  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    repository = CollectionsRepository(db);
    refresh();
    search.addListener(onSearch);
  }

  void onSearch() {
    if (mounted) setState(() {});
  }

  void refresh() {
    setState(() {
      collections = repository.all();
    });
  }

  @override
  void dispose() {
    search.removeListener(onSearch);
    search.dispose();
    db.close();
    super.dispose();
  }

  void showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$error')));
  }

  Future<void> edit([IzumiCollection? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    final concept = TextEditingController(text: item?.concept ?? '');

    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Nueva colección' : 'Editar colección'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de colección',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: concept,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Concepto de diseño',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, (
                name.text.trim(),
                description.text.trim(),
                concept.text.trim(),
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    try {
      await repository.save(
        id: item?.id,
        name: result.$1,
        description: result.$2,
        concept: result.$3,
      );
      if (mounted) refresh();
    } catch (error) {
      showError(error);
    }
  }

  Future<void> remove(IzumiCollection item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar colección'),
        content: Text('¿Eliminar "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repository.delete(item.id);
      if (mounted) refresh();
    } catch (error) {
      showError(error);
    }
  }

  Widget productImage(IzumiProduct product) {
    final path = product.imagePath;

    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return const Icon(Icons.local_florist_outlined, color: green, size: 32);
    }

    return Image.file(
      File(path),
      width: 65,
      height: 65,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.local_florist_outlined, color: green),
    );
  }

  Future<void> details(IzumiCollection item) async {
    try {
      final products = await ProductsRepository(db).getAll();

      final related = products.where((product) {
        return product.collection.trim().toLowerCase() ==
            item.name.trim().toLowerCase();
      }).toList();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(item.name),
          content: SizedBox(
            width: 650,
            height: 470,
            child: ListView(
              children: [
                const Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold, color: green),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description.isEmpty
                      ? 'Sin descripción.'
                      : item.description,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Concepto de diseño',
                  style: TextStyle(fontWeight: FontWeight.bold, color: green),
                ),
                const SizedBox(height: 6),
                Text(
                  item.concept.isEmpty
                      ? 'Sin concepto registrado.'
                      : item.concept,
                ),
                const Divider(height: 32),
                Text(
                  'Macetas de la colección (${related.length})',
                  style: const TextStyle(
                    color: green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (related.isEmpty)
                  const Text(
                    'Todavía no hay macetas asignadas a esta colección.',
                  ),
                for (final product in related)
                  Card(
                    child: ListTile(
                      leading: SizedBox(
                        width: 65,
                        height: 65,
                        child: productImage(product),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '\$${(product.priceCents / 100).toStringAsFixed(2)}'
                        ' | ${product.active ? 'Activo' : 'Inactivo'}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                edit(item);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          ],
        ),
      );
    } catch (error) {
      showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<IzumiCollection>>(
      future: collections,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SelectableText('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final query = search.text.trim().toLowerCase();
        final items = snapshot.data!.where((item) {
          return item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              item.concept.toLowerCase().contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Colecciones',
                    style: TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva colección'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Organiza las familias de diseños de Izumi.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar colecciones...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty
                            ? 'Todavía no existen colecciones.'
                            : 'No se encontraron colecciones.',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 780
                            ? 3
                            : constraints.maxWidth >= 480
                            ? 2
                            : 1;

                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                mainAxisExtent: 230,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return Card(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () => details(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.collections_bookmark_outlined,
                                        color: green,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: green,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: Text(
                                          item.description.isEmpty
                                              ? 'Sin descripción'
                                              : item.description,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            tooltip: 'Editar',
                                            onPressed: () => edit(item),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar',
                                            onPressed: () => remove(item),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
