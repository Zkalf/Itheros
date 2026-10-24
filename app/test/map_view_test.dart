// Plan 0017 M3, the owner's review: the map keeps what costs time to make.
// - A rebuild with the same roads, places and size keeps the placement of
//   the labels, which runs a search, and the laid-out step counts.
// - The map disposes of the step counts that it no longer paints.
// The tests read the paint calls of MapPainter, not pixels.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'images_test.dart' show loadFonts;
import 'world_route_test.dart' show paintCalls, painterIn, pumpWorld;

final _world = find.byType(WorldTab);

/// The painter of the World map, and the paragraphs of the step counts that
/// it paints.
(MapPainter, List<ui.Paragraph>) countsOf(WidgetTester t) {
  final (painter, box) = painterIn(t, _world);
  return (
    painter,
    [
      for (final c in paintCalls(painter, box.size))
        if (c.memberName == #drawParagraph)
          c.positionalArguments[0] as ui.Paragraph,
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('the owner\'s review of M3: the map keeps its placement and its '
      'step counts', () {
    testWidgets('a rebuild with the same roads, places and size keeps the '
        'placement of the labels and the laid-out step counts', (t) async {
      final c = await pumpWorld(t, 'camp');
      final (before, counts) = countsOf(t);
      expect(counts, isNotEmpty);
      // The controller tells its listeners, so the World tab builds again.
      await c.syncNow();
      await t.pump();
      final (after, again) = countsOf(t);
      expect(after, isNot(same(before)), reason: 'the map built again');
      expect(after.plates, same(before.plates), reason: 'the placement');
      expect(again, hasLength(counts.length));
      for (final (i, p) in counts.indexed) {
        expect(again[i], same(p), reason: 'step count ${i + 1}');
      }
    });

    testWidgets('a new width makes a new placement, and keeps the step '
        'counts', (t) async {
      await pumpWorld(t, 'camp');
      final (before, counts) = countsOf(t);
      t.view.physicalSize = const Size(411, 1200);
      await t.pumpAndSettle();
      final (after, again) = countsOf(t);
      expect(after.plates, isNot(same(before.plates)), reason: 'placement');
      for (final (i, p) in counts.indexed) {
        expect(again[i], same(p), reason: 'step count ${i + 1}');
      }
    });

    testWidgets('when the step counts change, the map disposes of the old '
        'ones, and of the last ones when it goes', (t) async {
      final c = await pumpWorld(t, 'camp', everywhere: false);
      final (_, counts) = countsOf(t);
      // Old Graveyard explored: the road to Grey Moor gets its count.
      c.state.explored.add('old_graveyard');
      await c.syncNow();
      await t.pump();
      final (_, again) = countsOf(t);
      expect(again.length, greaterThan(counts.length));
      for (final (i, p) in counts.indexed) {
        expect(p.debugDisposed, isTrue, reason: 'old step count ${i + 1}');
      }
      for (final p in again) {
        expect(p.debugDisposed, isFalse, reason: 'a step count it paints');
      }
      await t.pumpWidget(const SizedBox());
      for (final (i, p) in again.indexed) {
        expect(p.debugDisposed, isTrue, reason: 'last step count ${i + 1}');
      }
    });
  });
}
