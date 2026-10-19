import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: AppTheme.green, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Icon(icon, size: 45, color: AppTheme.green),
                const SizedBox(width: 22),
                const Expanded(
                  child: Text(
                    'Módulo preparado. Agregaremos sus funciones paso a paso.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
