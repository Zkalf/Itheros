import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'journal_screen.dart';
import 'labels.dart';
import 'quest_part.dart';
import 'socket.dart';
import 'theme.dart';

/// "Pell, the charcoal burner".
String personName(PersonDef p) => '${p.name}, ${p.title}';

/// The portrait id of a teacher or of Ysolde: the name in lower case
/// (spec 0023 §3.6).
String portraitId(String name) => name.toLowerCase();

/// The portrait id of a quest's giver: a person's id, or the teacher's name
/// in lower case (spec 0024 §3.4).
String giverPortrait(GameData data, String giver) =>
    data.people.containsKey(giver)
    ? giver
    : portraitId(data.professions[giver]!.teacher.name);

/// The portrait [id] in a socket of [size] (spec 0023 §3.1, §3.5, §3.6): a
/// person, a teacher or Ysolde. Claude's flat drawing until nabriis draws the
/// real art, else the placeholder.
class Portrait extends StatelessWidget {
  const Portrait(this.id, {super.key, this.size = 32});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) => PictureSocket(
    picture: ImageScope.of(context)
        .pictureOf(ControllerScope.of(context).game.data, GuideThing(id)),
    size: size,
  );
}

/// The top of a sheet of someone (spec 0023 §3.2, §3.6): the portrait at
/// 72 dp and the name.
class PortraitHeader extends StatelessWidget {
  const PortraitHeader({super.key, required this.id, required this.name});

  final String id;
  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Portrait(id, size: 72),
      const SizedBox(width: 16),
      Expanded(
        child: Text(name, style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
}

/// Opens [person]'s sheet. Opening hears every open line, so the lines and
/// their lore pages are heard as the sheet opens (spec 0023 §2.2).
Future<void> showPerson(
  BuildContext context,
  GameController c,
  String person,
) async {
  final pages = await c.hear(person);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PersonSheet(controller: c, person: person, newPages: pages),
  );
}

/// The sheet of a person (spec 0023 §3.2): the portrait and the name, the
/// newest line, the lore page that this opening found, and the other lines
/// heard, newest first.
class PersonSheet extends StatelessWidget {
  const PersonSheet({
    super.key,
    required this.controller,
    required this.person,
    this.newPages = const [],
  });

  final GameController controller;
  final String person;
  final List<String> newPages;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final p = game.data.people[person]!;
    final labels = Labels(game.data, s.character);
    final text = Theme.of(context).textTheme;
    const italic = TextStyle(fontStyle: FontStyle.italic);
    final newest = game.newestLine(s, person);
    final told = [
      for (final l in p.lines.reversed)
        if (s.heard.contains(l.id) && l.id != newest?.id) l,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('person-sheet'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PortraitHeader(id: p.id, name: personName(p)),
            const SizedBox(height: 12),
            if (newest != null)
              Text(
                '"${labels.fill(newest.text)}"',
                key: const ValueKey('person-line'),
                style: italic,
              ),
            // The quests, under the newest line (spec 0024 §3.3).
            QuestPart(controller: c, giver: person),
            for (final id in newPages)
              if (game.data.pages[id] case final page?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: InkWell(
                    key: ValueKey('person-new-page-$id'),
                    // The Lore tab, where the page now stands (§3.2).
                    onTap: () {
                      final nav = Navigator.of(context)..pop();
                      nav.push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JournalScreen(initialTab: 2),
                        ),
                      );
                    },
                    // Teal, as a link: it opens the Lore tab.
                    child: Text(
                      'New lore page: ${page.title}',
                      style: text.titleSmall?.copyWith(color: Quiet.teal),
                    ),
                  ),
                ),
            if (told.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('What ${p.name} told you', style: text.titleMedium),
              for (final l in told)
                Padding(
                  key: ValueKey('person-told-${l.id}'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('"${labels.fill(l.text)}"', style: italic),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
