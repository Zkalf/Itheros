// The "Active" chip of a running action stands in the title row, after the
// name, so the subtitle wraps across the whole row at text size 2.0 (#290).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

void main() {
  final chip = find.widgetWithText(Chip, 'Active');

  /// The Fairphone's 408 dp at text size 2.0.
  Future<void> bigText(WidgetTester t) async {
    t.view.physicalSize = const Size(1224, 7200);
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpAndSettle();
  }

  /// The chip stands beside the name, above the subtitle, and the subtitle
  /// takes the width of the row from its left edge.
  void expectWideSubtitle(WidgetTester t, Finder row, String name) {
    final title = find.descendant(of: row, matching: find.text(name));
    final subtitle = find
        .descendant(of: row, matching: find.byType(RichText))
        .evaluate()
        .map((e) => find.byWidget(e.widget))
        .firstWhere((f) => t.getTopLeft(f).dy > t.getBottomLeft(title).dy - 1);
    final inRow = find.descendant(of: row, matching: chip);
    expect(inRow, findsOneWidget);
    expect(
      t.getRect(inRow).bottom,
      lessThanOrEqualTo(t.getRect(subtitle).top + .5),
      reason: 'the chip stands above the subtitle',
    );
    final room = t.getRect(row).right - t.getRect(subtitle).left;
    expect(
      t.getRect(subtitle).width,
      greaterThan(room * .8),
      reason: 'the subtitle wraps across the row',
    );
    expect(t.takeException(), isNull);
  }

  testWidgets('at text size 2.0 a running recipe shows Active after its '
      'name, and its subtitle wraps across the row', (t) async {
    await loadFonts();
    final (c, _) = await pumpGame(t, inventory: {'copper_ore': 20});
    await c.startActivity(const Activity.craft('copper_sword'));
    await openProfession(t, 'crafting');
    await bigText(t);
    final row = option('craft', 'copper_sword');
    await t.ensureVisible(row);
    await t.pumpAndSettle();
    expectWideSubtitle(t, row, 'Copper sword');
  });

  testWidgets('at text size 2.0 a running monster shows Active after its '
      'name, and its subtitle wraps across the row', (t) async {
    await loadFonts();
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    await c.startActivity(const Activity.fight('goblin'));
    await openArea(t, 'goblin_woods');
    await bigText(t);
    final row = option('fight', 'goblin');
    await t.ensureVisible(row);
    await t.pumpAndSettle();
    expectWideSubtitle(t, row, Labels(game.data).enemy('goblin'));
  });
}
