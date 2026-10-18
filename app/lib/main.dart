import 'package:flutter/material.dart';

import 'probe/step_probe_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'walkingrpg',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const StepProbePage(),
    );
  }
}
