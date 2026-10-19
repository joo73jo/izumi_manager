import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/app_database.dart';
import 'quarterly_report_repository.dart';

class QuarterlyPdfService {
  QuarterlyPdfService(this.db);

  final AppDatabase db;

  static const reportFolder = r'D:\izumi_app\Izumi_Datos\Reportes';

  final green = PdfColor.fromHex('#284426');
  final lightGreen = PdfColor.fromHex('#EAF0E5');

  String money(int cents) {
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();
    final whole = abs ~/ 100;
    final decimal = (abs % 100).toString().padLeft(2, '0');
    return '$sign\$$whole.$decimal';
  }

  pw.Widget heading(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 15, bottom: 8),
    child: pw.Text(
      value,
      style: pw.TextStyle(
        color: green,
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );

  pw.Widget amount(String label, int cents) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(child: pw.Text(label)),
        pw.Text(
          money(cents),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  pw.Widget note(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
  );

  Future<int> bankBalanceBefore(int timestampSeconds) async {
    final result = await db
        .customSelect(
          '''
      SELECT
        COALESCE(SUM(jl.debit_cents - jl.credit_cents), 0)
          AS balance
      FROM journal_lines jl
      JOIN financial_accounts a ON a.id = jl.account_id
      JOIN journal_entries je ON je.id = jl.entry_id
      WHERE a.code = '1100'
        AND je.occurred_at < ?
      ''',
          variables: [Variable.withInt(timestampSeconds)],
        )
        .getSingle();

    return result.read<int>('balance');
  }

  Future<List<(String, int)>> movements({
    required int startSeconds,
    required int endSeconds,
  }) async {
    final rows = await db
        .customSelect(
          '''
      SELECT
        je.occurred_at,
        je.description,
        SUM(jl.debit_cents - jl.credit_cents) AS movement
      FROM journal_entries je
      JOIN journal_lines jl ON jl.entry_id = je.id
      JOIN financial_accounts a ON a.id = jl.account_id
      WHERE a.code = '1100'
        AND je.occurred_at >= ?
        AND je.occurred_at < ?
      GROUP BY je.id
      ORDER BY je.occurred_at, je.id
      ''',
          variables: [
            Variable.withInt(startSeconds),
            Variable.withInt(endSeconds),
          ],
        )
        .get();

    return rows.map((row) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('occurred_at') * 1000,
      );
      final dateText =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
      return (
        '$dateText - ${row.read<String>('description')}',
        row.read<int>('movement'),
      );
    }).toList();
  }

  Future<File> generate({required int year, required int quarter}) async {
    final report = await QuarterlyReportRepository(db)
        .getReport(year: year, quarter: quarter);

    final start = DateTime(year, (quarter - 1) * 3 + 1);
    final end = DateTime(year, quarter * 3 + 1);
    final startSeconds = start.millisecondsSinceEpoch ~/ 1000;
    final endSeconds = end.millisecondsSinceEpoch ~/ 1000;

    final openingBalance = await bankBalanceBefore(startSeconds);
    final closingBalance = await bankBalanceBefore(endSeconds);
    final bankMovements = await movements(
      startSeconds: startSeconds,
      endSeconds: endSeconds,
    );

    final document = pw.Document(
      title: 'IZUMI - Reporte trimestral $year T$quarter',
      author: 'Izumi',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: green, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'IZUMI',
                style: pw.TextStyle(
                  fontSize: 23,
                  fontWeight: pw.FontWeight.bold,
                  color: green,
                ),
              ),
              pw.Text('REPORTE FINANCIERO TRIMESTRAL'),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Documento interno - No constituye aprobacion de pagos',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 14),
          pw.Text(
            'Periodo: trimestre $quarter de $year',
            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Generado: ${DateTime.now().day}/'
            '${DateTime.now().month}/${DateTime.now().year}',
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            color: lightGreen,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resultado contable informativo',
                  style: pw.TextStyle(
                    color: green,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  money(report.netResultCents),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          heading('1. Resultados del trimestre'),
          amount('Ingresos por ventas', report.salesCents),
          amount('Otros ingresos', report.otherIncomeCents),
          amount('Costo de materiales vendidos', -report.materialCostsCents),
          amount('Gastos operativos', -report.operatingExpensesCents),
          amount('Otros gastos', -report.otherExpensesCents),
          pw.Divider(),
          amount('Resultado contable (informativo)', report.netResultCents),
          heading('2. Reparto de la utilidad de macetas'),
          amount(
            'Utilidad de ventas menos materiales',
            report.productionProfitCents,
          ),
          amount('Fondo retenido (50%)', report.reinvestmentCents),
          amount('Joel (65% del 50% distribuible)', report.joelCents),
          amount('Paul (35% del 50% distribuible)', report.paulCents),
          note(
            'Esta propuesta no registra distribuciones ni '
            'considera automaticamente obligaciones pendientes. '
            'Requiere conciliacion y aprobacion de los socios.',
          ),
          heading('Fondo de gastos y reinversion'),
          if (report.hasValuationWarnings)
            note(
              'No se puede determinar el fondo: existen '
              'ventas sin costo de materiales contabilizado.',
            )
          else ...[
            amount('50% reservado', report.reinvestmentCents),
            amount(
              'Gastos del fondo registrados',
              report.operatingExpensesCents + report.otherExpensesCents,
            ),
            amount(
              'Saldo del fondo en este trimestre',
              report.reinvestmentCents -
                  report.operatingExpensesCents -
                  report.otherExpensesCents,
            ),
          ],
          note(
            'Este saldo corresponde solamente al trimestre. '
            'No es una cuenta bancaria independiente y no '
            'incluye saldos pendientes de trimestres anteriores.',
          ),
          heading('3. Banco Izumi - Saldo contable'),
          amount('Saldo al inicio', openingBalance),
          amount(
            'Variacion bancaria del trimestre',
            closingBalance - openingBalance,
          ),
          amount('Saldo al cierre', closingBalance),
          note(
            'La variacion bancaria puede incluir aportes de capital, '
            'compras de inventario, maquinaria y otros movimientos. '
            'No equivale a utilidad.',
          ),
          heading('4. Observaciones y limitaciones'),
          note(
            'Las compras de inventario y maquinaria no se tratan '
            'como gastos del trimestre por el solo hecho de pagarse.',
          ),
          note(
            'Ventas de macetas sin asiento de costo detectadas: '
            '${report.unvaluedSales}.',
          ),
          note(
            'El reporte se construye con los asientos registrados. '
            'No sustituye la conciliacion bancaria, inventarios fisicos, '
            'revision de impuestos ni cierre contable.',
          ),
          heading('5. Movimientos bancarios del trimestre'),
          if (bankMovements.isEmpty)
            note('No existen movimientos bancarios registrados.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGreen),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text('Fecha / Movimiento'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text('Importe'),
                    ),
                  ],
                ),
                for (final movement in bankMovements)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          movement.$1,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          money(movement.$2),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );

    final directory = Directory(reportFolder);
    await directory.create(recursive: true);

    final file = File(
      '${directory.path}\\'
      'Izumi_Reporte_${year}_T$quarter.pdf',
    );

    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }
}
