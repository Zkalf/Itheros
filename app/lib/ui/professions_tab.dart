import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'item_card.dart';
import 'item_square.dart';
import 'labels.dart';
import 'level_badge.dart';

/// Professions (spec 0010 §8.1): one card per profession with its level,
/// progress, tier, tool and where to practise. Crafting's card holds the
/// forge and every recipe, in tier order.
class ProfessionsTab extends StatelessWidget {
  const ProfessionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final p in c.game.data.professions.values)
          _ProfessionCard(controller: c, profession: p),
      ],
    );
  }
}

class _ProfessionCard extends StatelessWidget {
  const _ProfessionCard({required this.controller, required this.profession});

  final GameController controller;
  final ProfessionDef profession;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final data = game.data;
    final s = c.state;
    final p = profession;
    final text = Theme.of(context).textTheme;
    final learned = s.learned.contains(p.id);
    final level = game.professionLevel(s, p.id);
    final xp = s.professions[p.id] ?? 0;
    final floor = data.professionXpForLevel(level);
    final next = data.professionXpForLevel(level + 1);

    final rows = <Widget>[
      Row(
        children: [
          Icon(professionIcon(p.icon)),
          const SizedBox(width: 8),
          Text(p.name, style: text.titleLarge),
          const Spacer(),
          if (learned) Text('Level $level', style: text.titleMedium),
        ],
      ),
      const SizedBox(height: 8),
      if (!learned)
        Text('Learn from ${p.teacher.name} in camp')
      else ...[
        Row(
          children: [
            Text(p.tierAt(level).name, style: text.titleSmall),
            const Spacer(),
            Text('${fmt(xp)} / ${fmt(next)} XP', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ((xp - floor) / (next - floor)).clamp(0, 1).toDouble(),
        ),
        const SizedBox(height: 8),
        _toolRow(context),
        ..._practise(context),
      ],
    ];
    return Card(
      key: ValueKey('profession-${p.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }

  /// The worn tool in its quality colour and its step cost; tap for its
  /// card.
  Widget _toolRow(BuildContext context) {
    final c = controller;
    final labels = Labels(c.game.data);
    final tool = c.state.tools[profession.id];
    if (tool == null) {
      return Text('No ${profession.toolName.toLowerCase()}');
    }
    return InkWell(
      onTap: () => showItemCard(context, c, tool, toolWorn: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '${labels.plain(tool)} · ${labels.stepShare(tool)}% steps',
          style: TextStyle(color: itemColour(c.game.data, tool)),
        ),
      ),
    );
  }

  /// Where to practise: the best open spot for the level, with Go there;
  /// for Crafting the nearest forge and the recipes.
  List<Widget> _practise(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    if (profession.id == 'crafting') {
      final forge = game.nearestForge(s);
      final recipes = game.allRecipes()
        ..sort(
          (a, b) => game.data.recipes[a]!.craftingLevel.compareTo(
            game.data.recipes[b]!.craftingLevel,
          ),
        );
      return [
        ListTile(
          key: const ValueKey('forge'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_fire_department),
          title: Text(switch (forge) {
            (final at, 0) => 'At the forge (${labels.location(at)})',
            (final at, final d) =>
              'Nearest forge: ${labels.location(at)} · '
                  '${fmt(d)} steps away',
            null => 'No forge within reach',
          }),
          subtitle: forge == null || forge.$2 == 0
              ? null
              : const Text('Crafting walks you there first.'),
        ),
        for (final id in recipes) _RecipeTile(controller: c, recipe: id),
      ];
    }
    final level = game.professionLevel(s, profession.id);
    NodeDef? best;
    for (final n in game.data.nodes.values) {
      if (n.profession == profession.id &&
          n.level <= level &&
          !game.nodeFogged(s, n.id) &&
          (best == null || n.level > best.level)) {
        best = n;
      }
    }
    if (best == null) return const [];
    final spot = best;
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: LevelBadge(
          level: spot.level,
          colour: professionColour(
            game,
            s,
            profession.id,
            spot.level,
            open: true,
          ),
        ),
        title: Text('${spot.name} · ${labels.homeOf(spot.id)}'),
        subtitle: const Text('Where to practise'),
        trailing: FilledButton.tonal(
          key: ValueKey('go-${profession.id}'),
          onPressed: () => startAction(context, c, Activity.gather(spot.id)),
          child: const Text('Go there'),
        ),
      ),
    ];
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.controller, required this.recipe});

  final GameController controller;
  final String recipe;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final r = game.data.recipes[recipe]!;
    final out = game.data.items[r.output]!;
    final short = Theme.of(context).colorScheme.error;
    final active = s.activity?.activity == Activity.craft(recipe);
    // With 3 queue slots a craft can always be queued before its materials
    // are gathered (spec 0003 §4, spec 0008 decision 7); only its Crafting
    // level holds it back (spec 0010 §2.2).
    final levelMet = game.recipeLevelMet(s, recipe);
    final kind = [
      ...labels.bonus(out.bonus),
      if (out.slot case final slot?) labels.slot(slot),
      if (out.tool != null) labels.toolLine(out.id),
    ].join(' · ');
    return ListTile(
      key: ValueKey('option-craft-$recipe'),
      contentPadding: EdgeInsets.zero,
      leading: LevelBadge(
        level: r.craftingLevel,
        // Its XP fades by the recipe's level (spec 0010 §2.3).
        colour: professionColour(
          game,
          s,
          r.profession,
          r.level,
          open: levelMet,
        ),
      ),
      enabled: levelMet,
      title: Text(labels.recipe(recipe)),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$kind\n'),
            for (final (i, e) in r.inputs.entries.indexed) ...[
              if (i > 0) const TextSpan(text: ', '),
              TextSpan(
                text:
                    '${labels.item(e.key)} ${s.inventory[e.key] ?? 0}/${e.value}',
                style: (s.inventory[e.key] ?? 0) < e.value
                    ? TextStyle(color: short)
                    : null,
              ),
            ],
            TextSpan(
              text: levelMet
                  ? ' · ${game.professionSteps(s, r.profession, r.steps)} '
                        'steps · '
                        '${game.professionXpFor(s, r.profession, r.level, r.xp)} '
                        'Crafting XP'
                  : ' · ${game.lockedReason(s, Activity.craft(recipe))}',
            ),
          ],
        ),
      ),
      trailing: active ? const Chip(label: Text('Active')) : null,
      onTap: active || !levelMet
          ? null
          : () => startAction(context, c, Activity.craft(recipe)),
    );
  }
}
