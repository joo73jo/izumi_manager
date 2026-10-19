import 'package:flutter/material.dart';

import '../../domain/inventory_item.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    super.key,
    required this.item,
    required this.onAdjust,
    required this.onPurchase,
    required this.onHistory,
    this.onEdit,
    this.onDelete,
  });

  final InventoryItem item;
  final VoidCallback onAdjust;
  final VoidCallback onPurchase;
  final VoidCallback onHistory;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.lowStock ? Icons.warning_amber : Icons.inventory_2_outlined,
          color: const Color(0xFF284426),
        ),
        title: Text(item.name),
        subtitle: Text(item.category.label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.quantity} ${item.unit}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: onHistory,
              tooltip: 'Ver historial',
              icon: const Icon(Icons.history),
            ),
            OutlinedButton.icon(
              onPressed: onPurchase,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Comprar'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Opciones del material',
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == 'edit') onEdit?.call();
                if (action == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  enabled: onEdit != null,
                  child: const Text('Editar material'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: onDelete != null,
                  child: const Text('Eliminar material'),
                ),
              ],
            ),
            IconButton(
              onPressed: onAdjust,
              tooltip: 'Ajustar existencias',
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
      ),
    );
  }
}
