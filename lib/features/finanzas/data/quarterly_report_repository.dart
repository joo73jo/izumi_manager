import 'package:drift/drift.dart' show Variable;

import '../../../core/database/app_database.dart';

class QuarterlyFinancialReport {
  const QuarterlyFinancialReport({
    required this.year,
    required this.quarter,
    required this.salesCents,
    required this.materialCostsCents,
    required this.operatingExpensesCents,
    required this.otherIncomeCents,
    required this.otherExpensesCents,
    required this.unvaluedSales,
  });

  final int year;
  final int quarter;
  final int salesCents;
  final int materialCostsCents;
  final int operatingExpensesCents;
  final int otherIncomeCents;
  final int otherExpensesCents;
  final int unvaluedSales;

  // Utilidad de las macetas antes de gastos del fondo.
  int get productionProfitCents => salesCents - materialCostsCents;

  // Resultado contable informativo, separado del reparto.
  int get netResultCents =>
      productionProfitCents +
      otherIncomeCents -
      operatingExpensesCents -
      otherExpensesCents;

  bool get hasValuationWarnings => unvaluedSales > 0;

  // No proponer reparto con ventas pendientes de valorar.
  int get distributableBaseCents =>
      hasValuationWarnings || productionProfitCents <= 0
      ? 0
      : productionProfitCents;

  int get reinvestmentCents => distributableBaseCents ~/ 2;

  int get partnersCents => distributableBaseCents - reinvestmentCents;

  int get paulCents => partnersCents * 35 ~/ 100;

  int get joelCents => partnersCents - paulCents;
}

class QuarterlyReportRepository {
  QuarterlyReportRepository(this.db);

  final AppDatabase db;

  Future<bool> tableExists(String name) async {
    final rows = await db
        .customSelect(
          '''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name = ?
      ''',
          variables: [Variable.withString(name)],
        )
        .get();

    return rows.isNotEmpty;
  }

  Future<QuarterlyFinancialReport> getReport({
    required int year,
    required int quarter,
  }) async {
    if (quarter < 1 || quarter > 4) {
      throw ArgumentError('Trimestre no valido.');
    }

    final start = DateTime(year, (quarter - 1) * 3 + 1);
    final end = DateTime(year, quarter * 3 + 1);

    final startSeconds = start.millisecondsSinceEpoch ~/ 1000;
    final endSeconds = end.millisecondsSinceEpoch ~/ 1000;

    final rows = await db
        .customSelect(
          '''
      SELECT
        a.code,
        COALESCE(SUM(jl.debit_cents), 0) AS debits,
        COALESCE(SUM(jl.credit_cents), 0) AS credits
      FROM journal_lines jl
      JOIN financial_accounts a ON a.id = jl.account_id
      JOIN journal_entries je ON je.id = jl.entry_id
      WHERE je.occurred_at >= ?
        AND je.occurred_at < ?
        AND (a.code LIKE '4%' OR a.code LIKE '5%')
      GROUP BY a.code
      ''',
          variables: [
            Variable.withInt(startSeconds),
            Variable.withInt(endSeconds),
          ],
        )
        .get();

    var sales = 0;
    var materialCosts = 0;
    var operating = 0;
    var otherIncome = 0;
    var otherExpenses = 0;

    for (final row in rows) {
      final code = row.read<String>('code');
      final debit = row.read<int>('debits');
      final credit = row.read<int>('credits');

      if (code == '4100') {
        sales += credit - debit;
      } else if (code == '5105') {
        materialCosts += debit - credit;
      } else if (code == '5100') {
        operating += debit - credit;
      } else if (code.startsWith('4')) {
        otherIncome += credit - debit;
      } else if (code.startsWith('5')) {
        otherExpenses += debit - credit;
      }
    }

    var unvalued = 0;

    if (await tableExists('izumi_sales')) {
      final missing = await db
          .customSelect(
            '''
        SELECT COUNT(*) AS total
        FROM izumi_sales s
        WHERE s.occurred_at >= ?
          AND s.occurred_at < ?
          AND NOT EXISTS (
            SELECT 1 FROM journal_entries je
            WHERE je.reference = 'COSTO-VENTA-' || s.id
          )
        ''',
            variables: [
              Variable.withInt(start.millisecondsSinceEpoch),
              Variable.withInt(end.millisecondsSinceEpoch),
            ],
          )
          .getSingle();

      unvalued = missing.read<int>('total');
    }

    return QuarterlyFinancialReport(
      year: year,
      quarter: quarter,
      salesCents: sales,
      materialCostsCents: materialCosts,
      operatingExpensesCents: operating,
      otherIncomeCents: otherIncome,
      otherExpensesCents: otherExpenses,
      unvaluedSales: unvalued,
    );
  }
}
