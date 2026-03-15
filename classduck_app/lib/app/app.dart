import 'package:flutter/material.dart';

import 'router/app_shell.dart';
import 'theme/app_theme.dart';

class ClassDuckApp extends StatelessWidget {
  const ClassDuckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassDuck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
