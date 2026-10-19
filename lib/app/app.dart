import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../core/widgets/app_shell.dart';

class IzumiApp extends StatelessWidget {
  const IzumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Izumi Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
