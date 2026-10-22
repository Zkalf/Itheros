// Your character: spec 0012 criteria 3-7 (rules and data side), 10 and 11
// (plan 0014 M1). The screens are M2's.
import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  GameState make(
    GameState s, {
    String name = 'Zkalf',
    Gender gender = Gender.neither,
    String origin = 'miners_child',
  }) => game.makeCharacter(s, name: name, gender: gender, origin: origin);

  /// [s] with its character, professions, learned set and tools left out:
  /// the parts making a character may change.
  Map<String, Object?> rest(GameState s) => s.toJson()
    ..remove('character')
    ..remove('professions')
    ..remove('learned')
    ..remove('tools');

  group('the six origins (spec 0012 §2.1)', () {
    test('in order, one per profession, head start level 5', () {
      expect(data.origins.keys, [
        'miners_child',
        'woodcutters_child',
        'smiths_apprentice',
        'coast_fisher',
        'hunters_apprentice',
        'tavern_cook',
      ]);
      expect(
        [for (final o in data.origins.values) o.profession],
        ['mining', 'woodcutting', 'crafting', 'fishing', 'hunting', 'cooking'],
      );
      expect(data.headStartLevel, 5);
      expect(
        data.origins['coast_fisher']!.line,
        'You learned to read the water before you could read words.',
      );
    });

    test('an origin naming an unknown profession is refused', () {
      final origins = dataJson('origins');
      (origins['origins']! as List).add({
        'id': 'sailor',
        'title': 'Sailor',
        'line': 'Salt.',
        'profession': 'sailing',
      });
      expect(
        () => loadGameData(overrides: {'origins': origins}),
        throwsFormatException,
      );
    });

    test('two origins for one profession are refused', () {
      final origins = dataJson('origins');
      (origins['origins']! as List).add({
        'id': 'second_miner',
        'title': 'Second miner',
        'line': 'Rock.',
        'profession': 'mining',
      });
      expect(
        () => loadGameData(overrides: {'origins': origins}),
        throwsFormatException,
      );
    });
  });

  group('criterion 3: names', () {
    test('trimmed; empty becomes Wanderer; at most 20 characters', () {
      final s = game.newGame(seed: 1);
      expect(make(s, name: '  Zkalf ').character!.name, 'Zkalf');
      expect(make(s, name: '').character!.name, 'Wanderer');
      expect(make(s, name: '   ').character!.name, 'Wanderer');
      expect(
        make(s, name: 'Abcdefghijklmnopqrstuvwxyz').character!.name,
        'Abcdefghijklmnopqrst',
      );
    });

    test('renaming follows the same rules and keeps the rest', () {
      final s = make(game.newGame(seed: 1), gender: Gender.female);
      final r = game.renameCharacter(s, ' Ada  ');
      expect(r.character!.name, 'Ada');
      expect(r.character!.gender, Gender.female);
      expect(r.character!.origin, 'miners_child');
      expect(game.renameCharacter(s, '').character!.name, 'Wanderer');
      expect(s.character!.name, 'Zkalf', reason: 'input untouched');
    });

    test('renaming or changing gender needs a character', () {
      final s = game.newGame(seed: 1);
      expect(
        () => game.renameCharacter(s, 'Ada'),
        throwsA(isA<ActivityError>()),
      );
      expect(
        () => game.setGender(s, Gender.male),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 4: Set out on a new game', () {
    for (final o in data.origins.values) {
      test('${o.id}: ${o.profession} learned at level 5, tool worn', () {
        final s = game.newGame(seed: 3);
        final made = make(s, origin: o.id, gender: Gender.male);
        final p = data.professions[o.profession]!;
        expect(made.character!.origin, o.id);
        expect(made.character!.gender, Gender.male);
        expect(made.learned, {o.profession});
        expect(made.tools, {o.profession: p.teacher.starterTool});
        expect(game.professionLevel(made, o.profession), 5);
        expect(made.professions, {o.profession: data.professionXpForLevel(5)});
        expect(made.xp, s.xp);
        expect(game.level(made), game.level(s));
        expect(made.rngState, s.rngState, reason: 'no shared draw');
        expect(made.professionRng, s.professionRng, reason: 'no stream draw');
        expect(rest(made), rest(s));
        expect(s.character, isNull, reason: 'input untouched');
      });
    }

    test('a character is made once; an unknown origin is refused', () {
      final s = make(game.newGame(seed: 1));
      expect(() => make(s), throwsA(isA<ActivityError>()));
      expect(
        () => make(game.newGame(seed: 1), origin: 'sailor'),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 5: Set out on an old save', () {
    test('a higher profession level is kept, a lower one raised', () {
      final old = stateAt(game, level: 12, professionLevel: 8)
        ..professions['fishing'] = data.professionXpForLevel(2) + 3
        ..inventory['copper_ore'] = 4;
      final miner = make(old);
      expect(miner.professions, old.professions, reason: 'Mining 8 kept');
      expect(miner.tools, old.tools);
      expect(miner.learned, old.learned);
      expect(rest(miner), rest(old));

      final fisher = make(old, origin: 'coast_fisher');
      expect(fisher.professions['fishing'], data.professionXpForLevel(5));
      expect(
        {...fisher.professions}..remove('fishing'),
        {...old.professions}..remove('fishing'),
      );
      expect(rest(fisher), rest(old));
    });

    test('an unlearned profession is learned; a worn tool is kept', () {
      var old = game.newGame(seed: 2);
      old = game.learn(old, 'mining')
        ..xp = data.xpForLevel(7)
        ..tools['mining'] = 'copper_pickaxe@rare';
      final cook = make(old, origin: 'tavern_cook');
      expect(cook.learned, {'mining', 'cooking'});
      expect(cook.tools, {
        'mining': 'copper_pickaxe@rare',
        'cooking': 'old_pot',
      });
      expect(game.professionLevel(cook, 'cooking'), 5);
      final miner = make(old);
      expect(miner.tools, {'mining': 'copper_pickaxe@rare'});
      expect(game.professionLevel(miner, 'mining'), 5);
      expect(rest(miner), rest(old));
    });
  });

  group('criterion 6: gendered words', () {
    Character who(Gender g, [String name = 'Zkalf']) =>
        Character(name: name, gender: g, origin: 'miners_child');

    test('the Woodcutter title follows the gender', () {
      final title = data.origins['woodcutters_child']!.title;
      expect(game.fill(title, who(Gender.male)), "Woodcutter's son");
      expect(game.fill(title, who(Gender.female)), "Woodcutter's daughter");
      expect(game.fill(title, who(Gender.neither)), "Woodcutter's child");
    });

    test("Bram's level 10 tip follows the gender", () {
      final tip = data.professions['woodcutting']!.tips.firstWhere(
        (t) => t.level == 10,
      );
      expect(
        game.fill(tip.text, who(Gender.male)),
        contains('Point first, lad. Never the edge.'),
      );
      expect(
        game.fill(tip.text, who(Gender.female)),
        contains('Point first, lass.'),
      );
      expect(
        game.fill(tip.text, who(Gender.neither)),
        contains('Point first, friend.'),
      );
    });

    test('a name and a line without tokens', () {
      expect(
        game.fill('Fish biting, {name}?', who(Gender.male, 'Ada')),
        'Fish biting, Ada?',
      );
      expect(game.fill('No tokens here.', who(Gender.male)), 'No tokens here.');
      expect(game.fill('Hello, {name}.', null), 'Hello, Wanderer.');
    });

    test('changing gender changes the filled lines at once', () {
      final s = make(game.newGame(seed: 1), origin: 'woodcutters_child');
      final title = data.origins['woodcutters_child']!.title;
      expect(game.fill(title, s.character), "Woodcutter's child");
      final m = game.setGender(s, Gender.male);
      expect(game.fill(title, m.character), "Woodcutter's son");
      expect(m.character!.name, 'Zkalf');
      expect(m.character!.origin, 'woodcutters_child');
    });

    test('every {a|b|c} in data has three choices', () {
      final p = dataJson('professions');
      final first = (p['professions']! as List).first as Map<String, Object?>;
      (first['teacher']! as Map<String, Object?>)['kinLine'] =
          'A miner\'s {son|daughter}, {name}.';
      expect(
        () => loadGameData(overrides: {'professions': p}),
        throwsFormatException,
      );
      final o = dataJson('origins');
      ((o['origins']! as List).first as Map<String, Object?>)['title'] =
          'Miner\'s {son|daughter|child|kid}';
      expect(
        () => loadGameData(overrides: {'origins': o}),
        throwsFormatException,
      );
      final e = dataJson('economy');
      ((e['ranks']! as List).first as Map<String, Object?>)['line'] =
          'Welcome, {nam}.';
      expect(
        () => loadGameData(overrides: {'economy': e}),
        throwsFormatException,
      );
    });
  });

  group('criterion 7: teachers greet the player', () {
    test('every teacher has a greeting and a kin line naming the player', () {
      for (final p in data.professions.values) {
        expect(p.teacher.greeting, contains('{name}'), reason: p.id);
        expect(p.teacher.kinLine, contains('{name}'), reason: p.id);
      }
      expect(
        data.professions['fishing']!.teacher.greeting,
        'Fish biting, {name}?',
      );
    });

    test("the origin's teacher says the kin line, the others greet", () {
      final s = make(
        game.newGame(seed: 1),
        origin: 'coast_fisher',
        gender: Gender.female,
      );
      expect(
        game.teacherLine(s, 'fishing'),
        "A coast lass! Salt in your hair, Zkalf. Take my old rod; you'll not "
        'need telling how.',
      );
      expect(game.teacherLine(s, 'mining'), 'Back from the hills, Zkalf?');
      expect(game.isKin(s, 'fishing'), isTrue);
      expect(game.isKin(s, 'mining'), isFalse);
    });
  });

  test('criterion 8 (data): the Adventurer rank line names the player', () {
    expect(
      data.ranks.firstWhere((r) => r.name == 'Adventurer').line,
      contains('{name}'),
    );
  });

  group('criterion 10: save version 10', () {
    test('a version 9 save loads with no character, all else kept', () {
      final old = stateAt(game, level: 9, inventory: {'copper_ore': 2});
      final json = old.toJson()
        ..['version'] = 9
        ..remove('character');
      final s = game.migrate(GameState.fromJson(json));
      expect(s.character, isNull);
      expect(s.toJson(), old.toJson());
    });

    test('a new game has no character until Set out', () {
      expect(game.newGame(seed: 1).character, isNull);
    });

    test('a version 10 save keeps its character', () {
      final s = make(game.newGame(seed: 1), name: 'Ada', gender: Gender.female);
      final back = GameState.fromJson(s.toJson());
      expect(back.loadedVersion, 10);
      expect(GameState.schemaVersion, 10);
      expect(back.character!.name, 'Ada');
      expect(back.character!.gender, Gender.female);
      expect(back.character!.origin, 'miners_child');
      expect(back.toJson(), s.toJson());
    });
  });

  test('criterion 11: the walkers are made as Miner\'s child', () {
    for (final w in Walker.values) {
      final r = simulate(game, stepsPerDay: 0, days: 1, walker: w);
      expect(r.finalState.character!.origin, 'miners_child', reason: w.name);
      expect(game.professionLevel(r.finalState, 'mining'), 5, reason: w.name);
    }
  });
}
