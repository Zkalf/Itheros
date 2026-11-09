import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';

/// Loads the real slice data from `data/*.json`. [overrides] replaces whole
/// files by name (without extension), for tests that need special content.
GameData loadGameData({Map<String, Object> overrides = const {}}) {
  final files = <String, String>{
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  overrides.forEach((name, json) => files[name] = jsonEncode(json));
  return GameData.fromJsonStrings(files);
}

/// One real data file, decoded, for tests that tweak a few values.
Map<String, Object?> dataJson(String name) =>
    jsonDecode(File('data/$name.json').readAsStringSync())
        as Map<String, Object?>;

/// The real combat numbers (spec 0009 §2.1), with [overrides].
Map<String, Object?> combatJson([Map<String, Object?> overrides = const {}]) =>
    {...dataJson('economy')['combat']! as Map<String, Object?>, ...overrides};

/// Every swing lands and none crits: spec 0009 §2.1 overrides spec 0001 §4's
/// "every hit lands", so tests of other rules turn the rolls off.
final Map<String, Object?> sureHits = combatJson({
  'hitBase': 100,
  'hitMin': 100,
  'hitMax': 100,
  'critBase': 0,
});

/// The real economy with a bag that never fills: for tests that run
/// thousands of units in a fixed number of steps to count rates. Since stacks
/// (spec 0021 amendment 4) their piles would overload a real bag and slow
/// every unit.
Map<String, Object?> roomyEconomy() => {
  ...dataJson('economy'),
  'bag': roomyBag(),
};

/// The real `bag` numbers of [roomyEconomy], alone: for [arenaGame]'s
/// `economy`, which replaces whole keys.
Map<String, Object?> roomyBag() => {
  ...dataJson('economy')['bag']! as Map<String, Object?>,
  'spaces': 1000000,
};

/// A game with one location, `arena`, holding [enemies], no damage variance
/// and [sureHits], so fights are exact. [economy] values replace real ones.
Game arenaGame(
  List<Map<String, Object?>> enemies, {
  Map<String, Object?> economy = const {},
}) {
  return newTestGame(
    overrides: {
      'economy': {
        ...dataJson('economy'),
        'damageVariance': 0,
        'combat': sureHits,
        ...economy,
      },
      'enemies': {'enemies': enemies},
      'world': {
        'startLocation': 'arena',
        'locations': [
          {
            'id': 'arena',
            'name': 'Arena',
            'enemies': [for (final e in enemies) e['id']],
          },
        ],
        'routes': <Object>[],
        'nodes': <Object>[],
      },
    },
  );
}

/// An arena monster: level 1, light armour, no drops, unless [extra] says
/// otherwise.
Map<String, Object?> monster(
  String id, {
  int hp = 1,
  int attack = 0,
  int defense = 0,
  int xp = 10,
  Map<String, Object?> extra = const {},
}) => {
  'id': id,
  'name': id,
  'level': 1,
  'armour': 'light',
  'hp': hp,
  'attack': attack,
  'defense': defense,
  'xp': xp,
  'drops': <Object>[],
  ...extra,
};

/// A game from the real data with [overrides]. A test world of its own
/// gets the teachers and the trainer at its start (spec 0010 §6.1, spec
/// 0015 §2.7); test monsters of their own keep only the tips about them
/// (§6.2).
Game newTestGame({Map<String, Object> overrides = const {}}) {
  final world = overrides['world'];
  final enemies = overrides['enemies'];
  if ((world is! Map<String, Object?> && enemies is! Map<String, Object?>) ||
      overrides.containsKey('professions')) {
    return Game(loadGameData(overrides: overrides));
  }
  final known = enemies is Map<String, Object?>
      ? {for (final e in enemies['enemies']! as List) (e as Map)['id']}
      : null;
  return Game(
    loadGameData(
      overrides: {
        if (world is Map<String, Object?> && !overrides.containsKey('talents'))
          'talents': {
            ...dataJson('talents'),
            'trainer': {
              ...dataJson('talents')['trainer']! as Map<String, Object?>,
              'location': world['startLocation'],
            },
          },
        ...overrides,
        'professions': {
          'professions': [
            for (final p in dataJson('professions')['professions']! as List)
              {
                ...p as Map<String, Object?>,
                'teacher': {
                  ...p['teacher']! as Map<String, Object?>,
                  if (world is Map<String, Object?>)
                    'location': world['startLocation'],
                  'tips': [
                    for (final t in (p['teacher']! as Map)['tips']! as List)
                      if (known == null || known.contains((t as Map)['enemy']))
                        t,
                  ],
                },
              },
          ],
        },
      },
    ),
  );
}

/// A fresh state at [location] with enough XP for [level], every profession
/// learned (spec 0010 decision 9) at [professionLevel] (default: [level]).
/// [s] has crossed the river: the road that waits for the Graveyard King is
/// open, as both its ends are explored (spec 0008 amendment 5).
GameState crossed(GameState s) =>
    s..explored.addAll(['old_graveyard', 'grey_moor']);

GameState stateAt(
  Game game, {
  String location = 'camp',
  int level = 1,
  int? professionLevel,
  int stepBank = 0,
  int seed = 1,
  Map<String, int> inventory = const {},
}) {
  final s = game.newGame(seed: seed);
  for (final p in game.data.professions.values) {
    s
      ..learned.add(p.id)
      ..tools[p.id] = p.teacher.starterTool
      ..professions[p.id] = game.data.professionXpForLevel(
        professionLevel ?? level,
      );
  }
  return s
    ..location = location
    ..xp = game.data.xpForLevel(level)
    ..stepBank = stepBank
    ..inventory.addAll(inventory);
}
