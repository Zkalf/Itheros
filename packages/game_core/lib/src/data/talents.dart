part of '../data.dart';

/// What a talent changes (spec 0015 §2.8). A closed list: a new kind of
/// talent needs a rule, a known kind only data.
enum TalentEffect {
  attackPercent,
  hpPercent,
  defensePercent,
  crit,
  hit,
  dodge,
  fightSteps,
  dropQuality,
  critDamage,
  bankCap,
  professionSteps,
  extraGather,
  lossXpShare,
  craftQuality,
  queueSlot,
  travelSteps,
  rerollQuality,
  professionXp,
}

/// A talent tree: Combat or Utility (spec 0015 §2.3, §2.4).
class TalentTreeDef {
  TalentTreeDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      line = _str(j, 'line');

  final String id;
  final String name;
  final String line;
}

/// A talent of [tree] in [row] and [column], with [ranks] of [value] each
/// (spec 0015 §2.8, amendment 3). [needs] names a talent that must have all
/// its ranks first.
class TalentDef {
  TalentDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      tree = _str(j, 'tree'),
      row = _int(j, 'row'),
      // No column reads as 0, which the data check refuses.
      column = (j['column'] as num?)?.toInt() ?? 0,
      ranks = _int(j, 'ranks'),
      name = _str(j, 'name'),
      line = _str(j, 'line'),
      image = _str(j, 'image'),
      effect = TalentEffect.values
          .where((e) => e.name == j['effect'])
          .firstOrNull,
      effectName = _str(j, 'effect'),
      value = _num(j, 'value'),
      needs = j['needs'] as String?;

  final String id;
  final String tree;
  final int row;

  /// Its place in the row on the Talents tab, 1-3.
  final int column;
  final int ranks;
  final String name;
  final String line;
  final String image;

  /// Null for an unknown effect: the data check refuses it.
  final TalentEffect? effect;
  final String effectName;
  final double value;
  final String? needs;
}

/// The Guild trainer who resets the trees (spec 0015 §2.7).
class TrainerDef {
  TrainerDef._(Map<String, Object?> j)
    : name = _str(j, 'name'),
      title = _str(j, 'title'),
      location = _str(j, 'location'),
      greeting = _str(j, 'greeting'),
      early = _str(j, 'early'),
      confirm = _str(j, 'confirm'),
      done = _str(j, 'done');

  final String name;
  final String title;
  final String location;
  final String greeting;

  /// Before the first talent point.
  final String early;
  final String confirm;
  final String done;
}

/// The price of a paid reset (spec 0015 §2.6), in steps from the bank.
class ResetRules {
  ResetRules._(Map<String, Object?> j)
    : base = _int(j, 'base'),
      step = _int(j, 'step'),
      cap = _int(j, 'cap'),
      cooldownSteps = _int(j, 'cooldownSteps');

  final int base;
  final int step;
  final int cap;
  final int cooldownSteps;
}
