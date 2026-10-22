import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'controller_scope.dart';
import 'labels.dart';

/// Opens from the trophy button in the top bar (spec 0006 amendment 2).
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, this.fresh = const {}});

  /// Earned achievements not seen before this visit: they show "New".
  final Set<String> fresh;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final s = c.state;
    final labels = Labels(c.game.data);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final a in c.game.data.achievements.values)
              _AchievementTile(
                achievement: a,
                unlocked: s.achievements.contains(a.id),
                fresh: fresh.contains(a.id),
                progress: s.counters[a.counter] ?? 0,
                labels: labels,
              ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.fresh,
    required this.progress,
    required this.labels,
  });

  final AchievementDef achievement;
  final bool unlocked;
  final bool fresh;
  final int progress;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final shown = progress.clamp(0, a.atLeast);
    return Card(
      child: ListTile(
        leading: Icon(
          unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
          color: unlocked ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(a.name),
        trailing: fresh
            ? Chip(
                key: ValueKey('achievement-new-${a.id}'),
                label: const Text('New'),
              )
            : null,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_goal(a)),
            if (a.bankCapReward > 0)
              Text('Reward: +${fmt(a.bankCapReward)} step bank cap'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: shown / a.atLeast),
            Text('${fmt(shown)} / ${fmt(a.atLeast)}'),
          ],
        ),
      ),
    );
  }

  String _goal(AchievementDef a) {
    final n = fmt(a.atLeast);
    final parts = a.counter.split('.');
    return switch (parts.first) {
      'steps' => 'Walk $n steps',
      'kills' => 'Defeat $n × ${labels.enemy(parts.last)}',
      'gathered' => 'Gather $n × ${labels.item(parts.last)}',
      'crafted' when parts.last == 'total' => 'Craft $n item(s)',
      'crafted' => 'Craft $n × ${labels.item(parts.last)}',
      'areas' => 'Arrive at all $n areas',
      _ => '${a.counter} ≥ $n',
    };
  }
}
