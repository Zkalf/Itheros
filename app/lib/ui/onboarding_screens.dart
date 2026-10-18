import 'package:flutter/material.dart';

import 'controller_scope.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 24),
              Text(
                title,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(body, style: text.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton(onPressed: onPressed, child: Text(button)),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    return _Message(
      icon: Icons.directions_walk,
      title: 'Your steps are your power',
      body:
          'Every fight, ore and crafted item is paid for with steps you walk. '
          'Allow step access so your walks count. Your step data stays on '
          'this phone. Steps walked before you install the game don\'t count.',
      button: 'Allow step access',
      onPressed: controller.requestPermission,
    );
  }
}

class UnavailableScreen extends StatelessWidget {
  const UnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    return _Message(
      icon: Icons.health_and_safety_outlined,
      title: 'Health Connect is needed',
      body:
          'This game reads your steps from Health Connect. Install or update '
          'Health Connect from the Play Store, then try again.',
      button: 'Try again',
      onPressed: controller.start,
    );
  }
}
