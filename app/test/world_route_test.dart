// Spec 0014 (Quiet Teal), plan 0017 M3: the tests of criteria 12, 18, 25 and
// 26, and what M3 adds to the tests of criteria 2, 3, 4 and 11. Each widget
// test reads what the player sees: the markers, the ring, the names and the
// step plates of the World map, the route map of a report, and the rows of
// Achievements.
// - The map image (pictures/world_map.webp) comes with the code of M3. Until
//   it exists, each test that shows a map fails with "Unable to load asset".
// - The file loads the four fonts of the app, so that the tests of criterion
//   18 measure the names as the player sees them.
// - The controller keeps its save in MemorySaveStore, so no real I/O runs in
//   a test.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/achievements_screen.dart';
import 'package:walkingrpg/ui/away_summary_card.dart'
    show AwayScreen, ReportBanner;
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/journal_screen.dart';
import 'package:walkingrpg/ui/labels.dart' show fmt;
import 'package:walkingrpg/ui/map_labels.dart';
import 'package:walkingrpg/ui/route_map.dart';
import 'package:walkingrpg/ui/socket.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'images_test.dart'
    show
        assetName,
        assetOf,
        boxIn,
        diskImages,
        expectShows,
        imagesIn,
        keyIn,
        loadFonts,
        markIn,
        socketIn;
import 'quiet_teal_files_test.dart'
    show allowedRgb, cormorant, hex, rgb, spectral, tealRgb;
import 'quiet_teal_test.dart'
    show
        byElement,
        drawnBy,
        expectBordersOnScreen,
        expectRgb,
        openJournal,
        piecesOf,
        squash,
        withRoot;
import 'ui_test.dart'
    show game, now, openAchievements, openTab, pumpGame, pumpSave, settle;

void main() {
  // The fonts load from disk before the tests.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  criterion12();
  criterion18();
  criterion25();
  criterion26();
  criterion11();
  criteria2to4();
}

// The World map.

final _world = find.byType(WorldTab);

Finder area(String place) => find.byKey(ValueKey('area-$place'));

/// Pumps the app at a width of 360 dp with the image files on disk, at
/// [location], and opens the World map. With [everywhere], each place is
/// explored and Smugglers' Cove is revealed. [change] changes the state before
/// the map opens.
Future<GameController> pumpWorld(
  WidgetTester t,
  String location, {
  bool everywhere = true,
  void Function(GameState)? change,
}) async {
  // A new tree, so that nothing of the last pump stays.
  await t.pumpWidget(const SizedBox());
  final (c, _) = await pumpGame(t, location: location, images: diskImages);
  if (everywhere) {
    c.state.explored.addAll(game.data.locations.keys);
    c.state.revealed.add('smugglers_cove');
  }
  change?.call(c.state);
  t.view.physicalSize = const Size(360, 1200);
  await t.pumpAndSettle();
  await openTab(t, 'world');
  return c;
}

/// The map image in [within].
Finder mapImage(Finder within) => find.descendant(
  of: within,
  matching: find.byWidgetPredicate(
    (w) => w is Image && assetName(w.image) == assetOf('pictures/world_map'),
  ),
);

/// The rect of the one map image in [within]: the map.
Rect mapIn(WidgetTester t, Finder within) {
  expect(mapImage(within), findsOneWidget, reason: 'one map image in $within');
  return t.getRect(mapImage(within));
}

/// The map point of [place] on the map image [image].
Offset pointOn(Rect image, String place) {
  final p = game.data.locations[place]!.map!;
  return image.topLeft + Offset(p.x * image.width, p.y * image.height);
}

/// The centre of the marker of [place] on [image]: its map point, moved
/// inward on each axis just enough that the marker of [size] and a ring of
/// [ring] around it lie inside the image. A marker never leaves the map.
Offset markerCentre(
  Rect image,
  String place, {
  required double size,
  required double ring,
}) {
  final p = pointOn(image, place);
  final r = size / 2 + ring;
  return Offset(
    p.dx.clamp(image.left + r, image.right - r),
    p.dy.clamp(image.top + r, image.bottom - r),
  );
}

/// The width of the one place ring in [within].
double ringWidth(WidgetTester t, Finder within) {
  final border = boxIn(t, within, 'place-ring')?.border;
  expect(border, isA<Border>(), reason: 'one ring with a border in $within');
  return (border! as Border).top.width;
}

/// The text [text] in [within], on one line or on two.
Finder textIn(Finder within, String text) => find.descendant(
  of: within,
  matching: find.byWidgetPredicate(
    (w) => w is RichText && squash(w.text.toPlainText()) == text,
  ),
);

/// The box of the name [name] in [within]: its text, with each painted box
/// that holds it, up to the first widget that also holds a marker.
Rect nameBox(WidgetTester t, Finder within, String name) {
  final text = textIn(within, name);
  expect(text, findsOneWidget, reason: 'the name $name in $within');
  var box = t.getRect(text);
  t.element(text).visitAncestorElements((a) {
    final socket = find.descendant(
      of: byElement(a),
      matching: find.byType(PictureSocket),
    );
    if (socket.evaluate().isNotEmpty) return false;
    if (drawnBy(a)?.paints ?? false) {
      box = box.expandToInclude(t.getRect(byElement(a)));
    }
    return true;
  });
  return box;
}

/// The outline of [box] drawn at [rect]: a circle or a rounded rect.
RRect outlineOf(BoxDecoration box, Rect rect) => box.shape == BoxShape.circle
    ? RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2))
    : (box.borderRadius?.resolve(TextDirection.ltr) ?? BorderRadius.zero)
          .toRRect(rect);

/// The outline of the face of [socket]: the first box that it draws.
RRect faceOf(WidgetTester t, Finder socket) {
  final face = find
      .descendant(of: socket, matching: find.byType(DecoratedBox))
      .first;
  final box = t.widget<DecoratedBox>(face).decoration;
  expect(box, isA<BoxDecoration>(), reason: 'the face of a socket is a box');
  return outlineOf(box as BoxDecoration, t.getRect(face));
}

/// Expects one teal ring in [within], flush around [socket]: its inner edge
/// is the outline of the face of the socket, with no gap and no overlap.
void expectPlaceRing(
  WidgetTester t,
  Finder within,
  Finder socket,
  String what,
) {
  final box = boxIn(t, within, 'place-ring');
  expect(box, isNotNull, reason: '$what: no ring');
  expect(box!.border, isA<Border>(), reason: '$what: the ring has a border');
  final border = box.border! as Border;
  final width = border.top.width;
  expect(width, greaterThan(0), reason: '$what: the ring has a width');
  for (final s in [border.top, border.right, border.bottom, border.left]) {
    expect((s.style, s.width), (BorderStyle.solid, width), reason: what);
    expectRgb(s.color, tealRgb, '$what: the ring');
  }
  final inner = outlineOf(
    box,
    t.getRect(keyIn(within, 'place-ring')),
  ).deflate(width);
  final face = faceOf(t, socket);
  expect(
    inner.outerRect,
    rectMoreOrLessEquals(face.outerRect, epsilon: .5),
    reason: '$what: the inner edge of the ring lies on the edge of the marker',
  );
  expect(
    inner.tlRadiusX,
    moreOrLessEquals(face.tlRadiusX, epsilon: .5),
    reason: '$what: the ring follows the shape of the marker',
  );
}

/// The elements of each widget that [finder] finds, with all below them.
Set<Element> subtree(Finder finder) => {
  for (final e in finder.evaluate()) ...withRoot(e),
};

/// The MapPainter in [within] and the rect of its CustomPaint.
(MapPainter, Rect) painterIn(WidgetTester t, Finder within) {
  final paint = find.descendant(
    of: within,
    matching: find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MapPainter,
    ),
  );
  expect(paint, findsOneWidget, reason: 'one MapPainter in $within');
  return (
    t.widget<CustomPaint>(paint).painter! as MapPainter,
    t.getRect(paint),
  );
}

/// The calls that [painter] makes on a canvas of [size].
List<Invocation> paintCalls(MapPainter painter, Size size) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, size);
  return [for (final c in canvas.invocations) c.invocation];
}

/// The step plates that [painter] paints on [box], each with the two ends of
/// its road, on the screen. A plate is the smallest filled rounded rect that
/// holds a count. The counts come in the order of the labelled paths.
List<(Rect, Offset, Offset)> platesOf(MapPainter painter, Rect box) {
  final calls = paintCalls(painter, box.size);
  final plates = [
    for (final c in calls)
      if (c.memberName == #drawRRect &&
          (c.positionalArguments[1] as Paint).style == PaintingStyle.fill)
        (c.positionalArguments[0] as RRect).outerRect,
  ];
  final counts = [
    for (final c in calls)
      if (c.memberName == #drawParagraph)
        if (c.positionalArguments[0] case final ui.Paragraph p)
          (c.positionalArguments[1] as Offset) & Size(p.longestLine, p.height),
  ];
  final roads = [
    for (final p in painter.paths)
      if (p.$3 != null) p,
  ];
  expect(counts, hasLength(roads.length), reason: 'a count on each road');
  return [
    for (final (i, count) in counts.indexed)
      (
        _holder(count, plates).shift(box.topLeft),
        roads[i].$1 + box.topLeft,
        roads[i].$2 + box.topLeft,
      ),
  ];
}

Rect _holder(Rect count, List<Rect> plates) {
  final holders = [
    for (final p in plates)
      if (p.inflate(.5).contains(count.topLeft) &&
          p.inflate(.5).contains(count.bottomRight))
        p,
  ]..sort((a, b) => (a.width * a.height).compareTo(b.width * b.height));
  expect(holders, isNotEmpty, reason: 'the count at $count has no plate');
  return holders.first;
}

/// The place whose marker centre in [centres] is [point].
String placeAt(Map<String, Offset> centres, Offset point) =>
    centres.entries
        .where((e) => (e.value - point).distance < .5)
        .map((e) => e.key)
        .firstOrNull ??
    'no marker at $point';

String road(String a, String b) => ([a, b]..sort()).join(' – ');

// The rule of the map labels.

bool _inside(Rect r, Rect map) =>
    r.left >= map.left - .01 &&
    r.top >= map.top - .01 &&
    r.right <= map.right + .01 &&
    r.bottom <= map.bottom + .01;

bool _overlap(Rect a, Rect b) {
  final both = a.intersect(b);
  return both.width > .01 && both.height > .01;
}

double _gap(Rect a, Rect b) {
  final dx = math.max(
    0.0,
    math.max(a.left, b.left) - math.min(a.right, b.right),
  );
  final dy = math.max(
    0.0,
    math.max(a.top, b.top) - math.min(a.bottom, b.bottom),
  );
  return math.sqrt(dx * dx + dy * dy);
}

/// Whether the segment from [a] to [b] crosses [r].
bool _crosses(Offset a, Offset b, Rect r) {
  var (t0, t1) = (0.0, 1.0);
  final d = b - a;
  for (final (p, q) in [
    (-d.dx, a.dx - r.left),
    (d.dx, r.right - a.dx),
    (-d.dy, a.dy - r.top),
    (d.dy, r.bottom - a.dy),
  ]) {
    if (p == 0) {
      if (q < 0) return false;
    } else if (p < 0) {
      t0 = math.max(t0, q / p);
    } else {
      t1 = math.min(t1, q / p);
    }
  }
  return t0 <= t1;
}

/// Expects the rule of the map labels (spec 0014 §2.3, plan 0017 M3):
/// - no two of the markers, the names and the plates overlap;
/// - each name lies inside [map], at most 8 dp from its marker;
/// - each plate lies on its road: the road crosses it.
/// The marker of the current place is the ring.
void expectPlaced({
  required Rect map,
  required Map<String, Rect> markers,
  required Map<String, Rect> names,
  required List<(Rect, Offset, Offset)> plates,
  required String what,
}) {
  final items = [
    for (final MapEntry(:key, :value) in markers.entries)
      ('the marker of $key', value),
    for (final MapEntry(:key, :value) in names.entries)
      ('the name of $key', value),
    for (final (i, (plate, _, _)) in plates.indexed)
      ('step plate ${i + 1}', plate),
  ];
  expect(
    [
      for (final (i, (a, ra)) in items.indexed)
        for (final (b, rb) in items.skip(i + 1))
          if (_overlap(ra, rb)) '$a $ra and $b $rb',
    ],
    isEmpty,
    reason: '$what: these overlap',
  );
  for (final MapEntry(key: place, value: name) in names.entries) {
    expect(
      _inside(name, map),
      isTrue,
      reason: '$what: the name of $place $name lies outside the map $map',
    );
    expect(
      _gap(name, markers[place]!),
      lessThanOrEqualTo(8),
      reason: '$what: the name of $place $name is far from its marker',
    );
  }
  for (final (i, (plate, a, b)) in plates.indexed) {
    expect(
      _crosses(a, b, plate),
      isTrue,
      reason: '$what: step plate ${i + 1} $plate is off its road $a – $b',
    );
  }
}

/// What [elements] show, apart from [skip]: each paint, each text with its
/// look, each icon and image, the size of each socket, and each paint of a
/// MapPainter. Sorted, so that the places of things do not count.
List<String> looksOf(
  WidgetTester t,
  Iterable<Element> elements,
  Set<Element> skip,
) => [
  for (final e in elements)
    if (!skip.contains(e)) ..._lookOf(t, e),
]..sort();

List<String> _lookOf(WidgetTester t, Element e) => switch (e.widget) {
  final RichText w => [
    'text "${squash(w.text.toPlainText())}": ${[for (final (_, s) in piecesOf(w)) '${s.color} ${s.fontFamily} ${s.fontWeight} ${s.fontSize} '
          '${s.fontStyle}']}',
  ],
  final Icon w => ['icon ${w.icon} ${w.color}'],
  final Image w => ['image ${assetName(w.image)}'],
  final PictureSocket w => ['socket ${w.size}'],
  CustomPaint(painter: final MapPainter p) => [
    for (final c in paintCalls(p, t.getSize(byElement(e))))
      '${c.memberName}: ${[for (final a in c.positionalArguments)
        if (a is Paint) '${a.color} ${a.style} ${a.strokeWidth}']}',
  ],
  _ => [
    if (drawnBy(e) case final d? when d.paints)
      '${d.what} ${d.fill} ${d.gradient} ${d.radius} ${d.sides}',
  ],
};

/// The size of [text] in [style] on one line, or on the lines of its "\n".
Size measure(String text, TextStyle style) {
  final p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final size = p.size;
  p.dispose();
  return size;
}

final _phone = Size(360, 360 * game.data.mapAspect);

/// The labels of the real map at 360 dp with [here] as the current place:
/// markers of 40 dp at their centres inside the map, a ring of 3 dp, names in
/// Cormorant Garamond 600 at 14 dp on one line or wrapped at the first space,
/// and the step counts in Spectral at 11 dp with 3 dp around them.
({List<MapName> names, List<MapPlate> plates}) realLabels(String here) {
  Offset at(String p) =>
      markerCentre(Offset.zero & _phone, p, size: 40, ring: 3);

  const name = TextStyle(
    fontFamily: cormorant,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
  return (
    names: [
      for (final l in game.data.locations.values)
        MapName(
          place: l.id,
          marker: Rect.fromCenter(
            center: at(l.id),
            width: 40,
            height: 40,
          ).inflate(l.id == here ? 3 : 0),
          sizes: [
            measure(l.name, name),
            if (l.name.contains(' '))
              measure(l.name.replaceFirst(' ', '\n'), name),
          ],
        ),
    ],
    plates: [
      for (final r in game.data.routes)
        MapPlate(
          from: at(r.from),
          to: at(r.to),
          size:
              (Offset.zero &
                      measure(
                        fmt(r.steps),
                        const TextStyle(fontFamily: spectral, fontSize: 11),
                      ))
                  .inflate(3)
                  .size,
        ),
    ],
  );
}

bool _sameSize(Size a, Size b) =>
    (a.width - b.width).abs() < .01 && (a.height - b.height).abs() < .01;

// The route.

/// The route of [walkRoute].
const _route = ['camp', 'goblin_woods', 'copper_hills', 'mirror_lake'];

/// A controller on a new game at [location], with its save in memory, and its
/// step source. Its clock is `now` of ui_test.dart.
Future<(GameController, FakeStepSource)> startController({
  String location = 'camp',
}) async {
  now = DateTime(2026, 10, 18, 9);
  final source = FakeStepSource();
  final state = game.newGame(seed: 1)
    ..location = location
    ..explored.add(location);
  final c = GameController(
    game: game,
    source: source,
    permissions: source,
    store: MemorySaveStore(
      SaveData(
        game: state,
        firstDay: '2026-10-18',
        credited: const {},
      ).toJson(),
    ),
    clock: () => now,
    syncInterval: null,
    newSeed: () => 1,
  );
  addTearDown(c.dispose);
  await c.start();
  return (c, source);
}

/// Queues the walk from Camp to Goblin Woods (200 steps), Copper Hills (300)
/// and Mirror Lake (300). The player walks 200 steps on 18 October and 300 on
/// 19 October, and opens the app at 09:00: one sync over two days.
Future<void> walkTwoDays(GameController c, FakeStepSource source) async {
  await c.startActivity(const Activity.travel('goblin_woods'));
  await c.addAction(const Activity.travel('copper_hills'));
  await c.addAction(const Activity.travel('mirror_lake'));
  c.pause();
  source
    ..walk(DateTime(2026, 10, 18, 20), 200)
    ..walk(DateTime(2026, 10, 19, 8), 300);
  now = DateTime(2026, 10, 19, 9);
  await c.resume();
}

/// Then 300 late steps arrive and sync at 09:01, inside the grace period of
/// the report: the second sync.
Future<void> syncLateSteps(GameController c, FakeStepSource source) async {
  source.walk(DateTime(2026, 10, 19, 8, 30), 300);
  now = DateTime(2026, 10, 19, 9, 1);
  await c.syncNow();
}

/// The walk of [_route] over two days and two syncs.
Future<void> walkRoute(GameController c, FakeStepSource source) async {
  await walkTwoDays(c, source);
  await syncLateSteps(c, source);
}

/// Pumps the app with the image files on disk and walks [_route], so that
/// the away screen opens on its report.
Future<GameController> pumpRoute(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  final (c, source) = await pumpGame(t, images: diskImages);
  t.view.physicalSize = const Size(360, 2400);
  await walkRoute(c, source);
  await t.pumpAndSettle();
  return c;
}

final _routeMap = find.byKey(const ValueKey('route-map'));

/// The marker of [place] on [routeMap]: the one socket with the key
/// `route-<id>`, or in the widget with that key.
Finder routeSocket(Finder routeMap, String place) {
  final socket = find.descendant(
    of: keyIn(routeMap, 'route-$place'),
    matching: find.byType(PictureSocket),
    matchRoot: true,
  );
  expect(socket, findsOneWidget, reason: 'the marker of $place');
  return socket;
}

/// Expects [routeMap] to show [route] (spec 0014 §5): the map image across its
/// width, cut to the strip of routeStrip; a marker at each place passed, and
/// no other; the roads walked; the ring on the last place; and its names and
/// plates by the rule of the map labels.
void expectRouteMap(
  WidgetTester t,
  Finder routeMap,
  List<String> route,
  String what,
) {
  final box = t.getRect(routeMap);
  final map = mapIn(t, routeMap);
  expect(map.left, moreOrLessEquals(box.left, epsilon: .5), reason: what);
  expect(
    map.width,
    moreOrLessEquals(box.width, epsilon: .5),
    reason: '$what: the map image fills the width of the route map',
  );
  expect(
    map.height,
    moreOrLessEquals(map.width * game.data.mapAspect, epsilon: .5),
  );
  final strip = routeStrip(game.data, route, box.width);
  expect(
    box.height,
    moreOrLessEquals(strip.height, epsilon: .5),
    reason: '$what: the route map is as tall as its strip $strip',
  );
  expect(
    map.top,
    moreOrLessEquals(box.top - strip.top, epsilon: .5),
    reason: '$what: the route map shows the strip $strip of the image',
  );
  final above = <Element>{};
  t.element(mapImage(routeMap)).visitAncestorElements((a) {
    above.add(a);
    return a != t.element(routeMap);
  });
  final clips = [
    for (final e in withRoot(t.element(routeMap)))
      if (above.contains(e) &&
          (e.widget is ClipRect ||
              e.widget is ClipRRect ||
              e.widget is ClipPath))
        t.getRect(byElement(e)),
  ];
  expect(
    clips.any(
      (c) =>
          (c.topLeft - box.topLeft).distance < .5 &&
          (c.bottomRight - box.bottomRight).distance < .5,
    ),
    isTrue,
    reason: '$what: no clip of the rect $box above the image, only $clips',
  );

  final places = route.toSet();
  expect(
    find.descendant(of: routeMap, matching: find.byType(PictureSocket)),
    findsNWidgets(places.length),
    reason: '$what: a marker at each place passed, and no other',
  );
  final centres = {
    for (final p in places) p: t.getCenter(routeSocket(routeMap, p)),
  };
  final ring = ringWidth(t, routeMap);
  for (final MapEntry(key: p, value: centre) in centres.entries) {
    // As on the World map: at its map point, inside the whole image.
    final at = markerCentre(
      map,
      p,
      size: t.getSize(routeSocket(routeMap, p)).width,
      ring: ring,
    );
    expect(
      centre,
      offsetMoreOrLessEquals(at, epsilon: .5),
      reason: '$what: the marker of $p sits at its place on the image',
    );
  }
  final (painter, paint) = painterIn(t, routeMap);
  final walked = {
    for (var i = 1; i < route.length; i++)
      if (route[i - 1] != route[i]) road(route[i - 1], route[i]),
  };
  final drawn = [
    for (final (a, b, _) in painter.paths)
      road(
        placeAt(centres, a + paint.topLeft),
        placeAt(centres, b + paint.topLeft),
      ),
  ];
  expect(drawn.toSet(), walked, reason: '$what: the roads walked');
  expect(drawn, hasLength(walked.length), reason: '$what: each road once');

  final last = routeSocket(routeMap, route.last);
  expectPlaceRing(t, routeMap, last, '$what: the last place');
  expectPlaced(
    map: box,
    markers: {
      for (final p in places)
        p: p == route.last
            ? t.getRect(keyIn(routeMap, 'place-ring'))
            : t.getRect(routeSocket(routeMap, p)),
    },
    names: {
      for (final p in places)
        if (textIn(
          routeMap,
          game.data.locations[p]!.name,
        ).evaluate().isNotEmpty)
          p: nameBox(t, routeMap, game.data.locations[p]!.name),
    },
    plates: platesOf(painter, paint),
    what: what,
  );
}

/// Expects the report in [card] to show [time] first, then its banners, then
/// the route map of [route], then its lines from "You walked [walked] steps.".
void expectReportWithRoute(
  WidgetTester t,
  Finder card,
  String time,
  int walked,
  List<String> route,
  String what,
) {
  final top = t.getRect(textIn(card, time));
  for (final e
      in find
          .descendant(of: card, matching: find.byType(RichText))
          .evaluate()) {
    expect(
      t.getRect(byElement(e)).top,
      greaterThanOrEqualTo(top.top - .5),
      reason: '$what: the time is the first line',
    );
  }
  final routeMap = keyIn(card, 'route-map');
  expect(routeMap, findsOneWidget, reason: '$what: one route map');
  final map = t.getRect(routeMap);
  final banners = find
      .descendant(of: card, matching: find.byType(ReportBanner))
      .evaluate();
  expect(banners, isNotEmpty, reason: '$what: the report has banners');
  for (final b in banners) {
    final banner = t.getRect(byElement(b));
    expect(banner.top, greaterThanOrEqualTo(top.bottom - .5), reason: what);
    expect(
      banner.bottom,
      lessThanOrEqualTo(map.top + .5),
      reason: '$what: the banner $banner comes before the route map $map',
    );
  }
  expect(
    map.bottom,
    lessThanOrEqualTo(
      t.getRect(textIn(card, 'You walked ${fmt(walked)} steps.')).top + .5,
    ),
    reason: '$what: the route map comes before the lines',
  );
  expectRouteMap(t, routeMap, route, what);
}

/// The card of the report with the time [time] in [screen].
Finder reportCard(Finder screen, String time) =>
    find.ancestor(of: textIn(screen, time), matching: find.byType(Card)).first;

/// Expects [socket] at the start of [row]: no text and no other socket lies
/// to its left.
void expectStartsRow(WidgetTester t, Finder row, Finder socket, String what) {
  final start = t.getRect(socket);
  final inside = subtree(socket);
  for (final e
      in find
          .descendant(
            of: row,
            matching: find.byWidgetPredicate(
              (w) => w is RichText || w is PictureSocket,
            ),
          )
          .evaluate()) {
    if (inside.contains(e)) continue;
    expect(
      t.getRect(byElement(e)).left,
      greaterThanOrEqualTo(start.right - .5),
      reason: '$what: ${e.widget} lies left of the picture $start',
    );
  }
}

// The criteria.

void criterion12() {
  group('spec 0014 criterion 12: the fog marker, the water icon and the '
      'locked patch', () {
    testWidgets('on the World map, each place in the fog shows the fog marker '
        'and "???", and Mirror Lake and Smugglers\' Cove show the water '
        'icon; none has the PH mark', (t) async {
      expect(
        diskImages.has('places/water'),
        isFalse,
        reason: 'the test needs water places with no marker',
      );
      final c = await pumpWorld(
        t,
        'camp',
        everywhere: false,
        change: (s) {
          s.explored.add('mirror_lake');
          s.revealed.add('smugglers_cove');
        },
      );
      final fogged = [
        for (final p in game.data.locations.keys)
          if (!game.isHidden(c.state, p) && game.isFogged(c.state, p)) p,
      ];
      expect(fogged, isNotEmpty);
      for (final p in fogged) {
        expect(imagesIn(t, area(p)), [assetOf('places/fog')], reason: p);
        expect(textIn(area(p), '???'), findsOneWidget, reason: p);
        expect(markIn(area(p)), findsNothing, reason: p);
      }
      for (final p in ['mirror_lake', 'smugglers_cove']) {
        expect(game.isFogged(c.state, p), isFalse, reason: p);
        final socket = socketIn(area(p));
        expect(
          find.descendant(of: socket, matching: find.byIcon(Icons.water)),
          findsOneWidget,
          reason: '$p shows the water icon in its marker',
        );
        expect(imagesIn(t, socket), isEmpty, reason: '$p shows no image');
        expect(markIn(area(p)), findsNothing, reason: '$p has no PH mark');
      }
    });

    testWidgets('on Achievements, a locked achievement shows the locked patch '
        'and an earned one its image, each in a 48 dp socket at the start of '
        'its row; the list stays a ListView', (t) async {
      final (c, _) = await pumpGame(t, images: diskImages);
      c.state.achievements.addAll(['first_steps', 'smith']);
      await openAchievements(t);
      final list = find.descendant(
        of: find.byType(AchievementsScreen),
        matching: find.byType(ListView),
      );
      expect(list, findsOneWidget);
      for (final a in game.data.achievements.values) {
        final earned = c.state.achievements.contains(a.id);
        final row = find.byKey(ValueKey('achievement-${a.id}'));
        expect(find.descendant(of: list, matching: row), findsOneWidget);
        final socket = socketIn(row);
        expect(t.getSize(socket), const Size(48, 48), reason: a.id);
        expect(imagesIn(t, socket), [
          assetOf(earned ? 'achievements/${a.id}' : 'pictures/locked_patch'),
        ], reason: '${a.id}, ${earned ? 'earned' : 'locked'}');
        expect(markIn(row), findsNothing, reason: a.id);
        expectStartsRow(t, row, socket, a.id);
      }
    });
  });
}

void criterion18() {
  final places = game.data.locations.keys.toList();

  group('spec 0014 criterion 18: one teal ring marks the current place, and '
      'nothing on the map overlaps', () {
    testWidgets('the map image fills the width of the World tab; each marker '
        'sits at its map point, moved inward only as far as the map edge '
        'needs; the roads join the markers, and MapPainter draws no '
        'river', (t) async {
      await pumpWorld(t, 'camp');
      final tab = t.getRect(_world);
      final map = mapIn(t, _world);
      expect(tab.width, 360);
      expect(map.left, moreOrLessEquals(tab.left, epsilon: .5));
      expect(map.width, moreOrLessEquals(tab.width, epsilon: .5));
      expect(
        map.height,
        moreOrLessEquals(map.width * game.data.mapAspect, epsilon: .5),
      );
      final centres = {
        for (final p in places) p: t.getCenter(socketIn(area(p))),
      };
      final ring = ringWidth(t, _world);
      final far = <String>[];
      for (final p in places) {
        final size = t.getSize(socketIn(area(p))).width;
        expect(
          centres[p],
          offsetMoreOrLessEquals(
            markerCentre(map, p, size: size, ring: ring),
            epsilon: .5,
          ),
          reason: 'the marker of $p sits at its map point, inside the map',
        );
        // A map point far from the edges stays exactly where it is.
        if (map.deflate(size / 2 + ring).contains(pointOn(map, p))) {
          far.add(p);
          expect(
            centres[p],
            offsetMoreOrLessEquals(pointOn(map, p), epsilon: .5),
            reason: 'the marker of $p sits on its map point',
          );
        }
      }
      expect(far, contains('camp'));
      expect(
        far,
        isNot(contains('smugglers_cove')),
        reason: 'the map point of the cove lies near the edge at 360 dp',
      );
      final (painter, box) = painterIn(t, _world);
      expect(
        [
          for (final (a, b, _) in painter.paths)
            road(
              placeAt(centres, a + box.topLeft),
              placeAt(centres, b + box.topLeft),
            ),
        ],
        unorderedEquals([for (final r in game.data.routes) road(r.from, r.to)]),
        reason: 'each road runs from marker to marker',
      );
      // A river crosses the map: no road holds it.
      final roads = [
        for (final (a, b, _) in painter.paths) Rect.fromPoints(a, b).inflate(2),
      ];
      for (final c in paintCalls(painter, box.size)) {
        final drawn = c.memberName == #drawPath
            ? (c.positionalArguments[0] as Path).getBounds()
            : c.memberName == #drawLine
            ? Rect.fromPoints(
                c.positionalArguments[0] as Offset,
                c.positionalArguments[1] as Offset,
              )
            : null;
        if (drawn == null) continue;
        expect(
          roads.any(
            (r) =>
                r.contains(drawn.topLeft) &&
                r.contains(drawn.bottomRight - const Offset(.01, .01)),
          ),
          isTrue,
          reason: 'MapPainter draws $drawn, which lies along no road',
        );
      }
      // The map image is a picture, not a thing: it shows without an image
      // index too.
      await t.pumpWidget(const SizedBox());
      await pumpGame(t);
      await openTab(t, 'world');
      expect(mapImage(_world), findsOneWidget, reason: 'with no image index');
    });

    testWidgets('at 360 dp, for each of the 12 places as the current place, '
        'each marker and the ring lie inside the map, with Mirror Lake and '
        'Smugglers\' Cove on it, and no marker moves when its place becomes '
        'current', (t) async {
      final centres = <String, Offset>{};
      for (final here in places) {
        await pumpWorld(t, here);
        final what = 'at $here';
        final map = mapIn(t, _world);
        for (final p in ['mirror_lake', 'smugglers_cove']) {
          expect(area(p), findsOneWidget, reason: '$what: $p is on the map');
        }
        for (final (thing, rect) in [
          for (final p in places)
            ('the marker of $p', t.getRect(socketIn(area(p)))),
          ('the ring', t.getRect(keyIn(_world, 'place-ring'))),
        ]) {
          expect(
            _inside(rect, map),
            isTrue,
            reason: '$what: $thing $rect reaches past the map $map',
          );
        }
        for (final p in places) {
          final centre = t.getCenter(socketIn(area(p)));
          expect(
            centre,
            offsetMoreOrLessEquals(centres[p] ??= centre, epsilon: .5),
            reason: '$what: the marker of $p moves with the current place',
          );
        }
      }
    });

    testWidgets('for each of the 12 places as the current place, one teal ring '
        'sits flush around its marker, and no other mark shows the current '
        'place', (t) async {
      expect(places, hasLength(12));
      final asHere = <String, List<String>>{};
      final asOther = <String, List<String>>{};
      List<String>? rest;
      for (final here in places) {
        await pumpWorld(t, here);
        final what = 'at $here';
        expectPlaceRing(t, _world, socketIn(area(here)), what);
        final ring = subtree(keyIn(_world, 'place-ring'));
        final areas = <Element>{};
        for (final p in places) {
          final own = subtree(area(p));
          areas.addAll(own);
          final look = looksOf(t, own, ring);
          if (p == here) {
            asHere[p] = look;
          } else {
            expect(
              look,
              asOther[p] ??= look,
              reason: '$what: $p looks other than with the player elsewhere',
            );
          }
        }
        // Outside the places: the same for each current place, with no icon
        // and no image but the map image.
        final outside = [
          for (final e in withRoot(t.element(_world)))
            if (!areas.contains(e) && !ring.contains(e)) e,
        ];
        final look = looksOf(t, outside, const {});
        expect(
          look,
          rest ??= look,
          reason: '$what: the map changes with the current place',
        );
        for (final e in outside) {
          final w = e.widget;
          expect(w, isNot(isA<Icon>()), reason: '$what: an icon on the map');
          if (w is Image) {
            expect(assetName(w.image), assetOf('pictures/world_map'));
          }
        }
      }
      for (final p in places) {
        expect(
          asHere[p],
          asOther[p],
          reason: 'at $p, its place shows a mark other than the ring',
        );
      }
    });

    testWidgets('at 360 dp, for each of the 12 places as the current place, '
        'no two names, step plates, markers or the ring overlap, each name '
        'lies inside the map next to its marker, and each plate lies on its '
        'road', (t) async {
      for (final here in places) {
        await pumpWorld(t, here);
        final (painter, box) = painterIn(t, _world);
        expectPlaced(
          map: mapIn(t, _world),
          markers: {
            for (final p in places)
              p: p == here
                  ? t.getRect(keyIn(_world, 'place-ring'))
                  : t.getRect(socketIn(area(p))),
          },
          names: {
            for (final l in game.data.locations.values)
              l.id: nameBox(t, area(l.id), l.name),
          },
          plates: platesOf(painter, box),
          what: 'at $here',
        );
      }
    });

    test('placeMapLabels on the map at 360 dp, for each current place: each '
        'name and plate gets a rect of its size, by the rule of the map '
        'labels', () {
      for (final here in places) {
        final (:names, :plates) = realLabels(here);
        final placed = placeMapLabels(
          map: _phone,
          names: names,
          plates: plates,
        );
        final what = 'at $here';
        expect(placed.names.keys.toSet(), places.toSet(), reason: what);
        for (final n in names) {
          final size = placed.names[n.place]!.size;
          expect(
            n.sizes.any((s) => _sameSize(s, size)),
            isTrue,
            reason:
                '$what: the name of ${n.place} is $size, not one of '
                '${n.sizes}',
          );
        }
        expect(placed.plates, hasLength(plates.length), reason: what);
        for (final (i, plate) in placed.plates.indexed) {
          expect(_sameSize(plate.size, plates[i].size), isTrue, reason: what);
        }
        expectPlaced(
          map: Offset.zero & _phone,
          markers: {for (final n in names) n.place: n.marker},
          names: placed.names,
          plates: [
            for (final (i, plate) in placed.plates.indexed)
              (plate, plates[i].from, plates[i].to),
          ],
          what: what,
        );
      }
    });

    test('placeMapLabels gives a name its next size when the first does not '
        'fit in the map, and the same input gives the same rects', () {
      const map = Size(120, 200);
      final names = [
        MapName(
          place: 'x',
          marker: Rect.fromCenter(
            center: const Offset(60, 100),
            width: 40,
            height: 40,
          ),
          sizes: const [Size(160, 18), Size(90, 36)],
        ),
      ];
      final placed = placeMapLabels(map: map, names: names, plates: const []);
      final size = placed.names['x']!.size;
      expect(_sameSize(size, const Size(90, 36)), isTrue, reason: '$size');
      final real = realLabels('camp');
      final once = placeMapLabels(
        map: _phone,
        names: real.names,
        plates: real.plates,
      );
      final again = placeMapLabels(
        map: _phone,
        names: real.names,
        plates: real.plates,
      );
      expect(again.names, once.names);
      expect(again.plates, once.plates);
    });
  });
}

void criterion25() {
  StepReport report(List<GameEvent> events) => StepReport(
    state: GameState(location: 'camp', rngState: 1),
    walked: 10,
    activitySteps: 10,
    boostUsed: 0,
    banked: 0,
    lost: 0,
    events: events,
  );

  group('spec 0014 criterion 25: a report keeps its route, and shows its '
      'route map', () {
    test('a report lists the place of each arrival, in order, with no start '
        'place', () {
      final summary = AwaySummary.fromReports([
        report(const [Arrived('goblin_woods'), Arrived('copper_hills')]),
        report(const [Arrived('mirror_lake')]),
      ]);
      expect(summary.route, ['goblin_woods', 'copper_hills', 'mirror_lake']);
      expect(AwaySummary.fromReports([report(const [])]).route, isEmpty);
    });

    test('two merged reports join their routes; a place where one route ends '
        'and the next starts shows once', () {
      AwaySummary on(List<String> route) =>
          AwaySummary(walked: 10, route: route);
      for (final (first, second, joined) in [
        (
          ['camp', 'goblin_woods'],
          ['goblin_woods', 'copper_hills'],
          ['camp', 'goblin_woods', 'copper_hills'],
        ),
        (['camp', 'goblin_woods'], ['goblin_woods'], ['camp', 'goblin_woods']),
        (['camp'], ['camp', 'mirror_lake'], ['camp', 'mirror_lake']),
        (
          ['camp', 'goblin_woods', 'camp'],
          ['camp', 'mirror_lake'],
          ['camp', 'goblin_woods', 'camp', 'mirror_lake'],
        ),
        (
          ['camp', 'goblin_woods'],
          ['copper_hills', 'mirror_lake'],
          ['camp', 'goblin_woods', 'copper_hills', 'mirror_lake'],
        ),
        (<String>[], ['camp', 'goblin_woods'], ['camp', 'goblin_woods']),
        (['camp', 'goblin_woods'], <String>[], ['camp', 'goblin_woods']),
      ]) {
        expect(
          (on(first) + on(second)).route,
          joined,
          reason: '$first + $second',
        );
      }
    });

    test('a route alone does not make a report eventful', () {
      const quiet = AwaySummary(
        walked: 300,
        banked: 300,
        route: ['camp', 'goblin_woods'],
      );
      expect(quiet.isEventful, isFalse);
      expect(
        (quiet + const AwaySummary(walked: 10, route: ['goblin_woods', 'camp']))
            .isEventful,
        isFalse,
      );
    });

    test('a walk over two days and two syncs keeps one route in its report, '
        'from the place where the player was', () async {
      final (c, source) = await startController();
      await walkTwoDays(c, source);
      expect(c.journal.single.summary.route, [
        'camp',
        'goblin_woods',
        'copper_hills',
      ], reason: 'one sync over two days');
      await syncLateSteps(c, source);
      expect(c.journal, hasLength(1), reason: 'the late steps join the report');
      expect(c.journal.single.summary.walked, 800);
      expect(c.journal.single.summary.route, _route);
      expect(c.awaySummary!.route, _route);
      expect(c.state.location, 'mirror_lake');
    });

    test('a walk with no arrival keeps a route of one place, and a test walk '
        'starts its route where the player was', () async {
      final (c, source) = await startController(location: 'goblin_woods');
      await c.startActivity(const Activity.fight('goblin'));
      c.pause();
      source.walk(DateTime(2026, 10, 18, 10), 300);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      expect(c.journal.single.summary.route, ['goblin_woods']);
      await c.startActivity(const Activity.travel('camp'));
      await c.testWalk(200);
      expect(c.journal.first.testWalk, isTrue);
      expect(c.journal.first.summary.route, ['goblin_woods', 'camp']);
    });

    double y(String place, double width) =>
        game.data.locations[place]!.map!.y * width * game.data.mapAspect;

    test(
      'routeStrip: the image fills the width, and the strip runs from 48 '
      'dp above the highest place of the route to 48 dp below the lowest',
      () {
        for (final width in [328.0, 360.0]) {
          // Old Graveyard, in the middle of the route, is the highest place.
          final route = ['goblin_woods', 'old_graveyard', 'goblin_woods'];
          final strip = routeStrip(game.data, route, width);
          expect((strip.left, strip.right), (0.0, width));
          expect(
            strip.top,
            moreOrLessEquals(y('old_graveyard', width) - 48, epsilon: .01),
          );
          expect(
            strip.bottom,
            moreOrLessEquals(y('goblin_woods', width) + 48, epsilon: .01),
          );
          expect(strip.height, greaterThan(120), reason: 'no minimum here');
        }
      },
    );

    test('routeStrip: a strip shorter than 120 dp grows to 120 dp, and still '
        'holds 48 dp above and below the places', () {
      for (final width in [328.0, 360.0]) {
        final top = y('grey_moor', width) - 48;
        final bottom = y('iron_ridge', width) + 48;
        expect(bottom - top, lessThan(120), reason: 'too short at $width');
        final strip = routeStrip(game.data, ['grey_moor', 'iron_ridge'], width);
        expect(
          strip.height,
          moreOrLessEquals(120, epsilon: .01),
          reason: '$width',
        );
        expect(strip.top, lessThanOrEqualTo(top + 1e-6), reason: '$width');
        expect(strip.bottom, greaterThanOrEqualTo(bottom - 1e-6));
        expect(strip.top, greaterThanOrEqualTo(0));
        expect(strip.bottom, lessThanOrEqualTo(width * game.data.mapAspect));
      }
    });

    test('routeStrip: the strip never runs past the top or the bottom of the '
        'map image', () {
      for (final width in [328.0, 360.0]) {
        final height = width * game.data.mapAspect;
        // Dragon's Peak lies less than 48 dp below the top of the image.
        final top = routeStrip(game.data, [
          'mountain_pass',
          'dragons_peak',
        ], width);
        expect(top.top, moreOrLessEquals(0, epsilon: .01), reason: '$width');
        expect(
          top.bottom,
          moreOrLessEquals(y('mountain_pass', width) + 48, epsilon: .01),
        );
        // At the bottom the strip is too short, so it grows upwards.
        final bottom = routeStrip(game.data, ['camp', 'smugglers_cove'], width);
        expect(
          bottom.bottom,
          moreOrLessEquals(height, epsilon: .01),
          reason: '$width',
        );
        expect(
          bottom.height,
          moreOrLessEquals(120, epsilon: .01),
          reason: '$width',
        );
        final all = routeStrip(game.data, [
          'dragons_peak',
          'mountain_pass',
          'camp',
        ], width);
        expect(all.top, moreOrLessEquals(0, epsilon: .01), reason: '$width');
        expect(
          all.bottom,
          moreOrLessEquals(height, epsilon: .01),
          reason: '$width',
        );
      }
    });

    testWidgets('with two or more places, the away screen and the journal '
        'entry show the route map between the banners and the lines, with '
        'the time first; it shows the roads walked, the places passed and '
        'the ring on the last place', (t) async {
      final c = await pumpRoute(t);
      expect(c.awaySummary!.route, _route);
      expectReportWithRoute(
        t,
        reportCard(find.byType(AwayScreen), 'Today 09:00'),
        'Today 09:00',
        800,
        _route,
        'the away screen',
      );
      await t.tap(find.byKey(const ValueKey('away-continue')));
      await t.pumpAndSettle();
      await openJournal(t);
      expectReportWithRoute(
        t,
        reportCard(find.byType(JournalScreen), 'Today 09:00'),
        'Today 09:00',
        800,
        _route,
        'the journal entry',
      );
    });

    testWidgets('a report with one place shows no route map, on the away '
        'screen and in the journal', (t) async {
      final (c, source) = await pumpGame(
        t,
        location: 'goblin_woods',
        images: diskImages,
      );
      await c.startActivity(const Activity.fight('goblin'));
      c.pause();
      source.walk(DateTime(2026, 10, 18, 10), 300);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      if (c.levelCards.isNotEmpty) c.dismissLevelCards();
      await t.pumpAndSettle();
      expect(c.journal.single.summary.route, ['goblin_woods']);
      expect(find.byType(AwayScreen), findsOneWidget);
      expect(_routeMap, findsNothing, reason: 'the away screen');
      await t.tap(find.byKey(const ValueKey('away-continue')));
      await t.pumpAndSettle();
      await openJournal(t);
      expect(find.textContaining('You walked 300 steps.'), findsOneWidget);
      expect(_routeMap, findsNothing, reason: 'the journal');
    });
  });
}

void criterion26() {
  final fixtures =
      Directory('test/fixtures/saves')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final entry = JournalEntry(
    started: DateTime(2026, 10, 19, 9),
    summary: const AwaySummary(walked: 800, route: _route),
  );

  group('spec 0014 criterion 26: old entries load with no route, the save '
      'versions stay at 10 and 3, and each fixture loads', () {
    test('GameState.schemaVersion is 10 and SaveData.version is 3', () {
      expect(GameState.schemaVersion, 10);
      expect(SaveData.version, 3);
    });

    test('a journal entry with a route comes back from JSON with its route; '
        'an entry without "route" loads with an empty route', () {
      final json = entry.toJson();
      expect((json['summary']! as Map<String, Object?>)['route'], _route);
      final back = JournalEntry.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, Object?>,
      );
      expect(back.summary.route, _route);
      expect(back.toJson(), json);
      (json['summary']! as Map<String, Object?>).remove('route');
      expect(JournalEntry.fromJson(json).summary.route, isEmpty);
    });

    test('there are fixtures', () => expect(fixtures, isNotEmpty));

    for (final f in fixtures) {
      final name = f.uri.pathSegments.last;
      final text = f.readAsStringSync();

      test('$name loads, and its journal entries have no route; with an entry '
          'with a route, the save keeps the route at versions 10 and 3', () {
        final save = SaveData.fromJson(
          jsonDecode(text) as Map<String, Object?>,
        );
        expect(save.journal, isNotEmpty);
        for (final e in save.journal) {
          expect(e.summary.route, isEmpty, reason: '${e.started}');
        }
        final saved = jsonDecode(
          jsonEncode(
            save
                .withGame(game.migrate(save.game))
                .copyWith(journal: [entry, ...save.journal])
                .toJson(),
          ),
        ) as Map<String, Object?>;
        expect(saved['version'], 3);
        expect((saved['game']! as Map<String, Object?>)['version'], 10);
        final back = SaveData.fromJson(saved);
        expect(back.journal.first.summary.route, _route);
        for (final e in back.journal.skip(1)) {
          expect(e.summary.route, isEmpty);
        }
      });

      testWidgets('$name shows its journal entries with no route map', (
        t,
      ) async {
        final c = await pumpSave(t, jsonDecode(text) as Map<String, Object?>);
        // An old save sets out first (spec 0012 decision 6).
        for (final key in ['origin-tavern_cook', 'set-out']) {
          await t.ensureVisible(find.byKey(ValueKey(key)));
          await t.tap(find.byKey(ValueKey(key)));
          await t.pump();
        }
        await settle(t, c);
        if (c.levelCards.isNotEmpty) c.dismissLevelCards();
        await t.pumpAndSettle();
        await openJournal(t);
        expect(c.journal, isNotEmpty);
        expect(
          find.textContaining('You walked'),
          findsNWidgets(c.journal.length),
          reason: 'each entry shows',
        );
        expect(_routeMap, findsNothing);
      });
    }
  });
}

/// The screens of M3, each with its check, as m2Screens in images_test.dart:
/// each thing on the screen shows the picture that pictureOf gives with the
/// files on disk.
final m3Screens = <(String, Future<void> Function(WidgetTester))>[
  (
    'the World map',
    (t) async {
      final c = await pumpWorld(
        t,
        'camp',
        everywhere: false,
        change: (s) {
          s.explored.add('mirror_lake');
          s.revealed.add('smugglers_cove');
        },
      );
      for (final p in game.data.locations.keys) {
        if (game.isHidden(c.state, p)) continue;
        expectShows(
          t,
          area(p),
          PlaceThing(p, fogged: game.isFogged(c.state, p)),
          'the marker of $p',
        );
      }
    },
  ),
  (
    'Achievements',
    (t) async {
      final (c, _) = await pumpGame(t, images: diskImages);
      c.state.achievements.add('first_steps');
      await openAchievements(t);
      for (final a in game.data.achievements.values) {
        expectShows(
          t,
          find.byKey(ValueKey('achievement-${a.id}')),
          AchievementThing(a.id, earned: c.state.achievements.contains(a.id)),
          a.id,
        );
      }
    },
  ),
  (
    'the route map',
    (t) async {
      await pumpRoute(t);
      for (final p in _route) {
        expectShows(
          t,
          keyIn(_routeMap, 'route-$p'),
          PlaceThing(p, fogged: false),
          '$p on the route map',
        );
      }
    },
  ),
];

void criterion11() {
  group('spec 0014 criterion 11: each thing shows its image by its key, or '
      'its placeholder (M3)', () {
    for (final (screen, check) in m3Screens) {
      testWidgets(
        '$screen shows the picture of each thing, with the PH mark on '
        'placeholders only',
        check,
      );
    }
  });
}

/// Expects each colour that [within] paints to be allowed: its boxes, texts,
/// icons and the paints of its MapPainter. The map image keeps its own
/// colours.
void expectAllowed(WidgetTester t, Finder within, String what) {
  final allowed = allowedRgb(game);
  final outside = <String>{};
  void check(Color? c, String where) {
    if (c != null && c.a > 0 && !allowed.contains(rgb(c))) {
      outside.add('${hex(rgb(c))} in $where');
    }
  }

  for (final e in withRoot(t.element(within))) {
    final w = e.widget;
    if (drawnBy(e) case final d?) {
      check(d.fill, '$d');
      check(d.gradient, '$d');
      for (final s in d.sides) {
        check(s.color, '$d');
      }
    }
    if (w is RichText) {
      for (final (text, s) in piecesOf(w)) {
        check(s.color, '"$text"');
      }
    }
    if (w is Icon) check(w.color ?? IconTheme.of(e).color, '${w.icon}');
    if (w case CustomPaint(painter: final MapPainter p)) {
      check(p.stepStyle.color, 'the step counts');
      for (final c in paintCalls(p, t.getSize(byElement(e)))) {
        for (final a in c.positionalArguments) {
          if (a is Paint) check(a.color, '${c.memberName}');
        }
      }
    }
  }
  expect(outside, isEmpty, reason: '$what paints colours outside spec 0014');
}

void criteria2to4() {
  group('spec 0014 criterion 2: the colours of §2.1 (M3)', () {
    testWidgets('the World map at 360 dp and the route map paint only allowed '
        'colours', (t) async {
      await pumpWorld(t, 'camp');
      expectAllowed(t, _world, 'the World map');
      await pumpRoute(t);
      expectAllowed(t, _routeMap, 'the route map');
    });
  });

  group('spec 0014 criterion 3: the four fonts (M3)', () {
    testWidgets('the names on the World map at 360 dp are in Cormorant '
        'Garamond, also on two lines; on the route map, names are in '
        'Cormorant Garamond and numbers in Spectral', (t) async {
      await pumpWorld(t, 'smugglers_cove');
      for (final l in game.data.locations.values) {
        for (final (_, s) in piecesOf(
          t.widget<RichText>(textIn(area(l.id), l.name)),
        )) {
          expect(s.fontFamily, cormorant, reason: l.name);
        }
      }
      await pumpRoute(t);
      final names = {for (final p in _route) game.data.locations[p]!.name};
      for (final e
          in find
              .descendant(of: _routeMap, matching: find.byType(RichText))
              .evaluate()) {
        // The glyph of an icon is no text.
        if (e.findAncestorWidgetOfExactType<Icon>() != null) continue;
        final rich = e.widget as RichText;
        final text = squash(rich.text.toPlainText());
        final family = RegExp(r'^[\d,]+$').hasMatch(text)
            ? spectral
            : names.contains(text)
            ? cormorant
            : null;
        expect(family, isNotNull, reason: '"$text" on the route map');
        for (final (_, s) in piecesOf(rich)) {
          expect(s.fontFamily, family, reason: '"$text" on the route map');
        }
      }
      final (painter, _) = painterIn(t, _routeMap);
      expect(painter.stepStyle.fontFamily, spectral);
    });
  });

  group('spec 0014 criterion 4: the 2 dp black border (M3)', () {
    testWidgets('the World map at 360 dp, Achievements with images, and the '
        'away screen and the Journal with a route map', (t) async {
      await pumpWorld(t, 'camp');
      expectBordersOnScreen(t, 'the World map at 360 dp');
      await t.pumpWidget(const SizedBox());
      await pumpGame(t, images: diskImages);
      await openAchievements(t);
      expectBordersOnScreen(t, 'Achievements with images');
      await pumpRoute(t);
      expect(_routeMap, findsOneWidget);
      expectBordersOnScreen(t, 'the away screen with a route map');
      await t.tap(find.byKey(const ValueKey('away-continue')));
      await t.pumpAndSettle();
      await openJournal(t);
      expect(_routeMap, findsOneWidget);
      expectBordersOnScreen(t, 'the Journal with a route map');
    });
  });
}
