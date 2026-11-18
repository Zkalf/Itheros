// Spec 0024 (quests, chapter 1), plan 0071 M2: the marks on the rows and the
// quests on the sheets. Criteria 32-38.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'package:walkingrpg/game_controller.dart';

import 'ui_test.dart' show closeSheet, game, pumpGame, settle;

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final personSheet = key('person-sheet');
  final teacherSheet = key('teacher-sheet');
  String fill(String text) => game.fill(
    text,
    const Character(name: 'Ada', gender: Gender.neither, origin: 'tavern_cook'),
  );
  final goblins = game.data.quests['odda_goblins']!;

  Future<GameController> openOdda(
    WidgetTester t, {
    Map<String, int> counters = const {},
    void Function(GameState)? prepare,
  }) async {
    final (c, _) = await pumpGame(t, counters: counters, prepare: prepare);
    await t.ensureVisible(key('person-odda'));
    await t.tap(key('person-odda'));
    await settle(t, c);
    await t.pumpAndSettle();
    return c;
  }

  group('the marks (spec 0024 §2.6, §3.2)', () {
    testWidgets('criterion 32: a gold "!" while the person has an offered '
        'quest', (t) async {
      await pumpGame(t);
      expect(key('quest-offer-odda'), findsOneWidget);
      expect(key('quest-ready-odda'), findsNothing);
      // The teachers' quests open after Odda's first.
      expect(key('quest-offer-mining'), findsNothing);
    });

    testWidgets('a teacher with an offered quest shows the "!"', (t) async {
      await pumpGame(
        t,
        prepare: (s) => s.quests['odda_goblins'] = const QuestProgress.done(),
      );
      expect(key('quest-offer-mining'), findsOneWidget);
    });

    testWidgets('a taken quest that is not ready puts no mark', (t) async {
      await pumpGame(
        t,
        prepare: (s) => s.quests['odda_goblins'] = const QuestProgress.taken(0),
      );
      expect(key('quest-offer-odda'), findsNothing);
      expect(key('quest-ready-odda'), findsNothing);
    });

    testWidgets('criterion 33: a gold "?" while the person has a ready quest, '
        'also when they have an offered one', (t) async {
      await pumpGame(
        t,
        counters: {'kills.graveyard_king': 1},
        prepare: (s) {
          for (final q in [
            'odda_goblins',
            'pell_hides',
            'pell_brutes',
            'aldous_guard',
            'aldous_cloth',
          ]) {
            s.quests[q] = const QuestProgress.done();
          }
          // odda_graveyard offered, odda_king taken and ready.
          s.quests['odda_king'] = const QuestProgress.taken(0);
        },
      );
      expect(key('quest-ready-odda'), findsOneWidget);
      expect(key('quest-offer-odda'), findsNothing);
    });

    testWidgets('criterion 34: a row with a mark shows no dot', (t) async {
      final (c, _) = await pumpGame(t);
      // Odda's first line is not heard, so without the mark a dot shows.
      expect(c.game.hasNewLine(c.state, 'odda'), isTrue);
      expect(key('quest-offer-odda'), findsOneWidget);
      expect(key('person-dot-odda'), findsNothing);
    });
  });

  group('the sheets (spec 0024 §3.3)', () {
    testWidgets('criterion 35: an offered quest shows its title, ask, task '
        'words, reward and Take', (t) async {
      await openOdda(t);
      Finder inQuest(Finder f) =>
          find.descendant(of: key('quest-odda_goblins'), matching: f);
      expect(inQuest(find.text(goblins.title)), findsOneWidget);
      expect(inQuest(find.text('"${fill(goblins.ask)}"')), findsOneWidget);
      expect(inQuest(find.text(goblins.task.words)), findsOneWidget);
      expect(inQuest(find.text('60 XP and a supply chest')), findsOneWidget);
      expect(key('quest-take-odda_goblins'), findsOneWidget);
    });

    testWidgets('criterion 36: Take makes the quest taken with its count; a '
        'ready quest shows Hand in', (t) async {
      final c = await openOdda(t);
      await t.tap(key('quest-take-odda_goblins'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.game.questState(c.state, 'odda_goblins'), QuestState.taken);
      expect(
        find.descendant(
          of: key('quest-count-odda_goblins'),
          matching: find.text('0 of 10'),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      expect(key('quest-hand-in-odda_goblins'), findsNothing);
      await closeSheet(t);
      c.state.counters['kills.goblin'] = 10;
      await c.markSeen(const []);
      await t.pump();
      expect(key('quest-ready-odda'), findsOneWidget);
      await t.tap(key('person-odda'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(key('quest-hand-in-odda_goblins'), findsOneWidget);
    });

    testWidgets('criterion 37: after Hand in, the sheet shows the thanks, the '
        'XP and the chest', (t) async {
      final c = await openOdda(
        t,
        counters: {'kills.goblin': 10},
        prepare: (s) => s.quests['odda_goblins'] = const QuestProgress.taken(0),
      );
      final chests = c.state.supplyChests.length;
      await t.tap(key('quest-hand-in-odda_goblins'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.game.questState(c.state, 'odda_goblins'), QuestState.done);
      expect(c.state.supplyChests, hasLength(chests + 1));
      expect(
        find.descendant(
          of: key('quest-thanks-odda_goblins'),
          matching: find.text('"${fill(goblins.thanks)}"'),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      expect(find.text('+60 XP and a supply chest'), findsOneWidget);
      // The hand-in goes into the Journal (criterion 43).
      expect(c.journal.first.summary.questsDone, ['odda_goblins']);
    });

    testWidgets('a hand-in that reaches a level shows its level-up card '
        '(spec 0024 §2.4, spec 0002 §9.1)', (t) async {
      final c = await openOdda(
        t,
        counters: {'kills.goblin': 10},
        prepare: (s) {
          s.xp = 0;
          s.quests['odda_goblins'] = const QuestProgress.taken(0);
        },
      );
      expect(c.levelCards, isEmpty);
      await t.tap(key('quest-hand-in-odda_goblins'));
      await settle(t, c);
      expect(c.levelCards, [2]);
    });

    testWidgets('a ready bring quest says what it gives', (t) async {
      final (c, _) = await pumpGame(
        t,
        location: 'goblin_woods',
        level: 5,
        counters: {'dropped.goblin_hide': 15},
        inventory: {'goblin_hide': 15},
        prepare: (s) {
          s.quests['odda_goblins'] = const QuestProgress.done();
          s.quests['pell_hides'] = const QuestProgress.taken(0);
        },
      );
      await t.tap(key('person-pell'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: personSheet,
          matching: find.text('Gives 15 goblin hides'),
        ),
        findsOneWidget,
      );
      expect(key('quest-hand-in-pell_hides'), findsOneWidget);
    });

    testWidgets("criterion 38: a teacher's sheet keeps its learn line, Learn "
        'and the quest', (t) async {
      final (c, _) = await pumpGame(
        t,
        learned: false,
        prepare: (s) => s.quests['odda_goblins'] = const QuestProgress.done(),
      );
      await t.ensureVisible(key('teacher-mining'));
      await t.tap(key('teacher-mining'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(key('learn-mining'), findsOneWidget);
      expect(find.text('Hilde teaches Mining.'), findsOneWidget);
      expect(
        find.descendant(of: teacherSheet, matching: key('quest-hilde_ore')),
        findsOneWidget,
      );
    });
  });
}
