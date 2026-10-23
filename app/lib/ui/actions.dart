import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'action_sheet.dart';
import 'level_badge.dart';
import 'labels.dart';
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
    this.enabled = true,
    this.deadly = false,
    this.startFrom,
  });

  final GameController controller;
  final Activity activity;
  final Widget leading;
  final String title;
  final Widget subtitle;
  final bool enabled;
  final bool deadly;

  /// Set in a sheet: the sheet closes, and the action starts from this
  /// screen's context instead.
  final BuildContext? startFrom;

  @override
  Widget build(BuildContext context) {
    final active = controller.state.activity?.activity == activity;
    return ListTile(
      key: ValueKey('option-${activity.kind.name}-${activity.target}'),
      leading: leading,
      title: Text(title),
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

/// A row for fighting [enemy]: level badge, stats once learned (spec 0009
/// §7.1), XP, and for red or skull monsters a warning first (spec 0002
/// §9.2).
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
    leading: LevelBadge(level: e.level, colour: band.colour),
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
                  '${game.data.combatRoundSteps} steps per round',
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

/// A row for mining [node].
Widget nodeTile(GameController c, String node, {BuildContext? startFrom}) {
  final game = c.game;
  final n = game.data.nodes[node]!;
  final labels = Labels(game.data);
  return ActionTile(
    controller: c,
    activity: Activity.gather(node),
    leading: LevelBadge(
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
    // One slot: it starts at once, as before level 5 (spec 0003
    // decision 1). Otherwise the player picks a stop condition and
    // whether to start now or queue it.
    if (c.game.queueSlots(c.state) == 1) {
      await c.addAction(a);
      showNow?.call();
      return;
    }
    final choice = await showModalBottomSheet<(StopCondition, bool)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ActionSheet(controller: c, activity: a),
    );
    if (choice == null) return;
    final (stop, now) = choice;
    await (now ? c.startActivity(a, stop: stop) : c.addAction(a, stop: stop));
    if (now) showNow?.call();
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
