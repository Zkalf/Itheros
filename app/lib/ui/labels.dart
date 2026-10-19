import 'package:game_core/game_core.dart';

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
  String item(String id) => data.items[id]?.name ?? id;
  String recipe(String id) => item(data.recipes[id]?.output ?? id);
  String achievement(String id) => data.achievements[id]?.name ?? id;

  String activity(Activity a) => switch (a.kind) {
    ActivityKind.travel => 'Walking to ${location(a.target)}',
    ActivityKind.fight => 'Fighting ${enemy(a.target)}s',
    ActivityKind.gather => 'Mining ${node(a.target)}',
    ActivityKind.craft => 'Crafting ${recipe(a.target)}',
  };

  String endReason(ActivityEnded e) => switch (e.reason) {
    EndReason.arrived => 'Arrived at ${location(e.activity.target)}',
    EndReason.defeated => 'Defeated by the ${enemy(e.activity.target)}',
    EndReason.noMaterials =>
      'Out of materials for ${recipe(e.activity.target)}',
  };

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
    NewsKind.turnedGrey =>
      'The ${enemy(n.id)} turned grey: little XP, but it still drops its loot',
  };

  /// The "Next goal" line (spec 0002 §9.3). [grey] marks a grey source.
  String goal(Goal g, {required bool canCraftHere, bool grey = false}) =>
      switch (g) {
        EquipGoal(:final item) =>
          'Equip the ${this.item(item)} (Character tab).',
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
