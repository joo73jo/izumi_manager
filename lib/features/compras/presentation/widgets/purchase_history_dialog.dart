import 'purchase_receipts_section.dart';
import '../../data/purchase_receipt_repository.dart';

import 'package:flutter/material.dart';

import '../../data/purchase_history_repository.dart';
import '../../domain/purchase_history_record.dart';

class PurchaseHistoryDialog extends StatelessWidget {
  const PurchaseHistoryDialog({super.key, required this.repository});

  final PurchaseHistoryRepository repository;

  String money(int cents) {
    final absolute = cents.abs();
    final sign = cents < 0 ? '-' : '';
    return '$sign\$${absolute ~/ 100}.'
        '${(absolute % 100).toString().padLeft(2, '0')}';
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String quantity(int millis) {
    return (millis / 1000)
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Widget purchaseTile(PurchaseHistoryRecord purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(
          Icons.receipt_long_outlined,
          color: Color(0xFF284426),
        ),
        title: Text(purchase.description),
        subtitle: Text(
          '${formatDate(purchase.date)}'
          '  |  ${purchase.lines.length} materiales',
        ),
        trailing: Text(
          money(purchase.totalCents),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF284426),
          ),
        ),
        children: [
          for (final line in purchase.lines)
            ListTile(
              dense: true,
              title: Text(line.name),
              subtitle: Text('${quantity(line.quantityMillis)} ${line.unit}'),
              trailing: Text(money(line.totalCents)),
            ),
          PurchaseReceiptsSection(
            purchaseId: purchase.id,
            repository: PurchaseReceiptRepository(repository.db),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Compra #${purchase.id}  |  '
                  'Total: ${money(purchase.totalCents)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Historial de compras',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF284426),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Compras registradas en el sistema.'),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<PurchaseHistoryRecord>>(
                  future: repository.getAll(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: SelectableText('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final purchases = snapshot.data!;

                    if (purchases.isEmpty) {
                      return const Center(
                        child: Text(
                          'No existen compras unificadas registradas.',
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        return purchaseTile(purchases[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
