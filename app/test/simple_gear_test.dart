// The Gear page as a plain grid of four columns: spec 0008 amendment 8
// criteria 1-5 (plan 0065).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/item_square.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final doll = key('paper-doll');
  const grid = [
    ['shoulder', 'head', 'neck', 'cloak'],
    ['mainHand', 'chest', 'gloves', 'offHand'],
    ['ring1', 'belt', 'bracer', 'ring2'],
    ['trinket1', 'legs', 'boots', 'trinket2'],
  ];

  testWidgets('criterion 1: the Gear page shows no figure', (t) async {
    await pumpGame(t, level: 12);
    await openGear(t);
    expect(doll, findsOneWidget);
    expect(
      find
          .descendant(of: doll, matching: find.byType(Icon))
          .evaluate()
          .where((e) => (e.widget as Icon).icon == Icons.accessibility_new),
      isEmpty,
    );
    // The Gear tab keeps its small figure icon; the page has none.
  });

  testWidgets('criterion 2: the 16 slots stand in four rows of four, in '
      'their places', (t) async {
    await pumpGame(t, level: 12);
    await openGear(t);
    expect(game.data.gearSlots, hasLength(16));
    expect(
      {for (final r in grid) ...r},
      {for (final g in game.data.gearSlots) g.id},
    );
    Rect at(String id) => t.getRect(key('slot-$id'));
    for (final (i, row) in grid.indexed) {
      for (final (j, id) in row.indexed) {
        // The same row as the first of its row, the same column as the
        // first of its column.
        expect(at(id).top, at(row.first).top, reason: '$id in row ${i + 1}');
        expect(
          at(id).left,
          at(grid.first[j]).left,
          reason: '$id in column ${j + 1}',
        );
        if (j > 0) {
          expect(at(id).left, greaterThan(at(row[j - 1]).left), reason: id);
        }
      }
      if (i > 0) {
        expect(at(row.first).top, greaterThan(at(grid[i - 1].first).top));
      }
    }
    expect(
      find.descendant(of: doll, matching: find.byType(ItemSquare)),
      findsNWidgets(16),
    );
  });

  testWidgets('criterion 3: on a 408 dp phone all 16 slots are on the screen '
      'without a scroll', (t) async {
    await t.runAsync(loadFonts);
    await pumpGame(t, level: 12);
    t.view.physicalSize = const Size(408, 884);
    await openGear(t);
    await t.pumpAndSettle();
    // Character opens at its top: each slot ends above the bottom bar.
    final bar = t.getTopLeft(find.byType(NavigationBar)).dy;
    final tabs = t.getRect(key('tab-gear')).bottom;
    for (final g in game.data.gearSlots) {
      final r = t.getRect(key('slot-${g.id}'));
      expect(r.top, greaterThan(tabs), reason: g.id);
      expect(r.bottom, lessThanOrEqualTo(bar), reason: '${g.id} on the screen');
    }
  });

  testWidgets('criterion 4: an empty slot opens its sheet, a filled one the '
      'card of its item', (t) async {
    await pumpGame(t, level: 12, equipment: {'chest': 'hide_vest'});
    await openGear(t);
    await t.tap(key('slot-head'));
    await t.pumpAndSettle();
    expect(key('slot-sheet'), findsOneWidget);
    await closeSheet(t);
    await t.tap(key('slot-chest'));
    await t.pumpAndSettle();
    expect(key('item-card'), findsOneWidget);
  });

  testWidgets('criterion 5: under a two-hander the Off hand is greyed', (
    t,
  ) async {
    await pumpGame(t, level: 30, equipment: {'mainHand': 'iron_pike'});
    await openGear(t);
    expect(t.widget<ItemSquare>(key('slot-offHand')).dimmed, isTrue);
    expect(t.widget<ItemSquare>(key('slot-head')).dimmed, isFalse);
  });
}
