// The queue, stop conditions, losing and the bigger bank: spec 0003,
// acceptance criteria 1-8 and 10.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const goblins = Activity.fight('goblin');
  const brutes = Activity.fight('goblin_brute');
  const mining = Activity.gather('copper_vein');

  List<T> all<T>(StepReport r) => r.events.whereType<T>().toList();

  group('criterion 1: queue size by level', () {
    test('one slot before level 5: a new action replaces the running one', () {
      var s = game.addAction(stateAt(game, level: 4), goblins);
      s = game.addAction(s, brutes);
      expect(s.activity!.activity, brutes);
      expect(s.queue, isEmpty);
    });

    test('two slots from level 5', () {
      var s = game.addAction(stateAt(game, level: 5), goblins);
      s = game.addAction(s, brutes);
      expect(s.activity!.activity, goblins);
      expect(s.queue.map((p) => p.activity), [brutes]);
      expect(
        () => game.addAction(s, mining),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            'The queue is full.',
          ),
        ),
      );
    });

    test('three slots from level 8', () {
      var s = stateAt(game, level: 8);
      for (final (a, item) in [
        (goblins, 'goblin_hide'),
        (brutes, 'goblin_hide'),
        (mining, 'copper_ore'),
      ]) {
        s = game.addAction(s, a, stop: StopCondition.untilHave(item, 99));
      }
      expect(s.queue, hasLength(2));
      expect(() => game.addAction(s, goblins), throwsA(isA<ActivityError>()));
    });
  });

  test(
    'criterion 2: the next action starts by itself, walking there first',
    () {
      var s = stateAt(game, level: 5);
      s = game.addAction(
        s,
        goblins,
        stop: StopCondition.untilHave('goblin_hide', 2),
      );
      s = game.addAction(s, mining);
      expect(s.activity!.leg, 'goblin_woods', reason: 'walking, no slot used');
      expect(s.queue, hasLength(1));

      final r = game.applySteps(s, 3000);

      expect(all<Arrived>(r).map((e) => e.location), [
        'goblin_woods',
        'copper_hills',
      ]);
      expect(all<ActivityEnded>(r).single.reason, EndReason.enough);
      expect(all<ActionStarted>(r).single.activity, mining);
      expect(r.state.location, 'copper_hills');
      expect(r.state.activity!.activity, mining);
      expect(r.state.inventory['copper_ore'], greaterThan(0));
      expect(r.state.inventory['goblin_hide'], greaterThanOrEqualTo(2));
    },
  );

  test('travel goes along the shortest open route, leg by leg', () {
    // Camp -> Old Graveyard: direct (500) beats Goblin Woods (200 + 400).
    var s = game.addAction(
      stateAt(game, level: 6),
      const Activity.fight('skeleton'),
    );
    expect(s.activity!.leg, 'old_graveyard');
    expect(game.unitCost(s), 500);
    s = game.applySteps(s, 500).state;
    expect(s.location, 'old_graveyard');
    expect(s.activity!.leg, isNull);
  });

  group('criterion 3: an action that can\'t start is skipped', () {
    test('no materials', () {
      var s = stateAt(game, level: 5, location: 'goblin_woods');
      s = game.addAction(
        s,
        goblins,
        stop: StopCondition.untilHave('goblin_hide', 1),
      );
      s = game.addAction(s, const Activity.craft('copper_sword'));
      final r = game.applySteps(s, 2000);
      final skipped = all<ActionSkipped>(r).single;
      expect(skipped.activity, const Activity.craft('copper_sword'));
      expect(skipped.reason, SkipReason.noMaterials);
      expect(r.state.activity, isNull, reason: 'resting');
    });

    test('a fight "until grey" whose monster is already grey', () {
      var s = stateAt(game, level: 8, location: 'goblin_woods');
      s = game.addAction(
        s,
        brutes,
        stop: StopCondition.untilHave('goblin_hide', 1),
      );
      s = game.addAction(s, goblins, stop: const StopCondition.untilGrey());
      final r = game.applySteps(s, 1000);
      expect(all<ActionSkipped>(r).single.reason, SkipReason.alreadyDone);
    });

    test('started by hand, it is refused with a reason', () {
      final s = stateAt(game, level: 8, location: 'goblin_woods');
      expect(
        () => game.addAction(s, goblins, stop: const StopCondition.untilGrey()),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 4: stop conditions', () {
    test('until grey ends the fight when the monster turns grey', () {
      // Goblins are level 1: green at 7, grey at 8. One win levels up.
      final s0 = stateAt(game, level: 7, location: 'goblin_woods')
        ..xp = game.data.xpForLevel(8) - 1;
      final s = game.addAction(
        s0,
        goblins,
        stop: const StopCondition.untilGrey(),
      );
      final r = game.applySteps(s, 500);
      expect(all<FightWon>(r), hasLength(1));
      expect(all<ActivityEnded>(r).single.reason, EndReason.grey);
    });

    test('until N crafted', () {
      var s = stateAt(game, level: 5, inventory: {'copper_ore': 15});
      s = game.addAction(
        s,
        const Activity.craft('copper_sword'),
        stop: const StopCondition.untilCrafted(2),
      );
      final r = game.applySteps(s, 1000);
      expect(r.state.inventory['copper_sword'], 2);
      expect(r.state.inventory['copper_ore'], 5);
      expect(all<ActivityEnded>(r).single.reason, EndReason.enough);
    });

    test('until I have N counts what is already owned', () {
      var s = stateAt(
        game,
        level: 5,
        location: 'copper_hills',
        inventory: {'copper_ore': 3},
      );
      s = game.addAction(
        s,
        mining,
        stop: StopCondition.untilHave('copper_ore', 5),
      );
      final r = game.applySteps(s, 1000);
      expect(r.state.inventory['copper_ore'], 5);
      expect(all<Gathered>(r), hasLength(2));
    });

    test('"never" only in the last slot', () {
      final s = game.addAction(
        stateAt(game, level: 5),
        goblins,
        stop: const StopCondition.never(),
      );
      expect(
        () => game.addAction(s, brutes),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            'The last action never stops. Change its stop condition first.',
          ),
        ),
      );
    });

    test('"Start now" with actions waiting needs a stop condition', () {
      var s = stateAt(game, level: 5, location: 'goblin_woods');
      s = game.addAction(
        s,
        goblins,
        stop: StopCondition.untilHave('goblin_hide', 9),
      );
      s = game.addAction(s, brutes);
      expect(
        () => game.startActivity(s, mining),
        throwsA(isA<ActivityError>()),
      );
      s = game.startActivity(
        s,
        mining,
        stop: StopCondition.untilHave('copper_ore', 3),
      );
      expect(s.activity!.activity, mining);
      expect(s.queue.map((p) => p.activity), [brutes]);
    });

    test('gathering in an earlier slot needs "until I have N"', () {
      var s = game.addAction(stateAt(game, level: 5), mining);
      expect(() => game.addAction(s, goblins), throwsA(isA<ActivityError>()));
      s = game.addAction(
        stateAt(game, level: 5),
        mining,
        stop: StopCondition.untilHave('copper_ore', 5),
      );
      s = game.addAction(s, goblins);
      expect(s.queue, hasLength(1));
    });

    test('conditions that don\'t fit the action are refused', () {
      final s = stateAt(game, level: 5);
      for (final (a, stop) in [
        (mining, const StopCondition.untilGrey()),
        (goblins, const StopCondition.untilCrafted(1)),
        (goblins, StopCondition.untilHave('copper_ore', 1)),
      ]) {
        expect(
          () => game.addAction(s, a, stop: stop),
          throwsA(isA<ActivityError>()),
        );
      }
    });

    test('"until I have N" opens at level 5', () {
      final s = stateAt(game, level: 4);
      expect(
        () => game.addAction(
          s,
          goblins,
          stop: StopCondition.untilHave('goblin_hide', 2),
        ),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 5: stop and remove', () {
    GameState three() {
      var s = stateAt(game, level: 8, location: 'goblin_woods');
      s = game.addAction(
        s,
        goblins,
        stop: StopCondition.untilHave('goblin_hide', 50),
      );
      s = game.addAction(
        s,
        brutes,
        stop: StopCondition.untilHave('goblin_hide', 99),
      );
      return game.addAction(s, mining);
    }

    test('Stop ends the running action and starts the next', () {
      final s = game.stopActivity(three());
      expect(s.activity!.activity, brutes);
      expect(s.queue.map((p) => p.activity), [mining]);
    });

    test('removing a queued action keeps the rest in order', () {
      final s = game.removeAction(three(), 1);
      expect(s.activity!.activity, goblins);
      expect(s.queue.map((p) => p.activity), [mining]);
    });

    test('removing the running action is Stop', () {
      final s = game.removeAction(three(), 0);
      expect(s.activity!.activity, brutes);
    });
  });

  group('losing (spec 0003 §5)', () {
    // A level 1 player (5 Attack) knocks 5 HP off before being killed.
    final g = arenaGame([
      monster(
        'ogre',
        hp: 100,
        attack: 100,
        xp: 100,
        extra: {
          'drops': [
            {'item': 'goblin_hide', 'chance': 1.0},
          ],
        },
      ),
      monster('imp'),
    ]);
    GameState fightingOgre() => g.addAction(
      stateAt(g, location: 'arena'),
      const Activity.fight('ogre'),
    );

    test('criterion 6: 75% of the XP for the health share, no loot', () {
      final r = g.applySteps(fightingOgre(), 10);
      final lost = all<FightLost>(r).single;
      expect(lost.share, 0.05);
      expect(lost.xp, 3); // 100 x 0.75 x 0.05 = 3.75, rounded down
      expect(r.state.xp, 3);
      expect(r.state.inventory, isEmpty);
      expect(r.state.activity, isNotNull, reason: 'one loss is not the end');
    });

    test('criterion 6: the share fades by colour; nothing earned is lost', () {
      // Level 5 (9 Attack) against a level 1 ogre: 4 below, green, 60%.
      final start = stateAt(
        g,
        location: 'arena',
        level: 5,
        inventory: {'copper_ore': 3},
      );
      final xp0 = start.xp;
      final s = g.addAction(start, const Activity.fight('ogre'));
      final r = g.applySteps(s, 10);
      final lost = all<FightLost>(r).single;
      expect(lost.share, 0.09);
      expect(lost.xp, 4); // 100 x 0.75 x 0.09 x 60% = 4.05
      expect(r.state.xp, xp0 + 4);
      expect(r.state.inventory, {'copper_ore': 3});
    });

    test('criterion 7: the action gives up after 3 losses in a row', () {
      final r = g.applySteps(fightingOgre(), 100);
      expect(all<FightLost>(r), hasLength(3));
      expect(all<ActivityEnded>(r).single.reason, EndReason.defeated);
      expect(r.state.bank, 70, reason: '3 rounds fought, then resting');
    });

    test('criterion 7: a win resets the count', () {
      var s = g.addAction(
        stateAt(g, location: 'arena'),
        const Activity.fight('imp'),
      );
      s.activity!.lossStreak = 2;
      s = g.applySteps(s, 10).state;
      expect(s.activity!.lossStreak, 0);
    });
  });

  test('criterion 8: bank cap 10,000 at level 1, +500 per level', () {
    expect(game.bankCap(stateAt(game)), 10000);
    expect(game.bankCap(stateAt(game, level: 10)), 14500);
  });

  test('levels 5 and 8 announce the queue', () {
    expect(
      game.levelNews(5),
      contains(const LevelNews(NewsKind.queueSlots, '2')),
    );
    expect(game.levelNews(5), contains(const LevelNews(NewsKind.untilN, '')));
    expect(
      game.levelNews(8),
      contains(const LevelNews(NewsKind.queueSlots, '3')),
    );
  });

  test('criterion 10: a version 2 save becomes a 1-action queue', () {
    final json = stateAt(game, location: 'goblin_woods').toJson()
      ..['version'] = 2
      ..remove('queue')
      ..['activity'] = {
        'kind': 'fight',
        'target': 'goblin',
        'progress': 6,
        'fight': {'playerHp': 20, 'enemyHp': 7, 'round': 2},
      };
    final s = GameState.fromJson(json);
    expect(s.activity!.activity, goblins);
    expect(s.activity!.stop, const StopCondition.untilGrey());
    expect(s.activity!.progress, 6);
    expect(s.activity!.fight!.enemyHp, 7);
    expect(s.queue, isEmpty);
  });
}
