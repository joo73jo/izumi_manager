import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class SaleProfitSummaryDialog extends StatefulWidget {
  const SaleProfitSummaryDialog({super.key});

  @override
  State<SaleProfitSummaryDialog> createState() =>
      _SaleProfitSummaryDialogState();
}

class _SaleProfitSummaryDialogState extends State<SaleProfitSummaryDialog> {
  late final AppDatabase db;
  late final Future<_SalesSummary> summary;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    summary = load();
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  Future<_SalesSummary> load() async {
    final tables = await db.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table'
        AND name IN (
          'izumi_sales',
          'finished_stock_sales',
          'finished_sale_productions'
        )
    ''').get();

    if (tables.length < 3) {
      return const _SalesSummary([], 0);
    }

    final rows = await db.customSelect('''
      SELECT
        s.id,
        s.description,
        s.occurred_at,
        s.revenue_cents,
        link.material_cost_cents,
        CASE
          WHEN link.production_id IS NOT NULL
          THEN 1 ELSE 0
        END AS valued
      FROM finished_stock_sales fs
      JOIN izumi_sales s ON s.id = fs.sale_id
      LEFT JOIN finished_sale_productions link
        ON link.sale_id = s.id
      ORDER BY s.occurred_at DESC, s.id DESC
    ''').get();

    final sales = <_SaleProfit>[];
    var pending = 0;

    for (final row in rows) {
      final valued = row.read<int>('valued') == 1;
      final cost = row.readNullable<int>('material_cost_cents');

      if (!valued || cost == null) pending++;

      sales.add(
        _SaleProfit(
          id: row.read<int>('id'),
          description: row.read<String>('description'),
          date: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('occurred_at'),
          ),
          revenueCents: row.read<int>('revenue_cents'),
          costCents: valued ? cost : null,
        ),
      );
    }

    return _SalesSummary(sales, pending);
  }

  String money(int cents) {
    final value = cents.abs();
    final sign = cents < 0 ? '-' : '';
    return '$sign\$${value ~/ 100}.'
        '${(value % 100).toString().padLeft(2, '0')}';
  }

  Widget amount(String label, int cents) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            money(cents),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganancias por maceta vendida'),
      content: SizedBox(
        width: 610,
        height: 520,
        child: FutureBuilder<_SalesSummary>(
          future: summary,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SelectableText('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = snapshot.data!;

            if (result.sales.isEmpty) {
              return const Center(
                child: Text(
                  'Todav\u00eda no hay ventas vinculadas '
                  'al stock de macetas terminadas.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView(
              children: [
                if (result.pending > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${result.pending} venta(s) sin costo '
                      'hist\u00f3rico vinculado. No se '
                      'calcular\u00e1 reparto para ellas.',
                      style: const TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                for (final sale in result.sales)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Venta #${sale.id} - '
                            '${sale.date.day}/${sale.date.month}/'
                            '${sale.date.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          amount('Precio de venta', sale.revenueCents),
                          if (sale.costCents == null)
                            const Text(
                              'Costo pendiente de valorar.',
                              style: TextStyle(color: Colors.deepOrange),
                            )
                          else ...[
                            amount('Costo de materiales', -sale.costCents!),
                            const Divider(),
                            amount('Utilidad', sale.profitCents!),
                            amount('Fondo (50%)', sale.fundCents!),
                            amount('Joel', sale.joelCents!),
                            amount('Paul', sale.paulCents!),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Desglose comercial informativo. '
                  'No registra pagos, no descuenta '
                  'nuevamente gastos y no autoriza '
                  'distribuciones.',
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

class _SalesSummary {
  const _SalesSummary(this.sales, this.pending);

  final List<_SaleProfit> sales;
  final int pending;
}

class _SaleProfit {
  const _SaleProfit({
    required this.id,
    required this.description,
    required this.date,
    required this.revenueCents,
    required this.costCents,
  });

  final int id;
  final String description;
  final DateTime date;
  final int revenueCents;
  final int? costCents;

  int? get profitCents => costCents == null ? null : revenueCents - costCents!;

  int? get fundCents {
    final profit = profitCents;
    if (profit == null) return null;
    return (profit > 0 ? profit : 0) ~/ 2;
  }

  int? get partnersCents {
    final profit = profitCents;
    if (profit == null) return null;
    return (profit > 0 ? profit : 0) - fundCents!;
  }

  int? get paulCents =>
      partnersCents == null ? null : partnersCents! * 35 ~/ 100;

  int? get joelCents =>
      partnersCents == null ? null : partnersCents! - paulCents!;
}
