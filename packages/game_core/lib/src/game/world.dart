part of '../game.dart';

/// The world: step costs, what is where, the fog and hidden places.
extension GameWorld on Game {
  int _costOf(GameState s, RunningActivity act) {
    final a = act.activity;
    if (act.leg case final leg?) return data.route(s.location, leg)!.steps;
    return switch (a.kind) {
      // A version 2 save walking to a neighbour, with no leg set.
      ActivityKind.travel => data.route(s.location, a.target)!.steps,
      ActivityKind.fight => data.combatRoundSteps,
      ActivityKind.gather => switch (data.nodes[a.target]!) {
        final n => professionSteps(s, n.profession, n.steps),
      },
      ActivityKind.craft => switch (data.recipes[a.target]!) {
        final r => professionSteps(s, r.profession, r.steps),
      },
      ActivityKind.reroll =>
        (data.rerollSteps * (1 - mealStepShare(s)) - 1e-9).ceil(),
    };
  }

  // Queries for the UI. Nothing is locked but gathering spots and recipes,
  // by profession (spec 0010 §2), which still show; fogged areas show
  // nothing.

  List<String> availableEnemies(GameState s) => _here(s).enemies;

  /// Spots here, those above the player's level included (see
  /// [nodeLevelMet]).
  List<String> availableNodes(GameState s) => _here(s).nodes;

  /// Whether [r] is made at [l]: crafts at a forge, meals at a fire (spec
  /// 0011 §5.1).
  bool _makesHere(LocationDef l, RecipeDef r) =>
      r.profession == 'cooking' ? l.fire : l.crafting;

  /// Whether the player has learned [node]'s profession and has the level
  /// to work it (spec 0010 §2.2).
  bool nodeLevelMet(GameState s, String node) {
    final n = data.nodes[node]!;
    return _canPractise(s, n.profession, n.level);
  }

  /// Whether the player has learned Crafting and has the level for
  /// [recipe].
  bool recipeLevelMet(GameState s, String recipe) {
    final r = data.recipes[recipe]!;
    return _canPractise(s, r.profession, r.craftingLevel);
  }

  bool _canPractise(GameState s, String profession, int level) =>
      s.learned.contains(profession) &&
      s.tools.containsKey(profession) &&
      level <= professionLevel(s, profession);

  /// Open locations, nearest first, with their walking distance from here
  /// (spec 0003 §8: plan a day from anywhere).
  Map<String, int> openLocationsByDistance(GameState s) {
    final dist = _paths(s).$1;
    return Map.fromEntries(
      dist.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
    );
  }

  /// Monsters at [location], unless it is fogged.
  List<String> enemiesAt(GameState s, String location) =>
      isFogged(s, location) ? const [] : data.locations[location]!.enemies;

  /// Gathering spots at [location], unless it is fogged.
  List<String> nodesAt(GameState s, String location) =>
      isFogged(s, location) ? const [] : data.locations[location]!.nodes;

  /// Every recipe (they can be crafted at any crafting place).
  List<String> allRecipes() => data.recipes.keys.toList();

  /// Whether [area] is in the fog: neither explored nor joined by a route to
  /// an explored area (spec 0008 decision 5).
  /// A hidden area is fogged until revealed, whatever its neighbours (spec
  /// 0011 §6.2).
  bool isFogged(GameState s, String area) =>
      isHidden(s, area) ||
      !s.explored.contains(area) &&
          !data.destinationsFrom(area).any(s.explored.contains);

  /// Whether [area] is hidden and not yet revealed: off the map and out of
  /// every list (spec 0011 §6.2).
  bool isHidden(GameState s, String area) =>
      data.locations[area]!.hidden && !s.revealed.contains(area);

  /// The nearest open crafting place and its distance, or null if none is
  /// reachable.
  (String, int)? nearestForge(GameState s) {
    final dist = _paths(s).$1;
    (String, int)? best;
    for (final l in data.locations.values) {
      final d = dist[l.id];
      if (l.crafting && d != null && (best == null || d < best.$2)) {
        best = (l.id, d);
      }
    }
    return best;
  }

  /// Every item [enemy] can drop, boss uniques last, each once.
  List<String> dropItems(String enemy) => {
    for (final d in data.enemies[enemy]!.drops) d.item,
    for (final d in data.enemies[enemy]!.firstKillDrops) d.item,
  }.toList();
}
