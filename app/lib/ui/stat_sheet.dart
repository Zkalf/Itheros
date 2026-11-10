import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'theme.dart';

/// The stats of the Character tab's stats block that open a sheet (spec 0009
/// amendment 4, rule 3). Level has none.
enum StatKind {
  hp('HP'),
  attack('Attack'),
  defense('Defense'),
  crit('Crit'),
  hit('Hit'),
  dodge('Dodge'),
  block('Block');

  const StatKind(this.label);

  /// The label in the stats block, and the title of the sheet.
  final String label;

  bool get _percent => index >= crit.index;

  int _of(Stats s) => switch (this) {
    hp => s.hp,
    attack => s.attack,
    defense => s.defense,
    crit => s.crit,
    hit => s.hit,
    dodge => s.dodge,
    block => s.block,
  };
}

/// One line of where a stat comes from: its source and its words.
typedef StatSource = ({String id, String line});

/// What the sheet of a stat says (spec 0009 amendment 4, rules 4-9).
class StatInfo {
  StatInfo(Game game, GameState s, this.kind)
    : number = _number(game, s, kind),
      does = _does(game, s, kind),
      sources = _sources(game, s, kind),
      limit = _limit(game.data.combat, kind);

  final StatKind kind;

  /// The number of the stats block, with its words.
  final String number;

  /// What the stat does.
  final String does;

  /// Where the number comes from, in the order of rule 6.
  final List<StatSource> sources;

  /// The limit of the stat; null for HP, Attack and Defense.
  final String? limit;

  /// The number alone, as the stats block shows it: "218" or "77%".
  static String value(Game game, GameState s, StatKind kind) {
    final stats = game.stats(s);
    return switch (kind) {
      StatKind.hp => '${stats.hp}',
      StatKind.attack => '${stats.attack}',
      StatKind.defense => '${stats.defense}',
      StatKind.crit => '${game.critChance(s)}%',
      StatKind.hit => '${game.hitChanceAtLevel(s)}%',
      StatKind.dodge => '${game.dodgeChance(s)}%',
      StatKind.block => '${game.blockChance(s)}%',
    };
  }

  static String _number(Game game, GameState s, StatKind kind) {
    final v = value(game, s, kind);
    return switch (kind) {
      StatKind.hp || StatKind.attack || StatKind.defense => '$v ${kind.label}',
      StatKind.crit => '$v chance of a critical hit',
      StatKind.hit => '$v against a monster of your level',
      StatKind.dodge => '$v chance to dodge a hit',
      StatKind.block => '$v chance to block a hit',
    };
  }

  static String _does(Game game, GameState s, StatKind kind) {
    final c = game.data.combat;
    return switch (kind) {
      StatKind.hp =>
        'You lose a fight when your HP reaches 0. Each fight starts at full '
            'HP.',
      StatKind.attack =>
        "A hit deals about your Attack minus half of the monster's Defense.",
      StatKind.defense => "A monster's hit loses half of your Defense.",
      StatKind.crit =>
        'A critical hit deals ${_plain(game.critDamage(s))} times the '
            'damage.',
      StatKind.hit =>
        'Each level a monster is above you takes ${c.hitPerLevel}% off. '
            'Each level below adds ${c.hitPerLevel}%.',
      StatKind.dodge => 'A dodged hit deals no damage.',
      StatKind.block =>
        'A blocked hit deals ${(c.blockShare * 100).round()}% of its '
            'damage.',
    };
  }

  static List<StatSource> _sources(Game game, GameState s, StatKind kind) {
    final c = game.data.combat;
    final parts = game.statParts(s);
    final pct = kind._percent ? '%' : '';
    // A source that takes away shows its own minus: "-3", not "+-3".
    String plus(int v) => '${v < 0 ? '' : '+'}$v$pct';
    final gear = kind._of(parts.gear);
    // Dodge and Block have no base, so "From gear" is their first line and
    // always shows (rule 7).
    final gearFirst = kind == StatKind.dodge || kind == StatKind.block;
    return [
      switch (kind) {
        StatKind.hp || StatKind.attack || StatKind.defense => (
          id: 'level',
          line: 'From your level: ${kind._of(parts.level)}',
        ),
        StatKind.crit => (id: 'base', line: 'Base: ${c.critBase}%'),
        StatKind.hit => (id: 'base', line: 'Base: ${c.hitBase}%'),
        StatKind.dodge ||
        StatKind.block => (id: 'gear', line: 'From gear: ${plus(gear)}'),
      },
      if (!gearFirst && gear != 0)
        (id: 'gear', line: 'From gear: ${plus(gear)}'),
      if (kind._of(parts.talents) case final v when v != 0)
        (id: 'talents', line: 'From talents: ${plus(v)}'),
      if (kind._of(parts.meal) case final v when v != 0)
        (id: 'meal', line: 'From your meal: ${plus(v)}'),
      if (kind._of(parts.achievements) case final v when v != 0)
        (id: 'achievements', line: 'From achievements: ${plus(v)}'),
    ];
  }

  static String? _limit(CombatRules c, StatKind kind) => switch (kind) {
    StatKind.hp || StatKind.attack || StatKind.defense => null,
    StatKind.crit => 'At most ${c.critCap}%.',
    StatKind.hit => 'Never under ${c.hitMin}% or over ${c.hitMax}%.',
    StatKind.dodge => 'At most ${c.dodgeCap}%.',
    // Achievements give Block too (erratum 1).
    StatKind.block =>
      'At most ${c.blockCap}%. Gear gives Block only on a shield.',
  };

  /// 2.0 as "2", 2.5 as "2.5".
  static String _plain(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';
}

/// Opens the sheet of [kind]: what the stat does and where its number comes
/// from (spec 0009 amendment 4, rule 3).
Future<void> showStatSheet(
  BuildContext context,
  Game game,
  GameState s,
  StatKind kind,
) {
  final info = StatInfo(game, s, kind);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          key: const ValueKey('stat-sheet'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kind.label,
                key: const ValueKey('stat-sheet-title'),
                style: text.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                info.number,
                key: const ValueKey('stat-sheet-number'),
                style: text.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(info.does, key: const ValueKey('stat-sheet-does')),
              const SizedBox(height: 12),
              for (final source in info.sources)
                Text(source.line, key: ValueKey('stat-source-${source.id}')),
              if (info.limit case final limit?) ...[
                const SizedBox(height: 12),
                Text(
                  limit,
                  key: const ValueKey('stat-sheet-limit'),
                  style: const TextStyle(color: Quiet.muted),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
