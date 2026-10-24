import 'dart:math' as math;
import 'dart:ui' show ImageFilter, PathMetric;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'labels.dart';
import 'map_labels.dart';
import 'socket.dart';
import 'theme.dart';

/// The world drawn as places joined by paths; tap a place to act there
/// (spec 0006 §2.2, spec 0008 §3.3). Areas away from explored ones are fog.
/// The map image fills the width (spec 0014 §4.2).
class WorldTab extends StatelessWidget {
  const WorldTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);

    return RefreshIndicator(
      onRefresh: c.syncNow,
      child: LayoutBuilder(
        builder: (context, box) => ListView(
          padding: EdgeInsets.zero,
          children: [
            fitMap(
              box.maxWidth,
              (width) => MapView(
                width: width,
                places: [
                  for (final area in game.data.locations.keys)
                    if (!game.isHidden(s, area))
                      MapSpot(
                        area,
                        key: ValueKey('area-$area'),
                        name: game.isFogged(s, area)
                            ? '???'
                            : labels.location(area),
                        fogged: game.isFogged(s, area),
                        onTap: () => _open(context, c, area),
                      ),
                ],
                roads: [
                  // A hidden area's roads aren't drawn either (spec 0011
                  // §6.2).
                  for (final r in game.data.routes)
                    if (!game.isHidden(s, r.from) && !game.isHidden(s, r.to))
                      (
                        r.from,
                        r.to,
                        game.isFogged(s, r.from) || game.isFogged(s, r.to)
                            ? null
                            : fmt(r.steps),
                      ),
                ],
                here: s.location,
                fog: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tap a place to see what lives there.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _open(BuildContext context, GameController c, String area) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AreaSheet(controller: c, area: area, host: context),
    );
  }
}

/// A place on a [MapView]: its id, the name that it shows, whether it is in
/// the fog, and what a tap on it does. [key] goes on the widget that holds
/// its marker and its name.
class MapSpot {
  const MapSpot(
    this.id, {
    required this.key,
    required this.name,
    this.fogged = false,
    this.onTap,
  });

  final String id;
  final Key key;
  final String name;
  final bool fogged;
  final VoidCallback? onTap;
}

/// The map image, or the part [strip] of it, with its marks (spec 0014
/// §2.3): the roads with their step plates, a marker and a name for each of
/// [places], and the one teal ring on the marker of [here]. The image fills
/// [width], and [strip] runs from the top of the image.
/// - Each marker sits at the map point of its place. A marker at the edge
///   moves inward, just enough that it and a ring stay on the image.
/// - [placeMapLabels] places the names and the step plates. Nothing
///   overlaps, and each name stays inside the map.
/// - [roads] are the two places of each road and its step count; null for a
///   road into the fog.
/// - With [fog], the painted fog lies over the image and under the marks.
class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.width,
    required this.places,
    required this.roads,
    required this.here,
    this.strip,
    this.marker = 40,
    this.fog = false,
  });

  final double width;
  final List<MapSpot> places;
  final List<(String, String, String?)> roads;
  final String here;
  final Rect? strip;
  final bool fog;

  /// The size of each marker.
  final double marker;

  /// The width of the ring of the current place.
  static const _ring = 3.0;

  /// The step counts are numbers that stand alone (spec 0014 §2.2): the
  /// size of main, in the weight of small numbers in the kit.
  static const _stepStyle = TextStyle(
    fontFamily: Fonts.number,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    color: Quiet.text,
  );

  /// The room around a name and around a step count on its plate.
  static const _namePad = EdgeInsets.symmetric(horizontal: 5, vertical: 1);
  static const _countPad = 3.0;

  static final _image = Image(
    image: AssetImage(const Picture('pictures/world_map').asset!),
    fit: BoxFit.cover,
    excludeFromSemantics: true,
  );

  /// How far a marker and its ring reach from its centre.
  double get _room => marker / 2 + _ring;

  @override
  Widget build(BuildContext context) {
    final data = ControllerScope.of(context).game.data;
    final images = ImageScope.of(context);
    final whole = Size(width, width * data.mapAspect);
    final shown = strip ?? Offset.zero & whole;
    // Each name is a name (spec 0014 §2.2), at the size of main.
    final name = nameStyle(context)!.copyWith(fontSize: 14);
    TextStyle styleOf(MapSpot p) =>
        p.fogged ? name.copyWith(color: Quiet.faint) : name;

    // Each marker in the coordinates of the strip. Each marker gets the
    // room of the ring, so that no name moves when the player moves.
    final centres = {
      for (final p in places)
        p.id: placeCentre(data, p.id, whole, _room) - shown.topLeft,
    };
    // A name on one line, and on two lines if it has a space.
    final lines = {
      for (final p in places)
        p.id: [
          p.name,
          if (p.name.contains(' ')) p.name.replaceFirst(' ', '\n'),
        ],
    };
    final placed = placeMapLabels(
      map: shown.size,
      names: [
        for (final p in places)
          MapName(
            place: p.id,
            marker: Rect.fromCircle(center: centres[p.id]!, radius: _room),
            sizes: [
              for (final text in lines[p.id]!)
                _namePad.inflateSize(_measure(text, styleOf(p))),
            ],
          ),
      ],
      plates: [
        for (final (a, b, count) in roads)
          if (count != null)
            MapPlate(
              from: centres[a]!,
              to: centres[b]!,
              size:
                  _measure(count, _stepStyle) + const Offset(2, 2) * _countPad,
            ),
      ],
    );

    // The image and the fog cover the whole map. The strip shows a part.
    Widget onImage(Widget child) => Positioned(
      left: 0,
      top: -shown.top,
      width: whole.width,
      height: whole.height,
      child: child,
    );
    return SizedBox.fromSize(
      size: shown.size,
      child: Stack(
        children: [
          onImage(_image),
          if (fog)
            onImage(
              _Fog(
                key: const ValueKey('map-fog'),
                painter: FogPainter(
                  holes: [
                    for (final p in places)
                      if (!p.fogged) _mapPoint(data, p.id, whole),
                  ],
                  clouds: [
                    for (final p in places)
                      if (p.fogged) _mapPoint(data, p.id, whole),
                  ],
                  scale: width / 360,
                ),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(
              painter: MapPainter(
                paths: [
                  for (final (a, b, count) in roads)
                    (centres[a]!, centres[b]!, count),
                ],
                plates: placed.plates,
                stepStyle: _stepStyle,
              ),
            ),
          ),
          for (final p in places)
            _place(
              p,
              centre: centres[p.id]!,
              name: placed.names[p.id]!,
              // The text of the size that the placement gave the name.
              text: lines[p.id]![placed.sizes[p.id]!],
              style: styleOf(p),
              picture: images.pictureOf(
                data,
                PlaceThing(p.id, fogged: p.fogged),
              ),
            ),
        ],
      ),
    );
  }

  /// The widget of [spot]: a box centred on its marker that holds the
  /// marker and the name at [name]. A tap on the middle of the box lands on
  /// the marker, and the empty part of the box lets taps through.
  Widget _place(
    MapSpot spot, {
    required Offset centre,
    required Rect name,
    required String text,
    required TextStyle style,
    required Picture picture,
  }) {
    double reach(List<double> ends, double middle) =>
        ends.map((e) => (e - middle).abs()).reduce(math.max);
    final box = Rect.fromCenter(
      center: centre,
      width: 2 * reach([name.left, name.right, centre.dx + _room], centre.dx),
      height: 2 * reach([name.top, name.bottom, centre.dy + _room], centre.dy),
    );
    final face = Rect.fromCircle(
      center: centre - box.topLeft,
      radius: marker / 2,
    );
    return Positioned.fromRect(
      rect: box,
      child: GestureDetector(
        key: spot.key,
        behavior: HitTestBehavior.deferToChild,
        onTap: spot.onTap,
        child: Stack(
          children: [
            // Under the marker, so that its glow shows only around it.
            if (spot.id == here)
              Positioned.fromRect(
                rect: face.inflate(_ring),
                child: const _Ring(),
              ),
            Positioned.fromRect(
              rect: face,
              child: PictureSocket(picture: picture, size: marker, round: true),
            ),
            Positioned.fromRect(
              rect: name.shift(-box.topLeft),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Quiet.caseBlack.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Quiet.teal.withValues(alpha: .4)),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: style,
                    textAlign: TextAlign.center,
                    softWrap: false,
                    // The sizes of the placement hold at each text size of
                    // the phone.
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The size of [text] in [style], on the lines of its "\n".
  static Size _measure(String text, TextStyle style) {
    final p = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final size = p.size;
    p.dispose();
    return size;
  }
}

/// The centre of the marker of [place] on the map image of [size]: its map
/// point, moved inward on each axis just enough that a marker and its ring,
/// [reach] from the centre, lie inside the image (plan 0017, M3).
Offset placeCentre(GameData data, String place, Size size, double reach) {
  final p = _mapPoint(data, place, size);
  return Offset(
    p.dx.clamp(reach, size.width - reach),
    p.dy.clamp(reach, size.height - reach),
  );
}

/// The map point of [place] on the map image of [size].
Offset _mapPoint(GameData data, String place, Size size) {
  final p = data.locations[place]?.map ?? const MapPoint(.5, .5);
  return Offset(p.x * size.width, p.y * size.height);
}

/// The map that [build] makes at a width, for a screen [width] wide. Below
/// 360 dp a map keeps the layout of 360 dp and is drawn smaller, so that
/// nothing on it overlaps there either (spec 0014 §2.3).
Widget fitMap(double width, Widget Function(double width) build) =>
    width < _least ? FittedBox(child: build(_least)) : build(width);

const _least = 360.0;

/// The one teal ring of the current place, flush around its marker (spec
/// 0014 §2.3), with a black edge outside it and a soft teal glow.
class _Ring extends StatelessWidget {
  const _Ring();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('place-ring'),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Quiet.teal, width: MapView._ring),
      boxShadow: [
        BoxShadow(color: Quiet.teal.withValues(alpha: .45), blurRadius: 8),
        const BoxShadow(color: Quiet.black, spreadRadius: 1),
      ],
    ),
  );
}

/// The painted fog of the World map, as the design phones 08, 10 and 15
/// show it: the map blurred and pale under a light veil, with a soft hole
/// around each place out of the fog and a cloud on each place in it. The
/// fog still shows by exploring (spec 0008 decision 5).
class _Fog extends StatelessWidget {
  const _Fog({super.key, required this.painter});

  final FogPainter painter;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    // The layer of the colour filter holds the blurred map and the veil.
    // Thus the holes of the painter clear them, and not the map under them.
    child: ColorFiltered(
      colorFilter: ColorFilter.matrix(_mist),
      child: CustomPaint(
        foregroundPainter: painter,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 2.4 * painter.scale,
            sigmaY: 2.4 * painter.scale,
            tileMode: TileMode.clamp,
          ),
          child: MapView._image,
        ),
      ),
    ),
  );
}

/// Saturation 0.45 and brightness 1.04: the paler map under the veil.
final _mist = _saturation(.45, 1.04);

List<double> _saturation(double s, double brightness) {
  // The weights of red, green and blue in the brightness of a colour.
  const w = [.213, .715, .072];
  return [
    for (var i = 0; i < 3; i++) ...[
      for (var j = 0; j < 3; j++)
        brightness * (w[j] * (1 - s) + (i == j ? s : 0)),
      0,
      0,
    ],
    ...[0, 0, 0, 1, 0],
  ];
}

/// The veil, the holes and the clouds of the painted fog, at a map of
/// [scale] × 360 dp. It paints over the blurred map of [_Fog].
/// - A hole is clear to [clear] from its centre and full fog from [full].
///   Where holes meet, each clears the fog.
/// - A cloud of the size [cloud] lies on each place in the fog.
@visibleForTesting
class FogPainter extends CustomPainter {
  FogPainter({required this.holes, required this.clouds, required this.scale});

  /// The map point of each place out of the fog.
  final List<Offset> holes;

  /// The map point of each place in the fog.
  final List<Offset> clouds;

  /// The width of the map over 360 dp.
  final double scale;

  double get clear => 62 * scale;
  double get full => 118 * scale;
  Size get cloud => const Size(176, 120) * scale;

  /// The veil from the top of the map to the bottom, and a cloud from its
  /// middle to its edge: light text colour, as the mist of the design.
  static final _veil = [
    Quiet.text.withValues(alpha: .66),
    Quiet.text.withValues(alpha: .56),
  ];
  static final _cloud = [
    Quiet.text.withValues(alpha: .95),
    Quiet.text.withValues(alpha: .64),
    Quiet.text.withValues(alpha: .13),
    Quiet.text.withValues(alpha: 0),
  ];

  /// Each colour that the fog paints. A hole clears with black.
  List<Color> get colours => [..._veil, ..._cloud, Quiet.black];

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _veil,
        ).createShader(all),
    );
    // Each hole clears the veil and the blurred map, so the map shows.
    for (final h in holes) {
      final round = Rect.fromCircle(center: h, radius: full);
      canvas.drawCircle(
        h,
        full,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = RadialGradient(
            colors: [
              Quiet.black,
              Quiet.black,
              Quiet.black.withValues(alpha: 0),
            ],
            stops: [0, clear / full, 1],
          ).createShader(round),
      );
    }
    // A cloud is a soft circle, made flat to the shape of the cloud.
    final r = cloud.width / 2;
    for (final c in clouds) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..scale(1, cloud.height / cloud.width)
        ..drawCircle(
          Offset.zero,
          r,
          Paint()
            ..shader = RadialGradient(
              colors: _cloud,
              stops: const [0, .55, .8, 1],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(FogPainter old) =>
      !listEquals(old.holes, holes) ||
      !listEquals(old.clouds, clouds) ||
      old.scale != scale;
}

/// The roads, then the step plates: solid roads with their step count
/// between open places, dashed and unlabelled into the fog. The map image
/// has its own river (spec 0014 §4.2).
@visibleForTesting
class MapPainter extends CustomPainter {
  MapPainter({
    required this.paths,
    required this.plates,
    required this.stepStyle,
  });

  /// Each path's ends and its step count; null for a path into the fog.
  final List<(Offset, Offset, String?)> paths;

  /// The step plate of each path with a count, in the order of [paths].
  final List<Rect> plates;

  /// The style of each step count.
  final TextStyle stepStyle;

  /// Each step count, laid out once for this painter and not on each paint.
  /// The painter keeps them while it lives: a canvas that records the
  /// paint, such as the one of a test, reads its paragraphs afterwards.
  late final _counts = [
    for (final (_, _, steps) in paths)
      if (steps != null)
        TextPainter(
          text: TextSpan(text: steps, style: stepStyle),
          textDirection: TextDirection.ltr,
        )..layout(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    Paint pen(Color colour, double width) => Paint()
      ..color = colour
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // A dark edge under each road, so that it reads on the painting.
    final edge = pen(Quiet.caseBlack.withValues(alpha: .6), 4.5);
    final road = pen(Quiet.text.withValues(alpha: .9), 2.5);
    final fog = pen(Quiet.text.withValues(alpha: .8), 2);
    for (final (a, b, steps) in paths) {
      final line = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
      if (steps != null) {
        canvas
          ..drawPath(line, edge)
          ..drawPath(line, road);
        continue;
      }
      for (final PathMetric m in line.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 12) {
          canvas.drawPath(m.extractPath(d, d + 6), fog);
        }
      }
    }
    // The plates stand on the roads, each with its count in the middle.
    for (final (i, label) in _counts.indexed) {
      final plate = RRect.fromRectAndRadius(
        plates[i],
        const Radius.circular(6),
      );
      canvas
        ..drawRRect(
          plate,
          Paint()..color = Quiet.caseBlack.withValues(alpha: .88),
        )
        ..drawRRect(
          plate.deflate(.5),
          Paint()
            ..color = Quiet.text.withValues(alpha: .45)
            ..style = PaintingStyle.stroke,
        );
      label.paint(canvas, plates[i].center - label.size.center(Offset.zero));
    }
  }

  @override
  bool shouldRepaint(MapPainter old) =>
      !listEquals(old.paths, paths) ||
      !listEquals(old.plates, plates) ||
      old.stepStyle != stepStyle;
}

/// What a place holds: its monsters (with the drops found so far) and
/// gathering spots, and walking there. Fog shows only when it opens.
class _AreaSheet extends StatelessWidget {
  const _AreaSheet({
    required this.controller,
    required this.area,
    required this.host,
  });

  final GameController controller;
  final String area;

  /// The map's context: actions start from it once the sheet is closed.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final text = Theme.of(context).textTheme;
    final l = game.data.locations[area]!;

    if (game.isFogged(s, area)) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('???', style: text.titleLarge),
              const SizedBox(height: 8),
              const Text(
                "Thick fog. Walk to a neighbouring area to see what's there.",
              ),
            ],
          ),
        ),
      );
    }

    final steps = game.openLocationsByDistance(s)[area];
    final enemies = game.enemiesAt(s, area);
    final nodes = game.nodesAt(s, area);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            ListTile(
              title: Text(labels.location(area), style: text.titleLarge),
              subtitle: Text(switch (steps) {
                0 => 'You are here',
                final n? => '${fmt(n)} steps away',
                null => 'No open road leads here',
              }),
            ),
            if (l.flavour case final f?)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  f,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            for (final id in enemies)
              enemyTile(
                c,
                id,
                drops: dropsLine(game, s, labels, id),
                startFrom: host,
              ),
            for (final id in nodes) nodeTile(c, id, startFrom: host),
            if (l.crafting)
              const ListTile(
                leading: Icon(Icons.local_fire_department),
                title: Text('A forge: crafting happens here'),
              ),
            if (steps != null && steps > 0)
              ActionTile(
                controller: c,
                activity: Activity.travel(area),
                leading: const Icon(Icons.signpost),
                title: 'Travel here',
                titleIsName: false,
                subtitle: Text('${fmt(steps)} steps'),
                startFrom: host,
              ),
          ],
        ),
      ),
    );
  }
}
