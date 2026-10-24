import 'dart:math' as math;
import 'dart:ui' show PathMetric;

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
class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.width,
    required this.places,
    required this.roads,
    required this.here,
    this.strip,
    this.marker = 40,
  });

  final double width;
  final List<MapSpot> places;
  final List<(String, String, String?)> roads;
  final String here;
  final Rect? strip;

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

  static const _image = Picture('pictures/world_map');

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

    return SizedBox.fromSize(
      size: shown.size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: -shown.top,
            width: whole.width,
            height: whole.height,
            child: Image(
              image: AssetImage(_image.asset!),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
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
  final p = data.locations[place]?.map ?? const MapPoint(.5, .5);
  return Offset(
    (p.x * size.width).clamp(reach, size.width - reach),
    (p.y * size.height).clamp(reach, size.height - reach),
  );
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
