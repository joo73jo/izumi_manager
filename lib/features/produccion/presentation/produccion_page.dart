import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../productos/data/product_variants_repository.dart';
import '../data/production_repository.dart';
import '../domain/production_order.dart';
import 'widgets/finished_stock_panel.dart';
import 'widgets/production_detail_dialog.dart';
import 'widgets/production_dialog.dart';

class ProduccionPage extends StatefulWidget {
  const ProduccionPage({super.key});

  @override
  State<ProduccionPage> createState() => _ProduccionPageState();
}

class _ProduccionPageState extends State<ProduccionPage> {
  late final AppDatabase db;
  late final ProductionRepository repository;
  late Future<List<ProductionRecord>> records;

  int stockVersion = 0;

  @override
  void initState() {
    super.initState();

    db = AppDatabase();
    repository = ProductionRepository(db);
    records = loadRecords();
  }

  Future<List<ProductionRecord>> loadRecords() async {
    await ProductVariantsRepository(db).initialize();
    return repository.getAll();
  }

  void refresh() {
    setState(() {
      stockVersion++;
      records = loadRecords();
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
                      'Producci\u00f3n',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 5),
                    const Text('Fabricaci\u00f3n y existencias de macetas'),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: newProduction,
                icon: const Icon(Icons.add),
                label: const Text('Nueva producci\u00f3n'),
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

          Text(
            'Historial de fabricaci\u00f3n',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Expanded(
            child: FutureBuilder<List<ProductionRecord>>(
              future: records,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: SelectableText(
                      'Error al cargar producciones:\n${snapshot.error}',
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Todav\u00eda no hay macetas fabricadas.'),
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      child: ListTile(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              ProductionDetailDialog(productionId: item.id),
                        ),
                        leading: const CircleAvatar(
                          child: Icon(Icons.precision_manufacturing_outlined),
                        ),
                        title: Text(
                          '${item.productName} - ${item.variantName}',
                        ),
                        subtitle: Text(
                          'Producci\u00f3n #${item.id} | '
                          '${dateText(item.createdAt)}'
                          '${item.notes.isEmpty ? '' : '\n${item.notes}'}',
                        ),
                        isThreeLine: item.notes.isNotEmpty,
                        trailing: const Chip(label: Text('1 unidad')),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
