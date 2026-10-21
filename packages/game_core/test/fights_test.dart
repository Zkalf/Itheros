// Hit, miss, dodge, crit, block and damage types: spec 0009 §2–§3,
// acceptance criteria 1-4. Arena fights have no damage variance; unless a
// test says otherwise, every swing lands and none crits (support.dart's
// sureHits). A level 1 player has 30 HP, 5 Attack and 2 Defense.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Test gear: a ring of [hit] Hit, a cloak of [dodge] Dodge, a shield of
/// [block] Block.
List<Map<String, Object?>> _testGear({
  int hit = 0,
  int dodge = 0,
  int block = 0,
}) => [
  {'id': 'hit_ring', 'name': 'Hit ring', 'slot': 'ring', 'hit': hit},
  {'id': 'dodge_cloak', 'name': 'Dodge cloak', 'slot': 'cloak', 'dodge': dodge},
  {'id': 'wall', 'name': 'Wall', 'slot': 'offHand', 'block': block},
];

/// An arena game whose items add [gear] to the real ones.
Game _arena(
  List<Map<String, Object?>> enemies, {
  Map<String, Object?> combat = const {},
  List<Map<String, Object?>> gear = const [],
}) {
  final items = dataJson('items');
  return newTestGame(
    overrides: {
      'economy': {
        ...dataJson('economy'),
        'damageVariance': 0,
        'combat': {...sureHits, ...combat},
      },
      'items': {
        ...items,
        'items': [...(items['items']! as List<Object?>), ...gear],
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

/// Real hit and crit rolls (spec 0009 §2.1), damage variance off.
final Map<String, Object?> _realRolls = combatJson();

GameState _wearing(Game g, Map<String, String> equipment, {int level = 1}) =>
    stateAt(g, location: 'arena', level: level)..equipment.addAll(equipment);

/// The rounds of one fight against [enemy], [rounds] long.
List<RoundLog> _rounds(Game g, GameState s, String enemy, int rounds) {
  final logs = <RoundLog>[];
  var state = g.startActivity(s, Activity.fight(enemy));
  for (var i = 0; i < rounds; i++) {
    state = g.applySteps(state, 10).state;
    logs.add(state.activity!.log.last);
  }
  return logs;
}

void main() {
  group('criterion 1: hit chance (§2.1)', () {
    // A monster for every level difference from -12 to +12 against a level
    // 13 player.
    final enemies = [
      for (var level = 1; level <= 25; level++)
        monster('m$level', extra: {'level': level}),
    ];

    for (final hit in [0, 10]) {
      test('85% + per level + Hit, within 50-95% (Hit $hit)', () {
        final g = _arena(enemies, combat: _realRolls, gear: _testGear(hit: 10));
        final c = g.data.combat;
        expect((c.hitBase, c.hitMin, c.hitMax), (85, 50, 95));
        final s = _wearing(g, {if (hit > 0) 'ring1': 'hit_ring'}, level: 13);
        for (var diff = -10; diff <= 12; diff++) {
          final expected = (85 + c.hitPerLevel * diff + hit).clamp(50, 95);
          expect(
            g.playerHitChance(s, 'm${13 - diff}'),
            expected,
            reason: 'player $diff levels above',
          );
          // Monsters have no Hit.
          expect(
            g.monsterHitChance(s, 'm${13 + diff}'),
            (85 + c.hitPerLevel * diff).clamp(50, 95),
            reason: 'monster $diff levels above',
          );
        }
      });
    }

    test('the bounds: far below is 50%, far above 95%', () {
      final g = _arena(enemies, combat: _realRolls);
      final s = _wearing(g, {}, level: 13);
      expect(g.playerHitChance(s, 'm25'), 50);
      expect(g.playerHitChance(s, 'm1'), 95);
      expect(g.playerHitChance(s, 'm13'), 85);
    });

    test('Dodge never changes the hit chance', () {
      final g = _arena(
        [
          monster('plain'),
          monster('slippery', extra: {'dodge': 30}),
        ],
        combat: _realRolls,
        gear: _testGear(dodge: 20),
      );
      final s = _wearing(g, {});
      final dodgy = _wearing(g, {'cloak': 'dodge_cloak'});
      expect(g.playerHitChance(s, 'slippery'), g.playerHitChance(s, 'plain'));
      expect(
        g.monsterHitChance(dodgy, 'plain'),
        g.monsterHitChance(s, 'plain'),
      );
    });
  });

  group('criterion 2: over many seeded swings', () {
    // A monster that dies to any hit: each round is one swing of the
    // player's. XP and kills are put back so neither the level nor Slayer
    // changes the odds.
    List<RoundLog> swings(Game g, int n) {
      final logs = <RoundLog>[];
      var s = g.startActivity(_wearing(g, {}), const Activity.fight('dummy'));
      final xp0 = s.xp;
      for (var i = 0; i < n; i++) {
        final r = g.applySteps(s, 10);
        logs.add(r.state.activity!.log.last);
        s = r.state
          ..xp = xp0
          ..counters.remove('kills.dummy');
      }
      return logs;
    }

    test('85% ± 1 point hit at even level; misses deal nothing', () {
      final g = _arena([monster('dummy')], combat: _realRolls);
      final logs = swings(g, 20000);
      final hits = logs.where(
        (l) => l.mine == Swing.hit || l.mine == Swing.crit,
      );
      expect(hits.length / logs.length, closeTo(0.85, 0.01));
      final misses = logs.where((l) => l.mine == Swing.miss);
      expect(misses.length, logs.length - hits.length);
      expect(misses.every((l) => l.dealt == 0), isTrue);
    });

    test('with 10% Dodge, about 10% of the hits are dodged for nothing', () {
      final g = _arena([
        monster('dummy', extra: {'dodge': 10}),
      ], combat: _realRolls);
      final logs = swings(g, 20000);
      final dodged = logs.where((l) => l.mine == Swing.dodge);
      final landed = logs.where(
        (l) => l.mine == Swing.hit || l.mine == Swing.crit,
      );
      final hits = dodged.length + landed.length;
      expect(hits / logs.length, closeTo(0.85, 0.01));
      expect(dodged.length / hits, closeTo(0.10, 0.01));
      expect(dodged.every((l) => l.dealt == 0), isTrue);
    });
  });

  group('criterion 3: crit and block', () {
    final allCrits = {'critBase': 100, 'critCap': 100};

    test('a crit deals double damage', () {
      final g = _arena([monster('dummy', hp: 1000)], combat: allCrits);
      final r = _rounds(g, _wearing(g, {}), 'dummy', 1).single;
      expect((r.mine, r.dealt), (Swing.crit, 10));
    });

    test('monsters never crit', () {
      // 12 Attack against 2 Defense: 11 damage, crits or not.
      final g = _arena([
        monster('brute', hp: 1000, attack: 12),
      ], combat: allCrits);
      final r = _rounds(g, _wearing(g, {}), 'brute', 1).single;
      expect((r.theirs, r.taken), (Swing.hit, 11));
    });

    test('a blocked hit deals 30% of its damage, at least 1', () {
      final g = _arena(
        [
          monster('brute', hp: 1000, attack: 12),
          monster('weakling', hp: 1000, attack: 2),
        ],
        combat: {'blockCap': 100},
        gear: _testGear(block: 100),
      );
      final s = _wearing(g, {'offHand': 'wall'});
      final hard = _rounds(g, s, 'brute', 1).single;
      expect((hard.theirs, hard.taken), (Swing.block, 3)); // 11 x 30% = 3.3
      final soft = _rounds(g, s, 'weakling', 1).single;
      expect((soft.theirs, soft.taken), (Swing.block, 1)); // 1 x 30% = 0.3
    });

    test('Block comes only from the off hand', () {
      final items = dataJson('items');
      final list = (items['items']! as List).cast<Map<String, Object?>>();
      list.add({
        'id': 'blocky_vest',
        'name': 'Blocky vest',
        'slot': 'chest',
        'block': 10,
      });
      expect(
        () => newTestGame(overrides: {'items': items}),
        throwsFormatException,
      );
    });

    test('the caps hold: Crit 50%, Block 50%, Dodge 30%', () {
      final g = _arena(
        [
          monster('slippery', extra: {'dodge': 60}),
        ],
        combat: {'critBase': 90},
        gear: _testGear(dodge: 60, block: 80),
      );
      final s = _wearing(g, {'cloak': 'dodge_cloak', 'offHand': 'wall'});
      expect(g.critChance(s), 50);
      expect(g.blockChance(s), 50);
      expect(g.dodgeChance(s), 30);
      expect(g.enemyDodge('slippery'), 30);
    });

    test('the player crits at 5% base', () {
      final g = _arena([monster('dummy')]);
      expect(g.critChance(_wearing(g, {})), 0, reason: 'sureHits: no crits');
      expect(newTestGame().data.combat.critBase, 5);
    });
  });

  group('criterion 4: damage types against armour (§3)', () {
    test('the type table, all nine pairs', () {
      final c = newTestGame().data.combat;
      const table = {
        'light': {'slash': 1.3, 'pierce': 1.0, 'crush': 0.8},
        'medium': {'pierce': 1.3, 'crush': 1.0, 'slash': 0.8},
        'heavy': {'crush': 1.3, 'slash': 1.0, 'pierce': 0.8},
      };
      for (final MapEntry(key: armour, value: row) in table.entries) {
        for (final MapEntry(key: type, value: factor) in row.entries) {
          expect(c.typeFactor(type, armour), factor, reason: '$type/$armour');
        }
        expect(c.typeFactor(null, armour), 1, reason: 'bare hands, $armour');
      }
    });

    test('a fight applies the main hand\'s type', () {
      // Level 1 (5 Attack) with a copper weapon (+3) against no defence: 8.
      final g = _arena([
        monster('knight', hp: 1000, extra: {'armour': 'heavy'}),
      ]);
      int dealt(String? weapon) => _rounds(
        g,
        _wearing(g, {'mainHand': ?weapon}),
        'knight',
        1,
      ).single.dealt!;
      expect(dealt('copper_mace'), 10); // crush: 8 x 1.3 = 10.4
      expect(dealt('copper_sword'), 8); // slash: neutral
      expect(dealt('copper_spear'), 6); // pierce: 8 x 0.8 = 6.4
      expect(dealt(null), 5); // bare hands: neutral
      expect(g.damageType(_wearing(g, {})), isNull);
    });
  });

  test('Slayer: 50 kills give +5% Hit against that monster (§7.1)', () {
    final g = _arena([monster('goblin'), monster('other')], combat: _realRolls);
    final s = _wearing(g, {})..counters['kills.goblin'] = 49;
    expect(g.playerHitChance(s, 'goblin'), 85);
    s.counters['kills.goblin'] = 50;
    expect(g.slayer(s, 'goblin'), isTrue);
    expect(g.playerHitChance(s, 'goblin'), 90);
    expect(g.playerHitChance(s, 'other'), 85);
  });

  test('a save wearing the maul and a shield loads with the shield in the bag '
      '(the maul becomes two-handed, §4.1)', () {
    final game = newTestGame();
    final json = game.newGame(seed: 1).toJson()
      ..['version'] = 6
      ..['equipment'] = {
        'mainHand': 'troll_bone_maul@rare',
        'offHand': 'iron_shield',
        'chest': 'troll_hide_armour',
      };
    final s = game.migrate(
      GameState.fromJson(jsonDecode(jsonEncode(json)) as Map<String, Object?>),
    );
    expect(s.equipment, {
      'mainHand': 'troll_bone_maul@rare',
      'chest': 'troll_hide_armour',
    });
    expect(s.inventory, {'iron_shield': 1});
  });
}
