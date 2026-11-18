// Spec 0024 (quests, chapter 1), plan 0071 M1: the rules in game_core.
// Criteria 1-22, 44 and 45.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  /// [s] at the place of [quest]'s giver, with [quest] taken.
  GameState took(GameState s, String quest) =>
      game.takeQuest(s..location = game.questPlace(quest), quest);

  /// [s] with [quests] done, as if handed in long ago.
  GameState doneWith(GameState s, List<String> quests) {
    for (final q in quests) {
      s.quests[q] = const QuestProgress.done();
    }
    return s;
  }

  group('the data (spec 0024 §2.8, criterion 6)', () {
    test('17 quests, in the order of §2.8, 3,490 XP in all', () {
      expect(data.quests, hasLength(17));
      expect(data.quests.keys.first, 'odda_goblins');
      expect(data.quests.keys.last, 'jory_bass');
      expect(data.quests.values.fold(0, (n, q) => n + q.xp), 3490);
    });

    test('the counts that the owner raised', () {
      int count(String id) => data.quests[id]!.task.count;
      expect(count('odda_goblins'), 10);
      expect(count('hilde_ore'), 25);
      expect(count('aldous_guard'), 40);
      expect(count('jory_bass'), 15);
      expect(data.quests['pell_hides']!.task.kind, TaskKind.bring);
      expect(data.quests['garrow_vest']!.task.kind, TaskKind.wear);
      expect(data.quests['odda_graveyard']!.task.kind, TaskKind.visit);
    });

    test('each giver is a person or a teacher, each after a quest', () {
      for (final q in data.quests.values) {
        expect(
          data.people.containsKey(q.giver) ||
              data.professions.containsKey(q.giver),
          isTrue,
          reason: q.id,
        );
        if (q.after case final a?) {
          expect(data.quests.containsKey(a), isTrue, reason: q.id);
        }
      }
    });

    test('a quest after an unknown quest is refused', () {
      final quests = dataJson('quests');
      final list = [...(quests['quests']! as List<Object?>)];
      list[1] = {...(list[1]! as Map<String, Object?>), 'after': 'nope'};
      expect(
        () => loadGameData(overrides: {'quests': {'quests': list}}),
        throwsFormatException,
      );
    });

    test('a task with an unknown target is refused', () {
      final quests = dataJson('quests');
      final list = [...(quests['quests']! as List<Object?>)];
      final first = list[0]! as Map<String, Object?>;
      list[0] = {
        ...first,
        'task': {...(first['task']! as Map<String, Object?>), 'target': 'nope'},
      };
      expect(
        () => loadGameData(overrides: {'quests': {'quests': list}}),
        throwsFormatException,
      );
    });
  });

  group('the states (spec 0024 §2.2)', () {
    test('criterion 1: a new game offers odda_goblins and jory_bass, '
        'every other quest is closed', () {
      final s = game.newGame(seed: 1);
      for (final id in data.quests.keys) {
        expect(
          game.questState(s, id),
          id == 'odda_goblins' || id == 'jory_bass'
              ? QuestState.offered
              : QuestState.closed,
          reason: id,
        );
      }
    });

    test('criterion 2: a quest is offered when its after quest is done', () {
      final s = doneWith(stateAt(game), ['odda_goblins']);
      expect(game.questState(s, 'pell_hides'), QuestState.offered);
      expect(game.questState(s, 'pell_brutes'), QuestState.closed);
    });

    test('criterion 3: taking makes it taken, and costs nothing', () {
      final s = stateAt(game, stepBank: 500);
      final t = took(s, 'odda_goblins');
      expect(game.questState(t, 'odda_goblins'), QuestState.taken);
      expect(t.stepBank, 500);
      expect(t.inventory, s.inventory);
      expect(t.xp, s.xp);
    });

    test('a quest is taken only at its giver, and only when offered', () {
      final s = stateAt(game, location: 'goblin_woods');
      expect(
        () => game.takeQuest(s, 'odda_goblins'),
        throwsA(isA<ActivityError>()),
      );
      expect(
        () => took(stateAt(game), 'pell_hides'),
        throwsA(isA<ActivityError>()),
      );
    });

    test('criterion 4: a done quest stays done and is not offered again', () {
      var s = took(stateAt(game), 'odda_goblins');
      s.counters['kills.goblin'] = 10;
      s = game.handIn(s, 'odda_goblins').state;
      expect(game.questState(s, 'odda_goblins'), QuestState.done);
      expect(
        () => game.takeQuest(s, 'odda_goblins'),
        throwsA(isA<ActivityError>()),
      );
      s.counters['kills.goblin'] = 500;
      final back = GameState.fromJson(s.toJson());
      expect(game.questState(back, 'odda_goblins'), QuestState.done);
    });

    test('criterion 5: more than one quest taken at once', () {
      var s = doneWith(stateAt(game), ['odda_goblins']);
      s = took(s, 'hilde_ore');
      s = took(s, 'bram_logs');
      s = took(s, 'pell_hides');
      expect(
        [
          for (final id in data.quests.keys)
            if (game.questState(s, id) == QuestState.taken) id,
        ],
        ['hilde_ore', 'bram_logs', 'pell_hides'],
      );
    });
  });

  group('the counts (spec 0024 §2.3)', () {
    GameState open(List<String> done) => doneWith(stateAt(game), done);

    test('criterion 7: a kill task counts only the kills after taking', () {
      final s = open([])..counters['kills.goblin'] = 30;
      final t = took(s, 'odda_goblins');
      expect(game.questCount(t, 'odda_goblins'), 0);
      t.counters['kills.goblin'] = 33;
      expect(game.questCount(t, 'odda_goblins'), 3);
      expect(game.questReady(t, 'odda_goblins'), isFalse);
      t.counters['kills.goblin'] = 40;
      expect(game.questReady(t, 'odda_goblins'), isTrue);
    });

    test('criterion 8: a gather task counts only the items after taking', () {
      final s = open(['odda_goblins'])..counters['gathered.copper_ore'] = 90;
      final t = took(s, 'hilde_ore');
      t.counters['gathered.copper_ore'] = 100;
      expect(game.questCount(t, 'hilde_ore'), 10);
    });

    test('criterion 9: a craft task counts only the crafts after taking', () {
      final s = open(['odda_goblins', 'sigrun_deer'])
        ..counters['crafted.venison_skewer'] = 7;
      final t = took(s, 'marta_skewers');
      expect(game.questCount(t, 'marta_skewers'), 0);
      t.counters['crafted.venison_skewer'] = 9;
      expect(game.questCount(t, 'marta_skewers'), 2);
    });

    test('criterion 10: a bring task counts the items dropped or gathered '
        'after taking', () {
      final s = open(['odda_goblins'])
        ..counters['dropped.goblin_hide'] = 40
        ..inventory['goblin_hide'] = 40;
      final t = took(s, 'pell_hides');
      expect(game.questCount(t, 'pell_hides'), 0);
      t
        ..counters['dropped.goblin_hide'] = 46
        ..counters['gathered.goblin_hide'] = 2;
      expect(game.questCount(t, 'pell_hides'), 8);
    });

    test('criterion 11: a bring task is not ready while the bag holds fewer '
        'than N', () {
      final t = took(open(['odda_goblins']), 'pell_hides')
        ..counters['dropped.goblin_hide'] = 15
        ..inventory['goblin_hide'] = 11
        ..itemBank['goblin_hide'] = 20;
      expect(game.questReady(t, 'pell_hides'), isFalse);
      expect(game.questCount(t, 'pell_hides'), 11);
      t.inventory['goblin_hide'] = 15;
      expect(game.questReady(t, 'pell_hides'), isTrue);
    });

    test('criterion 12: a wear task is ready while the item is worn, of any '
        'quality, and not once it is taken off', () {
      final t = took(open(['odda_goblins', 'pell_hides']), 'garrow_vest');
      expect(game.questReady(t, 'garrow_vest'), isFalse);
      t.equipment['chest'] = data.keyFor('hide_vest', 'rare');
      expect(game.questReady(t, 'garrow_vest'), isTrue);
      t.equipment.remove('chest');
      expect(game.questReady(t, 'garrow_vest'), isFalse);
    });

    test('criterion 13: a visit task is ready when the hero arrives', () {
      final quests = ['odda_goblins', 'pell_hides', 'pell_brutes'];
      var s = took(open(quests), 'odda_graveyard');
      expect(game.questReady(s, 'odda_graveyard'), isFalse);
      s.stepBank = 0;
      s = game.startActivity(s, const Activity.travel('old_graveyard'));
      final r = game.applySteps(s, 5000);
      expect(r.state.location, 'old_graveyard');
      expect(game.questReady(r.state, 'odda_graveyard'), isTrue);
      expect(
        r.events.whereType<QuestReady>().map((e) => e.quest),
        ['odda_graveyard'],
      );
    });

    test('criterion 13: a visit task is ready at once for a hero who stands '
        'there when taking it', () {
      // No quest of the data asks for its giver's own place, so a custom
      // one: Aldous asks the hero to come to the graveyard.
      final custom = newTestGame(
        overrides: {
          'quests': {
            'quests': [
              {
                'id': 'here',
                'giver': 'aldous',
                'title': 'Here',
                'task': {
                  'kind': 'visit',
                  'target': 'old_graveyard',
                  'count': 1,
                  'words': 'Go to the Old Graveyard',
                },
                'xp': 10,
                'ask': 'Come.',
                'thanks': 'Thanks.',
              },
            ],
          },
        },
      );
      final s = stateAt(custom, location: 'old_graveyard');
      final t = custom.takeQuest(s, 'here');
      expect(custom.questReady(t, 'here'), isTrue);
      final back = GameState.fromJson(t.toJson());
      expect(custom.questReady(back, 'here'), isTrue);
    });

    test('criterion 14: a count never shows more than N', () {
      final t = took(open([]), 'odda_goblins')..counters['kills.goblin'] = 99;
      expect(game.questCount(t, 'odda_goblins'), 10);
    });

    test('criterion 15: a fight counts dropped.<item> for each item that it '
        'puts into the bag', () {
      var s = stateAt(game, location: 'goblin_woods', level: 8);
      s = game.startActivity(s, const Activity.fight('goblin'));
      final r = game.applySteps(s, 20000);
      final hides = r.state.counters['dropped.goblin_hide'] ?? 0;
      expect(hides, greaterThan(0));
      expect(hides, game.owned(r.state, 'goblin_hide'));
    });
  });

  group('hand-in and reward (spec 0024 §2.4)', () {
    GameState ready() =>
        took(stateAt(game, level: 3), 'odda_goblins')
          ..counters['kills.goblin'] = 10;

    test('criterion 16: hand in only for a ready quest at its giver', () {
      final notReady = took(stateAt(game), 'odda_goblins');
      expect(
        () => game.handIn(notReady, 'odda_goblins'),
        throwsA(isA<ActivityError>()),
      );
      final away = ready()..location = 'goblin_woods';
      expect(
        () => game.handIn(away, 'odda_goblins'),
        throwsA(isA<ActivityError>()),
      );
      expect(game.handIn(ready(), 'odda_goblins').state, isNotNull);
    });

    test("criterion 17: hand-in gives the quest's XP, with its level-ups", () {
      final s = took(stateAt(game), 'odda_goblins')
        ..xp = 0
        ..counters['kills.goblin'] = 10;
      final r = game.handIn(s, 'odda_goblins');
      expect(r.state.xp, 60);
      expect(r.events.whereType<LevelUp>().map((e) => e.level), [2]);
    });

    test('criterion 18: hand-in gives one supply chest, rolled then, which '
        'waits on the supply chest screen', () {
      final s = ready();
      final r = game.handIn(s, 'odda_goblins');
      expect(r.state.supplyChests, hasLength(s.supplyChests.length + 1));
      final chest = r.state.supplyChests.last;
      expect(chest.quest, 'odda_goblins');
      expect(chest.items, isNotEmpty);
      final back = GameState.fromJson(r.state.toJson());
      expect(back.supplyChests.last.quest, 'odda_goblins');
    });

    test('criterion 19: a quest chest does not change the daily chest', () {
      final s = ready()
        ..supplySteps['2026-11-18'] = 1200
        ..supplyPaid.add('2026-11-17');
      final r = game.handIn(s, 'odda_goblins').state;
      expect(r.supplySteps, {'2026-11-18': 1200});
      expect(r.supplyPaid, {'2026-11-17'});
    });

    test('criterion 20: a quest roll shifts no fight, drop, catch or craft '
        '(the fight and profession streams do not move)', () {
      final s = ready();
      final r = game.handIn(s, 'odda_goblins').state;
      expect(r.rngState, s.rngState);
      expect(r.professionRng, s.professionRng);
    });

    test('criterion 21: a bring quest takes N from the bag, the lowest '
        'quality first, and none from the bank', () {
      final custom = newTestGame(
        overrides: {
          'quests': {
            'quests': [
              {
                'id': 'daggers',
                'giver': 'odda',
                'title': 'Daggers',
                'task': {
                  'kind': 'bring',
                  'target': 'rusty_dagger',
                  'count': 2,
                  'words': 'Bring Odda 2 rusty daggers',
                },
                'xp': 10,
                'ask': 'Two daggers.',
                'thanks': 'Thanks.',
              },
            ],
          },
        },
      );
      final common = custom.data.keyFor('rusty_dagger', 'common');
      final rare = custom.data.keyFor('rusty_dagger', 'rare');
      final uncommon = custom.data.keyFor('rusty_dagger', 'uncommon');
      var s = custom.takeQuest(stateAt(custom), 'daggers');
      s
        ..counters['dropped.rusty_dagger'] = 3
        ..inventory[rare] = 1
        ..inventory[uncommon] = 1
        ..inventory[common] = 1
        ..itemBank[common] = 4;
      s = custom.handIn(s, 'daggers').state;
      expect(s.inventory, {rare: 1});
      expect(s.itemBank, {common: 4});
    });

    test('criterion 22: a hand-in adds a QuestDone event', () {
      final r = game.handIn(ready(), 'odda_goblins');
      final done = r.events.whereType<QuestDone>().single;
      expect(done.quest, 'odda_goblins');
      expect(done.xp, 60);
    });

    test('criterion 22: a task that becomes ready during a walk adds one '
        'QuestReady event', () {
      var s = took(stateAt(game, level: 8), 'odda_goblins')
        ..location = 'goblin_woods';
      s = game.startActivity(s, const Activity.fight('goblin'));
      final r = game.applySteps(s, 20000);
      expect(game.questReady(r.state, 'odda_goblins'), isTrue);
      expect(
        r.events.whereType<QuestReady>().map((e) => e.quest),
        ['odda_goblins'],
      );
    });

    test('the next quest of the line is offered after hand-in', () {
      final s = game.handIn(ready(), 'odda_goblins').state;
      for (final id in [
        'hilde_ore',
        'bram_logs',
        'sigrun_deer',
        'wen_perch',
        'pell_hides',
      ]) {
        expect(game.questState(s, id), QuestState.offered, reason: id);
      }
    });
  });

  group('save (spec 0024 §4)', () {
    /// An old save: [s] written and read back as save 17.
    GameState saved(GameState s) {
      final json = s.toJson()..remove('quests');
      return GameState.fromJson({...json, 'version': 17});
    }

    test('criterion 44: an old save loads as version 18 with no quest taken '
        'and odda_goblins offered', () {
      final old = saved(stateAt(game, level: 25)..counters['kills.goblin'] = 900);
      final loaded = game.load(old).state;
      final back = GameState.fromJson(loaded.toJson());
      expect(back.loadedVersion, 18);
      expect(back.quests, isEmpty);
      expect(game.questState(back, 'odda_goblins'), QuestState.offered);
    });

    test("criterion 45: an old save's kills before the update do not count",
        () {
      final old = saved(stateAt(game)..counters['kills.goblin'] = 900);
      final s = took(game.load(old).state, 'odda_goblins');
      expect(game.questCount(s, 'odda_goblins'), 0);
    });

    test('a taken quest keeps its count across a save', () {
      final s = took(stateAt(game)..counters['kills.goblin'] = 5, 'odda_goblins')
        ..counters['kills.goblin'] = 9;
      final back = GameState.fromJson(s.toJson());
      expect(game.questState(back, 'odda_goblins'), QuestState.taken);
      expect(game.questCount(back, 'odda_goblins'), 4);
    });
  });
}
