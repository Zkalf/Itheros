import 'package:game_core/game_core.dart';

import '../sync/away_summary.dart';

/// 12345 -> "12,345".
String fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// (1, 'step') -> "1 step"; (1200, 'step') -> "1,200 steps".
String plural(int n, String noun) => '${fmt(n)} $noun${n == 1 ? '' : 's'}';

/// Display names from the game data.
class Labels {
  Labels(this.data);

  final GameData data;

  String location(String id) => data.locations[id]?.name ?? id;
  String enemy(String id) => data.enemies[id]?.name ?? id;
  String node(String id) => data.nodes[id]?.name ?? id;

  /// An item's name; gear better than common adds its quality: "Bone sword
  /// (Rare)" (spec 0005 decision 3).
  String item(String key) {
    final item = data.itemOf(key);
    if (item == null) return key;
    final q = data.qualityOf(key);
    return q == data.qualities.first ? item.name : '${item.name} (${q.name})';
  }

  /// A piece of gear you own, always with its quality: "Hide vest (Common)",
  /// "Bone sword (Rare)". Materials keep their plain name.
  String owned(String key) {
    final item = data.itemOf(key);
    if (item == null) return key;
    if (item.slot == null) return item.name;
    return '${item.name} (${data.qualityOf(key).name})';
  }

  String qualityName(String id) =>
      data.qualities.where((q) => q.id == id).firstOrNull?.name ?? id;

  /// A fight log line (spec 0006 decision 8): "Round 3 · You hit for 6 ·
  /// Skeleton hits for 3", ending with who was beaten.
  String round(RoundLog r, String enemyId) => [
    'Round ${r.round}',
    if (r.dealt case final d?) 'You hit for $d',
    if (r.taken case final t?) '${enemy(enemyId)} hits for $t',
    if (r.outcome == FightOutcome.won) '${enemy(enemyId)} is beaten',
    if (r.outcome == FightOutcome.lost) 'You are beaten',
  ].join(' · ');

  String recipe(String id) => item(data.recipes[id]?.output ?? id);
  String achievement(String id) => data.achievements[id]?.name ?? id;

  String activity(Activity a) => switch (a.kind) {
    ActivityKind.travel => 'Walking to ${location(a.target)}',
    ActivityKind.fight => 'Fighting ${enemy(a.target)}s',
    ActivityKind.gather => 'Mining ${node(a.target)}',
    ActivityKind.craft => 'Crafting ${recipe(a.target)}',
  };

  /// Why an action ended, as a sentence without the full stop.
  String endReason(Activity a, EndReason r) => switch (r) {
    EndReason.arrived => 'Arrived at ${location(a.target)}',
    EndReason.defeated => 'Gave up after 3 losses in a row',
    EndReason.grey => 'Stopped: the ${enemy(a.target)} turned grey',
    EndReason.enough => 'Stopped: goal reached',
    EndReason.noMaterials => 'Stopped: out of materials',
  };

  /// A stop condition, with progress toward it (spec 0003 §3).
  String stop(
    StopCondition c,
    Activity a, {
    required int owned,
    int crafted = 0,
  }) => switch (c.kind) {
    StopKind.untilGrey => 'Until it turns grey',
    StopKind.untilHave =>
      'Until you have ${fmt(c.count)} ${item(c.item!)} '
          '(${fmt(owned)} / ${fmt(c.count)})',
    StopKind.untilCrafted =>
      'Until ${fmt(c.count)} crafted (${fmt(crafted)} / ${fmt(c.count)})',
    StopKind.untilQuality => 'Until ${qualityName(c.item!)} or better',
    StopKind.never => switch (a.kind) {
      ActivityKind.travel => 'Until you arrive',
      ActivityKind.craft => 'Until materials run out',
      _ => 'Keeps going',
    },
  };

  /// Why a queued action never started. [missing]: what a craft lacked.
  String skipReason(
    Activity a,
    SkipReason r, {
    Map<String, int> missing = const {},
  }) => switch (r) {
    SkipReason.locked => 'not unlocked yet',
    SkipReason.noRoute => 'no open route there',
    SkipReason.noMaterials when missing.isNotEmpty =>
      'not enough ${missing.entries.map((e) => '${item(e.key)} (needs ${fmt(e.value)} more)').join(', ')}',
    SkipReason.noMaterials => 'not enough materials',
    SkipReason.alreadyDone => switch (a.kind) {
      ActivityKind.travel => 'you were already there',
      ActivityKind.fight => 'it was already grey or the goal was reached',
      _ => 'the goal was already reached',
    },
  };

  /// "Skipped the Bone shield: not enough Bones (needs 2 more)."
  String skipLine(Activity a, SkipReason r, Map<String, int> missing) =>
      'Skipped the ${short(a)}: ${skipReason(a, r, missing: missing)}.';

  /// A short name for an action: "Skeleton", "Copper vein", "Bone sword".
  String short(Activity a) => switch (a.kind) {
    ActivityKind.travel => 'walk to ${location(a.target)}',
    ActivityKind.fight => enemy(a.target),
    ActivityKind.gather => node(a.target),
    ActivityKind.craft => recipe(a.target),
  };

  /// The report lines for one action (spec 0003 §7), ending with the action
  /// that started after it.
  List<String> actionLines(ActionLog log) {
    final a = log.activity;
    if (log.skipped case final why?) {
      return [skipLine(a, why, log.missing)];
    }
    final gains = [
      if (log.wins > 0) plural(log.wins, 'win'),
      if (log.xp > 0) '+${fmt(log.xp)} XP',
      if (log.items.isNotEmpty) counts(log.items, owned),
    ];
    final ended = log.ended;
    final then = log.next != null ? ' Next: ${short(log.next!)}.' : '';
    final lines = <String>[
      if (a.kind != ActivityKind.travel)
        '${switch (a.kind) {
              ActivityKind.fight => 'Fought the ${enemy(a.target)}',
              ActivityKind.gather => 'Mined the ${node(a.target)}',
              _ => 'Crafted the ${recipe(a.target)}',
            }}${gains.isEmpty ? '' : ': ${gains.join(', ')}'}.'
            '${ended == null ? '' : ' ${endReason(a, ended)}.'}$then'
      else if (ended == EndReason.arrived)
        'Arrived at ${location(a.target)}.$then',
      for (final l in log.losses.take(3))
        'Lost to the ${enemy(l.enemy)} (knocked off '
            '${(l.share * 100).round()}% of its health), +${fmt(l.xp)} XP.',
      if (log.losses.length > 3)
        '…and ${log.losses.length - 3} more '
            '${log.losses.length == 4 ? 'loss' : 'losses'}.',
      for (final enemy in {for (final l in log.losses) l.enemy})
        ?data.enemies[enemy]?.lossHint,
    ];
    return lines;
  }

  String counts(Map<String, int> m, String Function(String) name) =>
      m.entries.map((e) => '${name(e.key)} ×${e.value}').join(', ');

  /// Where [enemy] or [node] lives.
  String homeOf(String id) => location(
    data.locations.values
        .firstWhere((l) => l.enemies.contains(id) || l.nodes.contains(id))
        .id,
  );

  String slot(String id) => id[0].toUpperCase() + id.substring(1);

  /// One "What's new" line of a level-up card (spec 0002 §9.1).
  String news(LevelNews n) => switch (n.kind) {
    NewsKind.rank => data.ranks.firstWhere((r) => r.name == n.id).line,
    NewsKind.area => 'New area: ${location(n.id)}',
    NewsKind.monster => 'New monster: ${enemy(n.id)} (${homeOf(n.id)})',
    NewsKind.gatheringSpot => 'You can now mine the ${node(n.id)}',
    NewsKind.recipe => 'New recipe: ${recipe(n.id)}',
    NewsKind.gearSlot => 'New gear slot: ${slot(n.id)}',
    NewsKind.talentPoint =>
      '+1 talent point. Talents arrive in a later update; your points wait '
          'for you.',
    NewsKind.yourLevel => 'The ${enemy(n.id)} is now your level',
    NewsKind.queueSlots =>
      'Your queue now holds ${n.id} actions: plan ahead, and the next one starts by itself',
    NewsKind.untilN =>
      'New stop condition: "until I have N" (and "until N crafted")',
    NewsKind.turnedGrey =>
      'The ${enemy(n.id)} turned grey: little XP, but it still drops its loot',
  };

  /// The "Next goal" line (spec 0002 §9.3). [grey] marks a grey source.
  String goal(Goal g, {required bool canCraftHere, bool grey = false}) =>
      switch (g) {
        EquipGoal(:final item) => 'Equip the ${owned(item)} (Character tab).',
        CraftGoal(:final recipe) =>
          'Craft the ${this.recipe(recipe)}'
              '${canCraftHere ? ' here' : ' at Camp or an outpost'}.',
        CollectGoal(:final item, :final count, :final source) =>
          switch (source.kind) {
                ActivityKind.gather =>
                  'Mine ${fmt(count)} more ${this.item(item)} at '
                      '${homeOf(source.target)}.',
                _ =>
                  'Get ${fmt(count)} more ${this.item(item)} from the '
                      '${enemy(source.target)} in ${homeOf(source.target)}.',
              } +
              (grey ? ' Grey monsters still drop their loot.' : ''),
        FightGoal(:final enemy) =>
          'The ${this.enemy(enemy)} in ${homeOf(enemy)} is your level.',
      };
}
