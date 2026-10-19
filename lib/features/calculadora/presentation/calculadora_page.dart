import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../data/pricing_repository.dart';

class CalculadoraPage extends StatefulWidget {
  const CalculadoraPage({super.key});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _RecipeLine {
  const _RecipeLine(this.material, this.quantity, this.waste);

  final PricingMaterial material;
  final int quantity;
  final int waste;

  int get consumption => (quantity * (100 + waste) + 99) ~/ 100;
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  late final AppDatabase db;
  late final Future<List<PricingMaterial>> materialsFuture;

  final quantity = TextEditingController();
  final waste = TextEditingController(text: '0');
  final markup = TextEditingController(text: '100');

  final lines = <_RecipeLine>[];
  int? selectedId;

  @override
  void initState() {
    super.initState();
    db = AppDatabase();
    materialsFuture = PricingRepository(db).getMaterials();
  }

  @override
  void dispose() {
    quantity.dispose();
    waste.dispose();
    markup.dispose();
    db.close();
    super.dispose();
  }

  String money(int cents) {
    final sign = cents < 0 ? '-' : '';
    final abs = cents.abs();
    return '$sign\$${abs ~/ 100}.'
        '${(abs % 100).toString().padLeft(2, '0')}';
  }

  String units(int millis) {
    return (millis / 1000)
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  int? parseQuantity(String raw) {
    final match = RegExp(r'^(\d+)(?:[,.](\d{1,3}))?$').firstMatch(raw.trim());

    if (match == null) return null;

    final whole = int.tryParse(match.group(1)!);
    final decimals = int.tryParse((match.group(2) ?? '').padRight(3, '0'));

    if (whole == null || decimals == null) return null;
    return whole * 1000 + decimals;
  }

  void message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void addMaterial(List<PricingMaterial> materials) {
    final id = selectedId ?? (materials.isEmpty ? null : materials.first.id);
    final qty = parseQuantity(quantity.text);
    final wasteValue = int.tryParse(waste.text.trim());

    if (id == null ||
        qty == null ||
        qty <= 0 ||
        wasteValue == null ||
        wasteValue < 0 ||
        wasteValue > 100) {
      message('Revisa la cantidad y el desperdicio (0 a 100%).');
      return;
    }

    final material = materials.firstWhere((m) => m.id == id);

    setState(() {
      lines.add(_RecipeLine(material, qty, wasteValue));
      quantity.clear();
      waste.text = '0';
    });
  }

  Widget amount(String label, int cents, {bool total = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: total ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            money(cents),
            style: TextStyle(
              fontWeight: total ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missing = lines.where((l) => !l.material.hasPrice).length;
    final knownCost = lines.fold<int>(
      0,
      (total, line) =>
          total +
          (line.material.hasPrice
              ? line.material.costFor(line.consumption)
              : 0),
    );

    final markupValue = int.tryParse(markup.text.trim());
    final validMarkup =
        markupValue != null && markupValue >= 0 && markupValue <= 10000;

    final ready = lines.isNotEmpty && missing == 0 && validMarkup;

    final price = ready ? (knownCost * (100 + markupValue) + 99) ~/ 100 : 0;

    final profit = price - knownCost;
    final fund = profit ~/ 2;
    final partners = profit - fund;
    final paul = partners * 35 ~/ 100;
    final joel = partners - paul;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Calculadora de precios',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text('Simula el costo de materiales y el precio de una maceta.'),
        const SizedBox(height: 20),
        FutureBuilder<List<PricingMaterial>>(
          future: materialsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SelectableText('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final materials = snapshot.data!;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materiales para una maceta',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    if (materials.isEmpty)
                      const Text(
                        'Primero registra los materiales en Inventario.',
                      )
                    else ...[
                      DropdownButtonFormField<int>(
                        key: ValueKey(selectedId),
                        initialValue: selectedId ?? materials.first.id,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Material',
                          border: OutlineInputBorder(),
                        ),
                        items: materials.map((m) {
                          return DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              '${m.name} (${m.unit})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (id) => setState(() => selectedId = id),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantity,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                hintText: 'Ej. 100',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: waste,
                              decoration: const InputDecoration(
                                labelText: 'Desperdicio (%)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => addMaterial(materials),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar material'),
                      ),
                    ],
                    const Divider(height: 26),
                    if (lines.isEmpty)
                      const Text('Agrega los materiales de la maceta.'),
                    for (var i = 0; i < lines.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(lines[i].material.name),
                        subtitle: Text(
                          '${units(lines[i].quantity)} '
                          '${lines[i].material.unit} + '
                          '${lines[i].waste}% desperdicio = '
                          '${units(lines[i].consumption)} '
                          '${lines[i].material.unit}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lines[i].material.hasPrice
                                  ? money(
                                      lines[i].material.costFor(
                                        lines[i].consumption,
                                      ),
                                    )
                                  : 'Sin precio',
                            ),
                            IconButton(
                              tooltip: 'Quitar',
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => lines.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: markup,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Margen sobre el costo (%)',
                        helperText: '100% significa vender al doble del costo.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    amount('Costo conocido de materiales', knownCost),
                    if (missing > 0)
                      Text(
                        '$missing material(es) sin precio de compra. '
                        'No se puede calcular un precio confiable.',
                        style: const TextStyle(color: Colors.deepOrange),
                      ),
                    if (!validMarkup)
                      const Text(
                        'Ingresa un margen entre 0 y 10000%.',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                    if (ready) ...[
                      const Divider(),
                      amount('Precio sugerido', price, total: true),
                      amount('Utilidad comercial', profit),
                      amount('Fondo de gastos (50%)', fund),
                      amount('Joel', joel),
                      amount('Paul', paul),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Simulacion informativa. No descuenta inventario '
                      'ni registra ventas o pagos.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
