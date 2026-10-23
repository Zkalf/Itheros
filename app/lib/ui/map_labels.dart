import 'dart:math' as math;
import 'dart:ui';

/// A name on the map, by its place: the rect of its marker and the sizes
/// that the name can take, for example on one line, then on two.
class MapName {
  const MapName({
    required this.place,
    required this.marker,
    required this.sizes,
  });

  final String place;

  /// The marker; for the current place, the ring's outer rect. A map can
  /// give each marker the room of the ring, so that no name moves when the
  /// current place changes.
  final Rect marker;
  final List<Size> sizes;
}

/// A step plate of size [size] on the road from [from] to [to], the centres
/// of the two markers of the road.
class MapPlate {
  const MapPlate({required this.from, required this.to, required this.size});

  final Offset from, to;
  final Size size;
}

/// The rects of the names and the step plates of a map of size [map] (spec
/// 0014 §2.3): each name by its place, each plate in the order of [plates].
/// - No two of the names, the plates and the markers overlap.
/// - Each name takes one of its sizes. It lies inside the map, at most 8 dp
///   from its marker.
/// - Each plate lies on its road: the road crosses it. It lies inside the
///   map.
///
/// A search tries the spots of each label in the order of their look, and
/// places the label with the fewest free spots first. If no placement
/// keeps each rule, each label takes the spot that overlaps least. The same
/// input gives the same rects.
({Map<String, Rect> names, List<Rect> plates}) placeMapLabels({
  required Size map,
  required List<MapName> names,
  required List<MapPlate> plates,
}) {
  final area = Offset.zero & map;
  final markers = [for (final n in names) n.marker];
  final spots = [
    for (final n in names) _nameSpots(n, area).toList(),
    for (final p in plates) _plateSpots(p, area).toList(),
  ];
  final free = [
    for (final s in spots)
      [
        for (final r in s)
          if (!markers.any((m) => _overlap(r, m))) r,
      ],
  ];
  final placed = _search(free) ?? _leastOverlap(spots, markers);
  return (
    names: {for (final (i, n) in names.indexed) n.place: placed[i]},
    plates: placed.sublist(names.length),
  );
}

/// The room between a name and its marker, and the most that a name may
/// lie from its marker.
const _gap = 1.0;
const _near = 8.0;

/// Each place where [name] can stand, the best look first: centred below,
/// above, right of and left of its marker; then moved along each side; then
/// the same on two lines. A spot at the edge of [area] moves inside it.
Iterable<Rect> _nameSpots(MapName name, Rect area) sync* {
  final m = name.marker;
  for (final s in name.sizes) {
    if (s.width > area.width || s.height > area.height) continue;
    // From the centre of a side to its corners, by parts of the room that
    // the name has along that side.
    for (final part in const [0, .25, -.25, .5, -.5, .75, -.75, 1.0, -1.0]) {
      final x = m.center.dx - s.width / 2 + part * (m.width + s.width) / 2;
      final y = m.center.dy - s.height / 2 + part * (m.height + s.height) / 2;
      for (final (left, top) in [
        (x, m.bottom + _gap),
        (x, m.top - _gap - s.height),
        (m.right + _gap, y),
        (m.left - _gap - s.width, y),
      ]) {
        final r = _into(Rect.fromLTWH(left, top, s.width, s.height), area);
        if (_distance(r, m) <= _near) yield r;
      }
    }
  }
}

/// Each place where [plate] can stand on its road, the best look first: at
/// the middle of the road, then a step at a time towards each end; at each
/// step on the road, then beside it with the road through the plate.
Iterable<Rect> _plateSpots(MapPlate plate, Rect area) sync* {
  final road = plate.to - plate.from;
  final s = plate.size;
  final steps = math.max(1, road.distance ~/ 6);
  for (var i = 0; i <= steps; i++) {
    final t = .5 + (i.isOdd ? 1 : -1) * ((i + 1) ~/ 2) / steps;
    if (t < 0 || t > 1) continue;
    final at = plate.from + road * t;
    for (final (dx, dy) in const [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final r = Rect.fromCenter(
        center: at + Offset(dx * s.width / 3, dy * s.height / 3),
        width: s.width,
        height: s.height,
      );
      if (_holds(area, r) && _crosses(plate.from, plate.to, r)) yield r;
    }
  }
}

/// A placement of one spot of each label in [spots] where no two overlap,
/// or null. The label with the fewest spots left goes first; each label
/// tries its spots in their order. The search stops after a fixed number of
/// tries, so that a crowded map does not hold up the screen.
List<Rect>? _search(List<List<Rect>> spots) {
  final placed = List<Rect?>.filled(spots.length, null);
  var tries = 4000;
  bool place(List<List<Rect>> left) {
    int? next;
    for (var i = 0; i < left.length; i++) {
      if (placed[i] == null &&
          (next == null || left[i].length < left[next].length)) {
        next = i;
      }
    }
    if (next == null) return true;
    for (final spot in left[next]) {
      if (--tries < 0) return false;
      placed[next] = spot;
      final rest = [
        for (var i = 0; i < left.length; i++)
          placed[i] != null
              ? left[i]
              : [
                  for (final r in left[i])
                    if (!_overlap(r, spot)) r,
                ],
      ];
      if (rest.every((s) => s.isNotEmpty) && place(rest)) return true;
      placed[next] = null;
    }
    return false;
  }

  return place(spots) ? [for (final r in placed) r!] : null;
}

/// For a map where no placement keeps each rule, for example on a narrow
/// phone: each label in turn takes the spot that overlaps the markers and
/// the labels before it least. Then each label moves to the spot that
/// overlaps all others least, for a few rounds.
List<Rect> _leastOverlap(List<List<Rect>> spots, List<Rect> markers) {
  double cost(Rect r, Iterable<Rect> others) => others.fold(0, (sum, o) {
    final both = r.intersect(o);
    return both.width > 0 && both.height > 0
        ? sum + both.width * both.height
        : sum;
  });
  Rect best(List<Rect> s, Iterable<Rect> others, Rect start) =>
      s.fold(start, (a, b) => cost(b, others) < cost(a, others) ? b : a);

  final placed = <Rect>[];
  for (final s in spots) {
    // A label without a spot is too big for the map: it takes no room.
    placed.add(
      s.isEmpty ? Rect.zero : best(s, [...markers, ...placed], s.first),
    );
  }
  for (var round = 0; round < 3; round++) {
    for (final (i, s) in spots.indexed) {
      final others = [
        ...markers,
        for (final (j, r) in placed.indexed)
          if (j != i) r,
      ];
      placed[i] = best(s, others, placed[i]);
    }
  }
  return placed;
}

/// Whether [a] and [b] share more than an edge.
bool _overlap(Rect a, Rect b) {
  final both = a.intersect(b);
  return both.width > .01 && both.height > .01;
}

bool _holds(Rect outer, Rect r) =>
    r.left >= outer.left - .01 &&
    r.top >= outer.top - .01 &&
    r.right <= outer.right + .01 &&
    r.bottom <= outer.bottom + .01;

/// [r] moved inside [area].
Rect _into(Rect r, Rect area) => r.translate(
  r.left < area.left ? area.left - r.left : math.min(0, area.right - r.right),
  r.top < area.top ? area.top - r.top : math.min(0, area.bottom - r.bottom),
);

/// The shortest distance between [a] and [b]; 0 when they touch.
double _distance(Rect a, Rect b) {
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
