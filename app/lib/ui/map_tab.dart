import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'actions.dart';
import 'controller_scope.dart';
import 'labels.dart';

/// Every open area with its monsters and gathering spots, nearest first, and
/// where to walk (spec 0006 §2.2).
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final destinations = game.travelDestinations(s);

    return RefreshIndicator(
      onRefresh: c.syncNow,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final MapEntry(key: place, value: steps)
              in game.openLocationsByDistance(s).entries)
            if ((game.enemiesAt(s, place), game.nodesAt(s, place))
                case (final enemies, final nodes)
                when enemies.isNotEmpty || nodes.isNotEmpty) ...[
              Heading(
                '${labels.location(place)} · '
                '${steps == 0 ? 'here' : '${fmt(steps)} steps away'}',
              ),
              for (final id in enemies) enemyTile(c, id),
              for (final id in nodes) nodeTile(c, id),
            ],
          if (destinations.isNotEmpty) const Heading('Travel'),
          for (final id in destinations)
            ActionTile(
              controller: c,
              activity: Activity.travel(id),
              leading: const Icon(Icons.signpost),
              title: labels.location(id),
              subtitle: '${fmt(game.data.route(s.location, id)!.steps)} steps',
            ),
        ],
      ),
    );
  }
}
