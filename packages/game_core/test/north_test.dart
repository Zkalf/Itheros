// Spec 0025 (role-play and quests, chapters 2 and 3: the north), plan 0072
// M1: the data and the rules in game_core.
// Criteria 5-6 (the data part), 8-17, 19-24, 26, 28-33, 35 and 37-39.
// Criterion 18 (the learn line on the sheet) is on screen: M2.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const chiefKill = 'kills.ogre_chieftain';
  const dragonKill = 'kills.young_dragon';
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

  List<String> open(GameState s, String person) =>
      game.openLines(s, person).map((l) => l.id).toList();

  /// [s] with [quests] done, as if handed in long ago.
  GameState doneWith(GameState s, Iterable<String> quests) {
    for (final q in quests) {
      s.quests[q] = const QuestProgress.done();
    }
    return s;
  }

  const chapter1 = [
    'odda_goblins',
    'hilde_ore',
    'bram_logs',
    'sigrun_deer',
    'wen_perch',
    'pell_hides',
    'garrow_blade',
    'garrow_vest',
    'marta_skewers',
    'pell_brutes',
    'pell_bear',
    'odda_graveyard',
    'aldous_guard',
    'aldous_cloth',
    'garrow_shield',
    'odda_king',
    'jory_bass',
  ];

  const chapter2 = [
    'maud_wolves',
    'maud_ghosts',
    'maud_bandits',
    'tobin_spiders',
    'tobin_trolls',
    'tobin_chieftain',
    'maud_vest',
    'maud_lamps',
    'odda_pelts',
    'hilde_iron',
    'bram_ash',
    'sigrun_elk',
    'wen_trout',
    'marta_roast',
    'garrow_helm',
    'tobin_silk',
    'garrow_troll',
  ];

  const chapter3 = [
    'corvin_golems',
    'corvin_cores',
    'corvin_harpies',
    'nessa_wyverns',
    'nessa_drakes',
    'nessa_dragon',
    'corvin_wraiths',
    'corvin_feathers',
    'nessa_ward',
    'odda_proof',
    'jory_seal',
    'hilde_mithril',
    'bram_pine',
    'wen_char',
    'sigrun_ibex',
    'marta_soup',
    'garrow_mithril',
  ];

  group('people (spec 0025 §2.2)', () {
    test(
      'criterion 5: four new people at their places, with name and title',
      () {
        final want = {
          'maud': ('Maud', 'the warden', 'grey_moor'),
          'tobin': ('Tobin', 'the carter', 'troll_bridge'),
          'corvin': ('Corvin', 'the lodge master', 'mountain_pass'),
          'nessa': ('Nessa', 'the dragon-watcher', 'dragons_peak'),
        };
        want.forEach((id, w) {
          final p = data.people[id]!;
          expect((p.name, p.title, p.location), w, reason: id);
          final s = stateAt(game, location: w.$3);
          expect(game.peopleHere(s).map((p) => p.id), [id], reason: id);
        });
      },
    );

    test('criterion 6: no two characters share a name', () {
      final names = [
        for (final p in data.people.values) p.name,
        for (final p in data.professions.values) p.teacher.name,
        data.trainer.name,
      ];
      expect(names.toSet(), hasLength(names.length));
      expect(names, hasLength(15));
    });
  });

  group('lines (spec 0025 §2.3, §2.10)', () {
    test('criterion 8: a new line opens when its condition first holds', () {
      final s = stateAt(game, location: 'grey_moor');
      expect(open(s, 'maud'), ['maud_1']);
      s.counters['kills.bandit'] = 49;
      expect(open(s, 'maud'), isNot(contains('maud_2')));
      s.counters['kills.bandit'] = 50;
      expect(open(s, 'maud'), contains('maud_2'));
      s.counters[chiefKill] = 1;
      expect(open(s, 'maud'), contains('maud_3'));
      s.counters[dragonKill] = 1;
      expect(game.newestLine(s, 'maud')!.id, 'maud_4');

      final t = stateAt(game)..counters['kills.troll'] = 30;
      expect(open(t, 'tobin'), contains('tobin_2'));
      final n = stateAt(game)..counters['kills.wyvern'] = 34;
      expect(open(n, 'nessa'), isNot(contains('nessa_2')));
      n.counters['kills.wyvern'] = 35;
      expect(open(n, 'nessa'), contains('nessa_2'));
      final o = stateAt(game);
      expect(open(o, 'odda'), isNot(contains('odda_4')));
      o.counters['visited.grey_moor'] = 1;
      expect(open(o, 'odda'), contains('odda_4'));
    });

    test('criterion 9: each new origin line is open only for its origin', () {
      const kin = {
        'maud': ('maud_kin', 'hunters_apprentice'),
        'tobin': ('tobin_kin', 'miners_child'),
        'corvin': ('corvin_kin', 'tavern_cook'),
        'nessa': ('nessa_kin', 'smiths_apprentice'),
      };
      kin.forEach((person, k) {
        final mine = hero(game.newGame(seed: 1), k.$2);
        expect(open(mine, person), contains(k.$1), reason: person);
        final other = hero(
          game.newGame(seed: 1),
          k.$2 == 'coast_fisher' ? 'tavern_cook' : 'coast_fisher',
        );
        expect(open(other, person), isNot(contains(k.$1)), reason: person);
      });
    });

    test('criterion 10: the new lines of chapter 1 people stand after their '
        'lines of today and show on top once open', () {
      List<String> ids(String p) =>
          data.people[p]!.lines.map((l) => l.id).toList();
      expect(ids('odda').skip(3), ['odda_4', 'odda_5', 'odda_6']);
      expect(ids('pell').last, 'pell_4');
      expect(ids('aldous').last, 'aldous_4');
      expect(ids('jory').skip(ids('jory').length - 2), ['jory_4', 'jory_5']);

      final s = stateAt(game)
        ..counters[kingKill] = 1
        ..counters['kills.goblin'] = 50
        ..counters['kills.skeleton'] = 25
        ..counters[chiefKill] = 1;
      expect(game.newestLine(s, 'odda')!.id, 'odda_5');
      expect(game.newestLine(s, 'jory')!.id, 'jory_4');
      s.counters[dragonKill] = 1;
      expect(game.newestLine(s, 'odda')!.id, 'odda_6');
      expect(game.newestLine(s, 'pell')!.id, 'pell_4');
      expect(game.newestLine(s, 'aldous')!.id, 'aldous_4');
      expect(game.newestLine(s, 'jory')!.id, 'jory_5');
    });

    test("criterion 11: Corvin's newest line is corvin_3 after 35 Wyvern "
        'kills', () {
      final s = stateAt(game, location: 'mountain_pass')
        ..counters['kills.harpy'] = 30;
      expect(game.newestLine(s, 'corvin')!.id, 'corvin_2');
      s.counters['kills.wyvern'] = 35;
      expect(game.newestLine(s, 'corvin')!.id, 'corvin_3');
    });
  });

  group('Camp lines (spec 0025 §2.4)', () {
    final whos = [...data.professions.keys, GameData.trainerId];

    String ids(String who) => data.campLines[who]!.map((l) => l.id).join(',');

    test('criterion 12: each teacher and Ysolde hold a list of Camp lines', () {
      for (final who in whos) {
        final name = who == GameData.trainerId
            ? 'ysolde'
            : data.professions[who]!.teacher.name.toLowerCase();
        expect(ids(who), 'king_$name,chief_$name,dragon_$name', reason: who);
      }
    });

    String line(GameState s, String who) => who == GameData.trainerId
        ? game.trainerLine(s)
        : game.teacherLine(s, who);

    String filled(GameState s, String id) => game.fill(
      [for (final ls in data.campLines.values) ...ls]
          .firstWhere((l) => l.id == id)
          .text,
      s.character,
    );

    test('criterion 13: after the first Chieftain kill, each sheet shows the '
        'Chieftain line', () {
      final s = hero(stateAt(game), 'miners_child')
        ..counters[kingKill] = 1
        ..counters[chiefKill] = 1;
      for (final who in whos) {
        expect(
          line(s, who),
          filled(s, data.campLines[who]![1].id),
          reason: who,
        );
      }
    });

    test('criterion 14: after the first Young Dragon kill, each sheet shows '
        'the dragon line, not the Chieftain line', () {
      final s = hero(stateAt(game), 'miners_child')
        ..counters[kingKill] = 1
        ..counters[chiefKill] = 1
        ..counters[dragonKill] = 1;
      for (final who in whos) {
        expect(
          line(s, who),
          filled(s, data.campLines[who]![2].id),
          reason: who,
        );
      }
    });

    test('criterion 15: an open Camp line that is not heard puts a dot', () {
      var s = stateAt(game)..counters[kingKill] = 1;
      s = game.hear(s, 'mining').state;
      expect(game.campLineWaiting(s, 'mining'), isFalse);
      s.counters[chiefKill] = 1;
      expect(game.campLineWaiting(s, 'mining'), isTrue);
      expect(game.campLineWaiting(s, GameData.trainerId), isTrue);
    });

    test('criterion 16: opening the sheet hears every open Camp line', () {
      var s = stateAt(game)
        ..counters[kingKill] = 1
        ..counters[chiefKill] = 1
        ..counters[dragonKill] = 1;
      s = game.hear(s, 'cooking').state;
      expect(
        s.heard,
        containsAll(['king_marta', 'chief_marta', 'dragon_marta']),
      );
      expect(game.campLineWaiting(s, 'cooking'), isFalse);
      s = game.hear(s, GameData.trainerId).state;
      expect(
        s.heard,
        containsAll(['king_ysolde', 'chief_ysolde', 'dragon_ysolde']),
      );
      expect(game.campLineWaiting(s, GameData.trainerId), isFalse);
      // Only the lines of who was heard.
      expect(s.heard, isNot(contains('chief_hilde')));
    });

    test('criterion 17: before the Chieftain, the King line or the greeting '
        'of today', () {
      final s = hero(stateAt(game), 'miners_child');
      final bram = data.professions['woodcutting']!.teacher;
      expect(
        game.teacherLine(s, 'woodcutting'),
        game.fill(bram.greeting, s.character),
      );
      s.counters[kingKill] = 1;
      expect(line(s, 'woodcutting'), filled(s, 'king_bram'));
      expect(line(s, GameData.trainerId), filled(s, 'king_ysolde'));
      // A Chieftain kill without a King kill: the Chieftain line, no gap.
      final t = stateAt(game)..counters[chiefKill] = 1;
      expect(line(t, 'woodcutting'), filled(t, 'chief_bram'));
    });
  });

  group('lore pages (spec 0025 §2.5, §2.10)', () {
    test('18 new pages, by place as §2.6 counts them', () {
      int pagesAt(String place) =>
          data.pages.values.where((p) => p.place == place).length;
      expect(pagesAt('grey_moor'), 3);
      expect(pagesAt('iron_ridge'), 2);
      expect(pagesAt('troll_bridge'), 4);
      expect(pagesAt('mountain_pass'), 3);
      expect(pagesAt('mithril_deep'), 2);
      expect(pagesAt('dragons_peak'), 4);
      expect(data.pages, hasLength(34));
    });

    test(
      'criterion 19: the first visit to each north place gives its page',
      () {
        const first = {
          'grey_moor': 'page_odda_letter',
          'iron_ridge': 'page_bandit_ledger',
          'troll_bridge': 'page_toll_board',
          'mountain_pass': 'page_lodge_book',
          'mithril_deep': 'page_deep_marks',
          'dragons_peak': 'page_cage',
        };
        first.forEach((place, page) {
          final s = stateAt(game, location: place)
            ..counters['visited.$place'] = 1;
          expect(pagesIn(game.applySteps(s, 1)), contains(page), reason: place);
        });
      },
    );

    test(
      "criterion 20: the first Chieftain kill gives The Chieftain's hoard",
      () {
        final s = stateAt(game)..counters[chiefKill] = 1;
        expect(
          pagesIn(game.applySteps(s, 1)),
          contains('page_chieftains_hoard'),
        );
      },
    );

    test("criterion 21: 30 Wraith kills give The King's war chest", () {
      final s = stateAt(game)..counters['kills.wraith'] = 29;
      expect(pagesIn(game.applySteps(s, 1)), isNot(contains('page_war_chest')));
      s.counters['kills.wraith'] = 30;
      expect(pagesIn(game.applySteps(s, 1)), contains('page_war_chest'));
    });

    test('criterion 22: the first Young Dragon kill gives The old scale', () {
      final s = stateAt(game)..counters[dragonKill] = 1;
      expect(pagesIn(game.applySteps(s, 1)), contains('page_old_scale'));
    });

    test("criterion 23: hearing maud_2, tobin_2 or nessa_2 gives that person's "
        'story page', () {
      const story = {
        'maud': ('grey_moor', 'kills.bandit', 50, 'page_maud'),
        'tobin': ('troll_bridge', 'kills.troll', 30, 'page_tobin'),
        'nessa': ('dragons_peak', 'kills.wyvern', 35, 'page_nessa'),
      };
      story.forEach((person, w) {
        final s = stateAt(game, location: w.$1)..counters[w.$2] = w.$3;
        final heard = game.hear(s, person);
        expect(heard.pages, [w.$4], reason: person);
      });
    });

    group('criterion 24: the finds of the north (seeded)', () {
      Game withChance(double chance) => newTestGame(
        overrides: {
          'economy': roomyEconomy(),
          'story': {...dataJson('story'), 'pageChance': chance},
        },
      );

      test('the find pages of the north places', () {
        expect(data.findPageAt('grey_moor')!.id, 'page_hunter_5');
        expect(data.findPageAt('iron_ridge')!.id, 'page_miners_slate');
        expect(data.findPageAt('troll_bridge')!.id, 'page_hunter_6');
        expect(data.findPageAt('mountain_pass')!.id, 'page_hunter_7');
        expect(data.findPageAt('mithril_deep')!.id, 'page_lost_lamp');
        expect(data.findPageAt('dragons_peak')!.id, 'page_foremans_letter');
      });

      test("Dragon's Peak: a fight finds it", () {
        final g = withChance(1);
        var s = stateAt(g, location: 'dragons_peak', level: 30)
          ..lore.add('page_cage');
        s = g.startActivity(s, const Activity.fight('wyvern'));
        expect(
          pagesIn(g.applySteps(s, 6000)),
          contains('page_foremans_letter'),
        );
      });

      test('Iron Ridge and Mithril Deep: a gathered item finds it', () {
        final g = withChance(1);
        for (final (place, spot, page, visit) in [
          (
            'iron_ridge',
            'iron_vein',
            'page_miners_slate',
            'page_bandit_ledger',
          ),
          ('mithril_deep', 'mithril_vein', 'page_lost_lamp', 'page_deep_marks'),
        ]) {
          var s = stateAt(g, location: place, level: 20, professionLevel: 20)
            ..lore.add(visit);
          s = g.startActivity(s, Activity.gather(spot));
          expect(pagesIn(g.applySteps(s, 3000)), contains(page), reason: place);
        }
      });
    });
  });

  group('lore achievements (spec 0025 §2.6-§2.7)', () {
    const want = {
      'lore_grey_moor': ('Moor Tales', AchievementStage.mid, 'grey_moor', 6),
      'lore_iron_ridge': (
        'Bandits\' Ledger',
        AchievementStage.mid,
        'iron_ridge',
        2,
      ),
      'lore_troll_bridge': (
        'Toll Paid',
        AchievementStage.mid,
        'troll_bridge',
        7,
      ),
      'lore_mountain_pass': (
        'Lodge Secrets',
        AchievementStage.late,
        'mountain_pass',
        6,
      ),
      'lore_mithril_deep': (
        'Silver Dark',
        AchievementStage.late,
        'mithril_deep',
        2,
      ),
      'lore_dragons_peak': (
        'Dragon Lore',
        AchievementStage.late,
        'dragons_peak',
        7,
      ),
    };

    test('six milestones of +250 bank cap, with their lore', () {
      want.forEach((id, w) {
        final a = data.achievements[id]!;
        expect(a.name, w.$1, reason: id);
        expect(a.stage, w.$2, reason: id);
        expect(a.kind, AchievementKind.milestone, reason: id);
        expect(a.criterion, LoreCriterion(w.$3), reason: id);
        expect(a.reward, const BankCapReward(250), reason: id);
        expect(data.loreOf(w.$3), hasLength(w.$4), reason: id);
      });
    });

    test(
      'criterion 26: all the lore of a north place earns its achievement',
      () {
        final s = stateAt(game);
        final lore = data.loreOf('troll_bridge');
        s.lore.addAll(lore.skip(1));
        expect(
          game
              .applySteps(s, 1)
              .events
              .whereType<AchievementUnlocked>()
              .map((e) => e.id),
          isNot(contains('lore_troll_bridge')),
        );
        s.lore.add(lore.first);
        final r = game.applySteps(s, 1);
        expect(
          r.events.whereType<AchievementUnlocked>().map((e) => e.id),
          contains('lore_troll_bridge'),
        );
        expect(game.bankCap(r.state), game.bankCap(s) + 250);
      },
    );
  });

  group('quests (spec 0025 §2.8)', () {
    test('criterion 28: 51 quests, each after and each giver exists', () {
      expect(data.quests, hasLength(51));
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

    test('criterion 29: the 34 new quests stand after the 17 of chapter 1, in '
        'the order of §2.8', () {
      expect(data.quests.keys.toList(), [
        ...chapter1,
        ...chapter2,
        ...chapter3,
      ]);
    });

    test('criterion 30: handing in odda_king offers the five quests', () {
      final before = doneWith(stateAt(game), chapter1.take(15));
      expect([
        for (final id in chapter2)
          if (game.questState(before, id) == QuestState.offered) id,
      ], isEmpty);
      final s = doneWith(stateAt(game), chapter1);
      expect(
        [
          for (final id in [...chapter2, ...chapter3])
            if (game.questState(s, id) == QuestState.offered) id,
        ],
        ['maud_wolves', 'odda_pelts', 'hilde_iron', 'bram_ash', 'sigrun_elk'],
      );
    });

    test('criterion 30: the hand-in of odda_king itself offers them', () {
      var s = doneWith(
        stateAt(game, level: 10),
        chapter1.where((q) => q != 'odda_king'),
      );
      s = game.takeQuest(
        s..location = game.questPlace('odda_king'),
        'odda_king',
      );
      s.counters[kingKill] = (s.counters[kingKill] ?? 0) + 1;
      s = game.handIn(s, 'odda_king').state;
      expect(game.questState(s, 'maud_wolves'), QuestState.offered);
    });

    test('criterion 31: handing in tobin_chieftain offers the six quests', () {
      final s = doneWith(stateAt(game), [...chapter1, ...chapter2]);
      expect(
        [
          for (final id in chapter3)
            if (game.questState(s, id) == QuestState.offered) id,
        ],
        [
          'corvin_golems',
          'jory_seal',
          'hilde_mithril',
          'bram_pine',
          'wen_char',
          'sigrun_ibex',
        ],
      );
    });

    test('criterion 32: with chapter 1 done, the first offered quest is '
        "Maud's", () {
      final s = doneWith(stateAt(game), chapter1);
      final first = data.quests.keys.firstWhere(
        (id) => game.questState(s, id) == QuestState.offered,
      );
      expect(first, 'maud_wolves');
      expect(game.questPlace(first), 'grey_moor');
    });

    test('criterion 33: the 34 new quests give 36,600 XP', () {
      int xp(Iterable<String> ids) =>
          ids.fold(0, (n, id) => n + data.quests[id]!.xp);
      expect(xp(chapter2), 10100);
      expect(xp(chapter3), 26500);
      expect(xp([...chapter2, ...chapter3]), 36600);
    });

    test('the tasks of §2.8', () {
      (TaskKind, String, int) t(String id) {
        final k = data.quests[id]!.task;
        return (k.kind, k.target, k.count);
      }

      expect(t('maud_wolves'), (TaskKind.kill, 'wolf', 40));
      expect(t('tobin_chieftain'), (TaskKind.kill, 'ogre_chieftain', 1));
      expect(t('maud_vest'), (TaskKind.wear, 'wolf_pelt_vest', 1));
      expect(t('maud_lamps'), (TaskKind.bring, 'ectoplasm', 10));
      expect(t('marta_roast'), (TaskKind.craft, 'elk_roast', 5));
      expect(t('garrow_helm'), (TaskKind.craft, 'iron_helm', 1));
      expect(t('corvin_cores'), (TaskKind.bring, 'stone_core', 8));
      expect(t('nessa_dragon'), (TaskKind.kill, 'young_dragon', 1));
      expect(t('wen_char'), (TaskKind.gather, 'arctic_char', 15));
      expect(
        [
          ...chapter2,
          ...chapter3,
        ].where((id) => data.quests[id]!.task.kind == TaskKind.visit),
        isEmpty,
      );
    });
  });

  group('the end words (spec 0025 §2.9)', () {
    test('criterion 35: the end words come from the data', () {
      expect(
        data.questEndWords,
        'The dragon is dead, and the lands are quiet. For now.',
      );
    });

    test('empty end words do not load', () {
      expect(
        () => loadGameData(
          overrides: {
            'quests': {...dataJson('quests'), 'endWords': ''},
          },
        ),
        throwsFormatException,
      );
    });
  });

  group('the save (spec 0025 §4)', () {
    GameState saved(GameState s) =>
        GameState.fromJson({...s.toJson(), 'version': 18});

    test('criterion 37: the save version stays 18', () {
      expect(GameState.schemaVersion, 18);
    });

    test("criterion 38: an old save with a Chieftain kill gets The "
        "Chieftain's hoard on load, without a report", () {
      final s = stateAt(game)
        ..counters[chiefKill] = 1
        ..lore.clear();
      final loaded = game.load(saved(s));
      expect(loaded.state.lore, contains('page_chieftains_hoard'));
      expect(loaded.events.whereType<LorePageFound>(), isEmpty);
    });

    test('criterion 39: an old save with odda_king done gets the five quests '
        'offered, and its old kills do not count', () {
      final s = doneWith(stateAt(game), chapter1)..counters['kills.wolf'] = 500;
      final loaded = game.load(saved(s)).state;
      for (final id in [
        'maud_wolves',
        'odda_pelts',
        'hilde_iron',
        'bram_ash',
        'sigrun_elk',
      ]) {
        expect(game.questState(loaded, id), QuestState.offered, reason: id);
      }
      final took = game.takeQuest(
        loaded..location = 'grey_moor',
        'maud_wolves',
      );
      expect(game.questCount(took, 'maud_wolves'), 0);
    });
  });
}
