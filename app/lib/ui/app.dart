import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'away_summary_card.dart';
import 'character_creation_screen.dart';
import 'controller_scope.dart';
import 'home_shell.dart';
import 'level_up_screen.dart';
import 'onboarding_screens.dart';
import 'theme.dart';

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
    return ControllerScope(
      controller: widget.controller,
      child: MaterialApp(
        title: 'Walking RPG',
        // Dark for each phone setting (spec 0014 decision 2): without a
        // dark theme of its own, the app uses this one in dark mode too.
        theme: quietTheme,
        home: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => switch (widget.controller.status) {
            ControllerStatus.loading => const LoadingScreen(),
            ControllerStatus.unavailable => const UnavailableScreen(),
            ControllerStatus.needsPermission => const PermissionScreen(),
            // Who you are comes first (spec 0012 decision 6).
            ControllerStatus.ready =>
              widget.controller.state.character == null
                  ? const CharacterCreationScreen()
                  : widget.controller.levelCards.isNotEmpty
                  ? const LevelUpScreen()
                  : widget.controller.awaySummary != null
                  ? const AwayScreen()
                  : const HomeShell(),
          },
        ),
      ),
    );
  }
}
