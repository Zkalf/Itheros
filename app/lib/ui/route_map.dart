import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'controller_scope.dart';
import 'labels.dart';
import 'world_tab.dart' show MapSpot, MapView, fitMap;

/// The room of the route map above the highest place of a route and below
/// the lowest, and its least height (plan 0017, M3).
const _margin = 48.0;
const _least = 120.0;

/// The part of the map image at [width] that the route map of [route]
/// shows, from the top of the image (plan 0017, M3). The image fills the
/// width, so the strip runs across it.
/// - The strip runs from 48 dp above the highest place of the route to
///   48 dp below the lowest. Each end stops at the edge of the image.
/// - A strip shorter than 120 dp grows to 120 dp, inside the image.
Rect routeStrip(GameData data, List<String> route, double width) {
  final height = width * data.mapAspect;
  final ys = [
    for (final p in route)
      if (data.locations[p]?.map case final m?) m.y * height,
  ];
  var top = math.max(0.0, ys.reduce(math.min) - _margin);
  var bottom = math.min(height, ys.reduce(math.max) + _margin);
  final grow = _least - (bottom - top);
  if (grow > 0) {
    top = (top - grow / 2).clamp(0, math.max(0, height - _least));
    bottom = math.min(height, top + _least);
  }
  return Rect.fromLTRB(0, top, width, bottom);
}

/// The route map of a report with [route] (spec 0014 §5), or null for a
/// route of fewer than two places. A place that the map does not have is
/// left out.
Widget? routeMapOf(GameData data, List<String> route) {
  final places = [
    for (final p in route)
      if (data.locations[p]?.map != null) p,
  ];
  return places.toSet().length < 2 ? null : RouteMap(route: places);
}

/// A strip of the map with the roads walked, the places passed and the
/// teal ring on the last place (spec 0014 §5). It stands between the
/// banners and the lines of a report.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.route});

  final List<String> route;

  @override
  Widget build(BuildContext context) {
    final data = ControllerScope.of(context).game.data;
    final labels = Labels(data);
    // Each road once, with its step count.
    final roads = <String, (String, String, String?)>{};
    for (var i = 1; i < route.length; i++) {
      final (a, b) = (route[i - 1], route[i]);
      if (a == b) continue;
      final steps = data.routes
          .where((r) => {r.from, r.to}.containsAll([a, b]))
          .firstOrNull
          ?.steps;
      roads[([a, b]..sort()).join(' ')] ??= (
        a,
        b,
        steps == null ? null : fmt(steps),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // As the World map, the route map keeps the layout of 360 dp in a
      // narrower card, drawn smaller.
      child: LayoutBuilder(
        builder: (context, box) => fitMap(
          box.maxWidth,
          (width) => ClipRRect(
            key: const ValueKey('route-map'),
            borderRadius: BorderRadius.circular(12),
            child: MapView(
              data: data,
              width: width,
              strip: routeStrip(data, route, width),
              places: [
                for (final p in route.toSet())
                  MapSpot(
                    p,
                    key: ValueKey('route-$p'),
                    name: labels.location(p),
                  ),
              ],
              roads: roads.values.toList(),
              here: route.last,
            ),
          ),
        ),
      ),
    );
  }
}
