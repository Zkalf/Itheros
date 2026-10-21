import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'labels.dart';
import 'level_badge.dart';

/// Opens [enemy]'s bestiary card on its own (from the Bestiary tab).
Future<void> showBestiaryCard(
  BuildContext context,
  GameController c,
  String enemy,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BestiaryCard(controller: c, enemy: enemy),
    ),
  ),
);

/// What the player knows about [enemy] (spec 0009 §7.1, §8.3): always its
/// name, level, area, flavour and found drops; its armour after the first
/// fight, its weakness and stats after 10 kills (or from a lore note), the
/// Slayer mark at 50. What isn't known yet shows "???". Never drop chances.
class BestiaryCard extends StatelessWidget {
  const BestiaryCard({
    super.key,
    required this.controller,
    required this.enemy,
  });

  final GameController controller;
  final String enemy;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final text = Theme.of(context).textTheme;
    final e = game.data.enemies[enemy]!;
    final k = game.knowledge(s, enemy);
    final c0 = game.data.combat;

    final next = switch (k.killsToNext) {
      null => null,
      final n when !k.stats =>
        '${plural(n, 'more kill')} to learn its '
            '${k.weakness ? 'stats' : 'weakness'}',
      final n => '${plural(n, 'more kill')} for Slayer',
    };

    return Column(
      key: const ValueKey('bestiary-card'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LevelBadge(level: e.level, colour: game.enemyBand(s, enemy).colour),
            const SizedBox(width: 12),
            Expanded(child: Text(labels.enemy(enemy), style: text.titleLarge)),
            if (k.slayer)
              Chip(
                avatar: const Icon(Icons.gps_fixed, size: 16),
                label: Text('Slayer: +${c0.slayerHit}% Hit'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(labels.homeOf(enemy), style: text.bodySmall),
        if (e.flavour case final f?) ...[
          const SizedBox(height: 8),
          Text(f, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 8),
        Text(dropsLine(game, s, labels, enemy)),
        const SizedBox(height: 8),
        Text(k.armour ? labels.armour(e.armour) : 'Armour: ???'),
        Text(k.weakness ? 'Weak to ${game.weakness(enemy)}' : 'Weakness: ???'),
        if (k.stats) ...[
          Text(
            [
              'HP ${e.stats.hp}',
              'Attack ${e.stats.attack}',
              'Defense ${e.stats.defense}',
              if (e.stats.dodge > 0) 'Dodge ${e.stats.dodge}%',
            ].join(' · '),
          ),
          for (final t in e.traits) Text(labels.trait(t)),
        ] else
          const Text('Stats: ???'),
        const SizedBox(height: 8),
        Text(
          [plural(k.kills, 'kill'), ?next].join(' · '),
          style: text.bodySmall,
        ),
      ],
    );
  }
}
