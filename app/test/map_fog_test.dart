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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'images_test.dart' show loadFonts;
import 'quiet_teal_files_test.dart' show allowedRgb, caseRgb, hex, rgb, textRgb;
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

/// The calls that [painter] makes on a canvas of [size].
List<Invocation> callsOf(CustomPainter painter, Size size) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, size);
  return [for (final c in canvas.invocations) c.invocation];
}

/// The colour filter that changes no colour: the filter of a layer of its
/// own.
const _sameColours = ColorFilter.matrix([
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// The widgets from [e] up to the widget [top], [e] and [top] left out.
List<Widget> between(Element e, Element top) {
  final out = <Widget>[];
  e.visitAncestorElements((a) {
    if (a == top) return false;
    out.add(a.widget);
    return true;
  });
  return out;
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

  // A review of the fog: what FogPainter paints, and the layers of the fog.
  group('the painted fog: what it paints, and its layers', () {
    testWidgets('FogPainter paints the veil over the whole map, a hole that '
        'clears it on each place out of the fog, and a cloud on each place '
        'in the fog', (t) async {
      await pumpWorld(
        t,
        'camp',
        everywhere: false,
        change: (s) {
          s.explored.add('mirror_lake');
          s.revealed.add('smugglers_cove');
        },
      );
      final (painter, rect) = fogIn(t, _fog);
      final calls = callsOf(painter, rect.size);
      expect(calls.first.memberName, #drawRect, reason: 'the veil');
      expect(calls.first.positionalArguments[0], Offset.zero & rect.size);
      final holes = [
        for (final c in calls)
          if (c.memberName == #drawCircle &&
              (c.positionalArguments[2] as Paint).blendMode == BlendMode.dstOut)
            c,
      ];
      expectPoints(
        [for (final c in holes) c.positionalArguments[0] as Offset],
        painter.holes,
        'a hole that clears the fog on each place out of the fog',
      );
      for (final c in holes) {
        expect(c.positionalArguments[1], moreOrLessEquals(painter.full));
      }
      // A cloud is a circle, made flat on its own centre.
      final r = painter.cloud.width / 2;
      final clouds = [
        for (final (i, c) in calls.indexed)
          if (c.memberName == #drawCircle &&
              (c.positionalArguments[2] as Paint).blendMode != BlendMode.dstOut)
            (calls[i - 2], calls[i - 1], c),
      ];
      expect(clouds, hasLength(painter.clouds.length));
      for (final (i, (move, flat, circle)) in clouds.indexed) {
        expect(move.memberName, #translate);
        expect(
          Offset(
            move.positionalArguments[0] as double,
            move.positionalArguments[1] as double,
          ),
          offsetMoreOrLessEquals(painter.clouds[i]),
        );
        expect(flat.memberName, #scale);
        expect(flat.positionalArguments, [
          1,
          moreOrLessEquals(painter.cloud.height / painter.cloud.width),
        ]);
        expect(circle.positionalArguments[0], Offset.zero);
        expect(circle.positionalArguments[1], moreOrLessEquals(r));
      }
    });

    testWidgets('a hole is clear to 62 dp and full fog from 118 dp at a map '
        'of 360 dp', (t) async {
      const size = Size(300, 300);
      const centre = Offset(150, 150);
      final painter = FogPainter(holes: [centre], clouds: [], scale: 1);
      final pixels = (await t.runAsync(() async {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), size);
        final image = await recorder.endRecording().toImage(300, 300);
        return image.toByteData();
      }))!;
      int alphaAt(double x) =>
          pixels.getUint8(150 * 300 * 4 + x.round() * 4 + 3);
      final veil = alphaAt(1);
      expect(veil, greaterThan(100), reason: 'the veil');
      expect(alphaAt(150), 0, reason: 'the centre of the hole');
      expect(alphaAt(150 + 60), lessThanOrEqualTo(2), reason: 'at 60 dp');
      expect(alphaAt(150 + 90), inExclusiveRange(2, veil - 2), reason: '90');
      expect(alphaAt(150 + 120), closeTo(veil, 2), reason: 'at 120 dp');
    });

    testWidgets('the fog has a layer of its own, which changes no colour: the '
        'holes clear only the fog; and the mist turns only the map pale, '
        'not the veil and the clouds', (t) async {
      await pumpWorld(t, 'camp', everywhere: false);
      final paint = find.descendant(
        of: _fog,
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.foregroundPainter is FogPainter,
        ),
      );
      final layers = [
        for (final w in between(t.element(paint), t.element(_fog)))
          if (w is ColorFiltered) w.colorFilter,
      ];
      expect(layers, [_sameColours], reason: 'the layer of the fog');
      final image = find.descendant(of: _fog, matching: find.byType(Image));
      if (image.evaluate().isEmpty) {
        // Once the map image has loaded, the blurred, pale map is one image
        // made once (#121): no live mist and no live blur under the painter.
        final made = find.descendant(of: _fog, matching: find.byType(RawImage));
        final underPaint = between(t.element(made), t.element(paint));
        expect(underPaint.whereType<ColorFiltered>(), isEmpty);
        expect(underPaint.whereType<ImageFiltered>(), isEmpty);
        return;
      }
      // Before it has loaded, the mist and the blur are live.
      final underPaint = between(t.element(image), t.element(paint));
      expect(
        [
          for (final w in underPaint)
            if (w is ColorFiltered) w.colorFilter,
        ],
        [isNot(_sameColours)],
        reason: 'the mist over the blurred map, and over nothing else',
      );
      expect(underPaint.whereType<ImageFiltered>(), hasLength(1));
    });

    testWidgets('each dash of a road into the fog lies on a dark edge, as a '
        'solid road does', (t) async {
      await pumpWorld(t, 'camp', everywhere: false);
      final paint = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MapPainter,
      );
      final painter = t.widget<CustomPaint>(paint).painter! as MapPainter;
      final calls = callsOf(painter, t.getSize(paint));
      final paths = [
        for (final c in calls)
          if (c.memberName == #drawPath)
            (
              (c.positionalArguments[0] as Path).getBounds(),
              c.positionalArguments[1] as Paint,
            ),
      ];
      final fog = [
        for (final (a, b, steps) in painter.paths)
          if (steps == null) Rect.fromPoints(a, b).inflate(2),
      ];
      expect(fog, isNotEmpty);
      var dashes = 0;
      for (final (i, (box, pen)) in paths.indexed) {
        if (rgb(pen.color) != textRgb) continue;
        if (!fog.any((r) => r.contains(box.center))) continue;
        dashes++;
        expect(i, greaterThan(0), reason: 'a dash at $box has no edge');
        final (under, edge) = paths[i - 1];
        expect(under, rectMoreOrLessEquals(box, epsilon: .01));
        expect(rgb(edge.color), caseRgb);
        expect(edge.strokeWidth, greaterThan(pen.strokeWidth));
      }
      expect(dashes, greaterThan(0));
    });
  });
}
