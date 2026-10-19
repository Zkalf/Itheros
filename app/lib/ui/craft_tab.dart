import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'labels.dart';

/// Every unlocked recipe with what it gives and needs, and where the forge
/// is (spec 0006 §2.3).
class CraftTab extends StatelessWidget {
  const CraftTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final recipes = game.unlockedRecipes(s);
    final forge = game.nearestForge(s);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            key: const ValueKey('forge'),
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
        ),
        for (final id in recipes) _RecipeTile(controller: c, recipe: id),
      ],
    );
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
    // From 2 slots a craft can be queued before its materials are
    // gathered (spec 0003 §4).
    final enabled = game.hasMaterials(s, recipe) || game.queueSlots(s) > 1;
    return ListTile(
      key: ValueKey('option-craft-$recipe'),
      leading: const Icon(Icons.handyman),
      enabled: enabled,
      title: Text(labels.recipe(recipe)),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  '${[...labels.bonus(out.bonus), if (out.slot case final slot?) labels.slot(slot)].join(' · ')}\n',
            ),
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
              text:
                  ' · ${r.steps} steps · '
                  '${fadedXp(r.xp, r.unlockLevel, game, s)} XP',
            ),
          ],
        ),
      ),
      trailing: active ? const Chip(label: Text('Active')) : null,
      onTap: active || !enabled
          ? null
          : () => startAction(context, c, Activity.craft(recipe)),
    );
  }
}
