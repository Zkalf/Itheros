import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'action_sheet.dart';
import 'level_badge.dart';
import 'labels.dart';

/// [xp] for something at [level], as the player would get it now.
int fadedXp(int xp, int level, Game game, GameState s) =>
    math.max(1, xp * game.data.bandFor(level, game.level(s)).xpPercent ~/ 100);

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
  final String subtitle;
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
      subtitle: Text(subtitle),
      enabled: enabled,
      trailing: active ? const Chip(label: Text('Active')) : null,
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
    subtitle:
        [
          if (band.colour == LevelColour.orange) 'Risky',
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
    leading: const Icon(Icons.landscape),
    title: labels.node(node),
    enabled: game.nodeLevelMet(c.state, node),
    subtitle: game.nodeLevelMet(c.state, node)
        ? '${n.steps} steps per ${labels.item(n.item)} · '
              '${fadedXp(n.xp, n.level, game, c.state)} XP'
        : 'Needs level ${n.level}',
    startFrom: startFrom,
  );
}

/// Starts or queues [a]: a warning first for [deadly] fights, then from 2
/// queue slots the stop condition sheet (spec 0003 §8).
Future<void> startAction(
  BuildContext context,
  GameController c,
  Activity a, {
  bool deadly = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (deadly) {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deadly'),
        content: const Text('You will almost certainly lose.'),
        actions: [
          TextButton(
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
  } on ActivityError catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// A section heading in a screen's list.
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
