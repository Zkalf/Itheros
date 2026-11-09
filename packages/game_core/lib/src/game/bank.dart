part of '../game.dart';

/// The item bank (spec 0020): items move between the bag and the bank at a
/// place with a bank, and crafts there use both.
extension GameBank on Game {
  /// The bag's spaces: the data's, plus Bigger bag's (spec 0021 rule 1).
  int bagSpaces(GameState s) =>
      data.bagSpaces + talentSum(s, TalentEffect.bagSpaces).round();

  /// The spaces that [count] of [key] use in the bag: one for each stack, or
  /// part of one (spec 0021 amendment 4, rule 2).
  int spacesOf(String key, int count) {
    if (count <= 0) return 0;
    final stack = data.stackOf(key);
    return (count + stack - 1) ~/ stack;
  }

  /// The spaces of all the bag's items (spec 0021 amendment 4, rule 2). Worn
  /// items, the bank and unopened supply chests are not in the bag.
  int spacesUsed(GameState s) =>
      s.inventory.entries.fold(0, (n, e) => n + spacesOf(e.key, e.value));

  /// The spaces the bag would use with [n] more of [key]: a new stack may
  /// need a new space (spec 0021 amendment 4, rule 2).
  int spacesWith(GameState s, String key, int n) {
    final had = s.inventory[key] ?? 0;
    return spacesUsed(s) - spacesOf(key, had) + spacesOf(key, had + n);
  }

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

  /// Destroys [count] of [key] for good, from the bag or, with [fromBank],
  /// from the item bank (spec 0021 amendment 2, rules 1-5). Anywhere, no
  /// steps, nothing back. Worn items are not in the bag, so they cannot go.
  GameState destroy(
    GameState s,
    String key,
    int count, {
    bool fromBank = false,
  }) {
    final have = (fromBank ? s.itemBank : s.inventory)[key] ?? 0;
    if (count < 1 || count > have) {
      throw ActivityError(
        'Not that many ${fromBank ? 'in the bank' : 'in the bag'}.',
      );
    }
    final n = s.copy();
    if (fromBank) {
      _takeFromBank(n, key, count);
    } else {
      n.addItem(key, -count);
    }
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

  /// The dust that reroll [a] can use: the bag, and the bank when the
  /// reroll happens at a place with a bank (spec 0020 amendment 1).
  int _dustFor(GameState s, Activity a) {
    final dust = _rerollDust(a);
    final bag = s.inventory[dust] ?? 0;
    if ((s.itemBank[dust] ?? 0) == 0) return bag;
    final place = _happensAt(s.location, a) ? s.location : _placeFor(s, a);
    if (place == null || !hasBank(place)) return bag;
    return bag + s.itemBank[dust]!;
  }

  /// Whether the dust after the queue pays for reroll [a] added now: the
  /// bag after the queue, and the bank when the reroll happens at a place
  /// with a bank (spec 0010 amendment 5 §3.1, spec 0020 amendment 1, #178).
  bool rerollPaid(GameState s, Activity a) {
    final end = queuePlaces(s).last;
    final place = _happensAt(end, a) ? end : _placeFor(s, a, from: end);
    final withBank = place != null && hasBank(place);
    final have = bagAfterQueue(s, withBank: withBank)[_rerollDust(a)] ?? 0;
    return have >= data.rerollDust;
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

  /// Takes [count] of [key] for a craft or a reroll: from the bag first,
  /// then from the bank at a place with a bank (spec 0020 rule 7,
  /// amendment 1).
  void _useInput(GameState s, String key, int count) {
    final fromBag = math.min(count, s.inventory[key] ?? 0);
    s.addItem(key, -fromBag);
    if (count > fromBag && hasBank(s.location)) {
      _takeFromBank(s, key, count - fromBag);
    }
  }
}
