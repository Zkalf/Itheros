import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'away_summary_card.dart';
import 'controller_scope.dart';
import '../version.dart';
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
        const SizedBox(height: 16),
        Text('Equipment', style: text.titleMedium),
        // Worn slots only, until the paper doll (plan 0010 M3).
        for (final slot in game.data.gearSlots.map((g) => g.id))
          if (s.equipment.containsKey(slot))
            ListTile(
              leading: Icon(_slotIcons[slot] ?? Icons.checkroom),
              title: switch (s.equipment[slot]) {
                final key? => _name(context, game.data, labels, key),
                null => const Text('Empty'),
              },
              subtitle: Text(
                [
                  labels.slot(slot),
                  if (s.equipment[slot] case final key?)
                    ..._bonusParts(game.data, key),
                ].join(' · '),
              ),
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
        // Gear, then materials (spec 0006 §2.4); each in data order, then
        // quality order, so rows don't move when something is equipped
        // (spec 0005 §5).
        for (final gear in [true, false]) ...[
          if (s.inventory.keys.any(
            (k) => (game.data.itemOf(k)?.slot != null) == gear,
          ))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                gear ? 'Gear' : 'Materials',
                key: ValueKey(gear ? 'heading-gear' : 'heading-materials'),
                style: text.titleSmall,
              ),
            ),
          for (final key in [
            for (final item in game.data.items.values)
              if ((item.slot != null) == gear)
                for (final q in game.data.qualities)
                  game.data.keyFor(item.id, q.id),
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
        const SizedBox(height: 16),
        Text('Settings', style: text.titleMedium),
        SwitchListTile(
          key: const ValueKey('show-next-goal'),
          title: const Text('Show "Next goal"'),
          value: !c.nextGoalHidden,
          onChanged: (show) => c.setNextGoalHidden(!show),
        ),
        // Friends quote it when they report something (spec 0007 §7).
        ListTile(
          key: const ValueKey('version'),
          title: Text('Version $appVersion', style: text.bodySmall),
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
    return Text(_bonusParts(data, key).join(' · '));
  }

  /// "+4 Defense", "+14 HP": a gear key's stats, quality included.
  static List<String> _bonusParts(GameData data, String key) =>
      Labels(data).bonus(data.bonusOf(key));

  static const _slotIcons = {
    'mainHand': Icons.gavel,
    'chest': Icons.checkroom,
    'offHand': Icons.shield,
    'head': Icons.face,
    'boots': Icons.hiking,
    'neck': Icons.diamond,
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
/// decision 5), in owner builds only (spec 0007 §4).
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
    if (!c.testWalkAllowed) return;
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
