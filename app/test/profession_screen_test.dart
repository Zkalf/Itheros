// Spec 0010 amendment 6 (issue #62): the profession screen says the name of
// its profession once, in the top bar, and shows the recipe filters only
// when the player has learned Crafting or Cooking.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/item_square.dart' show professionIcon;

import 'ui_test.dart' show game, openProfession, pumpGame;

Finder _card(String profession) =>
    find.byKey(ValueKey('profession-$profession'));

const _chips = ['filter-mats', 'filter-level', 'filter-ahead'];

void main() {
  for (final learned in [true, false]) {
    testWidgets('criteria 1-3: each screen shows the name in the top bar, '
        'not in its card, and the card starts with the icon'
        '${learned ? ' and "Level N"' : ''} (learned: $learned)', (t) async {
      await pumpGame(t, learned: learned);
      for (final p in game.data.professions.values) {
        await openProfession(t, p.id);
        expect(
          find.descendant(of: find.byType(AppBar), matching: find.text(p.name)),
          findsOneWidget,
          reason: '${p.id}: the name in the top bar',
        );
        expect(
          find.descendant(of: _card(p.id), matching: find.text(p.name)),
          findsNothing,
          reason: '${p.id}: the name in the card',
        );
        // The first line of the card holds the icon and "Level N".
        final head = find.byKey(ValueKey('profession-head-${p.id}'));
        expect(
          t.widget(
            find.descendant(of: _card(p.id), matching: find.byType(Row)).first,
          ),
          same(t.widget(head)),
          reason: '${p.id}: the first row of the card',
        );
        expect(
          find.descendant(
            of: head,
            matching: find.byIcon(professionIcon(p.icon)),
          ),
          findsOneWidget,
          reason: '${p.id}: the icon on the first line',
        );
        expect(
          find.descendant(
            of: head,
            matching: find.textContaining(RegExp(r'^Level \d+$')),
          ),
          learned ? findsOneWidget : findsNothing,
          reason: '${p.id}: "Level N"',
        );
      }
    });
  }

  testWidgets('criterion 4: Crafting and Cooking show the three chips when '
      'learned', (t) async {
    await pumpGame(t);
    for (final p in ['crafting', 'cooking']) {
      await openProfession(t, p);
      for (final chip in _chips) {
        expect(find.byKey(ValueKey(chip)), findsOneWidget, reason: '$p $chip');
      }
    }
  });

  testWidgets('criterion 5: Crafting and Cooking show no chip when not '
      'learned, and name their teacher', (t) async {
    await pumpGame(t, learned: false);
    for (final p in ['crafting', 'cooking']) {
      await openProfession(t, p);
      for (final chip in _chips) {
        expect(find.byKey(ValueKey(chip)), findsNothing, reason: '$p $chip');
      }
      final teacher = game.data.professions[p]!.teacher.name;
      expect(
        find.descendant(
          of: _card(p),
          matching: find.text('Learn from $teacher in camp'),
        ),
        findsOneWidget,
        reason: p,
      );
    }
  });

  for (final learned in [true, false]) {
    testWidgets('criterion 6: the other four screens show no chip '
        '(learned: $learned)', (t) async {
      await pumpGame(t, learned: learned);
      for (final p in game.data.professions.keys) {
        if (p == 'crafting' || p == 'cooking') continue;
        await openProfession(t, p);
        for (final chip in _chips) {
          expect(find.byKey(ValueKey(chip)), findsNothing, reason: '$p $chip');
        }
      }
    });
  }
}
