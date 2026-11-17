// Spec 0023 (role-play, chapter 1), plan 0069 M1: the rules in game_core.
// Criteria 8-11, 13, 15, 17-19, 22-25, 27-30, 33, 40, 42-46.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const kingKill = 'kills.graveyard_king';

  /// [s] with a character of [origin].
  GameState hero(GameState s, String origin) => game.makeCharacter(
    s,
    name: 'Ash',
    gender: Gender.neither,
    origin: origin,
  );

  Iterable<String> pagesIn(StepReport r) =>
      r.events.whereType<LorePageFound>().map((e) => e.page);

  /// An old save: [s] written and read back as save [version].
  GameState saved(GameState s, {required int version}) {
    final json = s.toJson()..remove('heard');
    return GameState.fromJson({...json, 'version': version});
  }

  group('the data (spec 0023 §2.1, §2.7)', () {
    test('four people at their places', () {
      expect(
        {for (final p in data.people.values) p.id: p.location},
        {
          'odda': 'camp',
          'pell': 'goblin_woods',
          'aldous': 'old_graveyard',
          'jory': 'smugglers_cove',
        },
      );
      expect(data.people['pell']!.name, 'Pell');
      expect(data.people['pell']!.title, 'the charcoal burner');
      expect(data.people['jory']!.name, 'Jory Tarr');
    });

    test('16 lore pages, by place as §2.6 counts them', () {
      expect(data.pages, hasLength(16));
      int pagesAt(String place) =>
          data.pages.values.where((p) => p.place == place).length;
      expect(pagesAt('camp'), 2);
      expect(pagesAt('goblin_woods'), 3);
      expect(pagesAt('old_graveyard'), 4);
      expect(pagesAt('copper_hills'), 2);
      expect(pagesAt('mirror_lake'), 2);
      expect(pagesAt('smugglers_cove'), 3);
    });

    test('a King line for each teacher and the trainer', () {
      expect(data.campLines.keys.toSet(), {
        ...data.professions.keys,
        GameData.trainerId,
      });
    });

    test('criterion 8: no two people, teachers or trainers share a name', () {
      final json = dataJson('story');
      final people = [
        for (final p in json['people']! as List) {...p as Map<String, Object?>},
      ];
      people.first['name'] = 'Hilde';
      expect(
        () => loadGameData(
          overrides: {
            'story': {...json, 'people': people},
          },
        ),
        throwsFormatException,
      );
    });

    test('a line with an unknown page does not load', () {
      final json = dataJson('story');
      final people = [
        for (final p in json['people']! as List) {...p as Map<String, Object?>},
      ];
      people.first['lines'] = [
        {'id': 'x', 'page': 'no_such_page', 'text': 'Hello.'},
      ];
      expect(
        () => loadGameData(
          overrides: {
            'story': {...json, 'people': people},
          },
        ),
        throwsFormatException,
      );
    });
  });

  group('lines (spec 0023 §2.2)', () {
    test('criterion 9: a line without a condition is open on a new game', () {
      final s = game.newGame(seed: 1);
      expect(game.openLines(s, 'pell').map((l) => l.id), ['pell_1']);
      expect(game.hasNewLine(s, 'pell'), isTrue);
    });

    test('criterion 10: a line with a condition opens when it first holds', () {
      final s = game.newGame(seed: 1);
      expect(
        game.openLines(s, 'pell').map((l) => l.id),
        isNot(contains('pell_2')),
      );
      s.counters['kills.goblin'] = 49;
      expect(
        game.openLines(s, 'pell').map((l) => l.id),
        isNot(contains('pell_2')),
      );
      s.counters['kills.goblin'] = 50;
      expect(game.openLines(s, 'pell').map((l) => l.id), contains('pell_2'));
    });

    test('criterion 11: an origin line opens only for its origin', () {
      final plain = hero(game.newGame(seed: 1), 'miners_child');
      expect(
        game.openLines(plain, 'pell').map((l) => l.id),
        isNot(contains('pell_kin')),
      );
      final kin = hero(game.newGame(seed: 1), 'woodcutters_child');
      expect(
        game.openLines(kin, 'pell').map((l) => l.id),
        contains('pell_kin'),
      );
    });

    test(
      'criterion 13: hearing makes every open line of that person heard',
      () {
        var s = stateAt(game, location: 'goblin_woods')
          ..counters['kills.goblin'] = 50
          ..counters[kingKill] = 1;
        s = game.hear(s, 'pell').state;
        expect(s.heard, containsAll(['pell_1', 'pell_2', 'pell_3']));
        expect(game.hasNewLine(s, 'pell'), isFalse);
        // Only that person's lines.
        expect(s.heard.any((id) => id.startsWith('odda')), isFalse);
      },
    );

    test('a person must be here to be heard', () {
      final s = stateAt(game, location: 'camp');
      expect(() => game.hear(s, 'pell'), throwsA(isA<ActivityError>()));
    });

    test('hearing leaves its input untouched', () {
      final s = stateAt(game, location: 'goblin_woods');
      game.hear(s, 'pell');
      expect(s.heard, isEmpty);
    });

    test(
      'criterion 15: the newest line is the open line last in data order',
      () {
        final s = stateAt(game, location: 'goblin_woods');
        expect(game.newestLine(s, 'pell')!.id, 'pell_1');
        s.counters['kills.goblin'] = 50;
        expect(game.newestLine(s, 'pell')!.id, 'pell_2');
        s.counters[kingKill] = 1;
        expect(game.newestLine(s, 'pell')!.id, 'pell_3');
      },
    );

    test('a new line after hearing puts the dot back', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.hear(s, 'pell').state;
      expect(game.hasNewLine(s, 'pell'), isFalse);
      s.counters['kills.goblin'] = 50;
      expect(game.hasNewLine(s, 'pell'), isTrue);
    });

    test('the people here: Jory only where he is', () {
      final camp = stateAt(game, location: 'camp');
      expect(game.peopleHere(camp).map((p) => p.id), ['odda']);
      final cove = stateAt(game, location: 'smugglers_cove')
        ..revealed.add('smugglers_cove');
      expect(game.peopleHere(cove).map((p) => p.id), ['jory']);
    });
  });

  group('Camp after the King (spec 0023 §2.5)', () {
    test('criterion 17: before the King falls, the greeting and kin line of '
        'today', () {
      final s = hero(stateAt(game), 'miners_child');
      final hilde = data.professions['mining']!.teacher;
      final bram = data.professions['woodcutting']!.teacher;
      expect(
        game.teacherLine(s, 'mining'),
        game.fill(hilde.kinLine, s.character),
      );
      expect(
        game.teacherLine(s, 'woodcutting'),
        game.fill(bram.greeting, s.character),
      );
      expect(game.campLineWaiting(s, 'mining'), isFalse);
    });

    test('criterion 18: after the first King kill, each teacher has its King '
        'line, the kin teacher too', () {
      final s = hero(stateAt(game), 'miners_child')..counters[kingKill] = 1;
      for (final p in data.professions.keys) {
        expect(
          game.teacherLine(s, p),
          game.fill(data.campLines[p]!.text, s.character),
          reason: p,
        );
      }
    });

    test(
      'criterion 19: after the first King kill, Ysolde has her King line',
      () {
        final s = stateAt(game);
        expect(
          game.trainerLine(s),
          game.fill(data.trainer.greeting, s.character),
        );
        s.counters[kingKill] = 1;
        expect(
          game.trainerLine(s),
          game.fill(data.campLines[GameData.trainerId]!.text, s.character),
        );
      },
    );

    test('a King line waits until heard', () {
      var s = stateAt(game)..counters[kingKill] = 1;
      expect(game.campLineWaiting(s, 'mining'), isTrue);
      s = game.hear(s, 'mining').state;
      expect(game.campLineWaiting(s, 'mining'), isFalse);
      expect(game.campLineWaiting(s, GameData.trainerId), isTrue);
      s = game.hear(s, GameData.trainerId).state;
      expect(game.campLineWaiting(s, GameData.trainerId), isFalse);
    });
  });

  group('lore pages (spec 0023 §2.4)', () {
    test('criterion 22: a new game has The Guild\'s charter', () {
      expect(game.newGame(seed: 1).lore, contains('page_charter'));
    });

    test('criterion 23: the first visit to a place gives its page', () {
      var s = stateAt(game, level: 5);
      s = game.startActivity(s, const Activity.travel('goblin_woods'));
      final r = game.applySteps(s, 3000);
      expect(pagesIn(r), contains('page_goblin_tally'));
      expect(r.state.lore, contains('page_goblin_tally'));
    });

    test('criterion 24: the first King kill gives The King\'s last words', () {
      final s = stateAt(game, location: 'old_graveyard')
        ..counters[kingKill] = 1;
      final r = game.applySteps(s, 1);
      expect(pagesIn(r), contains('page_kings_words'));
    });

    test('criterion 25: hearing a line that gives a page adds the page', () {
      final s = stateAt(game, location: 'goblin_woods')
        ..counters['kills.goblin'] = 50;
      final heard = game.hear(s, 'pell');
      expect(heard.pages, ['page_pell']);
      expect(heard.state.lore, contains('page_pell'));
      // A second hearing gives nothing more.
      expect(game.hear(heard.state, 'pell').pages, isEmpty);
    });

    test('criterion 30: each page is found at most once', () {
      var s = stateAt(game, location: 'old_graveyard')..counters[kingKill] = 1;
      final first = game.applySteps(s, 1);
      s = first.state;
      final again = game.applySteps(s, 1);
      expect(pagesIn(first), contains('page_kings_words'));
      expect(pagesIn(again), isNot(contains('page_kings_words')));
      expect(
        again.state.lore.where((id) => id == 'page_kings_words'),
        hasLength(1),
      );
    });

    test('a page from a line never comes from a step', () {
      final s = stateAt(game, location: 'goblin_woods')
        ..counters['kills.goblin'] = 50;
      expect(pagesIn(game.applySteps(s, 1)), isNot(contains('page_pell')));
    });

    test('a find page is the only find page of its place', () {
      expect(data.findPageAt('goblin_woods')!.id, 'page_hunter_1');
      expect(data.findPageAt('copper_hills')!.id, 'page_hunter_3');
      expect(data.findPageAt('camp'), isNull);
    });
  });

  group('the find roll (spec 0023 §2.4)', () {
    /// The real game with [chance] as `pageChance`.
    Game withChance(double chance) => newTestGame(
      overrides: {
        'economy': roomyEconomy(),
        'story': {...dataJson('story'), 'pageChance': chance},
      },
    );

    /// Goblin fights at Goblin Woods for [steps] steps.
    StepReport fights(Game g, int steps, {int seed = 3}) {
      var s = stateAt(g, location: 'goblin_woods', level: 8, seed: seed)
        ..lore.add('page_goblin_tally');
      s = g.startActivity(s, const Activity.fight('goblin'));
      return g.applySteps(s, steps);
    }

    test('criterion 27: a fight rolls at pageChance', () {
      // At 1.0 the first fight finds it; at 0 none ever does.
      expect(pagesIn(fights(withChance(1), 2000)), contains('page_hunter_1'));
      expect(
        pagesIn(fights(withChance(0), 20000)),
        isNot(contains('page_hunter_1')),
      );
      // At the real 1%, over many seeds, about 1 fight in 100.
      final g = withChance(data.pageChance);
      var found = 0;
      var fought = 0;
      for (var seed = 1; seed <= 40; seed++) {
        final r = fights(g, 3000, seed: seed);
        int fightsIn(Iterable<GameEvent> events) =>
            events.where((e) => e is FightWon || e is FightLost).length;
        final at = [
          for (final (i, e) in r.events.indexed)
            if (e is LorePageFound && e.page == 'page_hunter_1') i,
        ].firstOrNull;
        if (at != null) {
          found++;
          // The fight before the page is the one that found it.
          fought += fightsIn(r.events.take(at));
        } else {
          fought += fightsIn(r.events);
        }
      }
      // Fights per find: about 100 (40 seeds, a wide range).
      expect(fought / (found == 0 ? 1 : found), inInclusiveRange(40, 250));
    });

    test('criterion 27: a gathered item rolls in its place too', () {
      final g = withChance(1);
      var s = stateAt(g, location: 'copper_hills', level: 5)
        ..lore.add('page_miners_carving');
      s = g.startActivity(s, const Activity.gather('copper_vein'));
      expect(pagesIn(g.applySteps(s, 2000)), contains('page_hunter_3'));
    });

    test('criterion 28: no roll once found', () {
      final g = withChance(1);
      final r = fights(g, 6000);
      expect(
        r.events.whereType<LorePageFound>().where(
          (e) => e.page == 'page_hunter_1',
        ),
        hasLength(1),
      );
    });

    test('criterion 29: the roll changes no fight, loot or gathering', () {
      final off = fights(withChance(0), 8000).state.toJson();
      final on = fights(withChance(1), 8000).state.toJson();
      for (final key in ['lore', 'achievements']) {
        off.remove(key);
        on.remove(key);
      }
      expect(on, off);
    });

    test('criterion 33: a page gives no XP, no item and no gold', () {
      final s = stateAt(game, location: 'old_graveyard')
        ..counters[kingKill] = 1;
      final r = game.applySteps(s, 1);
      expect(pagesIn(r), contains('page_kings_words'));
      expect(r.state.xp, s.xp);
      expect(r.state.inventory, s.inventory);
      final heard = game.hear(
        stateAt(game, location: 'goblin_woods')..counters['kills.goblin'] = 50,
        'pell',
      );
      expect(heard.state.xp, data.xpForLevel(1));
      expect(heard.state.inventory, isEmpty);
    });
  });

  group('lore achievements (spec 0023 §2.6)', () {
    const places = {
      'lore_camp': 'camp',
      'lore_goblin_woods': 'goblin_woods',
      'lore_old_graveyard': 'old_graveyard',
      'lore_copper_hills': 'copper_hills',
      'lore_mirror_lake': 'mirror_lake',
      'lore_smugglers_cove': 'smugglers_cove',
    };

    test('six milestones of +250 bank cap', () {
      places.forEach((id, place) {
        final a = data.achievements[id]!;
        expect(a.kind, AchievementKind.milestone, reason: id);
        expect(a.criterion, LoreCriterion(place), reason: id);
        expect(a.reward, const BankCapReward(250), reason: id);
      });
      expect(
        data.achievements['lore_smugglers_cove']!.stage,
        AchievementStage.mid,
      );
      expect(data.achievements['lore_camp']!.stage, AchievementStage.early);
    });

    test(
      'criterion 42: the lore of a place counts its pages and its notes',
      () {
        expect(data.loreOf('goblin_woods').toSet(), {
          'page_goblin_tally',
          'page_pell',
          'page_hunter_1',
          'lore_goblin_brute',
          'lore_old_bear',
        });
        expect(data.loreOf('old_graveyard'), hasLength(6));
        expect(data.loreOf('copper_hills'), hasLength(2));
      },
    );

    test('criterion 40: all the lore of a place earns its achievement', () {
      final s = stateAt(game);
      final lore = data.loreOf('goblin_woods');
      s.lore.addAll(lore.skip(1));
      expect(
        game
            .applySteps(s, 1)
            .events
            .whereType<AchievementUnlocked>()
            .map((e) => e.id),
        isNot(contains('lore_goblin_woods')),
      );
      s.lore.add(lore.first);
      final r = game.applySteps(s, 1);
      expect(
        r.events.whereType<AchievementUnlocked>().map((e) => e.id),
        contains('lore_goblin_woods'),
      );
      expect(game.bankCap(r.state), game.bankCap(s) + 250);
    });

    test('found N of M for a place', () {
      final s = stateAt(game)..lore.add('lore_goblin_brute');
      expect(game.loreCount(s, 'goblin_woods'), (found: 1, total: 5));
    });
  });

  group('the save (spec 0023 §4)', () {
    test(
      'criterion 43: an old save loads as version 17 with no lines heard',
      () {
        final old = saved(stateAt(game), version: 16);
        expect(GameState.schemaVersion, 17);
        expect(old.heard, isEmpty);
        final back = GameState.fromJson(game.load(old).state.toJson());
        expect(back.loadedVersion, 17);
      },
    );

    test('heard lines are saved', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.hear(s, 'pell').state;
      expect(GameState.fromJson(s.toJson()).heard, {'pell_1'});
    });

    test('criterion 44: an old save with a King kill gets The King\'s last '
        'words on load, without a report', () {
      final s = stateAt(game)
        ..counters[kingKill] = 1
        ..lore.clear();
      final loaded = game.load(saved(s, version: 16));
      expect(
        loaded.state.lore,
        containsAll(['page_kings_words', 'page_charter']),
      );
      expect(loaded.events.whereType<LorePageFound>(), isEmpty);
    });

    test('criterion 45: an old save gets the first-visit pages of its '
        'explored places', () {
      final s = stateAt(game)
        ..counters['visited.goblin_woods'] = 1
        ..counters['visited.copper_hills'] = 1
        ..lore.clear();
      final loaded = game.load(saved(s, version: 16)).state;
      expect(
        loaded.lore,
        containsAll(['page_goblin_tally', 'page_miners_carving']),
      );
      expect(loaded.lore, isNot(contains('page_sexton_ledger')));
      // Finds and lines wait for play.
      expect(loaded.lore, isNot(contains('page_hunter_1')));
      expect(loaded.lore, isNot(contains('page_pell')));
    });

    test('criterion 46: an old save keeps every lore note that it had', () {
      final s = stateAt(game)..lore.addAll(['lore_zombie', 'lore_wolf']);
      final loaded = game.load(saved(s, version: 16)).state;
      expect(loaded.lore, containsAll(['lore_zombie', 'lore_wolf']));
    });
  });
}
