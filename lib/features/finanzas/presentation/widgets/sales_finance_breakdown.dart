import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class SalesFinanceBreakdown extends StatefulWidget {
  const SalesFinanceBreakdown({super.key});

  @override
  State<SalesFinanceBreakdown> createState() => _SalesFinanceBreakdownState();
}

class _SalesFinanceBreakdownState extends State<SalesFinanceBreakdown> {
  late final AppDatabase db;
  late Future<List<_SaleFinancialRow>> future;

  bool allTime = true;
  int selectedYear = DateTime.now().year;
  int selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;

  static const green = Color(0xFF284426);

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    future = loadSales();
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  Future<List<_SaleFinancialRow>> loadSales() async {
    final rows = await db.customSelect('''
      SELECT
        s.id,
        s.occurred_at,
        s.description,
        s.revenue_cents,
        CASE
          WHEN fs.sale_id IS NOT NULL
          THEN fp.material_cost_cents
          ELSE s.estimated_cost_cents
        END AS cost_cents
      FROM izumi_sales s
      LEFT JOIN finished_stock_sales fs
        ON fs.sale_id = s.id
      LEFT JOIN finished_sale_productions fp
        ON fp.sale_id = s.id
      ORDER BY s.occurred_at DESC, s.id DESC
    ''').get();

    return rows.map((row) {
      return _SaleFinancialRow(
        date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('occurred_at')),
        revenue: row.read<int>('revenue_cents'),
        cost: row.readNullable<int>('cost_cents'),
      );
    }).toList();
  }

  String money(int cents) {
    final sign = cents < 0 ? '-' : '';
    final value = cents.abs();
    return '$sign\$${value ~/ 100}.'
        '${(value % 100).toString().padLeft(2, '0')}';
  }

  String percent(int part, int total) {
    if (total == 0) return '0.0%';
    return '${(part / total * 100).toStringAsFixed(1)}%';
  }

  Widget amountRow(String name, int amount, {bool prominent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: prominent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            money(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: prominent ? 19 : 14,
              color: prominent ? green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget card(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFE5DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFE5DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_SaleFinancialRow>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SelectableText(
            'No se pudo calcular la contabilidad: ${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sales = snapshot.data!;

        final filtered = sales.where((sale) {
          if (allTime) return true;

          final quarter = ((sale.date.month - 1) ~/ 3) + 1;

          return sale.date.year == selectedYear && quarter == selectedQuarter;
        }).toList();

        final revenue = filtered.fold<int>(
          0,
          (sum, sale) => sum + sale.revenue,
        );

        final valued = filtered.where((sale) => sale.cost != null).toList();

        final pending = filtered.length - valued.length;

        final cost = valued.fold<int>(0, (sum, sale) => sum + sale.cost!);

        final valuedRevenue = valued.fold<int>(
          0,
          (sum, sale) => sum + sale.revenue,
        );

        final grossProfit = valuedRevenue - cost;

        // No distribuimos utilidades sobre perdidas.
        final availableProfit = grossProfit > 0 ? grossProfit : 0;

        // El centavo impar queda reservado para Izumi.
        final distributable = availableProfit ~/ 2;
        final reinvestment = availableProfit - distributable;

        final paul = distributable * 35 ~/ 100;
        final joel = distributable - paul;

        final costPercent = percent(cost, valuedRevenue);
        final marginPercent = percent(grossProfit, valuedRevenue);

        final years = <int>{
          DateTime.now().year,
          ...sales.map((sale) => sale.date.year),
        }.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Contabilidad de ventas',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ingresos, materiales y distribucion de utilidades.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Todo el historial'),
                  selected: allTime,
                  onSelected: (_) {
                    setState(() => allTime = true);
                  },
                ),
                ChoiceChip(
                  label: const Text('Por trimestre'),
                  selected: !allTime,
                  onSelected: (_) {
                    setState(() => allTime = false);
                  },
                ),
                if (!allTime)
                  DropdownButton<int>(
                    value: selectedYear,
                    items: years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedYear = value);
                      }
                    },
                  ),
                if (!allTime)
                  DropdownButton<int>(
                    value: selectedQuarter,
                    items: List.generate(4, (index) {
                      final quarter = index + 1;
                      return DropdownMenuItem(
                        value: quarter,
                        child: Text('Trimestre $quarter'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedQuarter = value);
                      }
                    },
                  ),
              ],
            ),

            const SizedBox(height: 18),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 650 ? 3 : 1;

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: columns == 3 ? 1.45 : 3.1,
                  children: [
                    card(
                      'Ventas totales',
                      money(revenue),
                      '${filtered.length} ventas registradas',
                      Icons.point_of_sale,
                    ),
                    card(
                      'Costo de materiales',
                      money(cost),
                      '$costPercent de ventas valoradas',
                      Icons.inventory_2_outlined,
                    ),
                    card(
                      'Utilidad bruta valorada',
                      money(grossProfit),
                      '$marginPercent de margen bruto',
                      Icons.trending_up,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            section('Resultado comercial', [
              amountRow('Ventas cobradas', revenue),
              amountRow('Ventas con costo identificado', valuedRevenue),
              amountRow('Costo de materiales', -cost),
              const Divider(),
              amountRow(
                'Utilidad bruta identificada',
                grossProfit,
                prominent: true,
              ),
              if (pending > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '$pending venta(s) sin costo historico '
                    'identificado. Sus ingresos estan '
                    'incluidos en ventas totales, pero '
                    'no generan reparto hasta valorarse.',
                    style: const TextStyle(color: Colors.deepOrange),
                  ),
                ),
            ]),

            const SizedBox(height: 16),

            section('Distribucion de la utilidad', [
              amountRow('Reinversion Izumi (50%)', reinvestment),
              amountRow(
                'Utilidad distribuible (50%)',
                distributable,
                prominent: true,
              ),
              const Divider(),
              amountRow('Joel - 65% del distribuible', joel),
              amountRow('Paul - 35% del distribuible', paul),
              const SizedBox(height: 12),
              const Text(
                'Estos importes representan participaciones '
                'calculadas, no pagos realizados. '
                'Permanecen dentro del saldo bancario '
                'hasta registrar su salida mediante '
                'Registrar movimientos. El reparto '
                'se revisa trimestralmente.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ]),

            const SizedBox(height: 14),

            const Text(
              'Los materiales son costos comerciales. '
              'No se descuentan nuevamente del banco. '
              'Las compras, gastos y retiros reales '
              'se contabilizan mediante sus movimientos.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        );
      },
    );
  }
}

class _SaleFinancialRow {
  const _SaleFinancialRow({
    required this.date,
    required this.revenue,
    required this.cost,
  });

  final DateTime date;
  final int revenue;
  final int? cost;
}
