// Item qualities: spec 0005, acceptance criteria 1-8.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const order = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

  /// Share of each quality over [n] rolls, in percent.
  Map<String, double> shares(int playerLevel, int itemLevel, {int n = 200000}) {
    final rng = Rng.seeded(7);
    final counts = {for (final q in order) q: 0};
    for (var i = 0; i < n; i++) {
      final q = game.rollQuality(
        rng,
        playerLevel: playerLevel,
        itemLevel: itemLevel,
      );
      counts[q] = counts[q]! + 1;
    }
    return counts.map((q, c) => MapEntry(q, 100 * c / n));
  }

  test('five qualities in order, their chances add up to 100%', () {
    expect(data.qualities.map((q) => q.id), order);
    final total = data.qualities.fold(0.0, (t, q) => t + q.chance);
    expect(total, closeTo(1, 1e-9));
    expect(data.qualities.first.bonus, 0);
  });

  group('criterion 2: chances at even level', () {
    final got = shares(6, 6);
    const want = {
      'common': 70.0,
      'uncommon': 20.0,
      'rare': 7.0,
      'epic': 2.5,
      'legendary': 0.5,
    };
    for (final q in order) {
      test(q, () {
        expect(got[q], closeTo(want[q]!, q == 'legendary' ? 0.2 : 1));
      });
    }
    test('a player below the item level gets the same odds', () {
      expect(shares(3, 6), got);
    });
  });

  group('criterion 3: being above the item helps very slightly', () {
    test('10 levels above: legendary about 0.6%, common about 64%', () {
      final got = shares(16, 6);
      expect(got['legendary'], closeTo(0.6, 0.1));
      expect(got['common'], closeTo(64, 1));
    });
    test('more than 10 levels above changes nothing', () {
      expect(shares(30, 6), shares(16, 6));
    });
  });

  group('criterion 4: stats with quality', () {
    Stats of(String key) => data.bonusOf(key);
    test('Bone sword: +5 / +6 / +7 / +9 / +10 Attack', () {
      expect(
        [for (final q in order) of(data.keyFor('bone_sword', q)).attack],
        [5, 6, 7, 9, 10],
      );
    });
    test('Hide vest: Defense +2..+6, HP +10..+20, no Attack', () {
      final vests = [for (final q in order) of(data.keyFor('hide_vest', q))];
      expect(vests.map((v) => v.defense), [2, 3, 4, 5, 6]);
      expect(vests.map((v) => v.hp), [10, 12, 14, 17, 20]);
      expect(vests.map((v) => v.attack), everyElement(0));
    });
    test('common keeps the plain id', () {
      expect(data.keyFor('bone_sword', 'common'), 'bone_sword');
      expect(data.keyFor('bone_sword', 'rare'), 'bone_sword@rare');
      expect(data.itemOf('bone_sword@rare')!.id, 'bone_sword');
      expect(data.qualityOf('bone_sword@rare').id, 'rare');
      expect(data.qualityOf('bone_sword').id, 'common');
    });
  });

  group('criterion 1: crafted and dropped gear has a quality', () {
    test('every crafted Bone sword is a Bone sword of some quality', () {
      var s = stateAt(
        game,
        level: 6,
        inventory: {'bones': 6 * 60, 'copper_ore': 2 * 60},
      );
      s = game.startActivity(s, const Activity.craft('bone_sword'));
      final r = game.applySteps(s, 200 * 60);
      final swords = {
        for (final e in r.state.inventory.entries)
          if (data.itemOf(e.key)!.id == 'bone_sword') e.key: e.value,
      };
      expect(swords.values.fold(0, (a, b) => a + b), 60);
      expect(swords.length, greaterThan(1), reason: '60 rolls, not all common');
      for (final k in swords.keys) {
        expect(order, contains(data.qualityOf(k).id));
      }
      expect(r.state.counters['crafted.bone_sword'], 60);
      final crafted = r.events.whereType<Crafted>().map((e) => e.item);
      expect(crafted.toSet(), swords.keys.toSet());
    });

    test('dropped gear rolls a quality; materials never do', () {
      final g = arenaGame([
        monster(
          'rat',
          extra: {
            'drops': [
              {'item': 'hide_vest', 'chance': 1.0},
              {'item': 'goblin_hide', 'chance': 1.0},
            ],
          },
        ),
      ]);
      var s = g.newGame(seed: 3);
      s = g.startActivity(s, const Activity.fight('rat'));
      final r = g.applySteps(s, 10 * 300);
      final inv = r.state.inventory;
      expect(inv['goblin_hide'], 300);
      expect(inv.keys.where((k) => k.startsWith('goblin_hide@')), isEmpty);
      final vests = inv.keys.where((k) => k.startsWith('hide_vest'));
      expect(vests.length, greaterThan(1));
      expect(vests.fold(0, (t, k) => t + inv[k]!), 300);
    });
  });

  group('criterion 5: stacks and equipping', () {
    test('each quality is its own stack; equip and remove keep it', () {
      var s = stateAt(
        game,
        level: 6,
        inventory: {'bone_sword@rare': 1, 'bone_sword': 2},
      );
      final base = game.stats(s).attack;
      s = game.equip(s, 'bone_sword@rare');
      expect(s.equipment['weapon'], 'bone_sword@rare');
      expect(s.inventory['bone_sword@rare'], isNull);
      expect(s.inventory['bone_sword'], 2);
      expect(game.stats(s).attack, base + 7);

      s = game.equip(s, 'bone_sword');
      expect(s.inventory['bone_sword@rare'], 1, reason: 'back in its stack');
      expect(s.inventory['bone_sword'], 1);
      expect(game.stats(s).attack, base + 5);

      s = game.unequip(s, 'weapon');
      expect(s.inventory['bone_sword'], 2);
    });
  });

  group('criterion 6: boss uniques', () {
    test(
      'every boss unique can drop again at 1% per later kill (amendment 1)',
      () {
        for (final id in ['graveyard_king', 'ogre_chieftain', 'young_dragon']) {
          final drops = data.enemies[id]!.firstKillDrops;
          expect(drops, isNotEmpty);
          for (final d in drops) {
            expect(d.repeatChance, 0.01, reason: '$id ${d.item}');
          }
        }
      },
    );

    test('sure on the first kill, then at the repeat chance, with quality', () {
      final g = arenaGame([
        monster(
          'king',
          extra: {
            'firstKillDrops': [
              {'item': 'copper_sword', 'count': 1, 'repeatChance': 0.25},
            ],
          },
        ),
      ]);
      var s = g.newGame(seed: 5);
      s = g.startActivity(s, const Activity.fight('king'));
      final first = g.applySteps(s, 10);
      final won = first.events.whereType<FightWon>().single;
      expect(won.drops.keys.single, startsWith('copper_sword'));

      final r = g.applySteps(first.state, 10 * 800);
      final later = r.events
          .whereType<FightWon>()
          .where((w) => w.drops.isNotEmpty)
          .length;
      expect(later, inInclusiveRange(150, 250), reason: 'about 25% of 800');
      final swords = r.state.inventory.keys.where(
        (k) => k.startsWith('copper_sword'),
      );
      expect(swords.length, greaterThan(1), reason: 'each rolls a quality');
    });
  });

  group('criterion 7: counting and ranking with quality', () {
    test('owned counts every quality, equipped included', () {
      final s = stateAt(
        game,
        level: 6,
        inventory: {
          'bone_sword@rare': 1,
          'bone_sword': 2,
          'bone_sword@epic': 1,
        },
      );
      final worn = game.equip(s, 'bone_sword@epic');
      expect(game.owned(worn, 'bone_sword'), 4);
    });

    test(
      '"Next goal" suggests equipping a better quality of the same item',
      () {
        var s = stateAt(
          game,
          level: 6,
          inventory: {'bone_sword': 1, 'bone_sword@legendary': 1},
        );
        s = game.equip(s, 'bone_sword');
        final goal = game.nextGoal(s);
        expect(goal, isA<EquipGoal>());
        expect((goal! as EquipGoal).item, 'bone_sword@legendary');
      },
    );

    test('"Next goal" never asks to craft another of an owned item', () {
      var s = stateAt(
        game,
        level: 6,
        inventory: {'bone_sword@rare': 1, 'bones': 60, 'copper_ore': 20},
      );
      s = game.equip(s, 'bone_sword@rare');
      final goal = game.nextGoal(s);
      expect(
        goal is CraftGoal && goal.recipe == 'bone_sword',
        isFalse,
        reason: 'it is owned (rare)',
      );
    });
  });

  test('criterion 8: an existing save loads with its gear common', () {
    final s = stateAt(game, level: 3, inventory: {'hide_vest': 1})
      ..equipment['weapon'] = 'copper_sword';
    final json = s.toJson()..['version'] = 4;
    final loaded = game.migrate(GameState.fromJson(json));
    expect(loaded.equipment['weapon'], 'copper_sword');
    expect(data.qualityOf(loaded.equipment['weapon']!).id, 'common');
    expect(loaded.inventory, {'hide_vest': 1});
    expect(game.stats(loaded).attack, game.stats(s).attack);
  });
}
