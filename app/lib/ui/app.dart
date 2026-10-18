import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'controller_scope.dart';
import 'home_shell.dart';
import 'onboarding_screens.dart';

class WalkingRpgApp extends StatefulWidget {
  const WalkingRpgApp({super.key, required this.controller});

  final GameController controller;

  @override
  State<WalkingRpgApp> createState() => _WalkingRpgAppState();
}

class _WalkingRpgAppState extends State<WalkingRpgApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: widget.controller.resume,
      onHide: widget.controller.pause,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B7A3A),
        brightness: b,
      ),
    );
    return ControllerScope(
      controller: widget.controller,
      child: MaterialApp(
        title: 'Walking RPG',
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        home: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => switch (widget.controller.status) {
            ControllerStatus.loading => const LoadingScreen(),
            ControllerStatus.unavailable => const UnavailableScreen(),
            ControllerStatus.needsPermission => const PermissionScreen(),
            ControllerStatus.ready => const HomeShell(),
          },
        ),
      ),
    );
  }
}
