import 'package:flutter/material.dart';

import 'bag_grid.dart';
import 'controller_scope.dart';
import 'paper_doll.dart';

/// Who am I (spec 0008 §3.5): level, stats and rank above two small tabs,
/// Gear (the paper doll) and Bag. Talents join them with their spec.
/// Equipping costs no steps.
class CharacterTab extends StatefulWidget {
  const CharacterTab({super.key});

  @override
  State<CharacterTab> createState() => _CharacterTabState();
}

class _CharacterTabState extends State<CharacterTab> {
  var _bag = false;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final stats = game.stats(s);
    // The meal's share, marked on its stats (spec 0011 §8.3).
    final meal = game.mealBonus(s);
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
                    _Stat('HP', '${stats.hp}', meal: meal.hp),
                    _Stat('Attack', '${stats.attack}', meal: meal.attack),
                    _Stat('Defense', '${stats.defense}', meal: meal.defense),
                  ],
                ),
                const SizedBox(height: 12),
                // Spec 0009 §2.2: with base Crit, each within its cap.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat('Crit', '${game.critChance(s)}%', meal: meal.crit),
                    _Stat('Hit', '${stats.hit}%'),
                    _Stat('Dodge', '${game.dodgeChance(s)}%'),
                    _Stat('Block', '${game.blockChance(s)}%'),
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
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Gear', key: ValueKey('tab-gear')),
              icon: Icon(Icons.accessibility_new),
            ),
            ButtonSegment(
              value: true,
              label: Text('Bag', key: ValueKey('tab-bag')),
              icon: Icon(Icons.backpack),
            ),
          ],
          selected: {_bag},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _bag = v.single),
        ),
        const SizedBox(height: 16),
        if (_bag) BagGrid(controller: c) else PaperDoll(controller: c),
      ],
    );
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
  const _Stat(this.label, this.value, {this.meal = 0});

  final String label;
  final String value;

  /// What the running meal adds, shown as "(+2 meal)".
  final int meal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      key: ValueKey('stat-$label'),
      children: [
        Text(value, style: text.headlineSmall),
        Text(label, style: text.bodySmall),
        if (meal > 0) Text('(+$meal meal)', style: text.bodySmall),
      ],
    );
  }
}
