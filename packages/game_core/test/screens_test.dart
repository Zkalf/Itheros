// More screens, rules side: spec 0006, acceptance criteria 3, 4, 7, 8, 11, 12.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  GameState reload(GameState s) => GameState.fromJson(
    jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
  );

  group('criterion 3: the fight log', () {
    // The player: 30 HP, 5 Attack, 2 Defense; no variance.
    final game = arenaGame([
      monster('rat', hp: 12, attack: 3),
      monster('ogre', hp: 100, attack: 50),
    ]);
    GameState fight(String enemy) => game.startActivity(
      game.newGame(seed: 1),
      Activity.fight(enemy),
      stop: const StopCondition.never(),
    );

    test('each round: damage dealt and taken; the last says who won', () {
      final s = game.applySteps(fight('rat'), 30).state;
      final log = s.activity!.log;
      expect([for (final r in log) r.round], [1, 2, 3]);
      expect([for (final r in log) r.dealt], [5, 5, 5]);
      expect([for (final r in log) r.taken], [2, 2, null]);
      expect([for (final r in log) r.outcome], [null, null, FightOutcome.won]);
    });

    test('a loss is logged as one', () {
      final s = game.applySteps(fight('ogre'), 10).state;
      final last = s.activity!.log.last;
      expect(
        (last.dealt, last.taken, last.outcome),
        (5, 49, FightOutcome.lost),
      );
    });

    test('only the last fightLogRounds rounds are kept, across fights', () {
      expect(game.data.fightLogRounds, 4);
      final s = game.applySteps(fight('rat'), 60).state;
      expect([for (final r in s.activity!.log) r.round], [3, 1, 2, 3]);
    });

    test('the log survives a reload', () {
      final s = game.applySteps(fight('rat'), 20).state;
      expect(reload(s).toJson(), s.toJson());
      expect(reload(s).activity!.log.length, 2);
    });
  });

  group('criterion 4: the tally', () {
    test('fights: won, lost and drops', () {
      final game = arenaGame([
        monster(
          'rat',
          hp: 5,
          extra: {
            'drops': [
              {'item': 'bones', 'chance': 1, 'count': 2},
            ],
          },
        ),
      ]);
      var s = game.startActivity(
        game.newGame(seed: 1),
        const Activity.fight('rat'),
        stop: const StopCondition.never(),
      );
      s = game.applySteps(s, 30).state;
      final run = reload(s).activity!;
      expect((run.won, run.lost), (3, 0));
      expect(run.gained, {'bones': 6});
    });

    test('losses count', () {
      final game = arenaGame([monster('ogre', hp: 100, attack: 50)]);
      var s = game.startActivity(
        game.newGame(seed: 1),
        const Activity.fight('ogre'),
        stop: const StopCondition.never(),
      );
      s = game.applySteps(s, 20).state;
      expect((s.activity!.won, s.activity!.lost), (0, 2));
    });

    test('gathering and crafting, with quality', () {
      final game = newTestGame();
      var s = stateAt(game, location: 'copper_hills', level: 3);
      s = game.startActivity(s, const Activity.gather('copper_vein'));
      s = game.applySteps(s, 250).state;
      expect(s.activity!.gained, {'copper_ore': 2});

      s = stateAt(game, level: 5, inventory: {'copper_ore': 60});
      s = game.startActivity(s, const Activity.craft('copper_sword'));
      s = game.applySteps(s, 1500).state;
      final gained = s.activity!.gained;
      expect(gained.values.fold(0, (a, b) => a + b), 10);
      expect(gained.keys.map((k) => game.data.itemOf(k)!.id).toSet(), {
        'copper_sword',
      });
    });

    test('a new action starts at zero', () {
      final game = newTestGame();
      var s = stateAt(game, location: 'copper_hills', level: 3);
      s = game.startActivity(s, const Activity.gather('copper_vein'));
      s = game.applySteps(s, 250).state;
      s = game.startActivity(s, const Activity.gather('copper_vein'));
      expect(s.activity!.gained, isEmpty);
      expect((s.activity!.won, s.activity!.lost), (0, 0));
    });

    test('a version 4 save loads with an empty tally', () {
      final game = newTestGame();
      var s = stateAt(game, location: 'copper_hills', level: 3);
      s = game.startActivity(s, const Activity.gather('copper_vein'));
      final json = s.toJson()..['version'] = 4;
      final act = (json['activity']! as Map<String, Object?>)
        ..remove('won')
        ..remove('lost')
        ..remove('gained')
        ..remove('log');
      json['activity'] = act;
      final loaded = game.migrate(GameState.fromJson(json));
      expect(loaded.activity!.gained, isEmpty);
      expect(loaded.activity!.log, isEmpty);
    });
  });

  group('criterion 7: found drops', () {
    test('the first drop from a monster marks it found', () {
      final game = arenaGame([
        monster(
          'rat',
          hp: 5,
          extra: {
            'drops': [
              {'item': 'bones', 'chance': 1, 'count': 1},
              {'item': 'goblin_hide', 'chance': 0, 'count': 1},
            ],
          },
        ),
      ]);
      var s = game.startActivity(
        game.newGame(seed: 1),
        const Activity.fight('rat'),
        stop: const StopCondition.never(),
      );
      expect(game.foundDrops(s, 'rat'), isEmpty);
      s = game.applySteps(s, 10).state;
      expect(s.counters['found.rat.bones'], 1);
      expect(game.foundDrops(s, 'rat'), ['bones']);
      expect(game.dropItems('rat'), ['bones', 'goblin_hide']);
    });

    test('bosses: the unique item counts as a drop', () {
      final game = newTestGame();
      final king = game.data.enemies['graveyard_king']!;
      expect(
        game.dropItems(king.id),
        containsAll(king.firstKillDrops.map((d) => d.item)),
      );
    });

    test('a version 4 save: found if killed and owned or worn now', () {
      final game = newTestGame();
      final json =
          (stateAt(game, location: 'old_graveyard', level: 7)
                ..counters['kills.skeleton'] = 3
                ..inventory['bones'] = 2
                ..equipment['mainHand'] = 'kings_blade@rare')
              .toJson()
            ..['version'] = 4;
      final s = game.migrate(GameState.fromJson(json));
      expect(game.foundDrops(s, 'skeleton'), ['bones']);
      // Owned, but the King was never killed.
      expect(game.foundDrops(s, 'graveyard_king'), isEmpty);
    });
  });

  group('criterion 8: craft until a quality', () {
    final game = newTestGame();

    test('offered for crafts from level 1 (spec 0008), not for fights', () {
      expect(
        game.stopKindsFor(stateAt(game), const Activity.craft('copper_sword')),
        contains(StopKind.untilQuality),
      );
      expect(
        game.stopKindsFor(
          stateAt(game, level: 5),
          const Activity.fight('goblin'),
        ),
        isNot(contains(StopKind.untilQuality)),
      );
    });

    test('common or an unknown quality is refused', () {
      final s = stateAt(game, level: 5, inventory: {'copper_ore': 5});
      for (final q in ['common', 'shiny']) {
        expect(
          () => game.startActivity(
            s,
            const Activity.craft('copper_sword'),
            stop: StopCondition.untilQuality(q),
          ),
          throwsA(isA<ActivityError>()),
        );
      }
    });

    test('stops on the first rare or better, not before', () {
      for (final seed in [1, 2, 3, 4, 5]) {
        var s = stateAt(
          game,
          level: 5,
          seed: seed,
          inventory: {'copper_ore': 5000},
        );
        s = game.startActivity(
          s,
          const Activity.craft('copper_sword'),
          stop: const StopCondition.untilQuality('rare'),
        );
        final report = game.applySteps(s, 150 * 400);
        final made = [
          for (final e in report.events)
            if (e is Crafted)
              game.data.qualities.indexOf(game.data.qualityOf(e.item)),
        ];
        final rare = game.data.qualities.indexWhere((q) => q.id == 'rare');
        expect(made.last, greaterThanOrEqualTo(rare), reason: 'seed $seed');
        expect(made.take(made.length - 1), everyElement(lessThan(rare)));
        expect(
          report.events.whereType<ActivityEnded>().single.reason,
          EndReason.enough,
        );
      }
    });

    test('out of materials it ends as today', () {
      var s = stateAt(game, level: 5, seed: 1, inventory: {'copper_ore': 5});
      s = game.startActivity(
        s,
        const Activity.craft('copper_sword'),
        stop: const StopCondition.untilQuality('legendary'),
      );
      final report = game.applySteps(s, 150);
      final made = report.events.whereType<Crafted>().single.item;
      if (game.data.qualityOf(made).id != 'legendary') {
        expect(
          report.events.whereType<ActivityEnded>().single.reason,
          EndReason.noMaterials,
        );
      }
    });
  });

  group('criterion 11: map data', () {
    final data = newTestGame().data;
    test('every area has a map position in 0-1', () {
      for (final l in data.locations.values) {
        final p = l.map;
        expect(p, isNotNull, reason: l.id);
        expect(p!.x, inInclusiveRange(0, 1), reason: l.id);
        expect(p.y, inInclusiveRange(0, 1), reason: l.id);
      }
    });
    test('the river is a line of points, the map has a shape', () {
      expect(data.mapRiver.length, greaterThanOrEqualTo(2));
      expect(data.mapAspect, greaterThan(0));
    });
  });

  group('map queries', () {
    final game = newTestGame();
    // Spec 0008 decision 5 replaced fog by level.
    test('areas away from explored ones are fogged, at any level', () {
      final s = stateAt(game, level: 30);
      expect(game.isFogged(s, 'old_graveyard'), isFalse);
      expect(game.isFogged(s, 'dragons_peak'), isTrue);
    });
    test('the nearest forge and its distance', () {
      expect(game.nearestForge(stateAt(game)), ('camp', 0));
      expect(game.nearestForge(stateAt(game, location: 'goblin_woods')), (
        'camp',
        200,
      ));
    });
  });
}
