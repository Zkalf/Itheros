import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'actions.dart' show Heading;
import 'controller_scope.dart';
import 'images.dart';
import 'labels.dart';
import 'socket.dart';
import 'theme.dart';

/// Opens from the trophy button in the top bar (spec 0006 amendment 2). The
/// achievements stand under the headings Early, Mid and Late (spec 0017 §6).
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
      appBar: AppBar(
        leading: const BackPlate(),
        title: const Text('Achievements'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(gutter),
          children: [
            for (final stage in AchievementStage.values) ...[
              Heading(
                _stageNames[stage]!,
                key: ValueKey('achievement-stage-${stage.name}'),
              ),
              for (final a in c.game.data.achievements.values)
                if (a.stage == stage)
                  _AchievementTile(
                    achievement: a,
                    unlocked: s.achievements.contains(a.id),
                    fresh: fresh.contains(a.id),
                    progress: c.game.achievementProgress(s, a.id),
                    labels: labels,
                  ),
            ],
          ],
        ),
      ),
    );
  }

  static const _stageNames = {
    AchievementStage.early: 'Early',
    AchievementStage.mid: 'Mid',
    AchievementStage.late: 'Late',
  };
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
  final ({int have, int need}) progress;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Card(
      key: ValueKey('achievement-${a.id}'),
      shape: plateShape(selected: unlocked),
      // A ListTile caps its leading widget at 56 dp, so the 72 dp picture
      // stands beside it (spec 0014 amendment 3).
      child: Row(
        children: [
          Padding(
            // The room above and below keeps the picture off the rim of a
            // short row.
            padding: const EdgeInsetsDirectional.only(
              start: 16,
              top: 8,
              bottom: 8,
            ),
            // Its picture, or the locked patch (spec 0014 §3.1).
            child: PictureSocket(
              picture: ImageScope.of(context).pictureOf(
                labels.data,
                AchievementThing(a.id, earned: unlocked),
              ),
              size: 72,
            ),
          ),
          Expanded(child: _tile(context)),
        ],
      ),
    );
  }

  /// The words of the row: its name, goal, reward and bar, and "New".
  Widget _tile(BuildContext context) {
    final a = achievement;
    final (:have, :need) = progress;
    final shown = have.clamp(0, need);
    // A quality is found or not: it has no bar.
    final bar = a.criterion is! QualityCriterion;
    // An earned achievement shows its goal and a teal rim, not a full bar
    // and "100 / 100" (spec 0014 §4.1).
    return ListTile(
      // A feat says so beside its name (spec 0017 §6).
      title: a.kind == AchievementKind.feat
          ? Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(a.name),
                statusChip(
                  'Feat',
                  Quiet.muted,
                  key: ValueKey('achievement-feat-${a.id}'),
                ),
              ],
            )
          : Text(a.name),
      titleTextStyle: nameStyle(context),
      // "New" is a teal outline (spec 0014 §2.1, §2.2).
      trailing: fresh
          ? statusChip(
              'New',
              Quiet.teal,
              key: ValueKey('achievement-new-${a.id}'),
            )
          : null,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_goal(a)),
          Text('Reward: ${labels.reward(a.reward)}'),
          if (!unlocked && bar) ...[
            const SizedBox(height: 6),
            // The bar of an achievement is teal (spec 0014 §2.3).
            LinearProgressIndicator(value: shown / need, color: Quiet.teal),
            Text.rich(numberSpan('${fmt(shown)} / ${fmt(need)}')),
          ],
        ],
      ),
    );
  }

  /// The goal of [a] in words (spec 0017 §3.1).
  String _goal(AchievementDef a) {
    final data = labels.data;
    String profession(String id) => data.professions[id]!.name;
    return switch (a.criterion) {
      CounterCriterion(:final counter, :final atLeast) => _counterGoal(
        counter,
        fmt(atLeast),
      ),
      LevelCriterion(:final level) => 'Reach level $level',
      ProfessionCriterion(:final profession, :final level) =>
        'Reach ${data.professions[profession]!.name} level $level',
      EachProfessionCriterion(:final professions, :final level) =>
        'Reach level $level in '
            '${professions.take(professions.length - 1).map(profession).join(', ')}'
            ' and ${profession(professions.last)}',
      QualityCriterion(:final quality) when quality == data.qualities.last.id =>
        'Find a ${data.qualities.last.name} item',
      QualityCriterion(:final quality) =>
        'Find an item of '
            '${data.qualities.firstWhere((q) => q.id == quality).name} '
            'quality or better',
    };
  }

  String _counterGoal(String counter, String n) {
    final parts = counter.split('.');
    return switch (parts.first) {
      'steps' => 'Walk $n steps',
      'kills' => 'Defeat $n × ${labels.enemy(parts.last)}',
      // A fish names its spot (spec 0017 amendments 2 and 3).
      'gathered' => switch (_fishingSpot(parts.last)) {
        final spot? => 'Catch $n fish at ${spot.name}',
        null => 'Gather $n × ${labels.item(parts.last)}',
      },
      'crafted' when parts.last == 'total' => 'Craft $n item(s)',
      'crafted' => 'Craft $n × ${labels.item(parts.last)}',
      'areas' => 'Arrive at all $n areas',
      'visited' => 'Find ${labels.location(parts.last)}',
      _ => '$counter ≥ $n',
    };
  }

  /// The fishing spot where [item] is caught, if one is.
  NodeDef? _fishingSpot(String item) => labels.data.nodes.values
      .where((n) => n.profession == 'fishing' && n.item == item)
      .firstOrNull;
}
