import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'labels.dart';
import 'theme.dart';

/// The world drawn as places joined by paths; tap a place to act there
/// (spec 0006 §2.2, spec 0008 §3.3). Areas away from explored ones are fog.
class WorldTab extends StatelessWidget {
  const WorldTab({super.key});

  /// Room around each place for its marker and name.
  static const _label = 104.0;
  static const _marker = 20.0;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);

    return RefreshIndicator(
      onRefresh: c.syncNow,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth - 32;
          final height = width * game.data.mapAspect;
          Offset at(String area) {
            final p = game.data.locations[area]!.map ?? const MapPoint(.5, .5);
            return Offset(p.x * width, p.y * height);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                width: width,
                height: height + 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MapPainter(
                          river: [
                            for (final p in game.data.mapRiver)
                              Offset(p.x * width, p.y * height),
                          ],
                          paths: [
                            // A hidden area's roads aren't drawn either
                            // (spec 0011 §6.2).
                            for (final r in game.data.routes)
                              if (!game.isHidden(s, r.from) &&
                                  !game.isHidden(s, r.to))
                                (
                                  at(r.from),
                                  at(r.to),
                                  game.isFogged(s, r.from) ||
                                          game.isFogged(s, r.to)
                                      ? null
                                      : fmt(r.steps),
                                ),
                          ],
                          water: Quiet.deepTeal,
                          road: Quiet.muted,
                          // The step counts are numbers that stand alone
                          // (spec 0014 §2.2), at today's size.
                          stepStyle: const TextStyle(
                            fontFamily: Fonts.number,
                            fontSize: 11,
                            color: Quiet.text,
                          ),
                          ground: Quiet.caseBlack,
                        ),
                      ),
                    ),
                    for (final area in game.data.locations.keys)
                      if (!game.isHidden(s, area))
                        Positioned(
                          // Kept inside the map, so edge names stay tappable.
                          left: (at(area).dx - _label / 2).clamp(
                            0,
                            width - _label,
                          ),
                          top: at(area).dy - _marker,
                          width: _label,
                          child: _Place(
                            key: ValueKey('area-$area'),
                            name: game.isFogged(s, area)
                                ? '???'
                                : labels.location(area),
                            icon: _icon(game, s, area),
                            here: area == s.location,
                            fogged: game.isFogged(s, area),
                            onTap: () => _open(context, c, area),
                          ),
                        ),
                  ],
                ),
              ),
              Text(
                'Tap a place to see what lives there.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  static IconData _icon(Game game, GameState s, String area) {
    final l = game.data.locations[area]!;
    if (game.isFogged(s, area)) return Icons.cloud;
    if (l.crafting) return Icons.cottage;
    // A lake or cove: only fishing spots, no monsters (spec 0011 §3.1).
    if (l.enemies.isEmpty &&
        l.nodes.isNotEmpty &&
        l.nodes.every((n) => game.data.nodes[n]?.profession == 'fishing')) {
      return Icons.water;
    }
    if (l.enemies.isEmpty) return Icons.landscape;
    return Icons.forest;
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

/// One place on the map: a marker with its name below.
class _Place extends StatelessWidget {
  const _Place({
    super.key,
    required this.name,
    required this.icon,
    required this.here,
    required this.fogged,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool here;
  final bool fogged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: WorldTab._marker,
            backgroundColor: here
                ? scheme.primary
                : fogged
                ? scheme.surfaceContainerHighest
                : scheme.secondaryContainer,
            foregroundColor: here
                ? scheme.onPrimary
                : fogged
                ? Quiet.faint
                : scheme.onSecondaryContainer,
            child: Icon(here ? Icons.person_pin_circle : icon),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: (here ? text.labelLarge : text.labelMedium)?.copyWith(
              color: fogged ? Quiet.faint : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The river, then the paths: solid with their step cost between open
/// places, dashed and unlabelled into the fog.
@visibleForTesting
class MapPainter extends CustomPainter {
  MapPainter({
    required this.river,
    required this.paths,
    required this.water,
    required this.road,
    required this.stepStyle,
    required this.ground,
  });

  final List<Offset> river;

  /// Each path's ends and its step count; null for a path into the fog.
  final List<(Offset, Offset, String?)> paths;
  final Color water;
  final Color road;

  /// The style of each step count.
  final TextStyle stepStyle;

  /// Behind each step count, so it reads where paths cross labels.
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    if (river.length >= 2) {
      final line = Path()..moveTo(river.first.dx, river.first.dy);
      for (var i = 1; i < river.length; i++) {
        final mid = (river[i - 1] + river[i]) / 2;
        line.quadraticBezierTo(
          river[i - 1].dx,
          river[i - 1].dy,
          mid.dx,
          mid.dy,
        );
      }
      line.lineTo(river.last.dx, river.last.dy);
      canvas.drawPath(
        line,
        Paint()
          ..color = water
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
    final pen = Paint()
      ..color = road
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (final (a, b, steps) in paths) {
      final line = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
      if (steps == null) {
        for (final PathMetric m in line.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += 12) {
            canvas.drawPath(m.extractPath(d, d + 6), pen);
          }
        }
        continue;
      }
      canvas.drawPath(line, pen);
      final label = TextPainter(
        text: TextSpan(text: steps, style: stepStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final mid = (a + b) / 2 - Offset(label.width / 2, label.height / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (mid & label.size).inflate(3),
          const Radius.circular(4),
        ),
        Paint()..color = ground,
      );
      label.paint(canvas, mid);
    }
  }

  @override
  bool shouldRepaint(MapPainter old) =>
      old.paths != paths ||
      old.water != water ||
      old.road != road ||
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
                subtitle: Text('${fmt(steps)} steps'),
                startFrom: host,
              ),
          ],
        ),
      ),
    );
  }
}
