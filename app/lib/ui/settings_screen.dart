import 'package:flutter/material.dart';

import '../version.dart';
import 'controller_scope.dart';

/// Settings, opened from the top bar (spec 0008 decision 12). Name and
/// gender join them with spec 0012.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              key: const ValueKey('show-next-goal'),
              title: const Text('Show "Next goal"'),
              value: !c.nextGoalHidden,
              onChanged: (show) => c.setNextGoalHidden(!show),
            ),
            // Only the owner's build has a test walk (spec 0007 §4).
            if (c.testWalkAllowed)
              SwitchListTile(
                key: const ValueKey('test-walk-switch'),
                title: const Text('Test walk'),
                subtitle: const Text('Pretend steps for playtesting'),
                value: c.testWalkOn,
                onChanged: c.setTestWalk,
              ),
            // Friends quote it when they report something (spec 0007 §7).
            ListTile(
              key: const ValueKey('version'),
              title: Text('Version $appVersion', style: text.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
