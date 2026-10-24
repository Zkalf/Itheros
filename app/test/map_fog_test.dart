// Plan 0017 M3: the painted fog of the World map, as the design phones 08, 10
// and 15 show it (the owner asked for it on the review of M3). The fog shows
// by exploring (spec 0008 decision 5, spec 0014 §4.2: "fog stay as today").
// - The veil: one layer of fog over the map, with a soft hole around each
//   place out of the fog. It is clear to 62 dp from the map point of the
//   place, and full fog from 118 dp, at a map of 360 dp.
// - A cloud of 176 x 120 dp lies on each place in the fog.
// - The fog lies under the roads, the step plates, the markers, the names and
//   the ring. It does not change with the current place.
// The tests read what FogPainter paints, not pixels.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'images_test.dart' show loadFonts;
import 'quiet_teal_files_test.dart' show allowedRgb, hex, rgb;
import 'quiet_teal_test.dart' show withRoot;
import 'ui_test.dart' show game;
import 'world_route_test.dart'
    show area, mapImage, mapIn, pointOn, pumpRoute, pumpWorld;

final _world = find.byType(WorldTab);
final _fog = find.byKey(const ValueKey('map-fog'));

/// The painter of the fog in [within], and the rect of its CustomPaint.
(FogPainter, Rect) fogIn(WidgetTester t, Finder within) {
  final paint = find.descendant(
    of: within,
    matching: find.byWidgetPredicate(
      (w) => w is CustomPaint && w.foregroundPainter is FogPainter,
    ),
  );
  expect(paint, findsOneWidget, reason: 'one fog in $within');
  return (
    t.widget<CustomPaint>(paint).foregroundPainter! as FogPainter,
    t.getRect(paint),
  );
}

/// Expects [actual] to be [expected], point by point, within 0.5 dp.
void expectPoints(List<Offset> actual, List<Offset> expected, String what) {
  expect(actual, hasLength(expected.length), reason: what);
  for (final (i, p) in expected.indexed) {
    expect(actual[i], offsetMoreOrLessEquals(p, epsilon: .5), reason: what);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('the painted fog of the World map (design phones 08, 10 and 15)', () {
    testWidgets('at 360 dp, the fog lies over the map image and under the '
        'roads, the step plates, the markers, the names and the ring', (
      t,
    ) async {
      await pumpWorld(t, 'camp', everywhere: false);
      expect(_fog, findsOneWidget);
      final map = mapIn(t, _world);
      final (_, rect) = fogIn(t, _fog);
      expect(rect, rectMoreOrLessEquals(map, epsilon: .5), reason: 'the fog');
      expect(t.getRect(_fog), rectMoreOrLessEquals(map, epsilon: .5));
      // A Stack paints its children in order, so the order of the elements
      // is the order of the paint.
      final order = withRoot(t.element(_world)).toList();
      final fog = order.indexOf(t.element(_fog));
      expect(
        order.indexOf(t.element(mapImage(_world))),
        lessThan(fog),
        reason: 'the map image comes before the fog',
      );
      final roads = order.indexWhere(
        (e) =>
            e.widget is CustomPaint &&
            (e.widget as CustomPaint).painter is MapPainter,
      );
      expect(roads, greaterThan(fog), reason: 'the roads and plates');
      for (final l in game.data.locations.values) {
        if (area(l.id).evaluate().isEmpty) continue;
        expect(
          order.indexOf(t.element(area(l.id))),
          greaterThan(fog),
          reason: 'the marker, the name and the ring of ${l.id}',
        );
        expect(
          find.descendant(of: _fog, matching: area(l.id)),
          findsNothing,
          reason: l.id,
        );
      }
    });

    testWidgets('it clears each place out of the fog: a hole on its map '
        'point, clear to 62 dp and full fog from 118 dp; it covers each '
        'place in the fog with a cloud of 176 x 120 dp, and no hole lies '
        'within 118 dp of it', (t) async {
      final c = await pumpWorld(
        t,
        'camp',
        everywhere: false,
        change: (s) {
          s.explored.add('mirror_lake');
          s.revealed.add('smugglers_cove');
        },
      );
      final map = mapIn(t, _world);
      final (painter, rect) = fogIn(t, _fog);
      final shown = [
        for (final p in game.data.locations.keys)
          if (!game.isHidden(c.state, p)) p,
      ];
      final open = [
        for (final p in shown)
          if (!game.isFogged(c.state, p)) p,
      ];
      final fogged = [
        for (final p in shown)
          if (game.isFogged(c.state, p)) p,
      ];
      expect(fogged, isNotEmpty);
      final k = map.width / 360;
      expect(painter.clear, moreOrLessEquals(62 * k));
      expect(painter.full, moreOrLessEquals(118 * k));
      expect(painter.cloud.width, moreOrLessEquals(176 * k));
      expect(painter.cloud.height, moreOrLessEquals(120 * k));
      expectPoints(
        [for (final h in painter.holes) h + rect.topLeft],
        [for (final p in open) pointOn(map, p)],
        'a hole on each place out of the fog, and no other',
      );
      expectPoints(
        [for (final h in painter.clouds) h + rect.topLeft],
        [for (final p in fogged) pointOn(map, p)],
        'a cloud on each place in the fog, and no other',
      );
      for (final p in fogged) {
        for (final h in painter.holes) {
          expect(
            (h + rect.topLeft - pointOn(map, p)).distance,
            greaterThan(painter.full),
            reason: 'a hole clears the fog of $p',
          );
        }
      }
    });

    testWidgets('the fog is the same for each current place, and with each '
        'place explored it stays: a hole on each place, no cloud, and the '
        'far corner of the map in full fog', (t) async {
      FogPainter? first;
      for (final here in game.data.locations.keys) {
        await pumpWorld(t, here);
        final (painter, rect) = fogIn(t, _fog);
        final map = mapIn(t, _world);
        first ??= painter;
        expect(painter.holes, first.holes, reason: 'at $here');
        expect(painter.clouds, isEmpty, reason: 'at $here');
        expect(painter.scale, first.scale, reason: 'at $here');
        expect(
          painter.holes,
          hasLength(game.data.locations.length),
          reason: 'at $here: a hole on each place',
        );
        // Past the places, the land stays in the fog (phone 08).
        final corner = map.topRight - rect.topLeft;
        expect(
          painter.holes.every((h) => (h - corner).distance > painter.full),
          isTrue,
          reason: 'at $here: the far corner is clear',
        );
      }
    });

    testWidgets('the fog paints only allowed colours', (t) async {
      await pumpWorld(t, 'camp', everywhere: false);
      final (painter, _) = fogIn(t, _fog);
      expect(painter.colours, isNotEmpty);
      final allowed = allowedRgb(game);
      for (final c in painter.colours) {
        expect(
          allowed.contains(rgb(c)),
          isTrue,
          reason: '${hex(rgb(c))} in the fog is outside spec 0014',
        );
      }
    });

    testWidgets('the route map has no fog', (t) async {
      await pumpRoute(t);
      final routeMap = find.byKey(const ValueKey('route-map'));
      expect(routeMap, findsOneWidget);
      expect(find.descendant(of: routeMap, matching: _fog), findsNothing);
      expect(_fog, findsNothing);
    });
  });
}
