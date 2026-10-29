import 'dart:async';

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter, PathMetric;

import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'labels.dart';
import 'map_labels.dart';
import 'socket.dart';
import 'text_size.dart';
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
              (width) => _snap(
                MapView(
                  data: game.data,
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
                  // Room for each place and road, also hidden and in the
                  // fog, so that no name moves (spec 0014 amendment 2).
                  roomFor: (
                    names: {
                      for (final area in game.data.locations.keys)
                        area: labels.location(area),
                    },
                    roads: [
                      for (final r in game.data.routes)
                        (r.from, r.to, fmt(r.steps)),
                    ],
                  ),
                ),
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

  static Widget _snap(Widget map) => _CoveredSnapshot(child: map);

  static void _open(BuildContext context, GameController c, String area) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _AreaSheet(controller: c, area: area, host: context),
      ),
    );
  }
}

/// [child] drawn once into an image while another route (a sheet) covers its
/// page, and drawn live otherwise (#136).
///
/// The renderer (Impeller) keeps no image of a layer. While a sheet slides
/// over the World map, it draws the whole map again on each frame: the
/// picture, the fog, the roads, the markers and the names. On the Fairphone,
/// that missed 1-3 frames each time a sheet opened or closed. The image of the
/// map costs one draw. The map cannot change under a sheet, and it is live
/// again once the sheet has closed.
class _CoveredSnapshot extends StatefulWidget {
  const _CoveredSnapshot({required this.child});

  final Widget child;

  @override
  State<_CoveredSnapshot> createState() => _CoveredSnapshotState();
}

class _CoveredSnapshotState extends State<_CoveredSnapshot> {
  final _controller = SnapshotController();
  Timer? _live;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final covered = !(ModalRoute.of(context)?.isCurrent ?? true);
    _live?.cancel();
    if (covered) {
      _controller.allowSnapshotting = true;
    } else if (_controller.allowSnapshotting) {
      // The page is current as soon as a sheet starts to close; its close
      // animation (200 ms) still runs over the map.
      _live = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _controller.allowSnapshotting = false;
      });
    }
  }

  @override
  void dispose() {
    _live?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SnapshotWidget(controller: _controller, child: widget.child);
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
/// - [roomFor] gives the places and roads that the labels keep room for, so
///   that no name moves when a place leaves the fog or shows on the map
///   (spec 0014 amendment 2). Null keeps room for [places] and [roads].
class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.data,
    required this.width,
    required this.places,
    required this.roads,
    required this.here,
    this.strip,
    this.marker = 40,
    this.fog = false,
    this.roomFor,
  });

  final GameData data;
  final double width;
  final List<MapSpot> places;
  final List<(String, String, String?)> roads;
  final String here;
  final Rect? strip;
  final bool fog;
  final MapRoom? roomFor;

  /// The size of each marker.
  final double marker;

  /// The width of the ring of the current place.
  static const _ring = 3.0;

  /// The size of the names (spec 0014 amendment 2).
  static const _nameSize = 13.0;

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

  /// The size of the whole map image, and the part of it that shows.
  Size get _whole => Size(width, width * data.mapAspect);
  Rect get _shown => strip ?? Offset.zero & _whole;

  /// The step counts of the roads, in their order.
  List<String> get _counts => [for (final (_, _, count) in roads) ?count];

  /// Whether [other] places its labels as this map does.
  bool _placesAs(MapView other) =>
      identical(data, other.data) &&
      width == other.width &&
      strip == other.strip &&
      marker == other.marker &&
      listEquals(roads, other.roads) &&
      mapEquals(roomFor?.names, other.roomFor?.names) &&
      listEquals(roomFor?.roads, other.roomFor?.roads) &&
      listEquals(
        [for (final p in places) (p.id, p.name, p.fogged)],
        [for (final p in other.places) (p.id, p.name, p.fogged)],
      );

  @override
  State<MapView> createState() => _MapViewState();
}

/// The places and roads that the labels of a map keep room for: the name of
/// each place by its id, and the two places and the step count of each
/// road. It holds each place and each road that the map draws, and can hold
/// more.
typedef MapRoom = ({
  Map<String, String> names,
  List<(String, String, String)> roads,
});

/// The labels of a map as it draws them: the rect and the text of each
/// name by its place, and the step plate of each road with a count, in the
/// order of the roads.
typedef _Labels = ({
  Map<String, Rect> names,
  Map<String, String> texts,
  List<Rect> plates,
});

/// The state of a map keeps what costs time to make: the laid-out step
/// counts and the placement of the labels. A rebuild with the same roads,
/// places and size keeps them.
class _MapViewState extends State<MapView> {
  late List<TextPainter> _counts = _layOut(widget._counts);
  _Labels? _labels;

  /// The centre of each marker in the coordinates of the strip. Each marker
  /// gets the room of the ring, so that no name moves when the player
  /// moves.
  late Map<String, Offset> _centres;

  static List<TextPainter> _layOut(List<String> counts) => [
    for (final count in counts)
      TextPainter(
        text: TextSpan(text: count, style: MapView._stepStyle),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The style of the names, the bold text or the images changed.
    _labels = null;
  }

  @override
  void didUpdateWidget(MapView old) {
    super.didUpdateWidget(old);
    if (!listEquals(old._counts, widget._counts)) {
      _dispose(_counts);
      _counts = _layOut(widget._counts);
    }
    if (!widget._placesAs(old)) _labels = null;
  }

  @override
  void dispose() {
    _dispose(_counts);
    super.dispose();
  }

  static void _dispose(List<TextPainter> painters) {
    for (final p in painters) {
      p.dispose();
    }
  }

  /// A name on one line, and on two lines if it has a space.
  static List<String> _lines(String name) => [
    name,
    if (name.contains(' ')) name.replaceFirst(' ', '\n'),
  ];

  /// Each name is a name (spec 0014 §2.2), at [MapView._nameSize].
  TextStyle _styleOf(MapSpot p) {
    final name = nameStyle(context)!.copyWith(fontSize: MapView._nameSize);
    return p.fogged ? name.copyWith(color: Quiet.faint) : name;
  }

  /// The size of [text] in a label. The labels keep their size at each
  /// text size of the phone, so that the placement holds.
  Size _sizeOf(String text, TextStyle style) =>
      textSizeOf(context, text, style, textScaler: TextScaler.noScaling);

  _Labels _place() {
    final w = widget;
    final room =
        w.roomFor ??
        (
          names: {for (final p in w.places) p.id: p.name},
          roads: [
            for (final (a, b, count) in w.roads)
              if (count != null) (a, b, count),
          ],
        );
    _centres = {
      for (final id in room.names.keys)
        id: placeCentre(w.data, id, w._whole, w._room) - w._shown.topLeft,
    };
    final name = nameStyle(context)!.copyWith(fontSize: MapView._nameSize);
    final step = TextPainter(textDirection: TextDirection.ltr);
    final placed = placeMapLabels(
      map: w._shown.size,
      names: [
        for (final MapEntry(key: id, value: text) in room.names.entries)
          MapName(
            place: id,
            marker: Rect.fromCircle(center: _centres[id]!, radius: w._room),
            sizes: [
              for (final line in _lines(text))
                MapView._namePad.inflateSize(_sizeOf(line, name)),
            ],
          ),
      ],
      plates: [
        for (final (a, b, count) in room.roads)
          MapPlate(
            from: _centres[a]!,
            to: _centres[b]!,
            size:
                (step
                      ..text = TextSpan(text: count, style: MapView._stepStyle)
                      ..layout())
                    .size +
                const Offset(2, 2) * MapView._countPad,
          ),
      ],
    );
    step.dispose();
    final names = <String, Rect>{};
    final texts = <String, String>{};
    for (final p in w.places) {
      final rect = placed.names[p.id]!;
      if (!p.fogged) {
        names[p.id] = rect;
        texts[p.id] = _lines(p.name)[placed.sizes[p.id]!];
      } else {
        // A name in the fog is shorter than the name that it keeps room
        // for. It stands in that room, as near to its marker as it can.
        final size = MapView._namePad.inflateSize(_sizeOf(p.name, name));
        final centre = _centres[p.id]!;
        names[p.id] = Rect.fromLTWH(
          (centre.dx - size.width / 2).clamp(
            rect.left,
            math.max(rect.left, rect.right - size.width),
          ),
          (centre.dy - size.height / 2).clamp(
            rect.top,
            math.max(rect.top, rect.bottom - size.height),
          ),
          size.width,
          size.height,
        );
        texts[p.id] = p.name;
      }
    }
    return (
      names: names,
      texts: texts,
      plates: [
        for (final (a, b, count) in w.roads)
          if (count != null)
            placed.plates[room.roads.indexWhere(
              (r) => {r.$1, r.$2}.containsAll([a, b]),
            )],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final labels = _labels ??= _place();
    final whole = w._whole;
    final shown = w._shown;
    final images = ImageScope.of(context);

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
          onImage(MapView._image),
          if (w.fog)
            onImage(
              _Fog(
                key: const ValueKey('map-fog'),
                size: whole,
                painter: FogPainter(
                  holes: [
                    for (final p in w.places)
                      if (!p.fogged) _mapPoint(w.data, p.id, whole),
                  ],
                  clouds: [
                    for (final p in w.places)
                      if (p.fogged) _mapPoint(w.data, p.id, whole),
                  ],
                  scale: w.width / 360,
                ),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(
              painter: MapPainter(
                paths: [
                  for (final (a, b, count) in w.roads)
                    (_centres[a]!, _centres[b]!, count),
                ],
                plates: labels.plates,
                counts: _counts,
                stepStyle: MapView._stepStyle,
              ),
            ),
          ),
          for (final p in w.places)
            _spot(
              p,
              centre: _centres[p.id]!,
              name: labels.names[p.id]!,
              // The text of the size that the placement gave the name.
              text: labels.texts[p.id]!,
              style: _styleOf(p),
              picture: images.pictureOf(
                w.data,
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
  Widget _spot(
    MapSpot spot, {
    required Offset centre,
    required Rect name,
    required String text,
    required TextStyle style,
    required Picture picture,
  }) {
    final w = widget;
    double reach(List<double> ends, double middle) =>
        ends.map((e) => (e - middle).abs()).reduce(math.max);
    final box = Rect.fromCenter(
      center: centre,
      width: 2 * reach([name.left, name.right, centre.dx + w._room], centre.dx),
      height:
          2 * reach([name.top, name.bottom, centre.dy + w._room], centre.dy),
    );
    final face = Rect.fromCircle(
      center: centre - box.topLeft,
      radius: w.marker / 2,
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
            if (spot.id == w.here)
              Positioned.fromRect(
                rect: face.inflate(MapView._ring),
                child: const _Ring(),
              ),
            Positioned.fromRect(
              rect: face,
              child: PictureSocket(
                picture: picture,
                size: w.marker,
                round: true,
              ),
            ),
            Positioned.fromRect(
              rect: name.shift(-box.topLeft),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Dark on the painting and on the fog (the design: 92%).
                  color: Quiet.caseBlack.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Quiet.teal.withValues(alpha: .4)),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: style,
                    textAlign: TextAlign.center,
                    softWrap: false,
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
///
/// Once the map image has loaded, the fog is made into images (#121): the
/// blurred, pale map once for each size of the map, and on it the whole fog
/// each time the fog changes. Drawn live, the fog made a sheet over the map
/// open at about 20 frames a second on the phone, because the renderer draws
/// the blur and the layer of the fog again on each frame. Until the map image
/// has loaded, the fog is drawn live, so the map never shows without its fog.
class _Fog extends StatefulWidget {
  const _Fog({super.key, required this.size, required this.painter});

  /// The size of the whole map.
  final Size size;
  final FogPainter painter;

  @override
  State<_Fog> createState() => _FogState();
}

class _FogState extends State<_Fog> {
  /// The blurred, pale map at the size in pixels of the map on screen, made
  /// once. A new size replaces it.
  static final _made = <Size, ui.Image>{};

  ImageStream? _stream;
  ImageStreamListener? _listener;

  /// The whole fog, and the painter and the pixels it was made for.
  ui.Image? _whole;
  FogPainter? _wholeFor;
  Size? _wholeAt;

  /// The size of the map in whole pixels.
  Size get _pixels {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return Size(
      (widget.size.width * ratio).roundToDouble(),
      (widget.size.height * ratio).roundToDouble(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_made[_pixels] == null) _load();
  }

  @override
  void didUpdateWidget(_Fog old) {
    super.didUpdateWidget(old);
    if (old.size != widget.size && _made[_pixels] == null) _load();
  }

  @override
  void dispose() {
    _stop();
    _whole?.dispose();
    super.dispose();
  }

  void _stop() {
    if (_listener case final l?) _stream?.removeListener(l);
    _stream = null;
    _listener = null;
  }

  /// Waits for the map image, then makes the blurred, pale map. A map image
  /// that fails to load keeps the live fog.
  void _load() {
    _stop();
    final pixels = _pixels;
    final stream = MapView._image.image.resolve(
      createLocalImageConfiguration(context),
    );
    // Kept before addListener: a map image in the cache calls back at once.
    _stream = stream;
    _listener = ImageStreamListener((info, _) {
      if (_made[pixels] == null) {
        for (final old in _made.values) {
          old.dispose();
        }
        _made
          ..clear()
          ..[pixels] = _make(info.image, pixels);
      }
      info.dispose();
      _stop();
      if (mounted) setState(() {});
    }, onError: (_, _) => _stop());
    stream.addListener(_listener!);
  }

  /// [map] blurred and pale at [pixels], as the live fog draws it: covered,
  /// blurred, then the mist filter. The live blur is 2.4 dp for each 360 dp
  /// of map width, so in pixels it is 2.4 for each 360 pixels.
  static ui.Image _make(ui.Image map, Size pixels) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final all = Offset.zero & pixels;
    final sigma = 2.4 * pixels.width / 360;
    canvas.saveLayer(
      all,
      Paint()
        ..colorFilter = _mist
        ..imageFilter = ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
    );
    paintImage(canvas: canvas, rect: all, image: map, fit: BoxFit.cover);
    canvas.restore();
    return recorder.endRecording().toImageSync(
      pixels.width.round(),
      pixels.height.round(),
    );
  }

  /// The whole fog at [pixels]: [blurred] and the veil, the holes and the
  /// clouds of [painter] over it, in a layer of their own, as the live fog
  /// draws them. So the holes clear the fog, and not the map under it. The
  /// painter paints at [size] in dp, scaled to fill the whole pixels.
  static ui.Image _makeWhole(
    ui.Image blurred,
    FogPainter painter,
    Size size,
    Size pixels,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas
      ..saveLayer(Offset.zero & pixels, Paint())
      ..drawImage(blurred, Offset.zero, Paint())
      ..scale(pixels.width / size.width, pixels.height / size.height);
    painter.paint(canvas, size);
    canvas.restore();
    return recorder.endRecording().toImageSync(
      pixels.width.round(),
      pixels.height.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final painter = widget.painter;
    final pixels = _pixels;
    if (_made[pixels] case final blurred?) {
      if (_whole == null ||
          _wholeAt != pixels ||
          _wholeFor!.shouldRepaint(painter)) {
        _whole?.dispose();
        _whole = _makeWhole(blurred, painter, widget.size, pixels);
        _wholeFor = painter;
        _wholeAt = pixels;
      }
      return RepaintBoundary(
        // The image widget owns and disposes the clone it is given.
        child: FogImage(
          painter: painter,
          image: _whole!.clone(),
          size: widget.size,
        ),
      );
    }
    return RepaintBoundary(
      // A layer of its own holds the blurred map and the veil. Thus the holes
      // of the painter clear them, and not the map under them.
      child: ColorFiltered(
        colorFilter: _ownLayer,
        child: CustomPaint(
          foregroundPainter: painter,
          // Only the map turns pale; the veil and the clouds keep the text
          // colour (the design's filter acts on the map behind the veil).
          child: ColorFiltered(
            colorFilter: _mist,
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
      ),
    );
  }
}

/// The whole fog of the World map made into [image] at [size]: what [painter]
/// paints over the blurred, pale map (#121). [painter] says what it holds.
class FogImage extends StatelessWidget {
  const FogImage({
    super.key,
    required this.painter,
    required this.image,
    required this.size,
  });

  final FogPainter painter;
  final ui.Image image;
  final Size size;

  @override
  Widget build(BuildContext context) => RawImage(
    image: image,
    width: size.width,
    height: size.height,
    fit: BoxFit.fill,
  );
}

/// The filter of the layer of the fog: it changes no colour.
const _ownLayer = ColorFilter.matrix([
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// The filter of the map under the veil: a saturation of 0.45 and a
/// brightness of 1.04.
final _mist = ColorFilter.matrix(_saturation(.45, 1.04));

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
    required this.counts,
    required this.stepStyle,
  });

  /// Each path's ends and its step count; null for a path into the fog.
  final List<(Offset, Offset, String?)> paths;

  /// The step plate of each path with a count, in the order of [paths].
  final List<Rect> plates;

  /// Each step count laid out in [stepStyle], in the order of [plates]. The
  /// map keeps them, and disposes of them when they change.
  final List<TextPainter> counts;

  /// The style of each step count.
  final TextStyle stepStyle;

  @override
  void paint(Canvas canvas, Size size) {
    Paint pen(Color colour, double width) => Paint()
      ..color = colour
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // A dark edge under each road and each dash, so that it reads on the
    // painting and on the light fog. The edge of a dash is a soft shadow:
    // four faint strokes, each narrower and darker than the one under it. A
    // blur looks the same, but the renderer blurs each dash again on each
    // frame (#121).
    final edge = pen(Quiet.caseBlack.withValues(alpha: .6), 4.5);
    final road = pen(Quiet.text.withValues(alpha: .9), 2.5);
    final dashEdges = [
      for (final (width, alpha) in const [
        (8.0, .05),
        (6.5, .08),
        (5.0, .12),
        (3.5, .15),
      ])
        pen(Quiet.caseBlack.withValues(alpha: alpha), width),
    ];
    final fog = pen(Quiet.text.withValues(alpha: .9), 2.5);
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
          final dash = m.extractPath(d, d + 6);
          for (final e in dashEdges) {
            canvas.drawPath(dash, e);
          }
          canvas.drawPath(dash, fog);
        }
      }
    }
    // The plates stand on the roads, each with its count in the middle.
    for (final (i, label) in counts.indexed) {
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
      old.counts != counts ||
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
            // One heading above the monster rows (spec 0014 §4.1).
            if (enemies.isNotEmpty) MonstersHeading(data: game.data),
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
                title: 'Walk here',
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
