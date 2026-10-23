import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/app_database.dart';
import '../data/tasks_repository.dart';

enum ActivityView { list, calendar }

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  static const green = Color(0xFF284426);

  late final AppDatabase db;
  late final TasksRepository repository;
  late Future<List<IzumiTask>> tasks;

  final searchController = TextEditingController();

  ActivityView currentView = ActivityView.list;
  bool completedView = false;
  bool exporting = false;

  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    repository = TasksRepository(db);
    refresh();
    searchController.addListener(onSearchChanged);
  }

  void onSearchChanged() {
    if (mounted) setState(() {});
  }

  void refresh() {
    setState(() {
      tasks = repository.all();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    db.close();
    super.dispose();
  }

  String priorityLabel(int value) {
    return switch (value) {
      1 => 'Alta',
      2 => 'Media',
      _ => 'Baja',
    };
  }

  Color priorityColor(int value) {
    return switch (value) {
      1 => const Color(0xFFAD513F),
      2 => const Color(0xFFAE873D),
      _ => const Color(0xFF558065),
    };
  }

  String dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String dateTimeLabel(DateTime date) {
    return '${dateLabel(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool matchesSearch(IzumiTask task) {
    final text = searchController.text.trim().toLowerCase();

    return text.isEmpty ||
        task.title.toLowerCase().contains(text) ||
        task.observations.toLowerCase().contains(text);
  }

  void showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $error')));
  }

  Future<void> edit([IzumiTask? task]) async {
    final title = TextEditingController(text: task?.title ?? '');
    final notes = TextEditingController(text: task?.observations ?? '');

    var priority = task?.priority ?? 2;

    final result = await showDialog<(String, int, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(task == null ? 'Nueva actividad' : 'Editar actividad'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: title,
                    autofocus: task == null,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Titulo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridad',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Alta')),
                      DropdownMenuItem(value: 2, child: Text('Media')),
                      DropdownMenuItem(value: 3, child: Text('Baja')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        update(() => priority = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notes,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      hintText: 'Resultados, detalles o comentarios...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La fecha de finalizacion se registra '
                    'automaticamente al completar la actividad.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) return;

                Navigator.pop(dialogContext, (
                  title.text.trim(),
                  priority,
                  notes.text.trim(),
                ));
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    // Liberamos los controladores despues del dialogo.
    if (!mounted || result == null) return;

    try {
      await repository.save(
        result.$1,
        result.$2,
        id: task?.id,
        observations: result.$3,
      );

      if (mounted) refresh();
    } catch (error) {
      showError(error);
    }
  }

  Future<void> toggle(IzumiTask task) async {
    try {
      await repository.toggle(task);
      if (mounted) refresh();
    } catch (error) {
      showError(error);
    }
  }

  Future<void> remove(IzumiTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text('¿Eliminar "${task.title}" definitivamente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repository.delete(task.id);
      if (mounted) refresh();
    } catch (error) {
      showError(error);
    }
  }

  Future<void> openDetails(IzumiTask task) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task.title),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text('Prioridad ${priorityLabel(task.priority)}')),
                const SizedBox(height: 12),
                Text(
                  task.done ? 'Completada' : 'Pendiente',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (task.completedAt != null) ...[
                  const SizedBox(height: 6),
                  Text('Finalizada: ${dateTimeLabel(task.completedAt!)}'),
                ],
                const Divider(height: 30),
                const Text(
                  'Observaciones',
                  style: TextStyle(fontWeight: FontWeight.bold, color: green),
                ),
                const SizedBox(height: 10),
                Text(
                  task.observations.isEmpty
                      ? 'Sin observaciones registradas.'
                      : task.observations,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              edit(task);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget activityCard(IzumiTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: () => openDetails(task),
        leading: Checkbox(value: task.done, onChanged: (_) => toggle(task)),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Prioridad ${priorityLabel(task.priority)}',
                style: TextStyle(color: priorityColor(task.priority)),
              ),
              if (task.completedAt != null)
                Text(dateTimeLabel(task.completedAt!)),
              if (task.observations.isNotEmpty)
                const Row(
                  children: [
                    Icon(Icons.notes, size: 15),
                    SizedBox(width: 3),
                    Text('Observaciones'),
                  ],
                ),
            ],
          ),
        ),
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: 'Editar actividad',
              onPressed: () => edit(task),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Eliminar actividad',
              onPressed: () => remove(task),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget listView(List<IzumiTask> allTasks) {
    final filtered = allTasks.where((task) {
      return task.done == completedView && matchesSearch(task);
    }).toList();

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Pendientes'),
                icon: Icon(Icons.pending_actions),
              ),
              ButtonSegment(
                value: true,
                label: Text('Completadas'),
                icon: Icon(Icons.check_circle_outline),
              ),
            ],
            selected: {completedView},
            onSelectionChanged: (value) {
              setState(() => completedView = value.first);
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No hay actividades en esta vista.'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return activityCard(filtered[index]);
                  },
                ),
        ),
      ],
    );
  }

  void changeMonth(int offset) {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + offset,
      );

      selectedDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    });
  }

  Widget calendarView(List<IzumiTask> allTasks) {
    final completed = allTasks
        .where(
          (task) =>
              task.done && task.completedAt != null && matchesSearch(task),
        )
        .toList();

    final year = displayedMonth.year;
    final month = displayedMonth.month;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final leading = firstDay.weekday - 1;
    final rows = ((leading + daysInMonth + 6) ~/ 7);

    final dailyTasks = completed.where((task) {
      return sameDay(task.completedAt!, selectedDay);
    }).toList();

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDFE6DD)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${monthName(month)} $year',
                    style: const TextStyle(
                      fontSize: 20,
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children:
                    const ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'].map(
                      (day) {
                        return Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        );
                      },
                    ).toList(),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.15,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                ),
                itemCount: rows * 7,
                itemBuilder: (context, index) {
                  final number = index - leading + 1;

                  if (number < 1 || number > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final date = DateTime(year, month, number);

                  final count = completed.where((task) {
                    return sameDay(task.completedAt!, date);
                  }).length;

                  final selected = sameDay(date, selectedDay);

                  return InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      setState(() => selectedDay = date);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE0EADD)
                            : count > 0
                            ? const Color(0xFFF1F5EE)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: selected
                            ? Border.all(color: green, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$number',
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Actividades del ${dateLabel(selectedDay)}',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
        const SizedBox(height: 12),
        if (dailyTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text('No se completaron actividades este dia.'),
          )
        else
          ...dailyTasks.map(activityCard),
      ],
    );
  }

  String monthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return months[month - 1];
  }

  Future<void> exportPdf() async {
    if (exporting) return;

    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      helpText: 'Periodo del informe',
      saveText: 'Generar informe',
    );

    if (range == null || !mounted) return;

    setState(() => exporting = true);

    try {
      final allTasks = await repository.all();

      final selected = allTasks.where((task) {
        if (!task.done || task.completedAt == null) {
          return false;
        }

        final date = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );

        return !date.isBefore(range.start) && !date.isAfter(range.end);
      }).toList()..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));

      final fontFile = File(r'C:\Windows\Fonts\arial.ttf');
      final boldFile = File(r'C:\Windows\Fonts\arialbd.ttf');

      if (!await fontFile.exists() || !await boldFile.exists()) {
        throw Exception('No se encontraron las fuentes Arial.');
      }

      final regularFont = pw.Font.ttf(
        (await fontFile.readAsBytes()).buffer.asByteData(),
      );

      final boldFont = pw.Font.ttf(
        (await boldFile.readAsBytes()).buffer.asByteData(),
      );

      final document = pw.Document(
        title: 'IZUMI - Informe de actividades',
        author: 'Izumi',
      );

      const pdfGreen = PdfColor.fromInt(0xFF284426);
      const pdfGray = PdfColor.fromInt(0xFF677267);
      const pdfLight = PdfColor.fromInt(0xFFF2F5EF);

      pw.Widget pdfText(
        String value, {
        double size = 10,
        bool bold = false,
        PdfColor color = PdfColors.black,
      }) {
        return pw.Text(
          value,
          style: pw.TextStyle(
            font: bold ? boldFont : regularFont,
            fontSize: size,
            color: color,
          ),
        );
      }

      final days = selected
          .map((task) {
            final d = task.completedAt!;
            return '${d.year}-${d.month}-${d.day}';
          })
          .toSet()
          .length;

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(38),
          header: (context) => pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pdfText('IZUMI.', size: 24, bold: true, color: pdfGreen),
                  pdfText('REPORTE DE ACTIVIDADES', size: 9, color: pdfGray),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(height: 3, color: pdfGreen),
              pw.SizedBox(height: 20),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(color: pdfLight),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pdfText(
                    'IZUMI | Registro de trabajo',
                    size: 8,
                    color: pdfGray,
                  ),
                  pdfText(
                    'Pagina ${context.pageNumber} '
                    'de ${context.pagesCount}',
                    size: 8,
                    color: pdfGray,
                  ),
                ],
              ),
            ],
          ),
          build: (context) => [
            pdfText(
              'Registro de actividades',
              size: 23,
              bold: true,
              color: pdfGreen,
            ),
            pw.SizedBox(height: 8),
            pdfText(
              'Periodo: ${dateLabel(range.start)}'
              ' - ${dateLabel(range.end)}',
              size: 11,
              color: pdfGray,
            ),
            pw.SizedBox(height: 25),
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: const pw.BoxDecoration(color: pdfLight),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pdfText(
                        '${selected.length}',
                        size: 25,
                        bold: true,
                        color: pdfGreen,
                      ),
                      pdfText('Actividades completadas'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pdfText('$days', size: 25, bold: true, color: pdfGreen),
                      pdfText('Dias con actividad'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 28),
            pdfText(
              'DETALLE DE ACTIVIDADES',
              size: 13,
              bold: true,
              color: pdfGreen,
            ),
            pw.SizedBox(height: 12),
            if (selected.isEmpty)
              pdfText(
                'No existen actividades completadas '
                'en el periodo seleccionado.',
              ),
            ...selected.map((task) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: pdfLight, width: 1),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pdfText(task.title, size: 12, bold: true, color: pdfGreen),
                    pw.SizedBox(height: 5),
                    pdfText(
                      '${dateTimeLabel(task.completedAt!)}'
                      '  |  Prioridad ${priorityLabel(task.priority)}',
                      size: 9,
                      color: pdfGray,
                    ),
                    if (task.observations.isNotEmpty) ...[
                      pw.SizedBox(height: 9),
                      pdfText('Observaciones:', bold: true, size: 9),
                      pw.SizedBox(height: 3),
                      pdfText(task.observations, size: 10),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      );

      final home = Platform.environment['USERPROFILE'];

      if (home == null || home.isEmpty) {
        throw Exception('No se encontro la carpeta del usuario.');
      }

      final folder = Directory('$home\\Downloads');
      await folder.create(recursive: true);

      final filename =
          'Izumi_Actividades_${range.start.year}'
          '${range.start.month.toString().padLeft(2, '0')}'
          '${range.start.day.toString().padLeft(2, '0')}'
          '_${range.end.year}'
          '${range.end.month.toString().padLeft(2, '0')}'
          '${range.end.day.toString().padLeft(2, '0')}.pdf';

      final output = File('${folder.path}\\$filename');

      await output.writeAsBytes(await document.save());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Informe guardado: ${output.path}'),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (error) {
      showError(error);
    } finally {
      if (mounted) {
        setState(() => exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Actividades de Izumi',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            OutlinedButton.icon(
              onPressed: exporting ? null : exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(exporting ? 'Generando...' : 'Informe PDF'),
            ),
            FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva actividad'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SegmentedButton<ActivityView>(
          segments: const [
            ButtonSegment(
              value: ActivityView.list,
              icon: Icon(Icons.list_alt),
              label: Text('Lista de tareas'),
            ),
            ButtonSegment(
              value: ActivityView.calendar,
              icon: Icon(Icons.calendar_month),
              label: Text('Calendario'),
            ),
          ],
          selected: {currentView},
          onSelectionChanged: (value) {
            setState(() => currentView = value.first);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Buscar actividades',
            hintText: 'Buscar por titulo u observaciones',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: searchController.clear,
                    icon: const Icon(Icons.close),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: FutureBuilder<List<IzumiTask>>(
            future: tasks,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SelectableText('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allTasks = snapshot.data!;

              return currentView == ActivityView.list
                  ? listView(allTasks)
                  : calendarView(allTasks);
            },
          ),
        ),
      ],
    );
  }
}
