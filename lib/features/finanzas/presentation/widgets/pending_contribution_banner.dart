import 'package:flutter/material.dart';

class PendingContributionBanner extends StatelessWidget {
  const PendingContributionBanner({
    super.key,
    required this.saving,
    required this.onRegister,
  });

  final bool saving;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E1D8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF284426)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Paul ya entregó \$2.000. Falta registrarlos en el sistema.',
              style: TextStyle(fontSize: 14, color: Color(0xFF1E1E1E)),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: saving ? null : onRegister,
            icon: const Icon(Icons.check),
            label: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
