part of '../game.dart';

/// The item bank (spec 0020): items move between the bag and the bank at a
/// place with a bank, and crafts there use both.
extension GameBank on Game {
  /// The bag's spaces: the data's, plus Bigger bag's (spec 0021 rule 1).
  int bagSpaces(GameState s) =>
      data.bagSpaces + talentSum(s, TalentEffect.bagSpaces).round();

  /// One space for each kind of item in the bag (spec 0021 rule 2). Worn
  /// items, the bank and unopened supply chests are not in the bag.
  int spacesUsed(GameState s) => s.inventory.values.where((c) => c > 0).length;

  /// Whether the bag holds more kinds than its spaces (spec 0021 rule 3).
  bool overloaded(GameState s) => spacesUsed(s) > bagSpaces(s);

  /// The share that each unit costs more: a step for each space over, up to
  /// the most (spec 0021 rule 5).
  double overload(GameState s) => math.min(
    data.bagOverloadMax,
    data.bagOverloadStep * math.max(0, spacesUsed(s) - bagSpaces(s)),
  );

  /// The factor on the steps of a unit of [a] here: 1 + [overload], but 1
  /// for a craft, cook or reroll at a place with a bank (spec 0021 rules 6,
  /// 7). A travel leg always takes it.
  double loadFactor(GameState s, Activity a, {bool leg = false}) {
    final atBench =
        !leg && (a.kind == ActivityKind.craft || a.kind == ActivityKind.reroll);
    if (atBench && hasBank(s.location)) return 1;
    return 1 + overload(s);
  }

  /// Whether [location] has an item bank (spec 0020 decision 1).
  bool hasBank(String location) => data.locations[location]?.itemBank ?? false;

  /// Moves [count] of [key] from the bag to the bank (spec 0020 rule 2). No
  /// steps, no roll. Worn items are not in the bag, so they cannot move.
  GameState store(GameState s, String key, int count) {
    _checkMove(s, s.inventory[key] ?? 0, count, 'in the bag');
    final n = s.copy()..addItem(key, -count);
    n.itemBank[key] = (n.itemBank[key] ?? 0) + count;
    return n;
  }

  /// Moves [count] of [key] from the bank to the bag (spec 0020 rule 3).
  GameState take(GameState s, String key, int count) {
    _checkMove(s, s.itemBank[key] ?? 0, count, 'in the bank');
    final n = s.copy()..addItem(key, count);
    _takeFromBank(n, key, count);
    return n;
  }

  void _checkMove(GameState s, int have, int count, String where) {
    if (!hasBank(s.location)) {
      throw ActivityError('Items move only at a bank.');
    }
    if (count < 1 || count > have) {
      throw ActivityError('Not that many $where.');
    }
  }

  void _takeFromBank(GameState s, String key, int count) {
    final left = (s.itemBank[key] ?? 0) - count;
    if (left > 0) {
      s.itemBank[key] = left;
    } else {
      s.itemBank.remove(key);
    }
  }

  /// Whether a craft of [recipe] uses the bank: it happens at a place with
  /// a bank, here or where the queue walks to (spec 0020 rules 7-9).
  bool craftUsesBank(GameState s, String recipe) {
    final a = Activity.craft(recipe);
    final place = _happensAt(s.location, a) ? s.location : _placeFor(s, a);
    return place != null && hasBank(place);
  }

  /// The items that a craft of [recipe] can use: the bag, and the bank when
  /// the craft happens at a place with a bank.
  Map<String, int> materialsFor(GameState s, String recipe) {
    // An empty bank needs no path search (the sims call this often).
    if (s.itemBank.isEmpty || !craftUsesBank(s, recipe)) return s.inventory;
    final all = Map.of(s.inventory);
    s.itemBank.forEach((k, v) => all[k] = (all[k] ?? 0) + v);
    return all;
  }

  /// Takes [count] of [key] for a craft: from the bag first, then from the
  /// bank at a place with a bank (spec 0020 rule 7).
  void _useInput(GameState s, String key, int count) {
    final fromBag = math.min(count, s.inventory[key] ?? 0);
    s.addItem(key, -fromBag);
    if (count > fromBag && hasBank(s.location)) {
      _takeFromBank(s, key, count - fromBag);
    }
  }
}
