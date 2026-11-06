// The camp tour: spec 0022 criteria 1-22, with erratum 1 (plan 0053).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/away_summary_card.dart';
import 'package:walkingrpg/ui/camp_tour.dart';
import 'package:walkingrpg/ui/character_tab.dart';
import 'package:walkingrpg/ui/home_shell.dart';
import 'package:walkingrpg/ui/now_tab.dart';
import 'package:walkingrpg/ui/professions_tab.dart';
import 'package:walkingrpg/ui/settings_screen.dart';
import 'package:walkingrpg/ui/socket.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final card = key('tour-card');

  /// A new game: "Who are you?", the name Ada, then Set out.
  Future<GameController> newGame(WidgetTester t) async {
    final (c, _) = await pumpGame(t, character: null);
    await t.enterText(key('character-name-field'), 'Ada');
    await t.ensureVisible(key('origin-tavern_cook'));
    await t.tap(key('origin-tavern_cook'));
    await t.pump();
    await t.ensureVisible(key('set-out'));
    await t.tap(key('set-out'));
    await settle(t, c);
    await t.pumpAndSettle();
    return c;
  }

  String words(WidgetTester t) => t.widget<Text>(key('tour-words')).data!;
  String step(WidgetTester t) => t.widget<Text>(key('tour-step')).data!;
  int lit(WidgetTester t) =>
      t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
  CharacterPane pane(WidgetTester t) => t
      .widget<SegmentedButton<CharacterPane>>(
        find.byType(SegmentedButton<CharacterPane>),
      )
      .selected
      .single;

  Future<void> next(WidgetTester t) async {
    await t.tap(key('tour-next'));
    await t.pumpAndSettle();
  }

  Future<void> goTo(WidgetTester t, int index) async {
    for (var i = 0; i < index; i++) {
      await next(t);
    }
    expect(step(t), '${index + 1} / 6');
  }

  void expectTourOver(WidgetTester t) {
    expect(card, findsNothing);
    expect(find.byType(NowTab), findsOneWidget);
    expect(lit(t), 0, reason: 'the bar lights Now');
  }

  group('when it starts', () {
    testWidgets('criterion 1: Set out opens step 1 on the Now tab', (t) async {
      final c = await newGame(t);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(card, findsOneWidget);
      expect(step(t), '1 / 6');
      expect(c.tourStep, 0);
      expect(find.byType(NowTab), findsOneWidget);
      expect(lit(t), 0);
    });

    testWidgets('criterion 2: a save with a character shows no card', (
      t,
    ) async {
      final (c, _) = await pumpGame(t);
      await t.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(card, findsNothing);
      expect(c.tourStep, isNull);
    });

    testWidgets('criterion 3: after a restart in the middle of the tour, no '
        'card shows', (t) async {
      final c = await newGame(t);
      await next(t);
      expect(card, findsOneWidget);
      final saved = (await c.store.load())!;
      expect(saved.game.character?.name, 'Ada');
      // A new controller on the same save is a new start of the app.
      await t.pumpWidget(const SizedBox());
      final again = await pumpSave(t, saved.toJson());
      await t.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(card, findsNothing);
      expect(again.tourStep, isNull);
    });
  });

  group('the card', () {
    testWidgets('criterion 4: Odda in a 48 dp socket with her placeholder, '
        'and the step', (t) async {
      await newGame(t);
      final portrait = t.widget<PictureSocket>(key('tour-portrait'));
      expect(portrait.size, 48);
      expect(portrait.picture.placeholder, isTrue);
      expect(find.descendant(of: card, matching: find.text('Odda')), findsOne);
      expect(step(t), '1 / 6');
    });

    testWidgets('criterion 5: step 1 reads its words with the name', (t) async {
      await newGame(t);
      expect(
        words(t),
        "Welcome to the Guild camp, Ada. I'm Odda, the quartermaster. Now "
        'shows what you are doing and what comes next. Every step you walk '
        'moves it on.',
      );
    });

    testWidgets('criterion 6: the card stands above the bar', (t) async {
      await newGame(t);
      expect(
        t.getRect(card).bottom,
        lessThanOrEqualTo(t.getRect(find.byType(NavigationBar)).top),
      );
    });

    testWidgets('criteria 7-8: Skip tour and Next; step 6 has Done, no Next', (
      t,
    ) async {
      await newGame(t);
      expect(
        find.descendant(of: key('tour-skip'), matching: find.text('Skip tour')),
        findsOne,
      );
      expect(
        find.descendant(of: key('tour-next'), matching: find.text('Next')),
        findsOne,
      );
      await goTo(t, 5);
      expect(
        find.descendant(of: key('tour-next'), matching: find.text('Done')),
        findsOne,
      );
      expect(find.text('Next'), findsNothing);
      expect(key('tour-skip'), findsOneWidget);
    });

    testWidgets('criterion 9: nothing dims or blurs the screen', (t) async {
      await newGame(t);
      for (var i = 0; i < 6; i++) {
        expect(find.byType(BackdropFilter), findsNothing, reason: 'step $i');
        expect(find.byType(ImageFiltered), findsNothing, reason: 'step $i');
        for (final b in t.widgetList<ModalBarrier>(find.byType(ModalBarrier))) {
          expect(
            b.color == null || b.color!.a == 0,
            isTrue,
            reason: 'step $i: a dark layer',
          );
        }
        if (i < 5) await next(t);
      }
    });
  });

  group('the steps', () {
    testWidgets('criterion 10: Next opens step 2 on the World tab', (t) async {
      await newGame(t);
      await next(t);
      expect(step(t), '2 / 6');
      expect(find.byType(WorldTab), findsOneWidget);
      expect(lit(t), 1);
    });

    testWidgets('criteria 11-14: steps 3-6 open their tabs and panes', (
      t,
    ) async {
      await newGame(t);
      await goTo(t, 2);
      expect(find.byType(ProfessionsTab), findsOneWidget, reason: 'step 3');
      expect(lit(t), 2);
      await next(t);
      expect(find.byType(CharacterTab), findsOneWidget, reason: 'step 4');
      expect(lit(t), 3);
      expect(pane(t), CharacterPane.gear, reason: 'step 4');
      await next(t);
      expect(find.byType(CharacterTab), findsOneWidget, reason: 'step 5');
      expect(pane(t), CharacterPane.bag, reason: 'step 5');
      await next(t);
      expect(find.byType(NowTab), findsOneWidget, reason: 'step 6');
      expect(lit(t), 0);
    });

    testWidgets('at text size 2.0 on a phone, the card does not hide the bag '
        'and its Bank button (intent 0021)', (t) async {
      // The game's fonts: the square test font is much wider.
      await t.runAsync(loadFonts);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await newGame(t);
      t.view.physicalSize = const Size(408, 900);
      await t.pumpAndSettle();
      await goTo(t, 4);
      await t.pumpAndSettle();
      final top = t.getRect(card).top;
      expect(t.getRect(key('bag-spaces')).bottom, lessThanOrEqualTo(top));
      expect(t.getRect(key('bag-bank')).bottom, lessThanOrEqualTo(top));
      expect(t.getRect(key('bag-bank')).top, greaterThanOrEqualTo(0));
    });

    testWidgets('criterion 15: each step reads its words', (t) async {
      await newGame(t);
      final shown = <String>[];
      for (var i = 0; i < 6; i++) {
        shown.add(words(t));
        if (i < 5) await next(t);
      }
      expect(shown, [
        for (final s in tourSteps) s.words.replaceAll('{name}', 'Ada'),
      ]);
      // Two steps by hand, with erratum 1.
      expect(
        shown[2],
        'Mining, woodcutting, fishing, hunting, cooking, crafting. Each has a '
        'teacher here at Camp. Learn from them, and go back for their tips.',
      );
      expect(
        shown[5],
        'Up top: your supply chest, your achievements, the Journal and '
        'Settings. Settings can show you this tour again. Off you go, Ada. '
        'Walk.',
      );
    });
  });

  group('ending the tour', () {
    testWidgets('criterion 16: Skip tour on step 3 opens the Now tab', (
      t,
    ) async {
      final c = await newGame(t);
      await goTo(t, 2);
      await t.tap(key('tour-skip'));
      await t.pumpAndSettle();
      expectTourOver(t);
      expect(c.tourStep, isNull);
    });

    testWidgets('criterion 17: Done on step 6 ends the tour on Now', (t) async {
      final c = await newGame(t);
      await goTo(t, 5);
      await t.tap(key('tour-next'));
      await t.pumpAndSettle();
      expectTourOver(t);
      expect(c.tourStep, isNull);
    });

    testWidgets('criterion 18: the back gesture ends the tour', (t) async {
      final c = await newGame(t);
      await goTo(t, 3);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expectTourOver(t);
      expect(c.tourStep, isNull);
    });

    testWidgets('criterion 19: a tab tap during the tour changes nothing', (
      t,
    ) async {
      await newGame(t);
      await t.tap(key('tab-world'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.byType(NowTab), findsOneWidget);
      expect(lit(t), 0);
      expect(step(t), '1 / 6');
      // The step picks the tab while the tour runs, so check the tap itself:
      // the bar does not receive it.
      final bar = find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(IgnorePointer),
      );
      expect(
        t.widgetList<IgnorePointer>(bar).any((w) => w.ignoring),
        isTrue,
        reason: 'the bar ignores taps',
      );
    });

    testWidgets('criterion 19 (rule 13): a tap inside the tab during the tour '
        'does nothing', (t) async {
      final c = await newGame(t);
      final hide = find.widgetWithText(TextButton, 'Hide');
      expect(hide, findsOneWidget);
      await t.tap(hide, warnIfMissed: false);
      await t.pumpAndSettle();
      expect(c.nextGoalHidden, isFalse, reason: 'Hide did not react');
      await t.tap(key('tour-skip'));
      await t.pumpAndSettle();
      await t.tap(hide);
      await t.pumpAndSettle();
      expect(c.nextGoalHidden, isTrue, reason: 'after the tour it works');
    });

    testWidgets('rule 7: a screen that opens during the tour comes first, and '
        'the tour goes on after it', (t) async {
      final c = await newGame(t);
      await goTo(t, 3);
      c.awaySummary = const AwaySummary(walked: 500);
      c.showTourStep(3);
      await t.pumpAndSettle();
      expect(find.byType(AwayScreen), findsOneWidget);
      expect(card, findsNothing);
      c.dismissAwaySummary();
      await t.pumpAndSettle();
      expect(card, findsOneWidget);
      expect(step(t), '4 / 6');
      expect(pane(t), CharacterPane.gear);
    });

    testWidgets('criterion 20: a top button during the tour opens nothing', (
      t,
    ) async {
      await newGame(t);
      for (final b in [
        'settings-button',
        'journal-button',
        'achievements-button',
        'supply-chest-button',
      ]) {
        await t.tap(key(b), warnIfMissed: false);
        await t.pumpAndSettle();
        expect(find.byType(HomeShell), findsOneWidget, reason: b);
        expect(find.byType(SettingsScreen), findsNothing, reason: b);
        expect(card, findsOneWidget, reason: b);
        expect(find.byType(BackButton), findsNothing, reason: b);
      }
      // Each of them pushes a screen that covers the home screen.
      expect(t.widgetList(find.byType(Scaffold)), hasLength(1));
    });

    testWidgets('after the tour, the tabs work again', (t) async {
      await newGame(t);
      await t.tap(key('tour-skip'));
      await t.pumpAndSettle();
      await openTab(t, 'world');
      expect(find.byType(WorldTab), findsOneWidget);
    });
  });

  group('settings', () {
    Future<void> openSettings(WidgetTester t) async {
      await t.tap(key('settings-button'));
      await t.pumpAndSettle();
      await t.ensureVisible(key('settings-tour'));
      await t.pumpAndSettle();
    }

    testWidgets('criterion 21: Settings shows Camp tour', (t) async {
      await pumpGame(t);
      await openSettings(t);
      final entry = key('settings-tour');
      expect(
        find.descendant(of: entry, matching: find.text('Camp tour')),
        findsOne,
      );
      expect(
        find.descendant(
          of: entry,
          matching: find.text('Odda shows you around again'),
        ),
        findsOne,
      );
    });

    testWidgets('criterion 22: Camp tour closes Settings and shows step 1 on '
        'Now', (t) async {
      final (c, _) = await pumpGame(t);
      await openTab(t, 'professions');
      await openSettings(t);
      await t.tap(key('settings-tour'));
      await t.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(card, findsOneWidget);
      expect(step(t), '1 / 6');
      expect(c.tourStep, 0);
      expect(find.byType(NowTab), findsOneWidget);
      expect(
        words(t),
        startsWith('Welcome to the Guild camp, ${c.state.character!.name}.'),
      );
    });
  });
}
