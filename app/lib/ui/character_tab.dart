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
    final slots = {
      for (final i in game.data.items.values)
        if (i.slot != null) i.slot!,
    };
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('Level', '${game.level(s)}'),
                _Stat('HP', '${stats.hp}'),
                _Stat('Attack', '${stats.attack}'),
                _Stat('Defense', '${stats.defense}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Equipment', style: text.titleMedium),
        for (final slot in slots)
          ListTile(
            leading: Icon(slot == 'weapon' ? Icons.gavel : Icons.checkroom),
            title: Text(
              s.equipment[slot] == null
                  ? 'Empty'
                  : labels.item(s.equipment[slot]!),
            ),
            subtitle: Text(_capitalise(slot)),
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
        for (final e in s.inventory.entries)
          ListTile(
            title: Text(labels.item(e.key)),
            subtitle: _bonusText(game.data.items[e.key]),
            trailing: game.data.items[e.key]?.slot == null
                ? Text('×${e.value}')
                : FilledButton.tonal(
                    onPressed: () => _run(context, () => c.equip(e.key)),
                    child: Text('Equip (×${e.value})'),
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

  static String _capitalise(String s) => s[0].toUpperCase() + s.substring(1);

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
