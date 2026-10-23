import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import '../version.dart';
import 'controller_scope.dart';
import 'labels.dart';
import 'licences_screen.dart';
import 'theme.dart';

/// Settings, opened from the top bar (spec 0008 decision 12), with the
/// character's name, gender and origin on top (spec 0012 §4.2).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final text = Theme.of(context).textTheme;
    final who = c.state.character;
    // The rows stand on plates (spec 0014 §2.2). A row of one line is 48 dp
    // high, as the design of Settings shows, not the 56 dp of a ListTile.
    Widget plate(List<Widget> rows) => Card(
      clipBehavior: Clip.antiAlias,
      child: ListTileTheme.merge(
        minTileHeight: 48,
        child: Column(children: rows),
      ),
    );
    return Scaffold(
      appBar: AppBar(leading: const BackPlate(), title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(gutter),
          children: [
            if (who != null)
              plate([
                ListTile(
                  key: const ValueKey('settings-name'),
                  title: const Text('Name'),
                  trailing: Text(who.name),
                  onTap: () => _rename(context, c, who.name),
                ),
                ListTile(
                  key: const ValueKey('settings-gender'),
                  title: const Text('Gender'),
                  trailing: Text(genderName(who.gender)),
                  onTap: () => _pickGender(context, c, who.gender),
                ),
                ListTile(
                  key: const ValueKey('settings-origin'),
                  title: const Text('Origin'),
                  subtitle: const Text('Chosen when you set out'),
                  trailing: Text(
                    c.game.fill(
                      c.game.data.origins[who.origin]?.title ?? '',
                      who,
                    ),
                  ),
                ),
              ]),
            plate([
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
            ]),
            // The licences of the four fonts (spec 0014 §4.2).
            plate([
              ListTile(
                key: const ValueKey('settings-licences'),
                title: const Text('Licences'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LicencesScreen(),
                  ),
                ),
              ),
            ]),
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

  Future<void> _rename(
    BuildContext context,
    GameController c,
    String name,
  ) async {
    final next = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(name),
    );
    if (next != null) await c.renameCharacter(next);
  }

  Future<void> _pickGender(
    BuildContext context,
    GameController c,
    Gender gender,
  ) async {
    final next = await showDialog<Gender>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Gender'),
        children: [
          // Each option is a slate box with the border (spec 0014 §2.2).
          for (final g in Gender.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ControlBox(
                child: SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, g),
                  child: Text(
                    genderName(g),
                    style: g == gender
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (next != null && next != gender) await c.setGender(next);
  }
}

/// Owns its text field's controller, so it lives as long as the dialog.
class _NameDialog extends StatefulWidget {
  const _NameDialog(this.name);

  final String name;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _field = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Name'),
    content: TextField(
      key: const ValueKey('rename-field'),
      controller: _field,
      autofocus: true,
      maxLength: Game.maxNameLength,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(hintText: Game.defaultName),
    ),
    actions: [
      TextButton(
        style: ghostButton,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _field.text),
        child: const Text('Save'),
      ),
    ],
  );
}
