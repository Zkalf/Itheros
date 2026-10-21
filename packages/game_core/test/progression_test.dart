// Levels, stats, gear, travel, gathering and achievements: spec 0001 §3–6.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  test('level is derived from XP thresholds', () {
    final s = game.newGame(seed: 1);
    expect(game.level(s), 1);
    s.xp = 19;
    expect(game.level(s), 1);
    s.xp = 20;
    expect(game.level(s), 2);
  });

  test('xpForNextLevel gives the next threshold', () {
    expect(game.xpForNextLevel(stateAt(game)), 20);
    expect(game.xpForNextLevel(stateAt(game, level: 3)), 300);
  });

  test('unitCost is the next unit of the current activity, null when idle', () {
    var s = stateAt(game);
    expect(game.unitCost(s), isNull);
    s = game.startActivity(s, const Activity.travel('goblin_woods'));
    expect(game.unitCost(s), 200);
    s = stateAt(game, location: 'goblin_woods');
    s = game.startActivity(s, const Activity.fight('goblin'));
    expect(game.unitCost(s), 10);
  });

  test('stats grow per level (spec 0002 §4)', () {
    final l1 = game.stats(stateAt(game));
    final l3 = game.stats(stateAt(game, level: 3));
    expect((l1.hp, l1.attack, l1.defense), (30, 5, 2));
    expect((l3.hp, l3.attack, l3.defense), (50, 7, 4));
  });

  test('bank cap is 9,500 + 500 per level (spec 0003 §6)', () {
    expect(game.bankCap(stateAt(game)), 10000);
    expect(game.bankCap(stateAt(game, level: 5)), 12000);
  });

  test('levelling up during catch-up raises the cap immediately', () {
    var s = stateAt(game, location: 'goblin_woods', level: 1, bank: 0);
    s.xp = game.data.xpForLevel(2) - 10; // one goblin from level 2
    s = game.startActivity(s, const Activity.fight('goblin'));
    final r = game.applySteps(s, 100);
    expect(r.events.whereType<LevelUp>().map((e) => e.level), contains(2));
    expect(game.bankCap(r.state), 10500);
  });

  group('gear', () {
    test('equipping moves an item from inventory and adds its stats', () {
      var s = stateAt(game, inventory: {'copper_sword': 1});
      s = game.equip(s, 'copper_sword');
      expect(s.equipment['mainHand'], 'copper_sword');
      expect(s.inventory['copper_sword'] ?? 0, 0);
      expect(game.stats(s).attack, 5 + 3);
    });

    test('equipping into a used slot returns the old item', () {
      var s = stateAt(game, inventory: {'copper_sword': 1, 'rusty_dagger': 1});
      s = game.equip(s, 'rusty_dagger');
      s = game.equip(s, 'copper_sword');
      expect(s.equipment['mainHand'], 'copper_sword');
      expect(s.inventory['rusty_dagger'], 1);
    });

    test('unequip returns the item to the inventory', () {
      var s = stateAt(game, inventory: {'hide_vest': 1});
      s = game.equip(s, 'hide_vest');
      expect(game.stats(s).hp, 30 + 10);
      s = game.unequip(s, 'chest');
      expect(s.equipment, isEmpty);
      expect(s.inventory['hide_vest'], 1);
    });

    // Spec 0008 decision 1: every slot is open from level 1.
    group('criterion 8: gear slots', () {
      test('an item for an unknown slot is rejected when data loads', () {
        expect(
          () => newTestGame(
            overrides: {
              'items': {
                ...dataJson('items'),
                'items': [
                  ...dataJson('items')['items']! as List<Object?>,
                  {'id': 'hat', 'name': 'Hat', 'slot': 'hat'},
                ],
              },
            },
          ),
          throwsFormatException,
        );
      });
    });

    test('items without a slot or not owned cannot be equipped', () {
      final s = stateAt(game, inventory: {'copper_ore': 3});
      expect(() => game.equip(s, 'copper_ore'), throwsA(isA<ActivityError>()));
      expect(
        () => game.equip(s, 'copper_sword'),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  test('travel arrives after the route cost, ends, and banks the rest', () {
    var s = stateAt(game);
    s = game.startActivity(s, const Activity.travel('goblin_woods'));
    final r = game.applySteps(s, 250);
    expect(r.state.location, 'goblin_woods');
    expect(r.state.activity, isNull);
    expect(r.events.whereType<Arrived>().single.location, 'goblin_woods');
    expect(
      r.events.whereType<ActivityEnded>().single.reason,
      EndReason.arrived,
    );
    expect(r.state.bank, 50);
  });

  test('mining yields one ore and 20 XP per 100 steps', () {
    var s = stateAt(game, level: 2, location: 'copper_hills');
    final xp0 = s.xp;
    s = game.startActivity(s, const Activity.gather('copper_vein'));
    final r = game.applySteps(s, 350);
    expect(r.state.inventory['copper_ore'], 3);
    expect(r.state.xp - xp0, 60);
    expect(r.state.activity!.progress, 50);
  });

  group('achievements', () {
    test('First Steps unlocks at 100 walked steps', () {
      final r = game.applySteps(stateAt(game), 100);
      expect(r.state.achievements, contains('first_steps'));
      expect(r.events.whereType<AchievementUnlocked>().map((e) => e.id), [
        'first_steps',
      ]);
    });

    test('achievements unlock only once', () {
      var s = game.applySteps(stateAt(game), 100).state;
      final r = game.applySteps(s, 100);
      expect(r.events.whereType<AchievementUnlocked>(), isEmpty);
    });

    test('Marathon raises the bank cap by 500', () {
      final s = stateAt(game)..counters['steps.walked'] = 42194;
      expect(game.bankCap(s), 10000);
      final r = game.applySteps(s, 1);
      expect(r.state.achievements, contains('marathon'));
      expect(game.bankCap(r.state), 10500);
    });

    test('Smith unlocks on the first crafted item', () {
      var s = stateAt(game, level: 3, inventory: {'goblin_hide': 4});
      s = game.startActivity(s, const Activity.craft('hide_vest'));
      final r = game.applySteps(s, 150);
      expect(r.state.achievements, contains('smith'));
    });
  });
}
