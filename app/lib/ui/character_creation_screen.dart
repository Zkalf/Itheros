import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'actions.dart' show Heading;
import 'controller_scope.dart';
import 'images.dart';
import 'labels.dart';
import 'socket.dart';
import 'teacher_sheet.dart';
import 'theme.dart';

/// "Who are you?" (spec 0012 §4.1): name, gender and origin before the
/// first walk. Shown while the save has no character; only Set out leaves.
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _name = TextEditingController();
  var _gender = Gender.neither;
  String? _origin;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final text = Theme.of(context).textTheme;
    // Anything to keep makes it an old save.
    final old = s.xp > 0 || s.learned.isNotEmpty;
    final who = Character(
      name: Game.defaultName,
      gender: _gender,
      origin: _origin ?? '',
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          key: const ValueKey('who-are-you'),
          padding: const EdgeInsets.all(gutter),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Text('Who are you?', style: text.headlineSmall),
            ),
            if (old)
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Text(
                  "Your progress stays. Your origin's profession rises to "
                  'level 5 if it is lower.',
                ),
              ),
            const SizedBox(height: 16),
            // The name and the gender stand on a plate (spec 0014 §2.2).
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      key: const ValueKey('character-name-field'),
                      controller: _name,
                      maxLength: Game.maxNameLength,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: Game.defaultName,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<Gender>(
                      expandedInsets: EdgeInsets.zero,
                      segments: [
                        for (final g in Gender.values)
                          ButtonSegment(value: g, label: Text(genderName(g))),
                      ],
                      selected: {_gender},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) =>
                          setState(() => _gender = v.single),
                    ),
                  ],
                ),
              ),
            ),
            const Heading('Origin'),
            const SizedBox(height: 8),
            for (final o in game.data.origins.values)
              _OriginCard(
                origin: o,
                gender: _gender,
                title: game.fill(o.title, who),
                line: game.fill(o.line, who),
                selected: _origin == o.id,
                onTap: () => setState(() => _origin = o.id),
              ),
            // Set out stands on a plate too.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(gutter),
                child: FilledButton(
                  key: const ValueKey('set-out'),
                  onPressed: _origin == null
                      ? null
                      : () => c.setOut(
                          name: _name.text,
                          gender: _gender,
                          origin: _origin!,
                        ),
                  child: const Text('Set out'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({
    required this.origin,
    required this.gender,
    required this.title,
    required this.line,
    required this.selected,
    required this.onTap,
  });

  final OriginDef origin;

  /// The gender picked above: the portrait follows it (spec 0014 §3.1).
  final Gender gender;

  /// Both filled for the gender picked (spec 0012 §2.3).
  final String title;
  final String line;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final data = c.game.data;
    final p = data.professions[origin.profession]!;
    final theme = Theme.of(context);
    // The picked card's outline is teal (spec 0012, spec 0014 §2.2).
    return Card(
      key: ValueKey('origin-${origin.id}'),
      shape: plateShape(selected: selected),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The portrait for this origin and the gender picked (spec
              // 0014 §4.2).
              PictureSocket(
                key: ValueKey('portrait-${origin.id}'),
                picture: ImageScope.of(context)
                    .pictureOf(data, PlayerThing(origin.id, gender)),
                size: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '"$line"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                'Starts with ${p.name} ${data.headStartLevel}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' · ${teacherName(p)}, greets you as kin',
                          ),
                        ],
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
