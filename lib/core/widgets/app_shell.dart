import '../../features/tareas/presentation/tareas_page.dart';

import 'package:flutter/material.dart';

import '../../app/router/app_sections.dart';
import '../../features/finanzas/presentation/finanzas_page.dart';
import '../../features/inventario/presentation/inventario_page.dart';
import '../../features/productos/presentation/productos_page.dart';
import '../../features/produccion/presentation/produccion_page.dart';
import '../../features/pedidos/presentation/pedidos_page.dart';
import '../../features/calculadora/presentation/calculadora_page.dart';
import 'app_sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection selected = AppSection.finanzas;

  Widget get currentPage => switch (selected) {
    AppSection.finanzas => const FinanzasPage(),
    AppSection.inventario => const InventarioPage(),
    AppSection.productos => const ProductosPage(),
    AppSection.produccion => const ProduccionPage(),
    AppSection.pedidos => const PedidosPage(),
    AppSection.calculadora => const CalculadoraPage(),
    AppSection.tareas => const TareasPage(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selected: selected,
            onSelect: (section) => setState(() => selected = section),
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: currentPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
