// Issue #121: a sheet over the World map opened at about 20 frames a
// second on the Fairphone, because the map was drawn again on each frame of
// the sheet animation, its fog most of all. Once the map image has loaded,
// the whole fog (the blurred, pale map, the veil, the holes and the clouds) is
// one image, made when the fog changes, with no live filter or layer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/images.dart' show Picture;
import 'package:walkingrpg/ui/world_tab.dart' show FogImage, MapPainter;

import 'map_fog_test.dart' show callsOf;
import 'ui_test.dart' show openTab, pumpGame;

void main() {
  // The soft edge of each dash of a road into the fog was a blur. The
  // renderer blurred each dash again on each frame, the biggest cost left
  // after the fog (measured on the phone: 11-12 frames in 2 s, 14-16 without).
  testWidgets('the roads are drawn with no live blur', (t) async {
    await pumpGame(t);
    await openTab(t, 'world');
    final paint = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MapPainter,
    );
    final painter = t.widget<CustomPaint>(paint).painter! as MapPainter;
    expect(painter.paths.any((p) => p.$3 == null), isTrue, reason: 'fog');
    final pens = [
      for (final c in callsOf(painter, t.getSize(paint)))
        if (c.memberName == #drawPath) c.positionalArguments[1] as Paint,
    ];
    expect(pens.where((p) => p.maskFilter != null), isEmpty);
  });

  testWidgets('the fog of a loaded map is one image, with no live filter', (
    t,
  ) async {
    await pumpGame(t);
    await openTab(t, 'world');
    final fog = find.byKey(const ValueKey('map-fog'));
    expect(fog, findsOneWidget);
    // The map image decodes outside the fake clock of the test.
    await t.runAsync(
      () => precacheImage(
        AssetImage(const Picture('pictures/world_map').asset!),
        t.element(fog),
      ),
    );
    await t.pumpAndSettle();
    final made = find.descendant(of: fog, matching: find.byType(FogImage));
    expect(made, findsOneWidget, reason: 'the fog, made once');
    for (final type in [ImageFiltered, ColorFiltered, CustomPaint]) {
      expect(
        find.descendant(of: fog, matching: find.byType(type)),
        findsNothing,
        reason: 'no live $type on each frame',
      );
    }
    // What the image holds (the review of #125): clear at the hole of the
    // current place, so the map shows there, and fog on a place in the fog.
    final fogImage = t.widget<FogImage>(made);
    final pixels = (await t.runAsync(() => fogImage.image.toByteData()))!;
    final scale = fogImage.image.width / fogImage.size.width;
    int alphaAt(Offset dp) {
      final x = (dp.dx * scale).round().clamp(0, fogImage.image.width - 1);
      final y = (dp.dy * scale).round().clamp(0, fogImage.image.height - 1);
      return pixels.getUint8((y * fogImage.image.width + x) * 4 + 3);
    }

    expect(fogImage.painter.holes, isNotEmpty);
    expect(fogImage.painter.clouds, isNotEmpty);
    for (final hole in fogImage.painter.holes) {
      expect(alphaAt(hole), lessThan(10), reason: 'the hole at $hole');
    }
    for (final cloud in fogImage.painter.clouds) {
      expect(alphaAt(cloud), 255, reason: 'the fog at $cloud');
    }
    // A tap on a place still opens its sheet.
    await t.tap(find.byKey(const ValueKey('area-camp')));
    await t.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
