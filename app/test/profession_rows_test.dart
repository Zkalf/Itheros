// The profession rows at a large text size (issue #96): at 360 dp and the
// text size 2.0 nothing runs past the edge and no word breaks; at the text
// size 1.0 the rows keep their one-line look.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

const _professions = [
  'mining',
  'woodcutting',
  'fishing',
  'hunting',
  'crafting',
  'cooking',
];

/// A phone 360 dp wide, at the text size [scale].
void _phone(WidgetTester t, double scale) {
  t.view.physicalSize = const Size(360, 2400);
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Every overflow error since the last call, as their messages.
List<String> _overflows(WidgetTester t) => [
  for (var e = t.takeException(); e != null; e = t.takeException())
    e.toString(),
];

void main() {
  // The real fonts: the test font's square letters are wider than the
  // player's.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  testWidgets('at the text size 2.0 the Professions tab fits', (t) async {
    await pumpGame(t, level: 14);
    _phone(t, 2);
    await openTab(t, 'professions');
    expect(_overflows(t), isEmpty);
  });

  for (final p in _professions) {
    testWidgets('at the text size 2.0 the $p screen fits, and its words '
        'keep room', (t) async {
      await pumpGame(t, level: 14);
      _phone(t, 2);
      await openProfession(t, p);
      expect(_overflows(t), isEmpty);
      // The spot row: its title is not squeezed to a letter or two on a
      // line beside the button.
      final row = find.ancestor(
        of: find.text('Where to practise'),
        matching: find.byType(ListTile),
      );
      if (row.evaluate().isNotEmpty) {
        final title = find.descendant(
          of: row,
          matching: find.textContaining(' · '),
        );
        expect(t.getSize(title).width, greaterThanOrEqualTo(200), reason: p);
      }
    });
  }

  testWidgets('at the text size 1.0 each name and level share one line, '
      'the level at the right', (t) async {
    await pumpGame(t, level: 14);
    _phone(t, 1);
    await openTab(t, 'professions');
    for (final p in _professions) {
      final button = find.byKey(ValueKey('profession-button-$p'));
      final name = find.descendant(of: button, matching: find.text(_name(p)));
      final level = find.descendant(
        of: button,
        matching: find.textContaining('Level 14', findRichText: true),
      );
      expect(t.getCenter(level).dy, t.getCenter(name).dy, reason: p);
      expect(
        t.getRect(level).left,
        greaterThan(t.getRect(name).right + 40),
        reason: '$p: the level stands at the right, apart from the name',
      );
      final xp = find.descendant(
        of: button,
        matching: find.textContaining(' XP', findRichText: true),
      );
      expect(t.getRect(xp).right, t.getRect(level).right, reason: p);
    }
    expect(_overflows(t), isEmpty);
  });
}

String _name(String id) => game.data.professions[id]!.name;
