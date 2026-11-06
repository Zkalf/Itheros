// Pictures on recipe rows and in the materials table, and no stop line for a
// reroll: spec 0014 amendment 9 criteria 1-13 (plan 0048).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/action_sheet.dart';
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/level_badge.dart';
import 'package:walkingrpg/ui/socket.dart';

import 'images_test.dart' show expectRing, qualityRgb, ringIn, ringless;
import 'now_monsters_test.dart' show expectSocketFirst, inside;
import 'ui_test.dart';

void main() {
  final data = game.data;

  /// The recipe rows on the screen of [profession], by recipe id.
  List<String> recipeRows(WidgetTester t) => [
    for (final e
        in find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'option-craft-',
                  ),
            )
            .evaluate())
      (e.widget.key! as ValueKey<String>).value.substring(
        'option-craft-'.length,
      ),
  ];

  Finder row(String recipe) => find.byKey(ValueKey('option-craft-$recipe'));

  group('the recipe rows', () {
    for (final (n, profession) in [(1, 'crafting'), (2, 'cooking')]) {
      testWidgets('criterion $n: each recipe row on $profession starts with '
          'the picture of its item in a 48 dp socket', (t) async {
        await pumpGame(t, images: ringless, level: 5);
        await openProfession(t, profession);
        final ids = recipeRows(t);
        expect(ids, isNotEmpty);
        for (final id in ids) {
          await t.ensureVisible(row(id));
          await t.pumpAndSettle();
          expectSocketFirst(
            t,
            row(id),
            ItemThing(data.recipes[id]!.output),
            48,
            '$profession: $id',
          );
        }
      });
    }

    testWidgets('criterion 3: a gear or tool recipe shows the ring of its '
        "item's quality", (t) async {
      await pumpGame(t, images: ringless, level: 5);
      await openProfession(t, 'crafting');
      for (final id in ['copper_sword', 'copper_pickaxe']) {
        await t.ensureVisible(row(id));
        await t.pumpAndSettle();
        expectRing(t, row(id), qualityRgb('common'), id);
      }
    });

    testWidgets('criterion 4: a meal recipe shows no ring', (t) async {
      await pumpGame(t, images: ringless, level: 5);
      await openProfession(t, 'cooking');
      for (final id in recipeRows(t)) {
        expect(data.items[data.recipes[id]!.output]!.meal, isNotNull);
        await t.ensureVisible(row(id));
        await t.pumpAndSettle();
        // The socket is there, and it has no ring.
        expect(
          inside(row(id), find.byType(PictureSocket)),
          findsOneWidget,
          reason: id,
        );
        expect(ringIn(t, row(id)), isNull, reason: id);
      }
    });

    testWidgets("criterion 5: the level badge stands on the title line, before "
        "the recipe's name", (t) async {
      await pumpGame(t, images: ringless, level: 5);
      await openProfession(t, 'crafting');
      final badge = find.byKey(const ValueKey('recipe-level-copper_sword'));
      expect(inside(row('copper_sword'), badge), findsOneWidget);
      final b = t.getRect(badge);
      final name = t.getRect(
        inside(row('copper_sword'), find.text('Copper sword')),
      );
      expect(
        b.top < name.center.dy && name.center.dy < b.bottom,
        isTrue,
        reason: 'the name $name on the line of the badge $b',
      );
      expect(name.left - b.right, inInclusiveRange(0, 24));
      final socket = t.getRect(
        inside(row('copper_sword'), find.byType(PictureSocket)),
      );
      expect(b.left, greaterThan(socket.right), reason: 'after the picture');
    });

    testWidgets('criterion 6: a locked recipe shows its picture, and its badge '
        'keeps the colour of a locked recipe', (t) async {
      final (c, _) = await pumpGame(t, images: ringless);
      await openProfession(t, 'crafting');
      final locked = recipeRows(t)
          .where((id) => !c.game.recipeLevelMet(c.state, id))
          .toList();
      expect(locked, isNotEmpty, reason: 'no locked recipe at level 1');
      final id = locked.first;
      await t.ensureVisible(row(id));
      await t.pumpAndSettle();
      expectSocketFirst(
        t,
        row(id),
        ItemThing(data.recipes[id]!.output),
        48,
        'the locked $id',
      );
      expect(
        t.widget<LevelBadge>(find.byKey(ValueKey('recipe-level-$id'))).colour,
        LevelColour.red,
      );
    });

    testWidgets('criterion 7: a tap on a recipe row still opens its action '
        'sheet', (t) async {
      await pumpGame(t, images: ringless, level: 5);
      await openProfession(t, 'crafting');
      await t.ensureVisible(row('copper_sword'));
      await t.pumpAndSettle();
      await t.tap(row('copper_sword'));
      await t.pumpAndSettle();
      expect(find.byType(ActionSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('item-card')), findsNothing);
    });
  });

  group('the materials table', () {
    Future<void> openSwordSheet(WidgetTester t) async {
      await pumpGame(
        t,
        images: ringless,
        level: 5,
        inventory: {'copper_ore': 2},
      );
      await openProfession(t, 'crafting');
      await t.ensureVisible(row('copper_spear'));
      await t.pumpAndSettle();
      await t.tap(row('copper_spear'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('materials')), findsOneWidget);
    }

    testWidgets("criterion 8: each line starts with the material's picture in "
        'a 32 dp socket, before its name', (t) async {
      await openSwordSheet(t);
      final inputs = data.recipes['copper_spear']!.inputs.keys.toList();
      expect(inputs, hasLength(greaterThan(1)));
      for (final item in inputs) {
        expectSocketFirst(
          t,
          find.byKey(ValueKey('material-$item-line')),
          ItemThing(item),
          32,
          item,
        );
      }
    });

    testWidgets('criteria 9 and 10: a tap on a line opens the card of that '
        'material, with no buttons', (t) async {
      await openSwordSheet(t);
      await t.tap(find.byKey(const ValueKey('material-oak_log-line')));
      await t.pumpAndSettle();
      final card = find.byKey(const ValueKey('item-card'));
      expect(card, findsOneWidget);
      expect(
        t.widget<Text>(find.byKey(const ValueKey('card-name'))).data,
        'Oak log',
      );
      // Any kind of button, icon variants included.
      expect(
        inside(
          card,
          find.byWidgetPredicate(
            (w) => w is ButtonStyleButton || w is IconButton,
          ),
        ),
        findsNothing,
      );
    });
  });

  group('the stop line of a reroll', () {
    final reroll = data.keyFor('bone_sword', 'uncommon');
    Finder queueCardText(String text) => find.textContaining(text);

    testWidgets('criteria 11 and 13: a waiting reroll shows no stop line; a '
        'waiting fight still does', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 5,
        inventory: {'copper_ore': 5, reroll: 1, 'uncommon_dust': 3},
      );
      await c.addAction(
        const Activity.craft('copper_sword'),
        stop: StopCondition.untilCrafted(1),
      );
      await c.addAction(Activity.reroll(reroll));
      await c.addAction(
        const Activity.fight('goblin'),
        stop: StopCondition.untilHave('goblin_hide', 2),
      );
      await settle(t, c);
      await openTab(t, 'now');
      await t.pumpAndSettle();
      expect(c.state.queue.first.activity, Activity.reroll(reroll));
      final rerollRow = find.byKey(const ValueKey('queued-0'));
      expect(inside(rerollRow, queueCardText('Until')), findsNothing);
      final fightRow = find.byKey(const ValueKey('queued-2'));
      expect(c.state.queue[2].activity, const Activity.fight('goblin'));
      expect(inside(fightRow, queueCardText('Until you have')), findsOneWidget);
    });

    testWidgets('criterion 12: a current reroll shows no stop line', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 5,
        inventory: {reroll: 1, 'uncommon_dust': 3},
      );
      await c.addAction(Activity.reroll(reroll));
      await settle(t, c);
      await openTab(t, 'now');
      await t.pumpAndSettle();
      expect(c.state.activity?.activity, Activity.reroll(reroll));
      // No stop line of any wording: nothing on Now says "Until".
      expect(queueCardText('Until'), findsNothing);
      expect(find.byKey(const ValueKey('stop-activity')), findsOneWidget);
    });
  });
}
