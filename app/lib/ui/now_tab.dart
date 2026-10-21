import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'away_summary_card.dart';
import 'controller_scope.dart';
import 'labels.dart';

/// What am I doing, and what can I do here (spec 0008 §3.2): the running
/// action, the queue, the step bank, then what the player's place offers.
class NowTab extends StatelessWidget {
  const NowTab({super.key, this.onOpenWorld, this.onOpenProfessions});

  /// Shows the World map, from the resting card.
  final VoidCallback? onOpenWorld;

  /// Shows Professions, from the Forge row.
  final VoidCallback? onOpenProfessions;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final labels = Labels(c.game.data);
    return RefreshIndicator(
      onRefresh: c.syncNow,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          _QueueCard(controller: c, labels: labels, onOpenWorld: onOpenWorld),
          _Here(
            controller: c,
            labels: labels,
            onOpenProfessions: onOpenProfessions,
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
}

/// "Next goal" (spec 0002 §9.3). It can be hidden from level 1 (spec 0008
/// decision 9), and turned back on in Settings.
class _NextGoal extends StatelessWidget {
  const _NextGoal({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    // Hideable from level 1 (spec 0008 decision 9).
    if (controller.nextGoalHidden) return const SizedBox.shrink();
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
            yourLevel: switch (goal) {
              FightGoal(:final enemy) =>
                game.data.enemies[enemy]!.level == game.level(s),
              _ => false,
            },
          ),
        ),
        trailing: TextButton(
          onPressed: () => controller.setNextGoalHidden(true),
          child: const Text('Hide'),
        ),
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
            const SizedBox(height: 8),
            Text(
              'Walked today: ${fmt(controller.stepsToday)}',
              key: const ValueKey('walked-today'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The running action and the ones waiting after it (spec 0003 §8).
class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.controller,
    required this.labels,
    this.onOpenWorld,
  });

  final GameController controller;
  final Labels labels;
  final VoidCallback? onOpenWorld;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final run = s.activity;
    final text = Theme.of(context).textTheme;
    final slots = game.queueSlots(s);

    final List<Widget> body;
    if (run == null) {
      // Spec 0008 §3.2 (replaces spec 0006 amendment 3).
      body = [
        Text('Resting', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Your steps go to the step bank. Pick something to do below, or on '
          'the World map.${slots > 1 ? ' Plan up to $slots actions; each starts '
                    'when the one before it stops.' : ''}',
        ),
        const SizedBox(height: 8),
        if (onOpenWorld != null)
          FilledButton.tonalIcon(
            key: const ValueKey('open-world'),
            onPressed: onOpenWorld,
            icon: const Icon(Icons.map),
            label: const Text('Open the World map'),
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
              owned: run.stop.kind == StopKind.untilHave
                  ? game.owned(s, run.stop.item!)
                  : 0,
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
        if (run.log.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            key: const ValueKey('fight-log'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in run.log)
                Text(
                  labels.round(r, run.activity.target),
                  style: text.bodySmall,
                ),
            ],
          ),
        ],
        if (run.won + run.lost > 0 || run.gained.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('So far', style: text.titleSmall),
          if (run.won + run.lost > 0)
            Text(
              '${fmt(run.won)} won · ${fmt(run.lost)} lost',
              key: const ValueKey('tally-fights'),
            ),
          if (run.gained.isNotEmpty)
            KeyedSubtree(
              key: const ValueKey('tally-items'),
              child: reportLine(
                labels.counts(_ordered(run.gained), labels.owned),
                labels,
              ),
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

  /// [gained] in item data order, then quality order, like the inventory.
  /// Items of the same quality count together, whatever their bonus stats
  /// (rows show none: spec 0009 §8.2).
  Map<String, int> _ordered(Map<String, int> gained) {
    final data = controller.game.data;
    final byPlain = <String, int>{};
    gained.forEach((key, n) {
      final plain = data.plainKey(key);
      byPlain[plain] = (byPlain[plain] ?? 0) + n;
    });
    return {
      for (final id in data.items.keys)
        for (final q in data.qualities)
          data.keyFor(id, q.id): ?byPlain[data.keyFor(id, q.id)],
    };
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

/// Everything the player's place offers (spec 0008 §3.2): its monsters and
/// gathering spots, and a Forge row where there is one. No Camp screen.
class _Here extends StatelessWidget {
  const _Here({
    required this.controller,
    required this.labels,
    this.onOpenProfessions,
  });

  final GameController controller;
  final Labels labels;
  final VoidCallback? onOpenProfessions;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final place = game.data.locations[s.location]!;
    final enemies = game.availableEnemies(s);
    final nodes = game.availableNodes(s);
    return Column(
      key: const ValueKey('here'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Heading('Here: ${labels.location(s.location)}'),
        for (final id in enemies)
          enemyTile(c, id, drops: dropsLine(game, s, labels, id)),
        for (final id in nodes) nodeTile(c, id),
        if (place.crafting && onOpenProfessions != null)
          ListTile(
            key: const ValueKey('here-forge'),
            leading: const Icon(Icons.local_fire_department),
            title: const Text('Forge'),
            subtitle: const Text('Craft gear in Professions'),
            onTap: onOpenProfessions,
          ),
        if (enemies.isEmpty && nodes.isEmpty && !place.crafting)
          const ListTile(title: Text('Nothing to do here. Try the World map.')),
      ],
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
