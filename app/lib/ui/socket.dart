import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'away_summary_card.dart' show qualityColour;
import 'images.dart';
import 'theme.dart';

/// A picture in its dark socket (spec 0014 §2.3): 72 dp in heads and
/// portraits, 48 dp in rows and the bag, 32 dp in banners. The socket is
/// [size] square; the count badge reaches outside it.
/// - [quality] is set for gear and tools: a 2 dp ring in its colour, Common
///   included, and from Uncommon up a wash of that colour from the bottom.
/// - A [count] of 2 or more shows the badge "×N" off the lower right corner.
/// - A placeholder has the PH mark on the object and the semantics label
///   "placeholder picture" (§3.2).
class PictureSocket extends StatelessWidget {
  const PictureSocket({
    super.key,
    required this.picture,
    required this.size,
    this.quality,
    this.count = 1,
    this.qualities = const [],
  });

  /// The socket of the item key [item]: gear and tools have the ring and the
  /// wash of its quality.
  PictureSocket.item(
    GameData data,
    String item, {
    super.key,
    required this.picture,
    required this.size,
    this.count = 1,
  }) : quality = switch (data.itemOf(item)) {
         ItemDef(slot: != null) ||
         ItemDef(tool: != null) => data.qualityOf(item),
         _ => null,
       },
       qualities = data.qualities;

  final Picture picture;
  final double size;
  final QualityDef? quality;
  final int count;

  /// The qualities of the data in their order. The place of [quality] among
  /// them sets the strength of the wash; without them, the socket has no
  /// wash.
  final List<QualityDef> qualities;

  @override
  Widget build(BuildContext context) {
    final q = quality;
    final radius = socketRadius(size);
    // None for the first quality, then the steps of the kit, and the last
    // step for each quality after them.
    final place = q == null ? -1 : qualities.indexOf(q);
    final wash = place < 1 ? null : _wash[math.min(place, _wash.length) - 1];
    final spot = picture.placeholder
        ? phSpots[picture.key] ?? const PhSpot(.5, .5, 0)
        : null;
    return SizedBox.square(
      dimension: size,
      child: CustomMultiChildLayout(
        delegate: _SocketLayout(spot),
        children: [
          LayoutId(
            id: _Part.face,
            child: DecoratedBox(
              decoration: socketDecoration(size),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: _shade,
                    ),
                  ),
                  if (q != null && wash != null)
                    DecoratedBox(
                      key: const ValueKey('wash'),
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0, .62],
                          colors: [
                            qualityColour(q).withValues(alpha: wash),
                            qualityColour(q).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(size * _inset),
                    child: _image(size),
                  ),
                ],
              ),
            ),
          ),
          if (q != null)
            LayoutId(
              id: _Part.ring,
              child: DecoratedBox(
                key: const ValueKey('ring'),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: qualityColour(q), width: 2),
                ),
              ),
            ),
          if (spot != null)
            LayoutId(
              id: _Part.mark,
              child: _PhMark(size: size, angle: spot.angle),
            ),
          if (count > 1) LayoutId(id: _Part.badge, child: _CountBadge(count)),
        ],
      ),
    );
  }

  Widget _image(double size) {
    if (picture.icon case final icon?) {
      return Icon(icon, size: size / 2, color: Quiet.muted);
    }
    return Image(
      image: AssetImage(picture.asset!),
      fit: BoxFit.contain,
      // A new portrait (another gender) replaces the old one with no gap.
      gaplessPlayback: true,
      // The PH mark has no semantics, so a screen reader says only this.
      semanticLabel: picture.placeholder ? 'placeholder picture' : null,
      excludeFromSemantics: !picture.placeholder,
    );
  }
}

/// A picture across the full width and [height] dp tall, in the dark
/// socket: the image of a boss on its sheet (spec 0014 §4.2). The image
/// covers the box from its top, so the head of the monster shows. A
/// placeholder keeps its PH mark and its semantics label (§3.2).
class WidePicture extends StatelessWidget {
  const WidePicture({super.key, required this.picture, required this.height});

  final Picture picture;
  final double height;

  @override
  Widget build(BuildContext context) {
    final spot = picture.placeholder
        ? phSpots[picture.key] ?? const PhSpot(.5, .5, 0)
        : null;
    final radius = socketRadius(height);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: socketDecoration(height),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(decoration: BoxDecoration(gradient: _shade)),
              Image(
                image: AssetImage(picture.asset!),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                semanticLabel: picture.placeholder
                    ? 'placeholder picture'
                    : null,
                excludeFromSemantics: !picture.placeholder,
                // The mark is a part of the picture, so the frame of the
                // image holds it.
                frameBuilder: spot == null
                    ? null
                    : (context, image, _, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          image,
                          CustomSingleChildLayout(
                            delegate: _WideMarkLayout(spot, radius.topLeft),
                            // At the height of a boss image the mark has
                            // its largest size, 16 dp.
                            child: _PhMark(size: height, angle: spot.angle),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Places the PH mark on a [WidePicture] at its spot in the image, or else
/// at the closest place inside the box.
class _WideMarkLayout extends SingleChildLayoutDelegate {
  _WideMarkLayout(this.spot, this.corner);

  final PhSpot spot;
  final Radius corner;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size mark) {
    // The images of monsters are square (plan 0017), so the image covers
    // the box at the larger side, centred across and from the top.
    final side = math.max(size.width, size.height);
    final centre = markCentre(
      spot: Offset((size.width - side) / 2 + spot.x * side, spot.y * side),
      mark: mark,
      angle: spot.angle,
      // 2 dp inside the edge, as in a socket.
      bounds: RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(2),
        corner - const Radius.circular(2),
      ),
    );
    return centre - mark.center(Offset.zero);
  }

  @override
  bool shouldRelayout(_WideMarkLayout oldDelegate) =>
      oldDelegate.spot != spot || oldDelegate.corner != corner;
}

/// The corners of a socket (the kit of spec 0014): radius 12, and 10 for a
/// small socket of 32 dp.
BorderRadius socketRadius(double size) =>
    BorderRadius.circular(size <= 32 ? 10 : 12);

/// The dark socket with its faint rim. An empty doll slot uses it too.
BoxDecoration socketDecoration(double size) => BoxDecoration(
  color: Quiet.socket,
  borderRadius: socketRadius(size),
  border: Border.all(color: Quiet.steel.withValues(alpha: .18)),
);

/// The recess of the socket: a slate shade at its centre, a little above
/// the middle (the kit).
final _shade = RadialGradient(
  center: const Alignment(0, -.16),
  radius: .6,
  colors: [
    Quiet.slate.withValues(alpha: .5),
    Quiet.slate.withValues(alpha: .19),
  ],
);

/// The image fills the socket but for this part of its width on each side
/// (the kit). The PH spots are parts of the image, not of the socket.
const _inset = .09;

/// The strength of the wash from the second quality up (the kit of spec
/// 0014: Uncommon to Legendary).
const _wash = [.14, .18, .22, .26];

enum _Part { face, ring, mark, badge }

/// Lays out the socket. The badge comes first: the PH mark keeps off it, by
/// the size that each has after its layout.
class _SocketLayout extends MultiChildLayoutDelegate {
  _SocketLayout(this.spot);

  final PhSpot? spot;

  @override
  void performLayout(Size size) {
    final whole = Offset.zero & size;
    for (final part in [_Part.face, _Part.ring]) {
      if (hasChild(part)) layoutChild(part, BoxConstraints.tight(size));
    }
    Rect? badge;
    if (hasChild(_Part.badge)) {
      final b = layoutChild(_Part.badge, const BoxConstraints());
      // 8 dp past the right edge and 7 dp past the bottom edge (the kit).
      final at = Offset(size.width + 8 - b.width, size.height + 7 - b.height);
      positionChild(_Part.badge, at);
      badge = at & b;
    }
    if (spot case final spot? when hasChild(_Part.mark)) {
      final mark = layoutChild(_Part.mark, const BoxConstraints());
      final image = whole.deflate(size.width * _inset);
      final centre = markCentre(
        spot: Offset(
          image.left + spot.x * image.width,
          image.top + spot.y * image.height,
        ),
        mark: mark,
        angle: spot.angle,
        // Inside the round inner edge of the 2 dp ring, and clear of the
        // badge. In a socket of 32 dp with a count, a steep mark has less
        // than 1 dp to spare above the badge.
        bounds: RRect.fromRectAndRadius(
          whole.deflate(2),
          socketRadius(size.width).topLeft - const Radius.circular(2),
        ),
        avoid: badge?.inflate(.5),
      );
      positionChild(_Part.mark, centre - mark.center(Offset.zero));
    }
  }

  @override
  bool shouldRelayout(_SocketLayout oldDelegate) => oldDelegate.spot != spot;
}

/// The centre of a PH mark of the size [mark], turned by [angle] degrees
/// about its centre: [spot] if the mark fits there, else the closest point
/// where each corner lies inside [bounds] and no part on [avoid] (spec 0014
/// §3.2). A mark that fits nowhere goes to the centre of [bounds].
Offset markCentre({
  required Offset spot,
  required Size mark,
  required double angle,
  required RRect bounds,
  Rect? avoid,
}) {
  final a = angle * math.pi / 180;
  final along = Offset(math.cos(a), math.sin(a));
  final across = Offset(-along.dy, along.dx);
  final corners = [
    for (final (x, y) in const [(-1, -1), (1, -1), (1, 1), (-1, 1)])
      along * (x * mark.width / 2) + across * (y * mark.height / 2),
  ];
  double reach(Iterable<Offset> points, Offset axis, bool far) =>
      points.map((p) => _dot(p, axis)).reduce(far ? math.max : math.min);

  // Each side of the bounds holds the corner of the mark that reaches
  // furthest towards it.
  final inside = [
    for (final (normal, limit) in _sidesOf(bounds))
      (normal, limit - reach(corners, normal, true)),
  ];
  if (avoid == null) return _closest(spot, inside) ?? bounds.center;

  // The mark misses [avoid] when one of four axes keeps them apart: across
  // the screen, down it, along the letters or across them. On each axis the
  // mark lies before [avoid] or after it.
  final box = [
    avoid.topLeft,
    avoid.topRight,
    avoid.bottomRight,
    avoid.bottomLeft,
  ];
  Offset? best;
  for (final axis in [const Offset(1, 0), const Offset(0, 1), along, across]) {
    for (final side in [
      (axis, reach(box, axis, false) - reach(corners, axis, true)),
      (-axis, reach(corners, axis, false) - reach(box, axis, true)),
    ]) {
      final p = _closest(spot, [...inside, side]);
      if (p != null &&
          (best == null || (p - spot).distance < (best - spot).distance)) {
        best = p;
      }
    }
  }
  return best ?? bounds.center;
}

double _dot(Offset p, Offset q) => p.dx * q.dx + p.dy * q.dy;

/// The sides of a polygon inside [r], with two chords for each round corner.
/// Each side is (normal, limit): a point p lies inside when
/// `normal · p <= limit`.
List<(Offset, double)> _sidesOf(RRect r) {
  final radius = r.tlRadiusX;
  final points = [
    for (final (centre, start) in [
      (Offset(r.left + radius, r.top + radius), 180),
      (Offset(r.right - radius, r.top + radius), 270),
      (Offset(r.right - radius, r.bottom - radius), 0),
      (Offset(r.left + radius, r.bottom - radius), 90),
    ])
      for (final turn in const [0, 45, 90])
        centre + Offset.fromDirection((start + turn) * math.pi / 180, radius),
  ];
  final sides = <(Offset, double)>[];
  for (final (i, p) in points.indexed) {
    final edge = points[(i + 1) % points.length] - p;
    if (edge.distance < 1e-9) continue;
    // The points run clockwise on the screen, so this normal points out.
    final normal = Offset(edge.dy, -edge.dx) / edge.distance;
    sides.add((normal, _dot(normal, p)));
  }
  return sides;
}

/// The point closest to [spot] that lies inside each of [sides], or null if
/// none does. The closest point is [spot] itself, its foot on one side, or
/// a corner where two sides meet.
Offset? _closest(Offset spot, List<(Offset, double)> sides) {
  bool fits(Offset p) => sides.every((s) => _dot(s.$1, p) <= s.$2 + 1e-9);
  final points = [
    spot,
    for (final (n, d) in sides) spot - n * (_dot(n, spot) - d),
    for (final (i, (n, d)) in sides.indexed)
      for (final (m, e) in sides.skip(i + 1))
        if (n.dx * m.dy - n.dy * m.dx case final det when det.abs() > 1e-9)
          Offset((d * m.dy - e * n.dy) / det, (n.dx * e - m.dx * d) / det),
  ];
  Offset? best;
  for (final p in points.where(fits)) {
    if (best == null || (p - spot).distance < (best - spot).distance) {
      best = p;
    }
  }
  return best;
}

/// "PH" on a placeholder (spec 0014 §3.2): small caps in light steel at 85%,
/// with a thin black stroke under the letters. Its font size is 22% of the
/// socket width, from 9 dp to 16 dp. The kit spaces the letters by 0.16 em.
class _PhMark extends StatelessWidget {
  const _PhMark({required this.size, required this.angle});

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final fontSize = (size * .22).clamp(9.0, 16.0);
    // A line of 0.9 em, cut evenly above and below, holds the capitals and
    // their stroke with little room to spare. Thus the layout places the
    // mark by its letters, not by an empty line height.
    final letters = TextStyle(
      fontFamily: Fonts.label,
      fontWeight: FontWeight.w800,
      fontSize: fontSize,
      height: .9,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: 0,
    );
    Widget text(TextStyle look) => Text.rich(
      TextSpan(
        style: letters.merge(look),
        children: [
          // The space goes between the letters, not after the H.
          TextSpan(
            text: 'P',
            style: TextStyle(letterSpacing: fontSize * .16),
          ),
          const TextSpan(text: 'H'),
        ],
      ),
      // The size follows the socket, not the text size of the phone.
      textScaler: TextScaler.noScaling,
      maxLines: 1,
      softWrap: false,
    );
    return ExcludeSemantics(
      key: const ValueKey('ph-mark'),
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Stack(
          children: [
            text(
              TextStyle(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.5
                  ..color = Quiet.black.withValues(alpha: .7),
              ),
            ),
            text(TextStyle(color: Quiet.steel.withValues(alpha: .85))),
          ],
        ),
      ),
    );
  }
}

/// The count "×N" in its badge (spec 0014 §2.3): slate with the 2 dp black
/// border, 21 dp high and at least 30 dp wide (the kit).
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 30, minHeight: 21),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Quiet.slate, Quiet.slateLow],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(width: 2),
    ),
    child: Text(
      '×$count',
      key: const ValueKey('count'),
      maxLines: 1,
      // The badge keeps its 21 dp at each text size of the phone. A taller
      // badge leaves no room for the PH mark in a socket of 32 dp.
      textScaler: TextScaler.noScaling,
      style: const TextStyle(
        fontFamily: Fonts.number,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        height: 17 / 12.5,
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: 0,
        color: Quiet.text,
        fontFeatures: [
          FontFeature.liningFigures(),
          FontFeature.tabularFigures(),
        ],
      ),
    ),
  );
}
