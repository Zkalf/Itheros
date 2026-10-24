import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'actions.dart';
import 'away_summary_card.dart';
import 'bestiary_card.dart';
import 'controller_scope.dart';
import 'labels.dart';
import 'level_badge.dart';
import 'route_map.dart';
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
/// the Bestiary and found Lore notes.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        leading: const BackPlate(),
        // "Zkalf's journal" (spec 0012 §4.5).
        title: Text(
          "${ControllerScope.of(context).state.character?.name ?? Game.defaultName}'s journal",
        ),
        // The tabs stand on a plate, each in its own box (spec 0014 §2.2).
        // The TabBar stays.
        bottom: PreferredSize(
          // A tab of 40, the TabBar's 2 for its indicator, the plate's padding
          // of 3 and border of 1 on each side, and the gutter below.
          preferredSize: const Size.fromHeight(40 + 2 + 2 * (3 + 1) + gutter),
          child: Container(
            margin: const EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
            padding: const EdgeInsets.all(3),
            decoration: plateDecoration,
            child: TabBar(
              tabs: [
                for (final (i, label) in const [
                  'Log',
                  'Bestiary',
                  'Lore',
                ].indexed)
                  Tab(height: 40, child: _TabBox(i, label)),
              ],
            ),
          ),
        ),
      ),
      body: const SafeArea(
        child: TabBarView(children: [_Log(), _Bestiary(), _Lore()]),
      ),
    ),
  );
}

/// A tab of the Journal: a box with the 2 dp black border, lit while its tab
/// is open (spec 0014 §2.2).
class _TabBox extends StatelessWidget {
  const _TabBox(this.index, this.label);

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tabs = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: tabs,
      builder: (context, _) => ControlBox(
        fill: tabs.index == index ? Quiet.lit : Quiet.slate,
        child: SizedBox.expand(child: Center(child: Text(label))),
      ),
    );
  }
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
/// order: level badge, its armour once known, "?" while its weakness isn't,
/// and the Slayer mark. Tapping one opens its card.
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
                          leading: LevelBadge(
                            level: e.level,
                            colour: game.enemyBand(s, id).colour,
                          ),
                          title: Text(labels.enemy(id)),
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

/// Found lore notes, newest first, and how many there are (spec 0009 §8.4),
/// then the tips each teacher told.
class _Lore extends StatelessWidget {
  const _Lore();

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final data = c.game.data;
    final labels = Labels(data, c.state.character);
    final text = Theme.of(context).textTheme;
    final byId = {for (final n in data.loreNotes) n.id: n};
    final found = [for (final id in c.state.lore.toList().reversed) ?byId[id]];
    return ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        Text.rich(
          numberSpan('${found.length} of ${data.loreNotes.length} found'),
          style: text.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final n in found)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: text.titleMedium),
                  Text(
                    'About the ${labels.enemy(n.about)}',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(n.text),
                ],
              ),
            ),
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
