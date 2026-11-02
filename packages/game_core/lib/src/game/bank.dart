part of '../game.dart';

/// The item bank (spec 0020): items move between the bag and the bank at a
/// place with a bank, and crafts there use both.
extension GameBank on Game {
  /// Whether [location] has an item bank (spec 0020 decision 1).
  bool hasBank(String location) => data.locations[location]?.bank ?? false;

  /// Moves [count] of [key] from the bag to the bank (spec 0020 rule 2). No
  /// steps, no roll. Worn items are not in the bag, so they cannot move.
  GameState store(GameState s, String key, int count) {
    _checkMove(s, s.inventory[key] ?? 0, count, 'in the bag');
    final n = s.copy()..addItem(key, -count);
    n.bankItems[key] = (n.bankItems[key] ?? 0) + count;
    return n;
  }

  /// Moves [count] of [key] from the bank to the bag (spec 0020 rule 3).
  GameState take(GameState s, String key, int count) {
    _checkMove(s, s.bankItems[key] ?? 0, count, 'in the bank');
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
    final left = (s.bankItems[key] ?? 0) - count;
    if (left > 0) {
      s.bankItems[key] = left;
    } else {
      s.bankItems.remove(key);
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
    if (s.bankItems.isEmpty || !craftUsesBank(s, recipe)) return s.inventory;
    final all = Map.of(s.inventory);
    s.bankItems.forEach((k, v) => all[k] = (all[k] ?? 0) + v);
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
