import 'package:flutter/material.dart';

import '../../data/inventory_history_repository.dart';
import '../../domain/inventory_history.dart';
import '../../domain/inventory_item.dart';

class InventoryHistoryDialog extends StatelessWidget {
  const InventoryHistoryDialog({
    super.key,
    required this.item,
    required this.repository,
  });

  final InventoryItem item;
  final InventoryHistoryRepository repository;

  String money(int cents) {
    final sign = cents < 0 ? '-' : '';
    final absolute = cents.abs();
    return '$sign\$${absolute ~/ 100}.'
        '${(absolute % 100).toString().padLeft(2, '0')}';
  }

  String date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String quantity(int millis) {
    final result = millis / 1000;
    return result
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Historial: ${item.name}'),
      content: SizedBox(
        width: 620,
        height: 470,
        child: FutureBuilder<InventoryHistory>(
          future: repository.load(item.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SelectableText('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final history = snapshot.data!;

            return DefaultTabController(
              length: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Existencia actual: '
                    '${quantity(item.quantityMillis)} ${item.unit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF284426),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (history.averagePurchaseCost != null)
                    Text(
                      'Costo promedio de compra: '
                      '\$${history.averagePurchaseCost!.toStringAsFixed(4)}'
                      ' por ${item.unit}',
                    ),
                  const SizedBox(height: 12),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Movimientos'),
                      Tab(text: 'Compras'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        history.movements.isEmpty
                            ? const Center(child: Text('Sin movimientos'))
                            : ListView.builder(
                                itemCount: history.movements.length,
                                itemBuilder: (context, index) {
                                  final movement = history.movements[index];

                                  return ListTile(
                                    title: Text(movement.reason),
                                    subtitle: Text(date(movement.date)),
                                    trailing: Text(
                                      '${movement.quantityMillis > 0 ? '+' : ''}'
                                      '${quantity(movement.quantityMillis)}'
                                      ' ${item.unit}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                        history.purchases.isEmpty
                            ? const Center(
                                child: Text('Sin compras registradas'),
                              )
                            : ListView.builder(
                                itemCount: history.purchases.length,
                                itemBuilder: (context, index) {
                                  final purchase = history.purchases[index];

                                  return ListTile(
                                    title: Text(
                                      '${quantity(purchase.quantityMillis)}'
                                      ' ${item.unit}',
                                    ),
                                    subtitle: Text(date(purchase.date)),
                                    trailing: Text(
                                      money(purchase.totalCents),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
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
