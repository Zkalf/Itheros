import 'package:game_core/game_core.dart';

import 'labels.dart';

/// The orders of a list of items (spec 0020 amendment 4, rule 10).
enum ItemSort { bagOrder, name, count, quality }

/// The word of each sort on the sort button and in its menu.
String itemSortName(ItemSort s) => switch (s) {
  ItemSort.bagOrder => 'Bag order',
  ItemSort.name => 'Name',
  ItemSort.count => 'Count',
  ItemSort.quality => 'Quality',
};

/// The keys of [items] that match [kind] (null is All) and [search], in the
/// order of [sort] (spec 0020 amendment 4, rules 2-11). Ties keep the bag's
/// order.
List<String> itemsShown(
  GameData data,
  Map<String, int> items, {
  ItemKind? kind,
  String search = '',
  ItemSort sort = ItemSort.bagOrder,
}) {
  final labels = Labels(data);
  final text = search.trim().toLowerCase();
  // The words of an item: its name, its quality and "Perfect" (rule 5).
  String words(String k) => [
    data.itemOf(k)?.name ?? k,
    data.qualityOf(k).name,
    if (data.isPerfect(k)) 'Perfect',
  ].join(' ').toLowerCase();
  final shown = [
    for (final k in bagOrder(data, items.keys))
      if ((kind == null || data.kindOf(k) == kind) &&
          (text.isEmpty || words(k).contains(text)))
        k,
  ];
  if (sort == ItemSort.bagOrder) return shown;
  final bagRank = {for (final (i, k) in shown.indexed) k: i};
  final qualityRank = {for (final (i, q) in data.qualities.indexed) q.id: i};
  int by(String a, String b) => switch (sort) {
    ItemSort.bagOrder => 0,
    ItemSort.name =>
      labels.item(a).toLowerCase().compareTo(labels.item(b).toLowerCase()),
    ItemSort.count => items[b]!.compareTo(items[a]!),
    ItemSort.quality => () {
      final q = qualityRank[data.qualityOf(b).id]!.compareTo(
        qualityRank[data.qualityOf(a).id]!,
      );
      if (q != 0) return q;
      // A Perfect meal comes before the other items of its quality.
      return (data.isPerfect(b) ? 1 : 0).compareTo(data.isPerfect(a) ? 1 : 0);
    }(),
  };
  // List.sort is not stable, so the bag's order breaks the ties (rule 11).
  return shown..sort((a, b) {
    final r = by(a, b);
    return r != 0 ? r : bagRank[a]!.compareTo(bagRank[b]!);
  });
}
