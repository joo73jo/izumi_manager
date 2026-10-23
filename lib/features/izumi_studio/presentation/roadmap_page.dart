import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

const _green = Color(0xFF284426);
const _deep = Color(0xFF182C1D);
const _cream = Color(0xFFF7F6F1);
const _sage = Color(0xFFE9EEE5);
const _gold = Color(0xFFB5A07B);
const _muted = Color(0xFF747A70);
const _line = Color(0xFFDFE5DA);

class _Stage {
  const _Stage(this.id, this.title, this.subtitle, this.icon);

  final int id;
  final String title;
  final String subtitle;
  final IconData icon;
}

const _stages = [
  _Stage(
    1,
    'Fundamentos de la marca',
    'Identidad y direcci\u00f3n estrat\u00e9gica.',
    Icons.auto_awesome_outlined,
  ),
  _Stage(
    2,
    'Producto y operaci\u00f3n',
    'Convertir la propuesta en productos reales.',
    Icons.precision_manufacturing_outlined,
  ),
  _Stage(
    3,
    'Cat\u00e1logo y lanzamiento',
    'Presentar nuestros dise\u00f1os al mercado.',
    Icons.storefront_outlined,
  ),
  _Stage(
    4,
    'Validaci\u00f3n comercial',
    'Aprender de las ventas reales.',
    Icons.analytics_outlined,
  ),
  _Stage(
    5,
    'Automatizaci\u00f3n',
    'Reducir tareas manuales y dependencia operativa.',
    Icons.settings_suggest_outlined,
  ),
  _Stage(
    6,
    'Negocio sostenible',
    'Rentabilidad con una estructura peque\u00f1a.',
    Icons.spa_outlined,
  ),
];

class _Milestone {
  const _Milestone({
    required this.id,
    required this.stage,
    required this.title,
    required this.description,
    required this.completed,
    required this.completedAt,
  });

  final String id;
  final int stage;
  final String title;
  final String description;
  final bool completed;
  final int? completedAt;
}

class _RoadmapRepository {
  _RoadmapRepository(this.db);

  final AppDatabase db;

  static const _initial = [
    (
      1,
      'Esencia de Izumi',
      'Prop\u00f3sito, misi\u00f3n, visi\u00f3n y valores.',
      true,
    ),
    (1, 'Posicionamiento', 'Dise\u00f1o de autor premium accesible.', true),
    (1, 'Plan de negocio', 'Modelo digital y estrategia inicial.', true),
    (1, 'Identidad visual', 'Logotipo, colores y tipograf\u00edas.', true),
    (1, 'Identidad corporativa inicial', 'Gmail e Instagram oficiales.', true),
    (
      2,
      'Herramientas de producci\u00f3n',
      'Impresora y herramientas principales.',
      true,
    ),
    (2, 'Izumi Manager', 'M\u00f3dulos administrativos en desarrollo.', true),
    (2, 'Prototipos iniciales', 'Pruebas de macetas y dise\u00f1os.', true),
    (2, 'Primer pedido de recuerdos', 'Completar las 36 unidades.', false),
    (2, 'Packaging', 'Probar la presentaci\u00f3n premium accesible.', false),
    (2, 'Insumos pendientes', 'Completar materiales necesarios.', false),
    (
      3,
      'Selecci\u00f3n de modelos',
      'Elegir los dise\u00f1os iniciales.',
      false,
    ),
    (3, 'Precios de venta', 'Determinar los precios.', false),
    (
      3,
      'Fotograf\u00eda editorial',
      'Crear im\u00e1genes para el cat\u00e1logo.',
      false,
    ),
    (3, 'Canales comerciales', 'Completar los canales digitales.', false),
    (3, 'Lanzamiento digital', 'Publicar productos y recibir pedidos.', false),
    (4, 'Registrar ventas', 'Medir pedidos, ingresos y margen.', false),
    (4, 'Detectar modelos preferidos', 'Identificar demanda real.', false),
    (4, 'Evaluar experiencia', 'Medir satisfacci\u00f3n del cliente.', false),
    (4, 'Mejorar el surtido', 'Priorizar productos rentables.', false),
    (5, 'Tienda en l\u00ednea', 'Compras y pagos digitales.', false),
    (5, 'Gesti\u00f3n de pedidos', 'Reducir tareas manuales.', false),
    (5, 'Producci\u00f3n estandarizada', 'Procesos reproducibles.', false),
    (5, 'Indicadores financieros', 'Decisiones basadas en resultados.', false),
    (6, 'Ventas recurrentes', 'Consolidar productos rentables.', false),
    (
      6,
      'Operaci\u00f3n eficiente',
      'Disminuir intervenci\u00f3n diaria.',
      false,
    ),
    (6, 'Colecciones consolidadas', 'Dise\u00f1os reconocibles.', false),
    (6, 'Crecimiento controlado', 'Reinvertir de forma sostenible.', false),
  ];

  Future<void> init() async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS studio_roadmap_milestones (
        id TEXT PRIMARY KEY,
        stage INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // No se sobrescriben cambios realizados previamente.
    // Las fechas antiguas se desconocen y quedan vacias.
    for (var i = 0; i < _initial.length; i++) {
      final item = _initial[i];

      await db.customStatement(
        '''
        INSERT OR IGNORE INTO studio_roadmap_milestones
        (id, stage, title, description, completed, completed_at, sort_order)
        VALUES (?, ?, ?, ?, ?, NULL, ?)
      ''',
        ['initial_${i + 1}', item.$1, item.$2, item.$3, item.$4 ? 1 : 0, i],
      );
    }
  }

  Future<List<_Milestone>> all() async {
    await init();

    final rows = await db.customSelect('''
      SELECT id, stage, title, description, completed, completed_at
      FROM studio_roadmap_milestones
      ORDER BY stage, sort_order, rowid
    ''').get();

    return rows.map((row) {
      return _Milestone(
        id: row.read<String>('id'),
        stage: row.read<int>('stage'),
        title: row.read<String>('title'),
        description: row.read<String>('description'),
        completed: row.read<int>('completed') == 1,
        completedAt: row.readNullable<int>('completed_at'),
      );
    }).toList();
  }

  Future<void> toggle(_Milestone item) async {
    final next = !item.completed;

    await db.customStatement(
      '''
      UPDATE studio_roadmap_milestones
      SET completed = ?, completed_at = ?
      WHERE id = ?
    ''',
      [
        next ? 1 : 0,
        next ? DateTime.now().millisecondsSinceEpoch : null,
        item.id,
      ],
    );
  }

  Future<void> save({
    String? id,
    required int stage,
    required String title,
    required String description,
  }) async {
    if (id != null) {
      await db.customStatement(
        '''
        UPDATE studio_roadmap_milestones
        SET stage = ?, title = ?, description = ?
        WHERE id = ?
      ''',
        [stage, title.trim(), description.trim(), id],
      );
      return;
    }

    final generatedId = 'custom_${DateTime.now().microsecondsSinceEpoch}';

    await db.customStatement(
      '''
      INSERT INTO studio_roadmap_milestones
      (id, stage, title, description, completed, sort_order)
      VALUES (?, ?, ?, ?, 0,
        (SELECT COALESCE(MAX(sort_order), 0) + 1
         FROM studio_roadmap_milestones WHERE stage = ?))
    ''',
      [generatedId, stage, title.trim(), description.trim(), stage],
    );
  }

  Future<void> delete(String id) async {
    await db.customStatement(
      'DELETE FROM studio_roadmap_milestones WHERE id = ?',
      [id],
    );
  }
}

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  late final AppDatabase db;
  late final _RoadmapRepository repository;
  late Future<List<_Milestone>> future;

  bool busy = false;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    repository = _RoadmapRepository(db);
    future = repository.all();
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  void refresh() {
    if (!mounted) return;
    setState(() {
      future = repository.all();
    });
  }

  void error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $e')));
  }

  Future<void> change(_Milestone item) async {
    if (busy) return;
    setState(() => busy = true);

    try {
      await repository.toggle(item);
      refresh();
    } catch (e) {
      error(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit({_Milestone? item, int initialStage = 1}) async {
    final title = TextEditingController(text: item?.title ?? '');
    final description = TextEditingController(text: item?.description ?? '');

    var stage = item?.stage ?? initialStage;
    final key = GlobalKey<FormState>();

    final result = await showDialog<(int, String, String)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) => AlertDialog(
            title: Text(item == null ? 'Nuevo hito' : 'Editar hito'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: stage,
                        decoration: const InputDecoration(
                          labelText: 'Etapa',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final s in _stages)
                            DropdownMenuItem(value: s.id, child: Text(s.title)),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            updateDialog(() => stage = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del hito',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe el nombre.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: description,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Descripci\u00f3n',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (key.currentState!.validate()) {
                    Navigator.pop(dialogContext, (
                      stage,
                      title.text.trim(),
                      description.text.trim(),
                    ));
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      try {
        await repository.save(
          id: item?.id,
          stage: result.$1,
          title: result.$2,
          description: result.$3,
        );
        refresh();
      } catch (e) {
        error(e);
      }
    }

    // Liberar luego de cerrar el dialogo.
    title.dispose();
    description.dispose();
  }

  Future<void> remove(_Milestone item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hito'),
        content: Text('?Eliminar "${item.title}" de la hoja de ruta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await repository.delete(item.id);
      refresh();
    } catch (e) {
      error(e);
    }
  }

  String dateText(int? timestamp) {
    if (timestamp == null) {
      return 'Completado previamente';
    }

    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget stageCard(_Stage stage, List<_Milestone> all) {
    final items = all.where((m) => m.stage == stage.id).toList();
    final done = items.where((m) => m.completed).length;
    final total = items.length;
    final progress = total == 0 ? 0.0 : done / total;

    final status = total > 0 && done == total
        ? 'COMPLETADO'
        : done > 0
        ? 'EN MARCHA'
        : 'PENDIENTE';

    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stage.icon, color: _green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stage.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ),
              Text(
                '${stage.id.toString().padLeft(2, '0')} / 06',
                style: const TextStyle(color: _gold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(stage.subtitle, style: const TextStyle(color: _muted)),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _sage,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$done de $total hitos ? $status',
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => edit(initialStage: stage.id),
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Agregar hito'),
              ),
            ],
          ),
          const Divider(height: 23),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Esta etapa no tiene hitos.'),
            ),
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: item.completed ? _sage : _cream,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: item.completed,
                      activeColor: _green,
                      onChanged: busy ? null : (_) => change(item),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w600,
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            if (item.completed) ...[
                              const SizedBox(height: 5),
                              Text(
                                dateText(item.completedAt),
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      onSelected: (value) {
                        if (value == 'edit') edit(item: item);
                        if (value == 'delete') remove(item);
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Milestone>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SelectableText(
            'Error al abrir la hoja de ruta: ${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        final done = items.where((m) => m.completed).length;
        final progress = items.isEmpty ? 0.0 : done / items.length;

        return ListView(
          padding: const EdgeInsets.only(bottom: 35),
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: _deep,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IZUMI / ROADMAP',
                    style: TextStyle(
                      color: _gold,
                      letterSpacing: 3,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Construir con intenci\u00f3n.\n'
                    'Crecer con criterio.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$done de ${items.length} hitos completados',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(progress * 100).round()} % del plan',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Etapas de Izumi',
                    style: TextStyle(
                      color: _green,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo hito'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            for (final stage in _stages) stageCard(stage, items),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'IZUMI / DISE\u00d1O QUE CONTIENE VIDA',
                style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}
