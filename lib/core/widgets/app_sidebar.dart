import 'package:flutter/material.dart';

import '../../app/router/app_sections.dart';
import '../../app/theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.selected, required this.onSelect});

  final AppSection selected;
  final ValueChanged<AppSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      color: AppTheme.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset('assets/images/izumi_logo.png'),
          ),
          const SizedBox(height: 12),
          const Text(
            'MANAGER',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, letterSpacing: 3),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: AppSection.values.map((section) {
                final active = section == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    selected: active,
                    selectedTileColor: Colors.white.withValues(alpha: 0.16),
                    leading: Icon(section.icon, color: Colors.white),
                    title: Text(
                      section.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    onTap: () => onSelect(section),
                  ),
                );
              }).toList(),
            ),
          ),
          const Text(
            'Izumi · Administración local',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
