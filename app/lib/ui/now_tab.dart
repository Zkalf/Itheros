import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'action_picture.dart';
import 'actions.dart';
import 'away_summary_card.dart';
import 'bag_spaces.dart';
import 'bank_screen.dart';
import 'controller_scope.dart';
import 'fight_sheet.dart';
import 'images.dart';
import 'labels.dart';
import 'item_card.dart';
import 'item_square.dart';
import 'meals.dart';
import 'socket.dart';
import 'teacher_sheet.dart';
import 'trainer_sheet.dart';
import 'theme.dart';

/// What am I doing, and what can I do here (spec 0008 §3.2): the running
/// action, the queue, the step bank, then what the player's place offers.
class NowTab extends StatelessWidget {
  const NowTab({super.key, this.onOpenWorld, this.onOpenProfessions});

  /// Shows the World map, from the resting card.
  final VoidCallback? onOpenWorld;

  /// Shows Professions, from the Forge row, or on one profession's card
  /// (the Camp fire row opens Cooking).
  final void Function([String? profession])? onOpenProfessions;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final labels = Labels(c.game.data);
    return RefreshIndicator(
      onRefresh: c.syncNow,
      child: ListView(
        padding: const EdgeInsets.all(gutter),
        children: [
          if (c.syncError != null)
            const Card(
              child: ListTile(
                leading: Icon(Icons.sync_problem),
                title: Text("Couldn't read your steps"),
                subtitle: Text('Health Connect did not answer. Retrying.'),
              ),
            ),
          _StatusCard(controller: c, labels: labels),
          if (c.testWalkOn) _TestWalkCard(controller: c),
          _NextGoal(controller: c, labels: labels),
          _Discoveries(controller: c, labels: labels),
          _QueueCard(controller: c, labels: labels, onOpenWorld: onOpenWorld),
          _Here(
            controller: c,
            labels: labels,
            onOpenProfessions: onOpenProfessions,
          ),
        ],
      ),
    );
  }
}

/// "Next goal" (spec 0002 §9.3). It can be hidden from level 1 (spec 0008
/// decision 9), and turned back on in Settings.
class _NextGoal extends StatelessWidget {
  const _NextGoal({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    // Hideable from level 1 (spec 0008 decision 9).
    if (controller.nextGoalHidden) return const SizedBox.shrink();
    final goal = game.nextGoal(s);
    if (goal == null) return const SizedBox.shrink();
    final grey = switch (goal) {
      CollectGoal(:final source) when source.kind == ActivityKind.fight =>
        game.enemyBand(s, source.target).colour == LevelColour.grey,
      _ => false,
    };
    return Card(
      key: const ValueKey('next-goal'),
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: const Text('Next goal'),
        subtitle: Text(
          labels.goal(
            goal,
            canCraftHere: game.data.locations[s.location]!.crafting,
            grey: grey,
            yourLevel: switch (goal) {
              FightGoal(:final enemy) =>
                game.data.enemies[enemy]!.level == game.level(s),
              _ => false,
            },
          ),
        ),
        trailing: TextButton(
          onPressed: () => controller.setNextGoalHidden(true),
          child: const Text('Hide'),
        ),
      ),
    );
  }
}

/// Flavour lines for the area and monsters here, the first time they're
/// seen (spec 0002 §9.5).
class _Discoveries extends StatelessWidget {
  const _Discoveries({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final here = game.data.locations[s.location]!;
    final lines = <String, String>{
      here.id: ?here.flavour,
      for (final id in game.availableEnemies(s))
        id: ?game.data.enemies[id]!.flavour,
    }..removeWhere((id, _) => controller.seen.contains(id));
    if (lines.isEmpty) return const SizedBox.shrink();
    return Card(
      key: const ValueKey('discoveries'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => controller.markSeen(lines.keys),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pretend steps for testing at home (spec 0004 §3, amendments 4 and 5).
/// Shown while the hidden switch on the Character tab is on. One row.
class _TestWalkCard extends StatelessWidget {
  const _TestWalkCard({required this.controller});

  final GameController controller;

  /// 100 -> "100", 1000 -> "1k", 100000 -> "100k" (amendment 5).
  static String _short(int n) => n >= 1000 ? '${n ~/ 1000}k' : '$n';

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('test-walk'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text('Test walk', style: Theme.of(context).textTheme.titleSmall),
          for (final n in const [100, 1000, 5000, 25000, 100000]) ...[
            const SizedBox(width: 4),
            Expanded(
              child: FilledButton.tonal(
                style: slateButton.copyWith(
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
                ),
                onPressed: () => controller.testWalk(n),
                child: FittedBox(child: Text('+${_short(n)}')),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller, required this.labels});

  final GameController controller;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final level = game.level(s);
    final floor = game.data.xpForLevel(level);
    final next = game.xpForNextLevel(s);
    final cap = game.bankCap(s);
    final text = Theme.of(context).textTheme;
    final images = ImageScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // The marker of the place in a 48 dp socket (spec 0014
                // §4.2, plan 0017 choice 9).
                PictureSocket(
                  key: const ValueKey('status-place'),
                  picture: images.pictureOf(
                    game.data,
                    PlaceThing(s.location, fogged: false),
                  ),
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    labels.location(s.location),
                    style: text.titleLarge,
                  ),
                ),
                Text.rich(numberSpan('Level $level'), style: text.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            _Bar(
              label: 'XP ${fmt(s.xp)} / ${fmt(next)}',
              value: (s.xp - floor) / (next - floor),
            ),
            const SizedBox(height: 12),
            // The step bank is mist; other bars are steel (spec 0014 §2.3).
            // A tap opens what it does (spec 0014 amendment 6).
            InkWell(
              key: const ValueKey('step-bank'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showStepBank(context),
              child: _Bar(
                label: 'Step bank ${fmt(s.stepBank)} / ${fmt(cap)}',
                value: s.stepBank / cap,
                colour: Quiet.mist,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Walked today: ${fmt(controller.stepsToday)}',
              key: const ValueKey('walked-today'),
            ),
            // An overloaded bag (spec 0021 points 15-17).
            ?overloadedLine(context, game, s),
            // The meal running (spec 0011 §8.2); tap for its card. It
            // starts with the meal (spec 0014 §4.2). The socket is 32 dp,
            // the banner size of §2.3, as the design phones 11 and 25 show
            // for an item on one line.
            if (mealLine(game, s) case final line?)
              InkWell(
                key: const ValueKey('meal-line'),
                onTap: () => showItemCard(context, controller, s.meal!.key),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      PictureSocket.item(
                        game.data,
                        s.meal!.key,
                        picture: images.pictureOf(
                          game.data,
                          ItemThing(s.meal!.key),
                        ),
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(line)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The running action and the ones waiting after it (spec 0003 §8).
class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.controller,
    required this.labels,
    this.onOpenWorld,
  });

  final GameController controller;
  final Labels labels;
  final VoidCallback? onOpenWorld;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final s = controller.state;
    final run = s.activity;
    final text = Theme.of(context).textTheme;
    final slots = game.queueSlots(s);
    final places = game.queuePlaces(s);

    final List<Widget> body;
    if (run == null) {
      // Spec 0008 §3.2 (replaces spec 0006 amendment 3).
      body = [
        Text('Resting', style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Your steps go to the step bank. Pick something to do below, or on '
          'the World map.${slots > 1 ? ' Plan up to $slots actions; each starts '
                    'when the one before it stops.' : ''}',
        ),
        const SizedBox(height: 8),
        if (onOpenWorld != null)
          FilledButton.tonalIcon(
            key: const ValueKey('open-world'),
            style: slateButton,
            onPressed: onOpenWorld,
            icon: const Icon(Icons.map),
            label: const Text('Open the World map'),
          ),
      ];
    } else {
      final cost = game.unitCost(s)!;
      final fight = run.fight;
      final enemyHp = run.activity.kind == ActivityKind.fight
          ? game.data.enemies[run.activity.target]!.stats.hp
          : 0;
      body = [
        Row(
          children: [
            // Its picture, numbered like the queued rows below it (2, 3,
            // ...) when the queue has room for more (spec 0014 amendment 8).
            ActionPicture(
              key: const ValueKey('queue-picture-0'),
              data: game.data,
              activity: run.activity,
              number: slots > 1 ? 1 : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _changeable(
                context,
                run.activity,
                0,
                Text(labels.activity(run.activity), style: text.titleMedium),
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('stop-activity'),
              onPressed: () => _stop(context, 0),
              icon: const Icon(Icons.stop),
              label: Text(s.queue.isEmpty ? 'Stop' : 'Stop · next'),
            ),
          ],
        ),
        // A walk and a reroll have no stop condition to show (spec 0014
        // amendment 9, rule 9).
        if (!_noStopLine(run.activity))
          _changeable(
            context,
            run.activity,
            0,
            Text(
              labels.stop(
                run.stop,
                run.activity,
                owned: run.stop.kind == StopKind.untilHave
                    ? game.owned(s, run.stop.item!)
                    : 0,
                crafted: run.crafted,
              ),
            ),
            key: false,
          ),
        const SizedBox(height: 8),
        _Bar(
          label: switch (run) {
            // The title names the place; a walk of more than one stage
            // names the stage under way.
            RunningActivity(:final leg?) when leg != run.activity.target =>
              '${labels.location(leg)} first: '
                  '${fmt(run.progress)} / ${fmt(cost)} steps',
            _ when run.activity.kind == ActivityKind.fight =>
              'Next round: ${run.progress} / $cost steps',
            _ => '${fmt(run.progress)} / ${fmt(cost)} steps',
          },
          value: run.progress / cost,
        ),
        if (fight != null) ...[
          const SizedBox(height: 8),
          _Bar(
            label: 'You: ${fight.playerHp} / ${game.stats(s).hp} HP',
            value: fight.playerHp / game.stats(s).hp,
          ),
          const SizedBox(height: 8),
          _Bar(
            label:
                '${labels.enemy(run.activity.target)}: '
                '${fight.enemyHp} / $enemyHp HP',
            value: fight.enemyHp / enemyHp,
          ),
        ],
        if (run.lossStreak > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Lost ${run.lossStreak} in a row; it gives up at '
            '${game.data.lossesToGiveUp}.',
            style: text.bodySmall,
          ),
        ],
        // How the last fight ended and the fight sheet (spec 0019 §3.1).
        if (run.fights.lastOrNull case final last?) ...[
          const SizedBox(height: 8),
          Text(
            'Last fight: ${labels.lastFight(last, run.activity.target)}',
            key: const ValueKey('last-fight'),
          ),
        ],
        if (run.log.isNotEmpty || run.fights.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('fight-details'),
              onPressed: () => showFightSheet(context),
              child: const Text('Fight details'),
            ),
          ),
        if (run.won + run.lost > 0 || run.gained.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('So far', style: headingStyle(context)),
          if (run.won + run.lost > 0)
            Text(
              '${fmt(run.won)} won · ${fmt(run.lost)} lost',
              key: const ValueKey('tally-fights'),
            ),
          if (run.gained.isNotEmpty)
            KeyedSubtree(
              key: const ValueKey('tally-items'),
              child: reportLine(
                labels.counts(_ordered(run.gained), labels.owned),
                labels,
              ),
            ),
          // Fish records beaten on this run (spec 0011 §8.2).
          if (run.records > 0)
            Text(
              'New records: ${fmt(run.records)}',
              key: const ValueKey('tally-records'),
            ),
        ],
        for (var i = 0; i < s.queue.length; i++)
          ListTile(
            key: ValueKey('queued-$i'),
            contentPadding: EdgeInsets.zero,
            // Its picture, with its number as a badge (spec 0014
            // amendment 8).
            leading: ActionPicture(
              key: ValueKey('queue-picture-${i + 1}'),
              data: game.data,
              activity: s.queue[i].activity,
              number: i + 2,
            ),
            // A walk: its place and its steps from where the queue stands
            // before it (spec 0016 §7.1).
            title: Text(switch (s.queue[i].activity) {
              Activity(kind: ActivityKind.travel, :final target) =>
                'Walk to ${labels.location(target)} · '
                    '${fmt(game.walkSteps(s, places[i], target) ?? 0)} steps',
              final a => labels.short(a),
            }),
            subtitle: _noStopLine(s.queue[i].activity)
                ? null
                : Text(
                    labels.stop(
                      s.queue[i].stop,
                      s.queue[i].activity,
                      owned: s.queue[i].stop.item == null
                          ? 0
                          : game.owned(s, s.queue[i].stop.item!),
                    ),
                  ),
            // A tap changes its stop condition (spec 0016 amendment 2).
            onTap: canChangeStop(s.queue[i].activity)
                ? () => changeAction(context, controller, i + 1)
                : null,
            trailing: IconButton(
              key: ValueKey('remove-${i + 1}'),
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
              onPressed: () => _stop(context, i + 1),
            ),
          ),
        if (slots > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${1 + s.queue.length} of $slots actions planned',
              style: text.bodySmall,
            ),
          ),
      ];
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: body,
        ),
      ),
    );
  }

  /// A walk and a reroll show no stop line: a walk ends at its place, and a
  /// reroll is one roll (spec 0014 amendment 9, rule 9).
  static bool _noStopLine(Activity a) =>
      a.kind == ActivityKind.travel || a.kind == ActivityKind.reroll;

  /// [child] on the queue card: a tap opens the change sheet of the action
  /// at [index] (spec 0016 amendment 2), unless it is a walk or a reroll.
  /// [key] gives it the key `change-<index>`.
  Widget _changeable(
    BuildContext context,
    Activity a,
    int index,
    Widget child, {
    bool key = true,
  }) => canChangeStop(a)
      ? InkWell(
          key: key ? ValueKey('change-$index') : null,
          onTap: () => changeAction(context, controller, index),
          child: child,
        )
      : child;

  /// [gained] in item data order, then quality order, like the inventory.
  /// Items of the same quality count together, whatever their bonus stats
  /// (rows show none: spec 0009 §8.2).
  Map<String, int> _ordered(Map<String, int> gained) {
    final data = controller.game.data;
    final byPlain = <String, int>{};
    gained.forEach((key, n) {
      final plain = data.plainKey(key);
      byPlain[plain] = (byPlain[plain] ?? 0) + n;
    });
    return {
      for (final id in data.items.keys) ...{
        for (final q in data.qualities)
          data.keyFor(id, q.id): ?byPlain[data.keyFor(id, q.id)],
        GameData.perfectKey(id): ?byPlain[GameData.perfectKey(id)],
      },
    };
  }

  /// Removes the action at [index] (0: Stop) and says which waiting actions
  /// couldn't start after it.
  Future<void> _stop(BuildContext context, int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final List<ActionSkipped> skipped;
    try {
      skipped = await controller.removeAction(index);
    } on ActivityError catch (e) {
      // A walk that the next action needs stays (spec 0016 §4.3). One
      // message for the latest tap, not one more in line for each tap.
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    // The queue changed, so older messages about it are out of date.
    messenger.clearSnackBars();
    if (skipped.isEmpty) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          skipped
              .map(
                (e) => labels.skipLine(
                  e.activity,
                  e.reason,
                  e.missing,
                  closedBy: e.closedBy,
                ),
              )
              .join('\n'),
        ),
      ),
    );
  }
}

/// Everything the player's place offers (spec 0008 §3.2): its monsters and
/// gathering spots, its teachers, and a Forge row where there is one. No
/// Camp screen.
class _Here extends StatelessWidget {
  const _Here({
    required this.controller,
    required this.labels,
    this.onOpenProfessions,
  });

  final GameController controller;
  final Labels labels;
  final void Function([String? profession])? onOpenProfessions;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final enemies = game.availableEnemies(c.state);
    final rest = _rows(context, enemies);
    // The status card names the place, so the heading is "Here" (spec 0014
    // §4.1). The rows stand on plates (§2.2): the monsters under their one
    // heading, then the rest.
    return Column(
      key: const ValueKey('here'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Heading('Here'),
        if (enemies.isNotEmpty)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonstersHeading(steps: game.roundSteps(c.state)),
                for (final id in enemies)
                  enemyTile(c, id, drops: dropsLine(game, c.state, labels, id)),
              ],
            ),
          ),
        if (rest.isNotEmpty)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: rest),
          ),
      ],
    );
  }

  /// The rows after the monsters.
  List<Widget> _rows(BuildContext context, List<String> enemies) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final place = game.data.locations[s.location]!;
    final nodes = game.availableNodes(s);
    return [
      for (final id in nodes) nodeTile(c, id),
      // The services first: Bank, Forge, Camp fire, then the teachers and
      // the trainer (spec 0020 amendment 6). The Bank row is a plain row:
      // a tap opens the bank.
      if (place.itemBank)
        ListTile(
          key: const ValueKey('bank-card'),
          leading: const SizedBox(
            width: 32,
            child: Icon(Icons.account_balance),
          ),
          // The plain title of the Forge and the Camp fire: the three
          // services read as one group, the people below in their own face.
          title: const Text('Bank'),
          subtitle: const Text('Store items and take them back'),
          onTap: () => openBank(context),
        ),
      if (place.crafting && onOpenProfessions != null)
        ListTile(
          key: const ValueKey('here-forge'),
          leading: const SizedBox(
            width: 32,
            child: Icon(Icons.local_fire_department),
          ),
          title: const Text('Forge'),
          subtitle: const Text('Craft gear in Professions'),
          onTap: () => onOpenProfessions!('crafting'),
        ),
      // The camp fire opens Cooking (spec 0011 §5.1).
      if (place.fire && onOpenProfessions != null)
        ListTile(
          key: const ValueKey('here-fire'),
          leading: const SizedBox(width: 32, child: Icon(Icons.outdoor_grill)),
          title: const Text('Camp fire'),
          subtitle: const Text('Cook meals in Professions'),
          onTap: () => onOpenProfessions!('cooking'),
        ),
      // The teachers here (spec 0010 §6.1), a dot when a tip waits.
      for (final p in game.data.professions.values)
        if (p.teacher.location == s.location)
          // The rows of Here share the 32 dp of the profession pictures, so
          // their names line up (spec 0014 amendment 7).
          ListTile(
            key: ValueKey('teacher-${p.id}'),
            leading: ProfessionPicture(p),
            title: Text(teacherName(p)),
            titleTextStyle: nameStyle(context),
            subtitle: Text(
              s.learned.contains(p.id)
                  ? '${p.name} ${game.professionLevel(s, p.id)}'
                  : 'Teaches ${p.name}',
            ),
            trailing: game.tipsWaiting(s, p.id).isEmpty
                ? null
                : Badge(key: ValueKey('teacher-dot-${p.id}')),
            onTap: () => showTeacher(context, c, p.id),
          ),
      // The Guild trainer resets the talents (spec 0015 §2.7), a dot when
      // points are left.
      if (game.data.trainer.location == s.location)
        ListTile(
          key: const ValueKey('trainer'),
          leading: const SizedBox(width: 32, child: Icon(Icons.auto_awesome)),
          title: Text(trainerName(game.data.trainer)),
          titleTextStyle: nameStyle(context),
          subtitle: const Text('Talents'),
          trailing: game.talentPointsLeft(s) > 0
              ? const Badge(key: ValueKey('trainer-dot'))
              : null,
          onTap: () => showTrainer(context, c),
        ),
      if (enemies.isEmpty &&
          nodes.isEmpty &&
          !place.crafting &&
          !place.fire &&
          !game.data.professions.values.any(
            (p) => p.teacher.location == s.location,
          ))
        const ListTile(title: Text('Nothing to do here. Try the World map.')),
    ];
  }
}

/// A bar with its number in Spectral (spec 0014 §2.2, §2.3).
/// What the step bank does, and when steps arrive (spec 0014 amendment 6).
Future<void> _showStepBank(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Padding(
      key: const ValueKey('step-bank-sheet'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step bank', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Steps walked while resting are saved here. During an '
            'activity, each step you walk uses one banked step and '
            'counts double.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Steps arrive from Health Connect about once a minute. '
            'Pull down to check now.',
          ),
        ],
      ),
    ),
  ),
);

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, this.colour});

  final String label;
  final double value;

  /// Null for the steel of the theme.
  final Color? colour;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(numberSpan(label)),
      const SizedBox(height: 4),
      LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        color: colour,
      ),
    ],
  );
}
