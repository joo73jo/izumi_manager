import 'package:flutter/material.dart';

import '../../domain/capital_overview.dart';

class CapitalOverviewCard extends StatelessWidget {
  const CapitalOverviewCard({super.key, required this.data});

  final CapitalOverview data;

  String money(int cents) {
    final absolute = cents.abs();
    final sign = cents < 0 ? '-' : '';
    return '$sign\$${absolute ~/ 100}.'
        '${(absolute % 100).toString().padLeft(2, '0')}';
  }

  Widget detail(String title, int cents) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Situaci\u00f3n del capital',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF284426),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Saldos contables y gastos acumulados.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            detail('Capital aportado por Paul', data.contributionCents),
            detail('Saldo de Banco Izumi', data.bankCents),
            const Divider(),
            detail('Inventario contable', data.inventoryCents),
            detail('Maquinaria y equipos', data.equipmentCents),
            detail('Gastos operativos acumulados', data.expensesCents),
            const SizedBox(height: 10),
            const Text(
              'Estos importes representan saldos de cuentas. '
              'No equivalen necesariamente al destino exclusivo '
              'del aporte de Paul ni a la utilidad distribuible. '
              'El inventario puede requerir ajustes de valoraci\u00f3n.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
