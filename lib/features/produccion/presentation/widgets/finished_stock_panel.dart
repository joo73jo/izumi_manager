import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../productos/data/product_variants_repository.dart';
import '../../data/production_repository.dart';

class FinishedStockPanel extends StatefulWidget {
  const FinishedStockPanel({super.key, required this.db});

  final AppDatabase db;

  @override
  State<FinishedStockPanel> createState() => _FinishedStockPanelState();
}

class _FinishedStockPanelState extends State<FinishedStockPanel> {
  late Future<List<_StockItem>> records;

  @override
  void initState() {
    super.initState();
    records = load();
  }

  Future<List<_StockItem>> load() async {
    await ProductVariantsRepository(widget.db).initialize();
    await ProductionRepository(widget.db).initialize();

    final rows = await widget.db.customSelect('''
      SELECT
        p.name AS product_name,
        v.name AS variant_name,
        COALESCE(s.quantity, 0) AS quantity,
        v.active AS variant_active
      FROM product_variants v
      JOIN izumi_products p ON p.id = v.product_id
      LEFT JOIN finished_stock s ON s.variant_id = v.id
      ORDER BY p.name COLLATE NOCASE,
               v.name COLLATE NOCASE
    ''').get();

    return rows.map((row) {
      return _StockItem(
        product: row.read<String>('product_name'),
        variant: row.read<String>('variant_name'),
        quantity: row.read<int>('quantity'),
        active: row.read<int>('variant_active') == 1,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_StockItem>>(
      future: records,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText('Error de stock: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        final total = items.fold<int>(0, (sum, item) => sum + item.quantity);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Macetas terminadas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text('$total unidades disponibles')),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Todav\u00eda no hay variantes registradas.'),
              )
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return ListTile(
                      dense: true,
                      title: Text('${item.product} - ${item.variant}'),
                      subtitle: item.active
                          ? null
                          : const Text('Variante inactiva'),
                      trailing: Chip(
                        label: Text('${item.quantity} unidades'),
                        avatar: Icon(
                          item.quantity == 0
                              ? Icons.warning_amber_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                      ),
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

class _StockItem {
  const _StockItem({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.active,
  });

  final String product;
  final String variant;
  final int quantity;
  final bool active;
}
