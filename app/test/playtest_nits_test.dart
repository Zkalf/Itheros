// The small fixes of the playtest (#255, plan 0062): spec 0010 amendment 13,
// spec 0004 amendment 6 and spec 0020 amendment 7. The tour's words (spec
// 0022 amendment 1) are in camp_tour_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/away_summary_card.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  Finder rich(String words) => find.text(words, findRichText: true);
  final data = game.data;
  final labels = Labels(data);

  group('XP numbers count in the level (spec 0010 amendment 13)', () {
    final floor = data.professionXpForLevel(5);
    final takes = data.professionXpForLevel(6) - floor;

    testWidgets('criterion 1: at the start of a level a profession shows '
        '"0 / N XP" on its screen and on the Professions tab', (t) async {
      await pumpGame(t, level: 5, professionLevel: 5);
      await openTab(t, 'professions');
      expect(rich('0 / ${fmt(takes)} XP'), findsNWidgets(6));
      await openProfession(t, 'fishing');
      expect(
        find.descendant(
          of: key('profession-fishing'),
          matching: rich('0 / ${fmt(takes)} XP'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('criterion 2: part way through a level the numbers are those '
        'of the bar', (t) async {
      await pumpGame(
        t,
        level: 5,
        professionLevel: 5,
        prepare: (s) => s.professions['fishing'] = floor + 10,
      );
      await openProfession(t, 'fishing');
      final card = key('profession-fishing');
      expect(
        find.descendant(of: card, matching: rich('10 / ${fmt(takes)} XP')),
        findsOneWidget,
      );
      final bar = t.widget<LinearProgressIndicator>(
        find.descendant(
          of: card,
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(bar.value, closeTo(10 / takes, 1e-9));
    });

    testWidgets(
      'criterion 3: the character\'s bar on Now counts in the level',
      (t) async {
        final start = data.xpForLevel(5);
        final levelTakes = data.xpForLevel(6) - start;
        await pumpGame(t, level: 5, xp: start + 7);
        expect(rich('XP 7 / ${fmt(levelTakes)}'), findsOneWidget);
      },
    );
  });

  group('a locked row does not repeat its name (spec 0010 amendment 13)', () {
    testWidgets('criterion 4: a locked recipe row', (t) async {
      await pumpGame(t, level: 30, professionLevel: 11);
      await openProfession(t, 'crafting');
      final recipe = data.recipes.values.firstWhere(
        (r) => r.profession == 'crafting' && r.craftingLevel > 11,
      );
      final row = key('option-craft-${recipe.id}');
      final name = labels.recipe(recipe.id);
      expect(
        find.descendant(
          of: row,
          matching: find.textContaining(
            'Needs Crafting ${recipe.craftingLevel} (you have 11)',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.textContaining('$name needs', findRichText: true),
        ),
        findsNothing,
      );
    });

    testWidgets('criterion 5: a locked spot row', (t) async {
      await pumpGame(t, level: 30, professionLevel: 9, location: 'iron_ridge');
      expect(find.text('Needs Mining 10 (you have 9)'), findsOneWidget);
      expect(find.textContaining('Iron vein needs'), findsNothing);
    });

    // The skip reasons use the same line with its name: their own tests are
    // in game_core (professions_test.dart, layout_test.dart).
    testWidgets('criteria 6 and 7: the line with its name stays for a skipped '
        'action; a profession that is not learned reads "Learn"', (t) async {
      final (c, _) = await pumpGame(t, level: 30, professionLevel: 9);
      expect(
        c.game.lockedReason(c.state, const Activity.gather('iron_vein')),
        'Iron vein needs Mining 10 (you have 9)',
      );
      c.state.learned.remove('mining');
      expect(
        c.game.lockedReason(
          c.state,
          const Activity.gather('iron_vein'),
          named: false,
        ),
        startsWith('Learn Mining from '),
      );
    });
  });

  group('one step bank line (spec 0004 amendment 6)', () {
    List<String> lines({int used = 0, int saved = 0}) => reportLines(
      AwaySummary(walked: 5000, boostUsed: used, banked: saved),
      labels,
    );
    bool sentence(String l) => l.startsWith('Used') || l.startsWith('Saved');

    test('criterion 1: both used and saved', () {
      final l = lines(used: 1185, saved: 3815);
      expect(l.last, 'Step bank: +2,630 steps.');
      expect(l.where(sentence), isEmpty);
    });

    test('criterion 2: more used than saved shows a minus', () {
      expect(lines(used: 800, saved: 300).last, 'Step bank: −500 steps.');
    });

    test('criterion 3: the same number used and saved', () {
      final l = lines(used: 400, saved: 400);
      expect(l.last, 'Step bank: no change.');
      expect(l.where(sentence), isEmpty);
    });

    test('criterion 4: one of them alone keeps its sentence', () {
      expect(
        lines(used: 1185),
        contains('Used 1,185 steps from your step bank.'),
      );
      expect(
        lines(saved: 3815),
        contains('Saved 3,815 steps in your step bank.'),
      );
      expect([
        ...lines(used: 1185),
        ...lines(saved: 3815),
      ], isNot(contains(startsWith('Step bank:'))));
    });
  });

  group('bank rows show their stats (spec 0020 amendment 7)', () {
    const hit = 'hide_vest@rare+hit4';
    const crit = 'hide_vest@rare+crit3';
    final tool = data.items.keys.firstWhere(
      (k) => data.toolProfession(k) == 'mining',
    );
    const material = 'bones';
    const meal = 'grilled_perch';
    const all = {hit: 1, crit: 1, material: 3, meal: 2};

    String? line(WidgetTester t, String row) {
      final found = find.descendant(
        of: key(row),
        matching: find.byWidgetPredicate(
          (w) => switch (w.key) {
            ValueKey<String>(:final value) => value.startsWith('bank-row-line'),
            _ => false,
          },
        ),
      );
      return found.evaluate().isEmpty ? null : t.widget<Text>(found).data;
    }

    Future<void> openList(WidgetTester t, {required bool bank}) async {
      await pumpGame(
        t,
        level: 12,
        inventory: bank ? const {} : {...all, tool: 1},
        prepare: bank ? (s) => s.itemBank.addAll({...all, tool: 1}) : null,
      );
      await t.tap(key('bank-button'));
      await t.pumpAndSettle();
      await t.tap(key(bank ? 'bank-tab-bank' : 'bank-tab-bag'));
      await t.pumpAndSettle();
    }

    for (final bank in [true, false]) {
      final prefix = bank ? 'bank-item' : 'bank-bag';
      testWidgets('criteria 1 to 5: the rows of the '
          '${bank ? 'Bank' : 'Bag'} list', (t) async {
        await openList(t, bank: bank);
        // Criterion 1: the base stats and the slot.
        final base = labels.bonus(data.baseStatsOf(hit)).join(' · ');
        expect(base, isNotEmpty);
        expect(line(t, '$prefix-$hit'), '$base · Chest · +4% Hit');
        // Criterion 2: alike gear with another bonus stat differs.
        expect(line(t, '$prefix-$crit'), '$base · Chest · +3% Crit');
        // Criterion 3: a tool row.
        expect(line(t, '$prefix-$tool'), labels.toolLine(tool));
        expect(labels.toolLine(tool), startsWith('Mining tool · '));
        // Criterion 4: materials and meals keep one line.
        expect(key('$prefix-$material'), findsOneWidget);
        expect(line(t, '$prefix-$material'), isNull);
        expect(key('$prefix-$meal'), findsOneWidget);
        expect(line(t, '$prefix-$meal'), isNull);
      });
    }

    test('a weapon shows its damage type and hands in place of the slot', () {
      const sword = 'bone_sword@rare+hit4';
      final base = labels.bonus(data.baseStatsOf(sword)).join(' · ');
      expect(
        labels.rowLine(sword),
        '$base · ${labels.weaponLine(sword)} · +4% Hit',
      );
    });

    testWidgets('criterion 6: at text size 2.0 on a 408 dp phone a gear row '
        'with bonus stats does not overflow', (t) async {
      await t.runAsync(loadFonts);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGame(t, level: 12, inventory: {hit: 1, crit: 1, tool: 1});
      t.view.physicalSize = const Size(408, 900);
      await t.pumpAndSettle();
      await t.tap(key('bank-button'));
      await t.pumpAndSettle();
      await t.tap(key('bank-tab-bag'));
      await t.pumpAndSettle();
      expect(line(t, 'bank-bag-$hit'), isNotNull);
      expect(t.takeException(), isNull);
    });
  });
}
