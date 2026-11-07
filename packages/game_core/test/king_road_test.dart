// The Graveyard King opens the river: spec 0008 amendment 5, criteria 1-13,
// 19-21 (the events) and 23. Criterion 25 is in pacing_test.dart.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const king = 'graveyard_king';
  RouteDef road() => game.data.route('old_graveyard', 'grey_moor')!;

  /// A player who has stood in Camp and Old Graveyard, never across.
  GameState south({String location = 'camp', int level = 1}) =>
      stateAt(game, location: location, level: level)
        ..explored.addAll({'camp', 'old_graveyard'});

  GameState killed(GameState s) => s..counters['kills.$king'] = 1;

  Matcher crossError() => throwsA(
    isA<ActivityError>().having(
      (e) => e.message,
      'message',
      'Beat the Graveyard King to cross.',
    ),
  );

  /// Steps until the King falls once, or [max] steps.
  StepReport fightKing(GameState s, {int max = 20000}) {
    final at = s..location = 'old_graveyard';
    return game.applySteps(
      game.startActivity(at, const Activity.fight(king)),
      max,
    );
  }

  group('the road', () {
    test('criterion 1: only Old Graveyard - Grey Moor waits, for the King', () {
      final waiting = [
        for (final r in game.data.routes)
          if (r.opensOn != null) r,
      ];
      expect(waiting, hasLength(1));
      expect(
        {waiting.single.from, waiting.single.to},
        {'old_graveyard', 'grey_moor'},
      );
      expect(waiting.single.opensOn, king);
    });

    test('criterion 2: a new save has the road closed', () {
      final s = game.newGame(seed: 1);
      expect(game.roadOpen(s, road()), isFalse);
      expect(game.closedRoads(s), [road()]);
    });

    test('criterion 3: one King kill opens it', () {
      expect(game.roadOpen(killed(south()), road()), isTrue);
      expect(game.closedRoads(killed(south())), isEmpty);
    });

    test('criterion 4: both ends explored, no kill, opens it', () {
      final s = south()..explored.add('grey_moor');
      expect(s.counters['kills.$king'], isNull);
      expect(game.roadOpen(s, road()), isTrue);
    });

    test('criterion 5: a loss to the King does not close it again', () {
      final r = fightKing(killed(south()), max: 3000);
      expect(r.events.whereType<FightLost>(), isNotEmpty);
      expect(game.roadOpen(r.state, road()), isTrue);
    });
  });

  group('travel and the queue', () {
    test('criterion 6: from Camp no area beyond the river is in reach', () {
      final reach = game.openLocationsByDistance(south()).keys;
      expect(reach, contains('old_graveyard'));
      for (final beyond in [
        'grey_moor',
        'iron_ridge',
        'troll_bridge',
        'mountain_pass',
        'mithril_deep',
        'dragons_peak',
      ]) {
        expect(reach, isNot(contains(beyond)), reason: beyond);
      }
    });

    test('criterion 7: Travel to Grey Moor says to beat the King', () {
      expect(
        () => game.startActivity(
          south(location: 'old_graveyard'),
          const Activity.travel('grey_moor'),
        ),
        crossError(),
      );
    });

    test('criterion 8: adding a Wolf fight from Camp says the same', () {
      expect(
        () => game.addAction(south(), const Activity.fight('wolf')),
        crossError(),
      );
      final busy = game.startActivity(
        south(),
        const Activity.travel('old_graveyard'),
      );
      expect(
        () => game.addAction(busy, const Activity.fight('wolf')),
        crossError(),
      );
    });

    test('fog keeps its own words', () {
      expect(
        // Iron Ridge lies in the fog behind the closed road: fog's words.
        () => game.startActivity(
          south(location: 'old_graveyard'),
          const Activity.travel('iron_ridge'),
        ),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            isNot(contains('Graveyard King')),
          ),
        ),
      );
    });

    test('criterion 9: a waiting walk across the river is skipped', () {
      final s = game.startActivity(
        south(),
        const Activity.travel('old_graveyard'),
      );
      // A queue from before the road closed, as an old save may hold.
      s.queue.add(
        PlannedAction(
          const Activity.travel('grey_moor'),
          StopCondition.defaultFor(const Activity.travel('grey_moor')),
        ),
      );
      final r = game.applySteps(s, 2000);
      final skipped = r.events.whereType<ActionSkipped>().single;
      expect(skipped.activity, const Activity.travel('grey_moor'));
      expect(skipped.reason, SkipReason.noRoute);
      expect(skipped.closedBy, king);
      expect(r.state.location, 'old_graveyard');
    });

    test('criterion 10: with the road open, Camp to Grey Moor goes through '
        'Old Graveyard', () {
      final s = game.startActivity(
        killed(south()),
        const Activity.travel('grey_moor'),
      );
      final r = game.applySteps(s, 3000);
      expect(r.events.whereType<Arrived>().map((a) => a.location), [
        'old_graveyard',
        'grey_moor',
      ]);
    });

    test('criterion 11: a walk already on the closed leg arrives', () {
      final s = south(location: 'old_graveyard')
        ..activity = RunningActivity(
          const Activity.travel('grey_moor'),
          leg: 'grey_moor',
        );
      final r = game.applySteps(s, 1000);
      expect(r.state.location, 'grey_moor');
      expect(r.state.explored, contains('grey_moor'));
      expect(game.roadOpen(r.state, road()), isTrue);
    });
  });

  group('fog', () {
    test('criterion 12: Grey Moor shows across the closed road', () {
      final s = south();
      expect(game.roadOpen(s, road()), isFalse);
      expect(game.isFogged(s, 'grey_moor'), isFalse);
      expect(game.enemiesAt(s, 'grey_moor'), contains('wolf'));
    });

    test('criterion 13: Iron Ridge and Troll Bridge stay fogged', () {
      final s = south();
      expect(game.isFogged(s, 'iron_ridge'), isTrue);
      expect(game.isFogged(s, 'troll_bridge'), isTrue);
    });
  });

  group('the first kill', () {
    test('criterion 19: the first King kill opens the road', () {
      final r = fightKing(south(level: 30));
      final won = r.events.whereType<FightWon>().where((e) => e.enemy == king);
      expect(won, isNotEmpty);
      final opened = r.events.whereType<RoadOpened>().single;
      expect(opened.boss, king);
      expect({opened.from, opened.to}, {'old_graveyard', 'grey_moor'});
      // It comes right after the first win.
      expect(r.events.indexOf(opened), r.events.indexOf(won.first) + 1);
      expect(game.roadOpen(r.state, road()), isTrue);
    });

    test('criterion 20: a later King kill opens nothing', () {
      final r = fightKing(killed(south(level: 30)));
      expect(r.events.whereType<FightWon>(), isNotEmpty);
      expect(r.events.whereType<RoadOpened>(), isEmpty);
    });

    test('criterion 21: a road open by exploring gets no line', () {
      final r = fightKing(south(level: 30)..explored.add('grey_moor'));
      expect(r.events.whereType<FightWon>(), isNotEmpty);
      expect(r.events.whereType<RoadOpened>(), isEmpty);
    });
  });

  // Advice never sends the player across a closed road (verifier, plan 0055
  // M1): Grey Moor shows, but Next goal must not name its monsters.
  test('Next goal names no Grey Moor monster while the road is closed', () {
    final moor = game.data.locations['grey_moor']!;
    bool there(Activity a) => switch (a.kind) {
      ActivityKind.fight => moor.enemies.contains(a.target),
      ActivityKind.gather => moor.nodes.contains(a.target),
      _ => false,
    };
    bool acrossRiver(Goal? g) => switch (g) {
      FightGoal(:final enemy) => moor.enemies.contains(enemy),
      CollectGoal(:final source) => there(source),
      ProfessionGoal(:final target) => there(target),
      _ => false,
    };
    final levels = [for (var l = 8; l <= 14; l++) l];
    // With the road open, some level is sent there: the check has teeth.
    expect(
      levels.any((l) => acrossRiver(game.nextGoal(killed(south(level: l))))),
      isTrue,
    );
    for (final l in levels) {
      expect(
        acrossRiver(game.nextGoal(south(level: l))),
        isFalse,
        reason: '$l',
      );
    }
  });

  test('criterion 23: the save schema stays at 16', () {
    expect(GameState.schemaVersion, 16);
  });
}
