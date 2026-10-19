import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'away_summary_card.dart';
import 'controller_scope.dart';
import 'labels.dart';
import 'action_sheet.dart';
import 'level_badge.dart';

/// Where you are, what you're doing, and what you can do here. Locked
/// content is hidden, not greyed out (spec 0001 §5).
class AdventureTab extends StatelessWidget {
  const AdventureTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    // Every open area, nearest first, so a day can be planned from anywhere
    // (spec 0003 §8).
    final areas = game.openLocationsByDistance(s);
    final recipes = game.unlockedRecipes(s);
    final destinations = game.travelDestinations(s);
    final current = s.activity?.activity;

    Widget option({
      required Activity activity,
      required Widget leading,
      required String title,
      required String subtitle,
      bool enabled = true,
      bool deadly = false,
    }) {
      final active = current == activity;
      return ListTile(
        key: ValueKey('option-${activity.kind.name}-${activity.target}'),
        leading: leading,
        title: Text(title),
        subtitle: Text(subtitle),
        enabled: enabled,
        trailing: active ? const Chip(label: Text('Active')) : null,
        onTap: active || !enabled
            ? null
            : () => _start(context, c, activity, deadly: deadly),
      );
    }

    return RefreshIndicator(
      onRefresh: c.syncNow,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (c.awaySummary case final summary?)
            AwaySummaryCard(
              summary: summary,
              labels: labels,
              onDismiss: c.dismissAwaySummary,
            ),
          if (c.syncError != null)
            const Card(
              child: ListTile(
                leading: Icon(Icons.sync_problem),
                title: Text("Couldn't read your steps"),
                subtitle: Text('Health Connect did not answer. Retrying.'),
              ),
            ),
          _StatusCard(controller: c, labels: labels),
          if (c.testWalkOn) _TestWalkCard(controller: c),
          _NextGoal(controller: c, labels: labels),
          _Discoveries(controller: c, labels: labels),
          _QueueCard(controller: c, labels: labels),
          for (final MapEntry(key: place, value: steps) in areas.entries)
            if ((game.enemiesAt(s, place), game.nodesAt(s, place))
                case (final enemies, final nodes)
                when enemies.isNotEmpty || nodes.isNotEmpty) ...[
              _Heading(
                '${labels.location(place)} · '
                '${steps == 0 ? 'here' : '${fmt(steps)} steps away'}',
              ),
              for (final id in enemies)
                if (game.enemyBand(s, id) case final band)
                  option(
                    activity: Activity.fight(id),
                    leading: LevelBadge(
                      level: game.data.enemies[id]!.level,
                      colour: band.colour,
                    ),
                    title: labels.enemy(id),
                    subtitle: _enemyText(
                      game.data.enemies[id]!,
                      band,
                      game.data,
                    ),
                    deadly:
                        band.colour == LevelColour.red ||
                        band.colour == LevelColour.skull,
                  ),
              for (final id in nodes)
                option(
                  activity: Activity.gather(id),
                  leading: const Icon(Icons.landscape),
                  title: labels.node(id),
                  subtitle:
                      '${game.data.nodes[id]!.steps} steps per '
                      '${labels.item(game.data.nodes[id]!.item)} · '
                      '${_faded(game.data.nodes[id]!.xp, game.data.nodes[id]!.unlockLevel, game, s)} XP',
                ),
            ],
          if (recipes.isNotEmpty)
            _Heading(
              game.data.locations[s.location]!.crafting
                  ? 'Craft · here'
                  : 'Craft · at the nearest camp or outpost',
            ),
          for (final id in recipes)
            option(
              activity: Activity.craft(id),
              leading: const Icon(Icons.handyman),
              title: labels.recipe(id),
              subtitle: _recipeText(game.data.recipes[id]!, s, game, labels),
              // From 2 slots a craft can be queued before its materials
              // are gathered (spec 0003 §4).
              enabled: game.hasMaterials(s, id) || game.queueSlots(s) > 1,
            ),
          if (destinations.isNotEmpty) const _Heading('Travel'),
          for (final id in destinations)
            option(
              activity: Activity.travel(id),
              leading: const Icon(Icons.signpost),
              title: labels.location(id),
              subtitle: '${fmt(game.data.route(s.location, id)!.steps)} steps',
            ),
          const SizedBox(height: 16),
          Text(
            'Steps arrive from Health Connect about once a minute. '
            'Pull down to check now.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _enemyText(EnemyDef e, LevelBand band, GameData data) => [
    if (band.colour == LevelColour.orange) 'Risky',
    'HP ${e.stats.hp} · Atk ${e.stats.attack} · Def ${e.stats.defense}',
    if (e.traits.isNotEmpty) e.traits.map((t) => _traitName[t]).join(', '),
    '${math.max(1, e.xp * band.xpPercent ~/ 100)} XP',
    '${data.combatRoundSteps} steps per round',
  ].join(' · ');

  static const _traitName = {
    Trait.quick: 'Quick',
    Trait.slow: 'Slow',
    Trait.ghostly: 'Ghostly',
    Trait.regenerates: 'Regenerates',
  };

  /// [xp] for something at [level], as the player would get it now.
  static int _faded(int xp, int level, Game game, GameState s) => math.max(
    1,
    xp * game.data.bandFor(level, game.level(s)).xpPercent ~/ 100,
  );

  static String _recipeText(
    RecipeDef r,
    GameState s,
    Game game,
    Labels labels,
  ) {
    final needs = r.inputs.entries
        .map(
          (e) => '${labels.item(e.key)} ${s.inventory[e.key] ?? 0}/${e.value}',
        )
        .join(', ');
    return 'Needs $needs · ${r.steps} steps · '
        '${_faded(r.xp, r.unlockLevel, game, s)} XP';
  }

  static Future<void> _start(
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
}

/// "Next goal" (spec 0002 §9.3). Always shown before level 10; from then
/// on it can be hidden, and turned back on in the Character tab.
class _NextGoal extends StatelessWidget {
  const _NextGoal({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final canHide = game.level(s) >= 10;
    if (canHide && controller.nextGoalHidden) return const SizedBox.shrink();
    final goal = game.nextGoal(s);
    if (goal == null) return const SizedBox.shrink();
    final grey = switch (goal) {
      CollectGoal(:final source) when source.kind == ActivityKind.fight =>
        game.enemyBand(s, source.target).colour == LevelColour.grey,
      _ => false,
    };
    return Card(
      key: const ValueKey('next-goal'),
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: const Text('Next goal'),
        subtitle: Text(
          labels.goal(
            goal,
            canCraftHere: game.data.locations[s.location]!.crafting,
            grey: grey,
          ),
        ),
        trailing: canHide
            ? TextButton(
                onPressed: () => controller.setNextGoalHidden(true),
                child: const Text('Hide'),
              )
            : null,
      ),
    );
  }
}

/// Flavour lines for the area and monsters here, the first time they're
/// seen (spec 0002 §9.5).
class _Discoveries extends StatelessWidget {
  const _Discoveries({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final here = game.data.locations[s.location]!;
    final lines = <String, String>{
      here.id: ?here.flavour,
      for (final id in game.availableEnemies(s))
        id: ?game.data.enemies[id]!.flavour,
    }..removeWhere((id, _) => controller.seen.contains(id));
    if (lines.isEmpty) return const SizedBox.shrink();
    return Card(
      key: const ValueKey('discoveries'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => controller.markSeen(lines.keys),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pretend steps for testing at home (spec 0004 §3). Shown while the
/// hidden switch on the Character tab is on.
class _TestWalkCard extends StatelessWidget {
  const _TestWalkCard({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('test-walk'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test walk', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Adds pretend steps, as if you walked them.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in const [100, 1000, 5000])
                FilledButton.tonal(
                  onPressed: () => controller.testWalk(n),
                  child: Text('+${fmt(n)}'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final level = game.level(s);
    final floor = game.data.xpForLevel(level);
    final next = game.xpForNextLevel(s);
    final cap = game.bankCap(s);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place),
                const SizedBox(width: 8),
                Text(labels.location(s.location), style: text.titleLarge),
                const Spacer(),
                Text('Level $level', style: text.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            _Bar(
              label: 'XP ${fmt(s.xp)} / ${fmt(next)}',
              value: (s.xp - floor) / (next - floor),
            ),
            const SizedBox(height: 12),
            _Bar(
              label: 'Step bank ${fmt(s.bank)} / ${fmt(cap)}',
              value: s.bank / cap,
            ),
            const SizedBox(height: 4),
            Text(
              'Steps walked while resting are saved here. During an '
              'activity, each step you walk uses one banked step and '
              'counts double.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// The running action and the ones waiting after it (spec 0003 §8).
class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final run = s.activity;
    final text = Theme.of(context).textTheme;
    final slots = game.queueSlots(s);

    final List<Widget> body;
    if (run == null) {
      body = [
        Text('Resting', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          slots == 1
              ? 'Pick something to do below. Until then, your steps go to '
                    'the step bank.'
              : 'Plan up to $slots actions below; each starts when the one '
                    'before it stops. Until then, your steps go to the step '
                    'bank.',
        ),
      ];
    } else {
      final cost = game.unitCost(s)!;
      final fight = run.fight;
      final enemyHp = run.activity.kind == ActivityKind.fight
          ? game.data.enemies[run.activity.target]!.stats.hp
          : 0;
      body = [
        Row(
          children: [
            Expanded(
              child: Text(
                labels.activity(run.activity),
                style: text.titleMedium,
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('stop-activity'),
              onPressed: () => _stop(context, 0),
              icon: const Icon(Icons.stop),
              label: Text(s.queue.isEmpty ? 'Stop' : 'Stop · next'),
            ),
          ],
        ),
        if (run.activity.kind != ActivityKind.travel)
          Text(
            labels.stop(
              run.stop,
              run.activity,
              owned: run.stop.item == null ? 0 : game.owned(s, run.stop.item!),
              crafted: run.crafted,
            ),
          ),
        const SizedBox(height: 8),
        _Bar(
          label: switch (run) {
            RunningActivity(:final leg?) =>
              'Walking to ${labels.location(leg)}: '
                  '${fmt(run.progress)} / ${fmt(cost)} steps',
            _ when run.activity.kind == ActivityKind.fight =>
              'Next round: ${run.progress} / $cost steps',
            _ => '${fmt(run.progress)} / ${fmt(cost)} steps',
          },
          value: run.progress / cost,
        ),
        if (fight != null) ...[
          const SizedBox(height: 8),
          _Bar(
            label: 'You: ${fight.playerHp} / ${game.stats(s).hp} HP',
            value: fight.playerHp / game.stats(s).hp,
          ),
          const SizedBox(height: 8),
          _Bar(
            label:
                '${labels.enemy(run.activity.target)}: '
                '${fight.enemyHp} / $enemyHp HP',
            value: fight.enemyHp / enemyHp,
          ),
        ],
        if (run.lossStreak > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Lost ${run.lossStreak} in a row; it gives up at '
            '${game.data.lossesToGiveUp}.',
            style: text.bodySmall,
          ),
        ],
        for (var i = 0; i < s.queue.length; i++)
          ListTile(
            key: ValueKey('queued-$i'),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 14, child: Text('${i + 2}')),
            title: Text(labels.short(s.queue[i].activity)),
            subtitle: Text(
              labels.stop(
                s.queue[i].stop,
                s.queue[i].activity,
                owned: s.queue[i].stop.item == null
                    ? 0
                    : game.owned(s, s.queue[i].stop.item!),
              ),
            ),
            trailing: IconButton(
              key: ValueKey('remove-${i + 1}'),
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
              onPressed: () => _stop(context, i + 1),
            ),
          ),
        if (slots > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${1 + s.queue.length} of $slots actions planned',
              style: text.bodySmall,
            ),
          ),
      ];
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: body,
        ),
      ),
    );
  }

  /// Removes the action at [index] (0: Stop) and says which waiting actions
  /// couldn't start after it.
  Future<void> _stop(BuildContext context, int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final skipped = await controller.removeAction(index);
    if (skipped.isEmpty) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          skipped
              .map((e) => labels.skipLine(e.activity, e.reason, e.missing))
              .join('\n'),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 4),
      LinearProgressIndicator(value: value.clamp(0, 1).toDouble()),
    ],
  );
}
