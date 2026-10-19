import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../data/sales_repository.dart';
import '../domain/sale.dart';
import 'widgets/sale_dialog.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  late final AppDatabase database;
  late final SalesRepository repository;
  late Future<List<SaleRecord>> sales;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    database = AppDatabase();
    repository = SalesRepository(database);
    sales = repository.getAll();
  }

  @override
  void dispose() {
    database.close();
    super.dispose();
  }

  void refresh() {
    setState(() => sales = repository.getAll());
  }

  String money(int cents) {
    final absolute = cents.abs();
    final sign = cents < 0 ? '-' : '';

    return '$sign\$${absolute ~/ 100}.'
        '${(absolute % 100).toString().padLeft(2, '0')}';
  }

  String date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> addSale() async {
    if (saving) return;

    final draft = await showDialog<SaleDraft>(
      context: context,
      builder: (_) => const SaleDialog(),
    );

    if (draft == null || !mounted || saving) return;

    setState(() => saving = true);

    try {
      await repository.register(draft);

      if (!mounted) return;

      refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget metric(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF284426)),
              const SizedBox(height: 10),
              Text(label),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF284426),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SaleRecord>>(
      future: sales,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: SelectableText('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!;

        final revenue = records.fold<int>(
          0,
          (total, sale) => total + sale.revenueCents,
        );

        final estimatedProfit = records.fold<int>(
          0,
          (total, sale) => total + sale.estimatedGrossProfitCents,
        );

        return ListView(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pedidos y ventas',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF284426),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : addSale,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva venta'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Registro de ventas cobradas y sus canales.'),
            const SizedBox(height: 20),
            Row(
              children: [
                metric(
                  'Ingresos registrados',
                  money(revenue),
                  Icons.payments_outlined,
                ),
                metric(
                  'Ventas',
                  '${records.length}',
                  Icons.receipt_long_outlined,
                ),
                metric(
                  'Ganancia estimada',
                  money(estimatedProfit),
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Historial de ventas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todav\u00eda no existen ventas registradas.'),
                ),
              )
            else
              ...records.map(
                (sale) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF284426),
                    ),
                    title: Text(sale.description),
                    subtitle: Text(
                      '${date(sale.date)}  |  ${sale.channel.label}'
                      '${sale.customerName.isEmpty ? '' : '  |  ${sale.customerName}'}',
                    ),
                    trailing: Text(
                      money(sale.revenueCents),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF284426),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'La ganancia mostrada es estimada. '
              'Todav\u00eda no representa la utilidad neta '
              'distribuible entre socios.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        );
      },
    );
  }
}
