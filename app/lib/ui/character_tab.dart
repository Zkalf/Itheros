import 'dart:async';

import 'package:flutter/material.dart';

import 'bag_grid.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'paper_doll.dart';
import 'socket.dart';
import 'text_size.dart';
import 'theme.dart';

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
    final rank = game.rank(level).name;
    final points = game.talentPoints(level);
    final text = Theme.of(context).textTheme;
    final who = s.character;

    return ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // The portrait next to the name (spec 0014 §4.2).
                    if (who != null) ...[
                      PictureSocket(
                        key: const ValueKey('character-portrait'),
                        picture: ImageScope.of(context).pictureOf(
                          game.data,
                          PlayerThing(who.origin, who.gender),
                        ),
                        size: 72,
                      ),
                      const SizedBox(width: 14),
                    ],
                    // Name, then rank · origin (spec 0012 §4.4).
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (who != null) ...[
                            Text(
                              who.name,
                              key: const ValueKey('character-name'),
                              style: text.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (who == null)
                            _RankTitle(rank)
                          else
                            _RankAndOrigin(
                              rank,
                              game.fill(
                                game.data.origins[who.origin]?.title ?? '',
                                who,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
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
        // The segments, the doll and the bag stand on plates (spec 0014
        // §2.2).
        Card(
          child: Padding(
            padding: const EdgeInsets.all(gutter),
            child: SegmentedButton<bool>(
              expandedInsets: EdgeInsets.zero,
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
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _bag ? BagGrid(controller: c) : PaperDoll(controller: c),
          ),
        ),
      ],
    );
  }
}

/// The rank, then "· origin" on the same line (spec 0012 §4.4). If the line
/// is too narrow for both, the origin shows on a line of its own below the
/// rank, without the dot. The origin is body text (spec 0014 §2.2).
class _RankAndOrigin extends StatelessWidget {
  const _RankAndOrigin(this.rank, this.origin);

  final String rank;
  final String origin;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final line = '· $origin';
    return LayoutBuilder(
      builder: (context, box) {
        final fits =
            textSizeOf(context, rank, _RankTitle.styleOf(context)).width +
                _RankTitle.gap +
                textSizeOf(context, line, style).width <=
            box.maxWidth;
        final title = _RankTitle(rank);
        final shown = Text(
          fits ? line : origin,
          key: const ValueKey('character-origin'),
          style: style,
        );
        return fits
            ? Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [title, shown],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, shown],
              );
      },
    );
  }
}

/// The rank name. Seven quick taps switch test walk on or off (spec 0004
/// decision 5), in owner builds only (spec 0007 §4).
class _RankTitle extends StatefulWidget {
  const _RankTitle(this.name);

  final String name;

  /// The space after the rank, before "· origin".
  static const gap = 6.0;

  /// The rank is teal (spec 0014 §2.1).
  static TextStyle? styleOf(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(color: Quiet.teal);

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
    unawaited(c.setTestWalk(on));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Test walk ${on ? 'on' : 'off'}')));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _tap,
    child: Padding(
      padding: const EdgeInsets.only(right: _RankTitle.gap),
      child: Text(widget.name, style: _RankTitle.styleOf(context)),
    ),
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
        // A stat value is a number that stands alone (spec 0014 §2.2).
        Text(
          value,
          style: text.headlineSmall?.copyWith(fontFamily: Fonts.number),
        ),
        Text(label, style: text.labelSmall?.copyWith(color: Quiet.muted)),
        if (meal > 0) Text('(+$meal meal)', style: text.bodySmall),
      ],
    );
  }
}
