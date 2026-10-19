import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'away_summary_card.dart';
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
                _RankTitle(game.rank(level).name),
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
            title: switch (s.equipment[slot]) {
              final key? => _name(context, game.data, labels, key),
              null => const Text('Empty'),
            },
            subtitle: Text(labels.slot(slot)),
            trailing: s.equipment[slot] == null
                ? null
                : SizedBox(
                    width: _buttonWidth,
                    child: OutlinedButton(
                      onPressed: () => _run(context, () => c.unequip(slot)),
                      child: const Text('Remove'),
                    ),
                  ),
          ),
        const SizedBox(height: 16),
        Text('Inventory', style: text.titleMedium),
        if (s.inventory.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nothing yet. Fight and gather to find things.'),
          ),
        // In data order, then quality order, so rows don't move when
        // something is equipped (spec 0005 §5).
        for (final key in [
          for (final id in game.data.items.keys)
            for (final q in game.data.qualities) game.data.keyFor(id, q.id),
        ])
          if (s.inventory[key] case final count?)
            KeyedSubtree(
              key: ValueKey('inventory-$key'),
              child: ListTile(
                key: const ValueKey('inventory-item'),
                title: _name(context, game.data, labels, key),
                subtitle: _bonusText(game.data, key),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('×$count'),
                    const SizedBox(width: 12),
                    // Kept empty for materials, so every count lines up.
                    SizedBox(
                      width: _buttonWidth,
                      child: game.data.itemOf(key)?.slot == null
                          ? null
                          : FilledButton.tonal(
                              key: ValueKey('equip-$key'),
                              onPressed: () =>
                                  _run(context, () => c.equip(key)),
                              child: const Text('Equip'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  /// Equip and Remove share one width, so the buttons form a column.
  static const _buttonWidth = 104.0;

  /// An item's name: gear better than common in its quality's colour, common
  /// gear in full text colour, materials softer, so gear stands out.
  static Widget _name(
    BuildContext context,
    GameData data,
    Labels labels,
    String key,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final q = data.qualityOf(key);
    final colour = switch (data.itemOf(key)?.slot) {
      null => scheme.onSurfaceVariant,
      _ when q == data.qualities.first => scheme.onSurface,
      _ => qualityColour(q),
    };
    return Text(labels.owned(key), style: TextStyle(color: colour));
  }

  static Widget? _bonusText(GameData data, String key) {
    if (data.itemOf(key)?.slot == null) return null;
    final b = data.bonusOf(key);
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

/// The rank name. Seven quick taps switch test walk on or off (spec 0004
/// decision 5).
class _RankTitle extends StatefulWidget {
  const _RankTitle(this.name);

  final String name;

  @override
  State<_RankTitle> createState() => _RankTitleState();
}

class _RankTitleState extends State<_RankTitle> {
  static const _taps = 7;
  static const _gap = Duration(seconds: 2);

  var _count = 0;
  DateTime? _last;

  void _tap() {
    final now = DateTime.now();
    final last = _last;
    _count = last != null && now.difference(last) < _gap ? _count + 1 : 1;
    _last = now;
    if (_count < _taps) return;
    _count = 0;
    final c = ControllerScope.of(context);
    final on = !c.testWalkOn;
    c.setTestWalk(on);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Test walk ${on ? 'on' : 'off'}')));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _tap,
    child: Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
  );
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
