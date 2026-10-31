part of '../data.dart';

/// A profession's teacher in camp (spec 0010 §6).
class TeacherDef {
  TeacherDef._(Map<String, Object?> j)
    : name = _str(j, 'name'),
      title = _str(j, 'title'),
      location = _str(j, 'location'),
      starterTool = _str(j, 'starterTool'),
      learnLine = _str(j, 'learnLine'),
      greeting = _str(j, 'greeting'),
      kinLine = _str(j, 'kinLine'),
      tips = List.unmodifiable(_maps(j, 'tips').map(TipDef._));

  final String name;
  final String title;
  final String location;
  final String starterTool;
  final String learnLine;

  /// What they say to a player of another origin, and to one of theirs in
  /// place of [learnLine] (spec 0012 §3.1).
  final String greeting;
  final String kinLine;

  /// Lowest level first (spec 0010 §6.2).
  final List<TipDef> tips;
}

/// A teacher's tip, told from profession [level]: about monster [enemy],
/// which reveals its armour and weakness (spec 0010 §6.2), or about
/// gathering spot [node], which only tells what lives there (amendment 8).
class TipDef {
  TipDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      level = _int(j, 'level'),
      enemy = j['enemy'] as String?,
      node = j['node'] as String?,
      title = _str(j, 'title'),
      text = _str(j, 'text');

  final String id;
  final int level;
  final String? enemy;
  final String? node;
  final String title;
  final String text;
}

/// A material tier of a profession, open from [level] (spec 0010 §2.1).
class TierDef {
  TierDef._(Map<String, Object?> j)
    : level = _int(j, 'level'),
      name = _str(j, 'name');

  final int level;
  final String name;
}

class ProfessionDef {
  ProfessionDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      icon = _str(j, 'icon'),
      toolName = _str(j, 'tool'),
      tiers = List.unmodifiable(_maps(j, 'tiers').map(TierDef._)),
      teacher = TeacherDef._(_map(j, 'teacher'));

  final String id;
  final String name;
  final String icon;

  /// What its tool slot is called: Pickaxe.
  final String toolName;

  /// Lowest first.
  final List<TierDef> tiers;
  final TeacherDef teacher;

  List<TipDef> get tips => teacher.tips;

  /// The tier held at profession [level].
  TierDef tierAt(int level) => tiers.lastWhere((t) => t.level <= level);
}

class RecipeDef {
  RecipeDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      level = _int(j, 'level'),
      craftingLevel = _intOr(j, 'crafting', _int(j, 'level')),
      steps = _int(j, 'steps'),
      xp = _int(j, 'xp'),
      profession = j['profession'] as String? ?? 'crafting',
      inputs = (j['inputs'] as Map<String, Object?>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      output = _str(j, 'output');

  final String id;

  /// Its level for the profession fade and the item level of its quality
  /// roll; the Crafting level it needs unless [craftingLevel] says less
  /// (spec 0010 §2.2).
  final int level;

  /// The level of [profession] it needs: `crafting` in data, else [level].
  /// The first recipes need Crafting 1 (spec 0010 amendment 1).
  final int craftingLevel;

  /// Crafting's, or Cooking's for a meal (spec 0011 §5.1).
  final String profession;
  final int steps;

  /// Crafting XP per craft (spec 0010 §2.2).
  final int xp;
  final Map<String, int> inputs;
  final String output;
}

/// Where the character comes from (spec 0012 §2.1): [profession] starts at
/// [GameData.headStartLevel]. [title] may hold gendered words.
class OriginDef {
  OriginDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      title = _str(j, 'title'),
      line = _str(j, 'line'),
      profession = _str(j, 'profession');

  final String id;
  final String title;
  final String line;
  final String profession;
}
