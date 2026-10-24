import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'action_sheet.dart';
import 'images.dart';
import 'level_badge.dart';
import 'labels.dart';
import 'socket.dart';
import 'theme.dart';

/// "Drops: Goblin hide, ??? · 1 of 2 found": only what the player has found,
/// no chances (spec 0006 §2.2).
String dropsLine(Game game, GameState s, Labels labels, String enemy) {
  final all = game.dropItems(enemy);
  final found = game.foundDrops(s, enemy);
  final names = [
    for (final item in all) found.contains(item) ? labels.item(item) : '???',
  ];
  return 'Drops: ${names.join(', ')} · ${found.length} of ${all.length} found';
}

/// A tappable row for one action; the running one is marked Active.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.controller,
    required this.activity,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.badge,
    this.enabled = true,
    this.deadly = false,
    this.titleIsName = true,
    this.startFrom,
  });

  final GameController controller;
  final Activity activity;
  final Widget leading;
  final String title;
  final Widget subtitle;

  /// Shown before [title] on its line: the level badge of a monster, when
  /// its picture leads the row.
  final Widget? badge;
  final bool enabled;
  final bool deadly;

  /// The title names a monster or a spot; false for a label, such as
  /// "Walk here".
  final bool titleIsName;

  /// Set in a sheet: the sheet closes, and the action starts from this
  /// screen's context instead.
  final BuildContext? startFrom;

  @override
  Widget build(BuildContext context) {
    final active = controller.state.activity?.activity == activity;
    return ListTile(
      key: ValueKey('option-${activity.kind.name}-${activity.target}'),
      leading: leading,
      title: switch (badge) {
        final badge? => Row(
          children: [
            badge,
            const SizedBox(width: 10),
            Flexible(child: Text(title)),
          ],
        ),
        null => Text(title),
      },
      titleTextStyle: titleIsName ? nameStyle(context) : null,
      subtitle: subtitle,
      enabled: enabled,
      trailing: active ? statusChip('Active', Quiet.steel) : null,
      onTap: active || !enabled
          ? null
          : () {
              final from = startFrom;
              if (from != null) Navigator.pop(context);
              startAction(
                from ?? context,
                controller,
                activity,
                deadly: deadly,
              );
            },
    );
  }
}

/// A row for fighting [enemy]: its picture, then its level badge and name,
/// stats once learned (spec 0009 §7.1), XP, and for red or skull monsters a
/// warning first (spec 0002 §9.2). The steps of a round stand in the
/// heading above the rows (spec 0014 §4.1).
Widget enemyTile(
  GameController c,
  String enemy, {
  String? drops,
  BuildContext? startFrom,
}) {
  final game = c.game;
  final e = game.data.enemies[enemy]!;
  final band = game.enemyBand(c.state, enemy);
  final known = game.knowledge(c.state, enemy).stats;
  return ActionTile(
    controller: c,
    activity: Activity.fight(enemy),
    // The row starts with the monster in a 48 dp socket (spec 0014 §2.3,
    // §4.2).
    leading: Builder(
      builder: (context) => PictureSocket(
        picture: ImageScope.of(context)
            .pictureOf(game.data, MonsterThing(enemy)),
        size: 48,
      ),
    ),
    badge: LevelBadge(level: e.level, colour: band.colour),
    title: Labels(game.data).enemy(enemy),
    subtitle: Text.rich(
      TextSpan(
        children: [
          // Only the word "Risky" is in its colour (spec 0014 §2.1).
          if (band.colour == LevelColour.orange) ...const [
            TextSpan(
              text: 'Risky',
              style: TextStyle(color: Quiet.risky),
            ),
            TextSpan(text: ' · '),
          ],
          TextSpan(
            text:
                [
                  if (known) ...[
                    'HP ${e.stats.hp} · Atk ${e.stats.attack} · Def ${e.stats.defense}',
                    if (e.traits.isNotEmpty)
                      e.traits.map((t) => _traitName[t]).join(', '),
                  ] else
                    'Stats unknown',
                  '${math.max(1, e.xp * band.xpPercent ~/ 100)} XP',
                ].join(' · ') +
                (drops == null ? '' : '\n$drops'),
          ),
        ],
      ),
    ),
    deadly: band.colour == LevelColour.red || band.colour == LevelColour.skull,
    startFrom: startFrom,
  );
}

const _traitName = {
  Trait.quick: 'Quick',
  Trait.slow: 'Slow',
  Trait.ghostly: 'Ghostly',
  Trait.regenerates: 'Regenerates',
};

/// A row for gathering at [node]: its picture, then its level badge and
/// name.
Widget nodeTile(GameController c, String node, {BuildContext? startFrom}) {
  final game = c.game;
  final n = game.data.nodes[node]!;
  final labels = Labels(game.data);
  return ActionTile(
    controller: c,
    activity: Activity.gather(node),
    // The row starts with the spot in a 48 dp socket, as a monster row
    // (spec 0014 amendment 1).
    leading: Builder(
      builder: (context) => PictureSocket(
        picture: ImageScope.of(context).pictureOf(game.data, SpotThing(node)),
        size: 48,
      ),
    ),
    badge: LevelBadge(
      key: ValueKey('spot-level-$node'),
      level: n.level,
      colour: professionColour(
        game,
        c.state,
        n.profession,
        n.level,
        open: game.nodeLevelMet(c.state, node),
      ),
    ),
    title: labels.node(node),
    enabled: game.nodeLevelMet(c.state, node),
    // Spots pay profession XP (spec 0010 §2.2).
    // A water or trail rolls its catch (spec 0011 §3.2, §4).
    subtitle: Text(
      game.lockedReason(c.state, Activity.gather(node)) ??
          '${game.professionSteps(c.state, n.profession, n.steps)} steps per '
              '${n.catches.isEmpty
                  ? labels.item(n.item)
                  : n.profession == 'fishing'
                  ? 'cast'
                  : 'hunt'} · '
              '${game.professionXpFor(c.state, n.profession, n.level, n.xp)} '
              '${game.data.professions[n.profession]!.name} XP',
    ),
    startFrom: startFrom,
  );
}

/// The colour of a spot or recipe whose XP fades by [level] of
/// [profession] (spec 0010 §2.3): its fade band, like a monster's, or red
/// while it isn't [open] to the player.
LevelColour professionColour(
  Game game,
  GameState s,
  String profession,
  int level, {
  required bool open,
}) => open
    ? game.data
          .professionBandFor(level, game.professionLevel(s, profession))
          .colour
    : LevelColour.red;

/// Starts or queues [a]: a warning first for [deadly] fights, then from 2
/// queue slots the stop condition sheet (spec 0003 §8).
Future<void> startAction(
  BuildContext context,
  GameController c,
  Activity a, {
  bool deadly = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final showNow = ShowNow.maybeOf(context);
  if (deadly) {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deadly'),
        content: const Text('You will almost certainly lose.'),
        actions: [
          TextButton(
            style: ghostButton,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fight anyway'),
          ),
        ],
      ),
    );
    if (go != true) return;
  }
  if (!context.mounted) return;
  try {
    // The player picks a stop condition and whether to start now or
    // queue it (the queue has at least 2 slots: spec 0016 §2).
    final choice = await showModalBottomSheet<(StopCondition, bool)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ActionSheet(controller: c, activity: a),
    );
    if (choice == null) return;
    final (stop, now) = choice;
    if (now) {
      await c.startActivity(a, stop: stop);
      showNow?.call();
      return;
    }
    // The player stays to plan more, so say what went in.
    final labels = Labels(c.game.data);
    final before = c.state.queue.length;
    await c.addAction(a, stop: stop);
    final s = c.state;
    final walk = s.queue.length - before == 2
        ? 'a walk to ${labels.location(s.queue[s.queue.length - 2].activity.target)}, then '
        : '';
    final name = labels.short(a);
    final added = walk.isEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : '$walk$name';
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Added to the queue: $added '
            '(${1 + s.queue.length} of ${c.game.queueSlots(s)}).',
          ),
        ),
      );
  } on ActivityError catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Brings the player to Now once an action starts (playtest 3), from any
/// screen below the bottom bar.
class ShowNow extends InheritedWidget {
  const ShowNow({super.key, required this.show, required super.child});

  final VoidCallback show;

  static VoidCallback? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShowNow>()?.show;

  @override
  bool updateShouldNotify(ShowNow oldWidget) => false;
}

/// A section heading in a screen's list, in small caps with a hairline after
/// it (spec 0014 §2.2).
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 14, 4, 0),
    child: Row(
      children: [
        Text(text, style: headingStyle(context)),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

/// The one heading above the monster rows, on Now and on the area sheet:
/// "Monsters · 10 steps per round" (spec 0014 §4.1). It is a list heading,
/// so its number keeps the font of the phrase.
class MonstersHeading extends StatelessWidget {
  const MonstersHeading({super.key, required this.data});

  final GameData data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Text(
      'Monsters · ${data.combatRoundSteps} steps per round',
      style: headingStyle(context),
    ),
  );
}
