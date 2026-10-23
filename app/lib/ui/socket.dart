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
  });

  final Picture picture;
  final double size;
  final QualityDef? quality;
  final int count;

  @override
  Widget build(BuildContext context) {
    final q = quality;
    final radius = socketRadius(size);
    final wash = _wash[q?.id];
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

/// The strength of the wash of each quality (the kit of spec 0014). Common
/// has no wash.
const _wash = {'uncommon': .14, 'rare': .18, 'epic': .22, 'legendary': .26};

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
        // Off the 2 dp ring, and clear of the badge. In a socket of 32 dp
        // with a count, a steep mark has less than 1 dp to spare above the
        // badge.
        bounds: whole.deflate(2),
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
/// §3.2). A mark too large for [bounds] goes to its centre.
Offset markCentre({
  required Offset spot,
  required Size mark,
  required double angle,
  required Rect bounds,
  Rect? avoid,
}) {
  final a = angle * math.pi / 180;
  final along = Offset(math.cos(a), math.sin(a));
  final across = Offset(-along.dy, along.dx);
  final corners = [
    for (final (x, y) in const [(-1, -1), (1, -1), (1, 1), (-1, 1)])
      along * (x * mark.width / 2) + across * (y * mark.height / 2),
  ];
  double dot(Offset p, Offset q) => p.dx * q.dx + p.dy * q.dy;
  double reach(Iterable<Offset> points, Offset axis, bool far) =>
      points.map((p) => dot(p, axis)).reduce(far ? math.max : math.min);

  // The centres where the mark stays inside the bounds.
  final xs = reach(corners, const Offset(1, 0), true);
  final ys = reach(corners, const Offset(0, 1), true);
  final room = Rect.fromLTRB(
    bounds.left + xs,
    bounds.top + ys,
    bounds.right - xs,
    bounds.bottom - ys,
  );
  if (room.width < 0 || room.height < 0) return bounds.center;
  final inRoom = Offset(
    spot.dx.clamp(room.left, room.right),
    spot.dy.clamp(room.top, room.bottom),
  );
  if (avoid == null) return inRoom;

  // The mark misses [avoid] when one of four axes keeps them apart: across
  // the screen, down it, along the letters or across them. On each axis the
  // mark lies before [avoid] or after it: a half plane of centres.
  final box = [
    avoid.topLeft,
    avoid.topRight,
    avoid.bottomRight,
    avoid.bottomLeft,
  ];
  Offset? best;
  for (final axis in [const Offset(1, 0), const Offset(0, 1), along, across]) {
    for (final (normal, limit) in [
      (axis, reach(box, axis, false) - reach(corners, axis, true)),
      (-axis, reach(corners, axis, false) - reach(box, axis, true)),
    ]) {
      final p = _closestInSide(spot, inRoom, room, normal, limit);
      if (p != null &&
          (best == null || (p - spot).distance < (best - spot).distance)) {
        best = p;
      }
    }
  }
  return best ?? inRoom;
}

/// The point of [room] closest to [spot] with `normal · p <= limit`, or
/// null if [room] has none. [inRoom] is [spot] moved into [room]; [normal]
/// has the length 1.
Offset? _closestInSide(
  Offset spot,
  Offset inRoom,
  Rect room,
  Offset normal,
  double limit,
) {
  double side(Offset p) => p.dx * normal.dx + p.dy * normal.dy;
  if (side(inRoom) <= limit) return inRoom;
  // Else the closest point lies on the edge of the half plane.
  final foot = spot - normal * (side(spot) - limit);
  final dir = Offset(-normal.dy, normal.dx);
  var lo = double.negativeInfinity;
  var hi = double.infinity;
  for (final (from, step, min, max) in [
    (foot.dx, dir.dx, room.left, room.right),
    (foot.dy, dir.dy, room.top, room.bottom),
  ]) {
    if (step.abs() < 1e-9) {
      if (from < min - 1e-9 || from > max + 1e-9) return null;
      continue;
    }
    final t1 = (min - from) / step;
    final t2 = (max - from) / step;
    lo = math.max(lo, math.min(t1, t2));
    hi = math.min(hi, math.max(t1, t2));
  }
  if (lo > hi) return null;
  return foot + dir * 0.0.clamp(lo, hi);
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
