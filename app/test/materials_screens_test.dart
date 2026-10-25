// The materials a craft has, needs, uses and keeps, on the screens: spec
// 0010 amendment 5 criteria 1-14 (plan 0022 M2).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/action_sheet.dart';
import 'package:walkingrpg/ui/theme.dart';

import 'ui_test.dart';

void main() {
  Finder recipe(String id) => find.byKey(ValueKey('option-craft-$id'));
  Finder cell(String item, String column) =>
      find.byKey(ValueKey('material-$item-$column'));
  String textOf(WidgetTester t, Finder f) => t.widget<Text>(f).data!;
  Color? colourOf(WidgetTester t, Finder f) => t.widget<Text>(f).style?.color;
  final enough = find.byKey(const ValueKey('materials-enough'));
  final afterQueue = find.byKey(const ValueKey('materials-after-queue'));

  /// The span of the recipe row [id] whose text is [text], or null.
  TextSpan? spanOf(WidgetTester t, String id, String text) {
    TextSpan? found;
    for (final rich in t.widgetList<RichText>(
      find.descendant(of: recipe(id), matching: find.byType(RichText)),
    )) {
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text == text) found = span;
        return found == null;
      });
    }
    return found;
  }

  Future<void> openRecipe(WidgetTester t, String profession, String id) async {
    await openProfession(t, profession);
    await t.ensureVisible(recipe(id));
    await t.tap(recipe(id));
    await t.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(ValueKey(key)));
    await t.tap(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
  }

  /// "Until N crafted" with [n] crafts.
  Future<void> untilCrafted(WidgetTester t, int n) async {
    await tapKey(t, 'stop-untilCrafted');
    for (var i = 1; i < n; i++) {
      await tapKey(t, 'count-up');
    }
  }

  group('the recipe row (§2.1)', () {
    testWidgets('criteria 1-2: "have/needed" for each material, then "Enough '
        'for N" from the bag of now', (t) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 12, 'oak_log': 5});
      await openProfession(t, 'crafting');
      await t.ensureVisible(recipe('copper_spear'));
      expect(spanOf(t, 'copper_spear', 'Copper ore 12/5'), isNotNull);
      expect(spanOf(t, 'copper_spear', 'Oak log 5/1'), isNotNull);
      final span = spanOf(t, 'copper_spear', ' · Enough for 2');
      expect(span, isNotNull);
      expect(span!.style?.color, isNot(Quiet.short));
    });

    testWidgets('criterion 3: "Enough for 0" shows in the short colour', (
      t,
    ) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 4});
      await openProfession(t, 'crafting');
      await t.ensureVisible(recipe('copper_sword'));
      expect(
        spanOf(t, 'copper_sword', ' · Enough for 0')?.style?.color,
        Quiet.short,
      );
    });

    testWidgets('criterion 4: a recipe with no materials shows no "Enough for '
        'N"', (t) async {
      // The data has no such recipe today, so the test adds one.
      final files = {
        for (final f in Directory(
          '../packages/game_core/data',
        ).listSync().whereType<File>())
          if (f.path.endsWith('.json'))
            f.uri.pathSegments.last.replaceAll('.json', ''): f
                .readAsStringSync(),
      };
      final items = jsonDecode(files['items']!) as Map<String, Object?>;
      (items['recipes']! as List<Object?>).add({
        'id': 'free_sword',
        'level': 1,
        'crafting': 1,
        'steps': 10,
        'xp': 1,
        'inputs': <String, Object?>{},
        'output': 'copper_sword',
      });
      files['items'] = jsonEncode(items);
      final game = Game(GameData.fromJsonStrings(files));
      await pumpGame(t, level: 5, withGame: game);
      await openProfession(t, 'crafting');
      await t.ensureVisible(recipe('free_sword'));
      expect(
        find.descendant(
          of: recipe('free_sword'),
          matching: find.textContaining('Enough for'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: recipe('copper_sword'),
          matching: find.textContaining('Enough for'),
        ),
        findsOneWidget,
      );
    });
  });

  group('the action sheet (§2.2)', () {
    testWidgets('criterion 5: Have, Uses and Left for each material', (
      t,
    ) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 12, 'oak_log': 5});
      await openRecipe(t, 'crafting', 'copper_spear');
      for (final item in ['copper_ore', 'oak_log']) {
        for (final column in ['name', 'have', 'uses', 'left']) {
          expect(cell(item, column), findsOneWidget, reason: '$item $column');
        }
      }
      expect(textOf(t, cell('copper_ore', 'name')), 'Copper ore');
      expect(textOf(t, cell('copper_ore', 'have')), '12');
    });

    testWidgets(
      'criteria 6-7: "Until 5 crafted" with a need of 2 uses 10; Left '
      'is Have minus Uses, never below 0',
      (t) async {
        await pumpGame(t, level: 5, inventory: {'perch': 13});
        await openRecipe(t, 'cooking', 'grilled_perch');
        await untilCrafted(t, 5);
        expect(textOf(t, cell('perch', 'uses')), '10');
        expect(textOf(t, cell('perch', 'left')), '3');
        await untilCrafted(t, 8);
        expect(textOf(t, cell('perch', 'uses')), '16');
        expect(textOf(t, cell('perch', 'left')), '0');
      },
    );

    testWidgets('criteria 8-9: a short line takes the short colour, and '
        '"Enough for N" shows', (t) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 20, 'oak_log': 2});
      await openRecipe(t, 'crafting', 'copper_spear');
      await untilCrafted(t, 3);
      for (final column in ['name', 'have', 'uses', 'left']) {
        expect(colourOf(t, cell('oak_log', column)), Quiet.short);
        expect(colourOf(t, cell('copper_ore', column)), isNot(Quiet.short));
      }
      expect(textOf(t, enough), 'Enough for 2');
      await untilCrafted(t, 2);
      expect(enough, findsNothing, reason: 'enough for 2 crafts');
    });

    testWidgets('criterion 10: a meal "Until I have N" counts the crafts from '
        'the meals in the bag', (t) async {
      await pumpGame(t, level: 5, inventory: {'perch': 20, 'grilled_perch': 2});
      await openRecipe(t, 'cooking', 'grilled_perch');
      await tapKey(t, 'stop-untilHave');
      // The sheet starts at "you have 2" + 5 = 7 meals: 5 crafts.
      expect(textOf(t, cell('perch', 'uses')), '10');
    });

    testWidgets('criterion 11: "Until a quality" and "Never stop" show "–" and '
        '"Enough for N"', (t) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 12});
      await openRecipe(t, 'crafting', 'copper_sword');
      for (final stop in ['stop-never', 'stop-untilQuality']) {
        await tapKey(t, stop);
        expect(textOf(t, cell('copper_ore', 'have')), '12', reason: stop);
        expect(textOf(t, cell('copper_ore', 'uses')), '–', reason: stop);
        expect(textOf(t, cell('copper_ore', 'left')), '–', reason: stop);
        expect(textOf(t, enough), 'Enough for 2', reason: stop);
      }
    });

    testWidgets('criterion 12: the table updates with the stop choice and the '
        'count', (t) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 30});
      await openRecipe(t, 'crafting', 'copper_sword');
      expect(textOf(t, cell('copper_ore', 'uses')), '–');
      await tapKey(t, 'stop-untilCrafted');
      expect(textOf(t, cell('copper_ore', 'uses')), '5');
      await tapKey(t, 'count-up');
      expect(textOf(t, cell('copper_ore', 'uses')), '10');
      expect(textOf(t, cell('copper_ore', 'left')), '20');
    });

    testWidgets('criterion 13: with an empty queue, Have is the bag of now and '
        'there is no "After your queue" line', (t) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 12});
      await openRecipe(t, 'crafting', 'copper_sword');
      expect(afterQueue, findsNothing);
      expect(textOf(t, cell('copper_ore', 'have')), '12');
    });

    testWidgets('a reroll has no materials table', (t) async {
      const key = 'bone_sword@uncommon+crit2';
      final (c, _) = await pumpGame(
        t,
        level: 5,
        inventory: {key: 1, 'uncommon_dust': 3},
      );
      Future<void> sheet(Activity a) => t.pumpWidget(
        MaterialApp(
          theme: quietTheme,
          home: Scaffold(
            body: ActionSheet(controller: c, activity: a),
          ),
        ),
      );
      await sheet(const Activity.craft('copper_sword'));
      expect(find.byKey(const ValueKey('materials')), findsOneWidget);
      await sheet(const Activity.reroll(key));
      expect(find.byKey(const ValueKey('materials')), findsNothing);
    });

    testWidgets('the table fits at 360 dp and the text size 2.0', (t) async {
      await pumpGame(t, level: 5, inventory: {'copper_ore': 12, 'oak_log': 5});
      await openRecipe(t, 'crafting', 'copper_spear');
      // Only the sheet at this size: the profession buttons are not part of
      // this change.
      t.view.physicalSize = const Size(360, 4000);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpAndSettle();
      await untilCrafted(t, 3);
      expect(textOf(t, cell('copper_ore', 'uses')), '15');
      expect(t.takeException(), isNull);
    });
  });

  group('the queue (§2.3)', () {
    testWidgets('criterion 14: with actions in the queue, "After your queue" '
        'and Have counts the bag after the queue', (t) async {
      final (c, _) = await pumpGame(t, level: 5, inventory: {'copper_ore': 12});
      await c.addAction(
        const Activity.craft('copper_sword'),
        stop: const StopCondition.untilCrafted(2),
      );
      await settle(t, c);
      await openRecipe(t, 'crafting', 'copper_sword');
      expect(afterQueue, findsOneWidget);
      expect(textOf(t, afterQueue), 'After your queue');
      expect(textOf(t, cell('copper_ore', 'have')), '2');
    });
  });
}
