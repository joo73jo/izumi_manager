import 'package:flutter/material.dart';

import '../../data/quarterly_report_repository.dart';

class QuarterlyFundPanel extends StatelessWidget {
  const QuarterlyFundPanel({super.key, required this.report});

  final QuarterlyFinancialReport report;

  String money(int cents) {
    final sign = cents < 0 ? '-' : '';
    final value = cents.abs();
    final integer = value ~/ 100;
    final decimals = (value % 100).toString().padLeft(2, '0');

    return '$sign\$$integer.$decimals';
  }

  Widget line(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = report.operatingExpensesCents + report.otherExpensesCents;

    final reserve = report.reinvestmentCents;
    final balance = reserve - expenses;

    return Card(
      color: const Color(0xFFEAF0E5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fondo de gastos y reinversi\u00f3n',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (report.hasValuationWarnings) ...[
              const Text(
                'Fondo pendiente de calcular: existen ventas '
                'sin costo de materiales contabilizado.',
              ),
              const SizedBox(height: 8),
              line('Gastos registrados', money(expenses)),
            ] else ...[
              line('50% reservado', money(reserve)),
              line('Gastos operativos y otros gastos', money(expenses)),
              const Divider(),
              line('Saldo del trimestre', money(balance)),
            ],
            const SizedBox(height: 8),
            const Text(
              'Control informativo del trimestre. '
              'No representa una cuenta bancaria separada. '
              'Los gastos registrados no se descuentan '
              'nuevamente de la utilidad para el reparto.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
