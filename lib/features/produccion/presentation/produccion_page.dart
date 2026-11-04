import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../productos/data/product_variants_repository.dart';
import '../data/production_repository.dart';
import '../domain/production_order.dart';
import 'widgets/finished_stock_panel.dart';
import 'widgets/production_detail_dialog.dart';
import 'widgets/production_dialog.dart';
import 'widgets/production_test_dialog.dart';

class ProduccionPage extends StatefulWidget {
  const ProduccionPage({super.key});

  @override
  State<ProduccionPage> createState() => _ProduccionPageState();
}

class _ProduccionPageState extends State<ProduccionPage> {
  late final AppDatabase db;
  late final ProductionRepository repository;
  late final ProductionTestRepository testRepository;

  late Future<List<ProductionRecord>> records;
  late Future<List<ProductionTestRecord>> tests;

  int stockVersion = 0;

  @override
  void initState() {
    super.initState();

    db = AppDatabase();
    repository = ProductionRepository(db);
    testRepository = ProductionTestRepository(db);

    records = loadRecords();
    tests = testRepository.getAll();
  }

  Future<List<ProductionRecord>> loadRecords() async {
    await ProductVariantsRepository(db).initialize();
    return repository.getAll();
  }

  void refresh() {
    setState(() {
      stockVersion++;
      records = loadRecords();
      tests = testRepository.getAll();
    });
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  Future<void> newProduction() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProductionDialog(),
    );

    if (created == true && mounted) {
      refresh();
    }
  }

  Future<void> newTest() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProductionTestDialog(),
    );

    if (created == true && mounted) {
      refresh();
    }
  }

  String dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Produccion',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 5),
                    const Text('Fabricacion, pruebas y existencias de macetas'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: newTest,
                icon: const Icon(Icons.science_outlined),
                label: const Text('Registrar prueba'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: newProduction,
                icon: const Icon(Icons.add),
                label: const Text('Nueva produccion'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FinishedStockPanel(key: ValueKey(stockVersion), db: db),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                Text(
                  'Historial de fabricacion',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ProductionRecord>>(
                  future: records,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SelectableText(
                        'Error al cargar producciones:\n${snapshot.error}',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data!;

                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Todavia no hay macetas fabricadas.'),
                      );
                    }

                    return Column(
                      children: [
                        for (final item in items)
                          Card(
                            child: ListTile(
                              onTap: () => showDialog<void>(
                                context: context,
                                builder: (_) => ProductionDetailDialog(
                                  productionId: item.id,
                                ),
                              ),
                              leading: const CircleAvatar(
                                child: Icon(
                                  Icons.precision_manufacturing_outlined,
                                ),
                              ),
                              title: Text(
                                '${item.productName} - ${item.variantName}',
                              ),
                              subtitle: Text(
                                'Produccion #${item.id} | '
                                '${dateText(item.createdAt)}'
                                '${item.notes.isEmpty ? '' : '\n${item.notes}'}',
                              ),
                              isThreeLine: item.notes.isNotEmpty,
                              trailing: const Chip(label: Text('1 unidad')),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Historial de pruebas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ProductionTestRecord>>(
                  future: tests,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SelectableText(
                        'Error al cargar pruebas:\n${snapshot.error}',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data!;

                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Todavia no hay pruebas registradas.'),
                      );
                    }

                    return Column(
                      children: [
                        for (final item in items)
                          Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.science_outlined),
                              ),
                              title: Text('Prueba #${item.id}'),
                              subtitle: Text(
                                '${dateText(item.createdAt)}\n'
                                '${item.materials}'
                                '${item.notes.isEmpty ? '' : '\n${item.notes}'}',
                              ),
                              isThreeLine: true,
                              trailing: const Chip(label: Text('Prueba')),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
