import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'away_summary_card.dart';
import 'controller_scope.dart';
import 'labels.dart';

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
    final enemies = game.availableEnemies(s);
    final nodes = game.availableNodes(s);
    final recipes = game.availableRecipes(s);
    final destinations = game.travelDestinations(s);
    final current = s.activity?.activity;

    Widget option({
      required Activity activity,
      required IconData icon,
      required String title,
      required String subtitle,
      bool enabled = true,
    }) {
      final active = current == activity;
      return ListTile(
        key: ValueKey('option-${activity.kind.name}-${activity.target}'),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        enabled: enabled,
        trailing: active
            ? const Chip(label: Text('Active'))
            : const Icon(Icons.chevron_right),
        onTap: active || !enabled ? null : () => _start(context, c, activity),
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
          _ActivityCard(controller: c, labels: labels),
          if (enemies.isNotEmpty) const _Heading('Fight'),
          for (final id in enemies)
            option(
              activity: Activity.fight(id),
              icon: Icons.sports_kabaddi,
              title: labels.enemy(id),
              subtitle: _enemyText(game.data.enemies[id]!, game.data),
            ),
          if (nodes.isNotEmpty) const _Heading('Gather'),
          for (final id in nodes)
            option(
              activity: Activity.gather(id),
              icon: Icons.landscape,
              title: labels.node(id),
              subtitle:
                  '${game.data.nodes[id]!.steps} steps per '
                  '${labels.item(game.data.nodes[id]!.item)} · '
                  '${game.data.nodes[id]!.xp} XP',
            ),
          if (recipes.isNotEmpty) const _Heading('Craft'),
          for (final id in recipes)
            option(
              activity: Activity.craft(id),
              icon: Icons.handyman,
              title: labels.recipe(id),
              subtitle: _recipeText(game.data.recipes[id]!, s, labels),
              enabled: game.hasMaterials(s, id),
            ),
          if (destinations.isNotEmpty) const _Heading('Travel'),
          for (final id in destinations)
            option(
              activity: Activity.travel(id),
              icon: Icons.signpost,
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

  static String _enemyText(EnemyDef e, GameData data) =>
      'HP ${e.stats.hp} · Atk ${e.stats.attack} · Def ${e.stats.defense} · '
      '${e.xp} XP · ${data.combatRoundSteps} steps per round';

  static String _recipeText(RecipeDef r, GameState s, Labels labels) {
    final needs = r.inputs.entries
        .map(
          (e) => '${labels.item(e.key)} ${s.inventory[e.key] ?? 0}/${e.value}',
        )
        .join(', ');
    return 'Needs $needs · ${r.steps} steps · ${r.xp} XP';
  }

  static Future<void> _start(
    BuildContext context,
    GameController c,
    Activity a,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await c.startActivity(a);
    } on ActivityError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
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
              label: next == null
                  ? 'XP ${fmt(s.xp)} (max level)'
                  : 'XP ${fmt(s.xp)} / ${fmt(next)}',
              value: next == null ? 1 : (s.xp - floor) / (next - floor),
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final run = s.activity;
    final text = Theme.of(context).textTheme;

    final List<Widget> body;
    if (run == null) {
      body = [
        Text('Resting', style: text.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Pick something to do below. Until then, your steps go '
          'to the step bank.',
        ),
      ];
    } else {
      final cost = game.unitCost(s)!;
      final fight = run.fight;
      body = [
        Text(labels.activity(run.activity), style: text.titleMedium),
        const SizedBox(height: 8),
        _Bar(
          label: run.activity.kind == ActivityKind.fight
              ? 'Next round: ${run.progress} / $cost steps'
              : '${fmt(run.progress)} / ${fmt(cost)} steps',
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
                '${fight.enemyHp} / '
                '${game.data.enemies[run.activity.target]!.stats.hp} HP',
            value:
                fight.enemyHp /
                game.data.enemies[run.activity.target]!.stats.hp,
          ),
        ],
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
