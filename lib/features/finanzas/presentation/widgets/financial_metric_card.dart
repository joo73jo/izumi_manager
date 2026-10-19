import 'package:flutter/material.dart';

class FinancialMetricCard extends StatelessWidget {
  const FinancialMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF284426)),
            const SizedBox(height: 14),
            Text(label),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFF284426),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
