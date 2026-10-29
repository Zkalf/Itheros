part of '../data.dart';

/// Character stats. Also used for gear bonuses and per-level growth. [crit],
/// [hit], [dodge] and [block] are percent points (spec 0009 §2.2).
class Stats {
  const Stats({
    this.hp = 0,
    this.attack = 0,
    this.defense = 0,
    this.crit = 0,
    this.hit = 0,
    this.dodge = 0,
    this.block = 0,
  });

  factory Stats.fromJson(Map<String, Object?> json) => Stats(
    hp: _intOr(json, 'hp'),
    attack: _intOr(json, 'attack'),
    defense: _intOr(json, 'defense'),
    crit: _intOr(json, 'crit'),
    hit: _intOr(json, 'hit'),
    dodge: _intOr(json, 'dodge'),
    block: _intOr(json, 'block'),
  );

  final int hp;
  final int attack;
  final int defense;
  final int crit;
  final int hit;
  final int dodge;
  final int block;

  Stats _zip(Stats o, int Function(int, int) f) => Stats(
    hp: f(hp, o.hp),
    attack: f(attack, o.attack),
    defense: f(defense, o.defense),
    crit: f(crit, o.crit),
    hit: f(hit, o.hit),
    dodge: f(dodge, o.dodge),
    block: f(block, o.block),
  );

  Stats operator +(Stats o) => _zip(o, (a, b) => a + b);

  Stats operator -(Stats o) => _zip(o, (a, b) => a - b);

  Stats operator *(int n) => _zip(this, (a, _) => a * n);

  @override
  bool operator ==(Object other) =>
      other is Stats &&
      other.hp == hp &&
      other.attack == attack &&
      other.defense == defense &&
      other.crit == crit &&
      other.hit == hit &&
      other.dodge == dodge &&
      other.block == block;

  @override
  int get hashCode => Object.hash(hp, attack, defense, crit, hit, dodge, block);

  @override
  String toString() =>
      'Stats(hp: $hp, attack: $attack, defense: $defense, crit: $crit, '
      'hit: $hit, dodge: $dodge, block: $block)';
}

/// The combat numbers of spec 0009 §2.1 and the type table of §3, from
/// `economy.json`. Chances are percent points.
class CombatRules {
  CombatRules._(Map<String, Object?> j)
    : hitBase = _int(j, 'hitBase'),
      hitPerLevel = _int(j, 'hitPerLevel'),
      hitMin = _int(j, 'hitMin'),
      hitMax = _int(j, 'hitMax'),
      critBase = _int(j, 'critBase'),
      critDamage = (j['critDamage'] as num).toDouble(),
      blockShare = (j['blockShare'] as num).toDouble(),
      critCap = _int(j, 'critCap'),
      blockCap = _int(j, 'blockCap'),
      dodgeCap = _int(j, 'dodgeCap'),
      slayerKills = _int(j, 'slayerKills'),
      slayerHit = _int(j, 'slayerHit'),
      studyKills = _int(j, 'studyKills'),
      loreChance = (j['loreChance'] as num).toDouble(),
      typeFactors = Map.unmodifiable(
        _map(j, 'typeFactors').map(
          (armour, row) => MapEntry(
            armour,
            Map<String, double>.unmodifiable(
              (row as Map<String, Object?>).map(
                (type, f) => MapEntry(type, (f as num).toDouble()),
              ),
            ),
          ),
        ),
      );

  final int hitBase;
  final int hitPerLevel;
  final int hitMin;
  final int hitMax;
  final int critBase;

  /// A crit's damage, times a normal hit's.
  final double critDamage;

  /// A blocked hit's share of the damage.
  final double blockShare;
  final int critCap;
  final int blockCap;
  final int dodgeCap;

  /// Kills of a monster that earn Slayer, and the Hit it gives against that
  /// monster (spec 0009 §7.1).
  final int slayerKills;
  final int slayerHit;

  /// Kills of a monster that show its weakness and stats (spec 0009 §7.1).
  final int studyKills;

  /// The chance a kill drops its monster's lore note, until found (§7.2).
  final double loreChance;

  /// Armour type -> damage type -> damage factor.
  final Map<String, Map<String, double>> typeFactors;

  Iterable<String> get armourTypes => typeFactors.keys;

  Set<String> get damageTypes => {
    for (final row in typeFactors.values) ...row.keys,
  };

  /// The attacker's chance to hit, in percent: base, plus per level above
  /// the defender, plus Hit, kept within the bounds.
  int hitChance(int levelDiff, int hit) =>
      (hitBase + hitPerLevel * levelDiff + hit).clamp(hitMin, hitMax);

  /// The damage factor of [damageType] against [armour]; bare hands (null)
  /// are neutral.
  double typeFactor(String? damageType, String armour) =>
      damageType == null ? 1 : typeFactors[armour]![damageType]!;

  /// The damage type that hits [armour] hardest.
  String strongAgainst(String armour) => typeFactors[armour]!.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
}

/// One bonus stat roll on a piece of gear (spec 0009 §5): `crit` 3.
typedef BonusRoll = ({String stat, int value});

/// The bonus stats gear of an item level up to [upToLevel] (null: any) can
/// roll, each with its value range (spec 0009 §5.1).
class BonusTier {
  BonusTier._(Map<String, Object?> j)
    : upToLevel = j['upToLevel'] as int?,
      ranges = Map.unmodifiable({
        for (final stat in GameData.bonusStats)
          if (j[stat] case [final int lo, final int hi]) stat: (lo, hi),
      });

  final int? upToLevel;
  final Map<String, (int, int)> ranges;
}
