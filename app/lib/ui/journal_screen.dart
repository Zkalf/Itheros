import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'actions.dart';
import 'away_summary_card.dart';
import 'bestiary_card.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'labels.dart';
import 'level_badge.dart';
import 'route_map.dart';
import 'socket.dart';
import 'tab_boxes.dart';
import 'teacher_sheet.dart';
import 'theme.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Today 14:05", "Yesterday 18:30" or "Fri 16 Oct 09:12" (spec 0004
/// decision 4).
String journalTime(DateTime t, DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(t.hour)}:${two(t.minute)}';
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Today $time';
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return 'Yesterday $time';
  }
  return '${_days[t.weekday - 1]} ${t.day} ${_months[t.month - 1]} $time';
}

/// The Journal (spec 0009 §8.4): the newest reports (Log, spec 0004 §2),
/// the Bestiary and the Lore (spec 0023 §3.3). [initialTab] 2 opens on Lore.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    initialIndex: initialTab,
    child: Scaffold(
      appBar: AppBar(
        leading: const BackPlate(),
        // "Zkalf's journal" (spec 0012 §4.5).
        title: Text(
          "${ControllerScope.of(context).state.character?.name ?? Game.defaultName}'s journal",
        ),
        // The tabs stand on a plate, each in its own box (spec 0014 §2.2).
        bottom: const TabBoxes(labels: ['Log', 'Bestiary', 'Lore']),
      ),
      body: const SafeArea(
        child: TabBarView(children: [_Log(), _Bestiary(), _Lore()]),
      ),
    ),
  );
}

class _Log extends StatelessWidget {
  const _Log();

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final labels = Labels(c.game.data);
    final text = Theme.of(context).textTheme;
    if (c.journal.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No reports yet. Pick something to do, go for a walk, and '
          'what happened shows up here.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        for (final e in c.journal)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    numberSpan(
                      '${journalTime(e.started, c.now)}'
                      '${e.testWalk ? ' (test walk)' : ''}',
                    ),
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...reportBanners(e.summary, labels),
                  // Between the banners and the lines (spec 0014 §4.2).
                  ?routeMapOf(labels.data, e.summary.route),
                  for (final l in reportLines(e.summary, labels))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: reportLine(l, labels),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Every monster in an area out of the fog (decision 10), by area in map
/// order: its picture, then its level badge and name as in a fight row
/// (`enemyTile`), its armour once known, "?" while its weakness isn't, and
/// the Slayer mark. Tapping one opens its card.
class _Bestiary extends StatelessWidget {
  const _Bestiary();

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    return ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        for (final l in game.data.locations.values)
          if (l.enemies.isNotEmpty && !game.isFogged(s, l.id)) ...[
            Heading(l.name),
            // The rows of an area stand on a plate (spec 0014 §2.2).
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final id in l.enemies)
                    Builder(
                      builder: (context) {
                        final e = game.data.enemies[id]!;
                        final k = game.knowledge(s, id);
                        return ListTile(
                          key: ValueKey('bestiary-$id'),
                          // The monster in a 48 dp socket, as in a fight
                          // row (spec 0014 §2.3, §4.2).
                          leading: PictureSocket(
                            picture: ImageScope.of(context)
                                .pictureOf(game.data, MonsterThing(id)),
                            size: 48,
                          ),
                          title: Row(
                            children: [
                              LevelBadge(
                                key: ValueKey('bestiary-level-$id'),
                                level: e.level,
                                colour: game.enemyBand(s, id).colour,
                              ),
                              const SizedBox(width: 10),
                              Flexible(child: Text(labels.enemy(id))),
                            ],
                          ),
                          titleTextStyle: nameStyle(context),
                          // The word "Slayer" is the mark, with no icon
                          // (spec 0014 §4.1).
                          subtitle: Text(
                            [
                              k.armour ? labels.armour(e.armour) : 'Armour ???',
                              k.weakness ? 'weak to ${game.weakness(id)}' : '?',
                              if (k.slayer) 'Slayer',
                            ].join(' · '),
                          ),
                          onTap: () => showBestiaryCard(context, c, id),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}

/// The lore by place, in the order of `world.json`, with "N of M" for each
/// place and for all (spec 0023 §3.3), then the tips each teacher told.
class _Lore extends StatelessWidget {
  const _Lore();

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final data = game.data;
    final labels = Labels(data, s.character);
    final text = Theme.of(context).textTheme;
    final images = ImageScope.of(context);
    final notes = {for (final n in data.loreNotes) n.id: n};
    final all = {for (final p in data.locations.keys) ...data.loreOf(p)};
    // A hidden place has no group until it is revealed (spec 0011 §6.2).
    final places = [
      for (final p in data.locations.keys)
        if (data.loreOf(p).isNotEmpty && !game.isHidden(s, p)) p,
    ];

    Widget entry(String id) {
      final found = s.lore.contains(id);
      final page = data.pages[id];
      final note = notes[id];
      final picture = !found
          ? Picture.placeholderOf('generic')
          : page != null
          ? (images.has(lorePageKey)
                ? const Picture(lorePageKey)
                : Picture.placeholderOf('generic'))
          : images.pictureOf(data, MonsterThing(note!.about));
      return Card(
        key: ValueKey('lore-$id'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PictureSocket(picture: picture, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: found
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page?.title ?? note!.title,
                            style: text.titleMedium,
                          ),
                          if (note != null)
                            Text(
                              'About the ${labels.enemy(note.about)}',
                              style: text.bodySmall,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            page != null ? labels.fill(page.text) : note!.text,
                          ),
                        ],
                      )
                    : Text('Not found yet', style: text.bodyMedium),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        Text.rich(
          numberSpan(
            '${all.where(s.lore.contains).length} of ${all.length} found',
          ),
          style: text.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final p in places)
          Column(
            key: ValueKey('lore-group-$p'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Heading(
                '${data.locations[p]!.name} · '
                '${game.loreCount(s, p).found} of ${game.loreCount(s, p).total}',
              ),
              for (final id in data.loreOf(p)) entry(id),
            ],
          ),
        // Teachers' tips, under each teacher; they aren't counted above
        // (spec 0010 §6.2).
        for (final p in data.professions.values)
          if (p.tips.any((t) => c.state.tips.contains(t.id))) ...[
            Heading(teacherName(p)),
            for (final t in p.tips)
              if (c.state.tips.contains(t.id)) TipCard(tip: t, labels: labels),
          ],
      ],
    );
  }
}
