import '../../ventas/presentation/widgets/sale_profit_summary_dialog.dart';

import 'package:flutter/material.dart';

import '../../ventas/presentation/ventas_page.dart';
import '../../ventas/presentation/widgets/finished_stock_sale_dialog.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  int salesVersion = 0;

  Future<void> sellFinishedProduct() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FinishedStockSaleDialog(),
    );

    if (saved == true && mounted) {
      setState(() => salesVersion++);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta registrada y stock actualizado correctamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const SaleProfitSummaryDialog(),
                  ),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Ganancias por venta'),
                ),
                FilledButton.icon(
                  onPressed: sellFinishedProduct,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Vender maceta del stock'),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: VentasPage(key: ValueKey(salesVersion))),
      ],
    );
  }
}
