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
}
