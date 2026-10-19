import 'package:flutter/material.dart';

// Los identificadores se mantienen estables para futuras rutas y permisos.
enum AppSection {
  finanzas('Finanzas', Icons.account_balance_wallet_outlined),
  inventario('Inventario', Icons.inventory_2_outlined),
  productos('Productos', Icons.local_florist_outlined),
  produccion('Producción', Icons.precision_manufacturing_outlined),
  pedidos('Pedidos y ventas', Icons.receipt_long_outlined),
  calculadora('Calculadora', Icons.calculate_outlined),
  tareas('Tareas', Icons.task_alt_outlined);

  const AppSection(this.label, this.icon);
  final String label;
  final IconData icon;
}
