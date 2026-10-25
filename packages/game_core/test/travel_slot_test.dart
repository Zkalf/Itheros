// Travel in the queue: spec 0016, acceptance criteria 1-18 and 20-24.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const goblins = Activity.fight('goblin');
  const brutes = Activity.fight('goblin_brute');
  const skeletons = Activity.fight('skeleton');
  const mining = Activity.gather('copper_vein');
  const sword = Activity.craft('copper_sword');
  Activity travel(String to) => Activity.travel(to);
  final someOre = StopCondition.untilHave('copper_ore', 3);
  final someHides = StopCondition.untilHave('goblin_hide', 50);

  List<Activity> planned(GameState s) => [
    if (s.activity case final run?) run.activity,
    for (final p in s.queue) p.activity,
  ];

  Matcher refused(String message) => throwsA(
    isA<ActivityError>().having((e) => e.message, 'message', message),
  );

  /// At Goblin Woods, fighting goblins, with a walk to Copper Hills and
  /// mining queued.
  GameState fightThenMine() {
    var s = stateAt(game, location: 'goblin_woods');
    s = game.addAction(s, goblins, stop: someHides);
    return game.addAction(s, mining, stop: someOre);
  }

  group('slots', () {
    test('criterion 1: a new save has 5 queue slots', () {
      expect(game.queueSlots(stateAt(game)), 5);
    });

    test('criteria 2 and 8: the running action and travel count', () {
      // Camp: a walk to the woods runs, goblins wait (2 of 5).
      var s = game.addAction(stateAt(game), goblins, stop: someHides);
      expect(planned(s), [travel('goblin_woods'), goblins]);
      // A walk to the hills and mining (4 of 5).
      s = game.addAction(s, mining, stop: someOre);
      expect(planned(s), [
        travel('goblin_woods'),
        goblins,
        travel('copper_hills'),
        mining,
      ]);
      expect(
        () => game.addAction(s, skeletons),
        refused(
          'The queue is full. The walk to Old Graveyard needs a slot too.',
        ),
      );
    });

    test('criterion 3: a walk of two legs takes one slot', () {
      // Copper Hills -> Old Graveyard: via Goblin Woods (300 + 400).
      var s = stateAt(game, location: 'copper_hills');
      s = game.addAction(s, skeletons);
      expect(planned(s), [travel('old_graveyard'), skeletons]);
      final r = game.applySteps(s, 700);
      expect(r.events.whereType<Arrived>().map((e) => e.location), [
        'goblin_woods',
        'old_graveyard',
      ]);
      expect(r.state.activity!.activity, skeletons);
    });

    test('criterion 4: the data check refuses queueSlots below 2', () {
      final economy = dataJson('economy')..['queueSlots'] = 1;
      expect(
        () => loadGameData(overrides: {'economy': economy}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('adding', () {
    test('criterion 5: an action at the end place goes in alone', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.addAction(s, goblins, stop: someHides);
      s = game.addAction(s, brutes);
      expect(planned(s), [goblins, brutes]);
    });

    test('criterion 6: an action elsewhere goes in after a walk there', () {
      expect(planned(fightThenMine()), [
        goblins,
        travel('copper_hills'),
        mining,
      ]);
    });

    test('criterion 6: a recipe walks to the nearest forge from there', () {
      // From Copper Hills, Camp (400) is the nearest forge.
      final s = game.addAction(fightThenMine(), sword);
      expect(planned(s).skip(3), [travel('camp'), sword]);
    });

    test('criterion 7: two actions in one area take one walk', () {
      var s = game.addAction(stateAt(game), goblins, stop: someHides);
      s = game.addAction(s, brutes);
      expect(planned(s), [travel('goblin_woods'), goblins, brutes]);
    });

    test('criterion 9: a walk to the end place is refused', () {
      final s = game.addAction(stateAt(game), goblins, stop: someHides);
      expect(
        () => game.addAction(s, travel('goblin_woods')),
        refused('The queue already ends at Goblin Woods.'),
      );
    });

    test('a walk from the Travel list takes one slot', () {
      var s = fightThenMine();
      s = game.addAction(s, travel('camp'));
      expect(planned(s).last, travel('camp'));
      expect(planned(s), hasLength(4));
    });

    test('an action behind the fog is refused', () {
      // Grey Moor: no explored area next to it.
      expect(
        () => game.addAction(fightThenMine(), const Activity.fight('wolf')),
        refused('The way there is in the fog'),
      );
    });

    test('a walk behind a "never" action is refused', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.addAction(s, goblins, stop: someHides);
      s = game.addAction(s, mining);
      expect(
        () => game.addAction(s, travel('camp')),
        refused(
          'The last action never stops. Change its stop condition first.',
        ),
      );
    });

    test('a monster in two areas is fought where the queue ends', () {
      final world = dataJson('world');
      final hills = (world['locations'] as List)
          .cast<Map<String, Object?>>()
          .firstWhere((l) => l['id'] == 'copper_hills');
      hills['enemies'] = ['goblin'];
      final g = newTestGame(overrides: {'world': world});
      var s = stateAt(g, location: 'goblin_woods');
      s = g.addAction(s, brutes, stop: someHides);
      s = g.addAction(s, mining, stop: someOre);
      s = g.addAction(s, goblins);
      expect(planned(s), [brutes, travel('copper_hills'), mining, goblins]);
    });

    test('an action where a walk from the Travel list ends needs no walk', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.addAction(s, goblins, stop: someHides);
      s = game.addAction(s, travel('copper_hills'));
      s = game.addAction(s, mining);
      expect(planned(s), [goblins, travel('copper_hills'), mining]);
    });

    test('a reroll walks to the nearest forge first', () {
      const key = 'bone_sword@uncommon+crit2';
      final s = game.startActivity(
        stateAt(
          game,
          level: 10,
          location: 'copper_hills',
          inventory: {key: 1, 'uncommon_dust': 3},
        ),
        const Activity.reroll(key),
      );
      expect(planned(s), [travel('camp'), const Activity.reroll(key)]);
    });

    test('the screens read the walk an action needs, with its steps', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.addAction(s, goblins, stop: someHides);
      expect(game.walkFirst(s, mining), (place: 'copper_hills', steps: 300));
      expect(game.walkFirst(s, brutes), isNull);
      expect(game.walkFirst(s, travel('camp')), isNull);
      expect(game.walkSteps(s, 'goblin_woods', 'copper_hills'), 300);
    });

    test('each arrival carries the steps of its leg', () {
      final s = game.addAction(stateAt(game), goblins, stop: someHides);
      final r = game.applySteps(s, 200);
      final arrived = r.events.whereType<Arrived>().single;
      expect(arrived.location, 'goblin_woods');
      expect(arrived.steps, 200);
    });

    test('a full queue refuses with "The queue is full."', () {
      var s = fightThenMine();
      s = game.addAction(s, travel('camp'));
      s = game.addAction(s, travel('mirror_lake'));
      expect(
        () => game.addAction(s, travel('camp')),
        refused('The queue is full.'),
      );
    });
  });

  group('starting', () {
    test('criterion 10: a walk costs the same steps as today', () {
      final s = game.addAction(stateAt(game), skeletons);
      expect(game.unitCost(s), 500, reason: 'Camp -> Old Graveyard direct');
    });

    test('criteria 11 and 12: an action at the wrong place is skipped', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.addAction(
        s,
        goblins,
        stop: StopCondition.untilHave('goblin_hide', 1),
      );
      // A queue without its walk, as no rule of spec 0016 makes it.
      s.queue.add(PlannedAction(mining, someOre));
      final r = game.applySteps(s, 2000);
      final skipped = r.events.whereType<ActionSkipped>().single;
      expect(skipped.activity, mining);
      expect(skipped.reason, SkipReason.notThere);
      expect(r.events.whereType<Arrived>(), isEmpty, reason: 'no walk');
      expect(r.state.location, 'goblin_woods');
      expect(r.state.activity, isNull, reason: 'resting');
    });

    test('criterion 12: a started action has no walk of its own', () {
      final s = game.stopActivity(fightThenMine());
      expect(s.activity!.activity, travel('copper_hills'));
      final r = game.applySteps(s, 300);
      expect(r.state.activity!.activity, mining);
      expect(r.state.activity!.leg, isNull);
    });
  });

  group('removing', () {
    test('criterion 13: removing an action keeps the walk before it', () {
      final s = game.removeAction(fightThenMine(), 2);
      expect(planned(s), [goblins, travel('copper_hills')]);
    });

    test('criterion 14: a walk that is not needed can go', () {
      var s = game.removeAction(fightThenMine(), 2);
      s = game.removeAction(s, 1);
      expect(planned(s), [goblins]);
    });

    test('criterion 14: a walk followed by a walk is not needed', () {
      var s = game.addAction(fightThenMine(), travel('camp'));
      s = game.removeAction(s, 2);
      s = game.addAction(s, travel('mirror_lake'));
      // goblins, walk to hills, walk to Camp, walk to Mirror Lake.
      s = game.removeAction(s, 2);
      expect(planned(s), [
        goblins,
        travel('copper_hills'),
        travel('mirror_lake'),
      ]);
    });

    test('criterion 15: a needed walk cannot go', () {
      expect(
        () => game.removeAction(fightThenMine(), 1),
        refused('Copper vein needs this walk. Remove Copper vein first.'),
      );
    });

    test('criterion 16: Stop on a needed running walk is refused', () {
      final s = game.addAction(stateAt(game), goblins, stop: someHides);
      const message = 'Goblin needs this walk. Remove Goblin first.';
      expect(() => game.stopActivity(s), refused(message));
      expect(() => game.removeAction(s, 0), refused(message));
    });

    test('criterion 16: Stop on a running walk that is not needed works', () {
      var s = game.addAction(stateAt(game), travel('goblin_woods'));
      s = game.addAction(s, travel('copper_hills'));
      s = game.stopActivity(s);
      expect(planned(s), [travel('copper_hills')]);
    });

    test('criterion 17: Stop on a fight starts the next action', () {
      final s = game.stopActivity(fightThenMine());
      expect(planned(s), [travel('copper_hills'), mining]);
    });
  });

  group('Start now', () {
    test('criterion 18: with an empty queue, it walks there first', () {
      final s = game.startActivity(stateAt(game), mining);
      expect(planned(s), [travel('copper_hills'), mining]);
      expect(s.queue.single.stop, const StopCondition.never());
    });

    test('criterion 18: an action here starts at once', () {
      final s = game.startActivity(
        stateAt(game, location: 'copper_hills'),
        mining,
      );
      expect(planned(s), [mining]);
    });

    test('criterion 20: with actions waiting, it clears the queue', () {
      final s = game.startActivity(fightThenMine(), skeletons);
      expect(planned(s), [travel('old_graveyard'), skeletons]);
    });

    test('criterion 20: it clears a needed running walk too', () {
      final s0 = game.addAction(stateAt(game), goblins, stop: someHides);
      final s = game.startActivity(s0, mining);
      expect(planned(s), [travel('copper_hills'), mining]);
    });

    test('criterion 21: unspent progress goes to the bank', () {
      final s0 = fightThenMine();
      s0.activity!.progress = 40;
      final s = game.startActivity(s0, skeletons);
      expect(s.bank, s0.bank + 40);
    });
  });

  group('save', () {
    // A version 10 save: the old rule walked inside the action.
    GameState load(
      Map<String, Object?> activity,
      List<Object?> queue, {
      String location = 'camp',
    }) {
      final json = stateAt(game, location: location).toJson()
        ..['version'] = 10
        ..['activity'] = activity
        ..['queue'] = queue;
      return game.migrate(GameState.fromJson(json));
    }

    Map<String, Object?> fight({String? leg}) => {
      'kind': 'fight',
      'target': 'goblin',
      'stop': {'kind': 'untilHave', 'item': 'goblin_hide', 'count': 3},
      'progress': 30,
      'leg': leg,
    };
    final waiting = [
      {
        'kind': 'gather',
        'target': 'copper_vein',
        'stop': {'kind': 'untilHave', 'item': 'copper_ore', 'count': 5},
      },
      {
        'kind': 'craft',
        'target': 'copper_sword',
        'stop': {'kind': 'never'},
      },
    ];

    test('criterion 22: a walking action becomes a walk, then the action', () {
      final s = load(fight(leg: 'goblin_woods'), const []);
      expect(s.activity!.activity, travel('goblin_woods'));
      expect(s.activity!.leg, 'goblin_woods');
      expect(s.activity!.progress, 30);
      expect(s.queue.single.activity, goblins);
      expect(s.queue.single.stop, StopCondition.untilHave('goblin_hide', 3));
    });

    test('criterion 23: each waiting action gets the walk it needs', () {
      final t = load(fight(), waiting, location: 'goblin_woods');
      expect(planned(t), [
        goblins,
        travel('copper_hills'),
        mining,
        travel('camp'),
        sword,
      ]);
      expect(t.queue[1].stop, StopCondition.untilHave('copper_ore', 5));
    });

    test('criterion 24: an over-full queue keeps all and refuses more', () {
      final s = load(fight(leg: 'goblin_woods'), waiting);
      expect(planned(s), [
        travel('goblin_woods'),
        goblins,
        travel('copper_hills'),
        mining,
        travel('camp'),
        sword,
      ]);
      expect(
        () => game.addAction(s, travel('mirror_lake')),
        refused('The queue is full.'),
      );
    });

    test('a version 11 save keeps its queue as it is', () {
      final s = fightThenMine();
      final t = game.migrate(GameState.fromJson(s.toJson()));
      expect(planned(t), planned(s));
      // Version 12 (spec 0017) keeps the format of 11.
      expect(GameState.schemaVersion, 12);
    });
  });
}
