import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../data/production_cost_repository.dart';
import '../../data/production_cost_snapshot_repository.dart';

class ProductionDetailDialog extends StatefulWidget {
  const ProductionDetailDialog({super.key, required this.productionId});

  final int productionId;

  @override
  State<ProductionDetailDialog> createState() => _ProductionDetailDialogState();
}

class _ProductionDetailDialogState extends State<ProductionDetailDialog> {
  late final AppDatabase db;
  late final Future<_CostDetails> details;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    details = loadDetails();
  }

  Future<_CostDetails> loadDetails() async {
    final historical = await ProductionCostSnapshotRepository(db)
        .get(widget.productionId);

    final current = await ProductionCostRepository(db)
        .forProduction(widget.productionId);

    return _CostDetails(historical: historical, current: current);
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  String quantity(int millis) {
    return (millis / 1000)
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Producci\u00f3n #${widget.productionId}'),
      content: SizedBox(
        width: 620,
        height: 500,
        child: FutureBuilder<_CostDetails>(
          future: details,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SelectableText(
                'No se pudo cargar el detalle:\n${snapshot.error}',
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final historical = data.historical;
            final current = data.current;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Costo hist\u00f3rico de materiales',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),

                if (historical == null)
                  const Text(
                    'Esta fabricaci\u00f3n es anterior al '
                    'registro de costos hist\u00f3ricos.',
                  )
                else ...[
                  Text(
                    money(historical.knownCostCents),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (!historical.complete)
                    Text(
                      'Costo parcial: ${historical.missingPrices} '
                      'material(es) sin precio registrado.',
                    ),
                  const Text(
                    'Valor guardado al momento de fabricar.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],

                const Divider(height: 28),

                Text(
                  'Materiales utilizados',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: current.materials.isEmpty
                      ? const Center(
                          child: Text('No hay materiales registrados.'),
                        )
                      : ListView.separated(
                          itemCount: current.materials.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final material = current.materials[index];

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF284426),
                              ),
                              title: Text(material.name),
                              subtitle: Text(
                                'Cantidad: '
                                '${quantity(material.quantityMillis)} '
                                '${material.unit}\n'
                                'Desperdicio: '
                                '${material.wastePercent}%\n'
                                'Consumo: '
                                '${quantity(material.consumedMillis)} '
                                '${material.unit}',
                              ),
                              isThreeLine: true,
                              trailing: SizedBox(
                                width: 125,
                                child: Text(
                                  material.estimatedCostCents == null
                                      ? 'Sin precio'
                                      : money(material.estimatedCostCents!),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const Divider(height: 20),

                Text(
                  current.complete
                      ? 'Estimaci\u00f3n actual de materiales: '
                            '${money(current.knownCostCents)}'
                      : 'Estimaci\u00f3n parcial actual: '
                            '${money(current.knownCostCents)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!current.complete)
                  Text(
                    '${current.missingPrices} material(es) '
                    'sin precio de compra.',
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Los importes individuales anteriores son '
                  'estimaciones actuales. No corresponden '
                  'necesariamente al costo hist\u00f3rico. '
                  'No incluyen electricidad ni mano de obra.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _CostDetails {
  const _CostDetails({required this.historical, required this.current});

  final ProductionCostSnapshot? historical;
  final ProductionCostReport current;
}
