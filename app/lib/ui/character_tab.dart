import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'controller_scope.dart';
import 'labels.dart';

/// Stats, equipped gear and inventory. Equipping costs no steps.
class CharacterTab extends StatelessWidget {
  const CharacterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final stats = game.stats(s);
    final level = game.level(s);
    final points = game.talentPoints(level);
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(game.rank(level).name, style: text.titleLarge),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat('Level', '$level'),
                    _Stat('HP', '${stats.hp}'),
                    _Stat('Attack', '${stats.attack}'),
                    _Stat('Defense', '${stats.defense}'),
                  ],
                ),
                if (points > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$points talent point${points == 1 ? '' : 's'} waiting. '
                    'Talents arrive in a later update.',
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (level >= 10)
          SwitchListTile(
            key: const ValueKey('show-next-goal'),
            title: const Text('Show "Next goal"'),
            value: !c.nextGoalHidden,
            onChanged: (show) => c.setNextGoalHidden(!show),
          ),
        const SizedBox(height: 16),
        Text('Equipment', style: text.titleMedium),
        for (final slot in game.openSlots(s))
          ListTile(
            leading: Icon(_slotIcons[slot] ?? Icons.checkroom),
            title: Text(
              s.equipment[slot] == null
                  ? 'Empty'
                  : labels.item(s.equipment[slot]!),
            ),
            subtitle: Text(labels.slot(slot)),
            trailing: s.equipment[slot] == null
                ? null
                : TextButton(
                    onPressed: () => _run(context, () => c.unequip(slot)),
                    child: const Text('Remove'),
                  ),
          ),
        const SizedBox(height: 16),
        Text('Inventory', style: text.titleMedium),
        if (s.inventory.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nothing yet. Fight and gather to find things.'),
          ),
        // In data order, so rows don't move when something is equipped.
        for (final id in game.data.items.keys)
          if (s.inventory[id] case final count?)
            KeyedSubtree(
              key: ValueKey('inventory-$id'),
              child: ListTile(
                key: const ValueKey('inventory-item'),
                title: Text(labels.item(id)),
                subtitle: _bonusText(game.data.items[id]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('×$count'),
                    if (game.data.items[id]?.slot != null) ...[
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        key: ValueKey('equip-$id'),
                        onPressed: () => _run(context, () => c.equip(id)),
                        child: const Text('Equip'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }

  static Widget? _bonusText(ItemDef? item) {
    if (item == null || item.slot == null) return null;
    final b = item.bonus;
    return Text(
      [
        if (b.attack != 0) '+${b.attack} Attack',
        if (b.defense != 0) '+${b.defense} Defense',
        if (b.hp != 0) '+${b.hp} HP',
      ].join(' · '),
    );
  }

  static const _slotIcons = {
    'weapon': Icons.gavel,
    'body': Icons.checkroom,
    'shield': Icons.shield,
    'head': Icons.face,
    'feet': Icons.hiking,
    'amulet': Icons.diamond,
  };

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on ActivityError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: text.headlineSmall),
        Text(label, style: text.bodySmall),
      ],
    );
  }
}
