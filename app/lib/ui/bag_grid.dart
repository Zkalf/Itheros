import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'item_card.dart';
import 'item_square.dart';

/// One big bag as a grid (spec 0008 §3.5): gear first, by slot order then
/// best first, then materials in data order. Identical items stack.
class BagGrid extends StatelessWidget {
  const BagGrid({super.key, required this.controller});

  final GameController controller;

  /// Squares to a row on the phone.
  static const columns = 5;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final data = c.game.data;
    final s = c.state;
    if (s.inventory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Nothing yet. Fight and gather to find things.'),
      );
    }
    // Ties fall back to data order, then quality order, so squares never
    // move when something is equipped (spec 0005 §5).
    final slotRank = <String, int>{};
    for (final g in data.gearSlots) {
      slotRank.putIfAbsent(g.kind, () => slotRank.length);
    }
    final itemRank = {for (final (i, id) in data.items.keys.indexed) id: i};
    final qualityRank = {for (final (i, q) in data.qualities.indexed) q.id: i};
    int stable(String a, String b) {
      final byItem = (itemRank[data.itemOf(a)?.id] ?? 1 << 20).compareTo(
        itemRank[data.itemOf(b)?.id] ?? 1 << 20,
      );
      if (byItem != 0) return byItem;
      return qualityRank[data.qualityOf(a).id]!.compareTo(
        qualityRank[data.qualityOf(b).id]!,
      );
    }

    final gear =
        [
          for (final k in s.inventory.keys)
            if (data.itemOf(k)?.slot != null) k,
        ]..sort((a, b) {
          final bySlot = slotRank[data.itemOf(a)!.slot]!.compareTo(
            slotRank[data.itemOf(b)!.slot]!,
          );
          if (bySlot != 0) return bySlot;
          final byScore = data.scoreOf(b).compareTo(data.scoreOf(a));
          return byScore != 0 ? byScore : stable(a, b);
        });
    final materials = [
      for (final k in s.inventory.keys)
        if (data.itemOf(k)?.slot == null) k,
    ]..sort(stable);

    return GridView.count(
      key: const ValueKey('bag'),
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final key in [...gear, ...materials])
          ItemSquare(
            key: ValueKey('bag-$key'),
            data: data,
            item: key,
            count: s.inventory[key]!,
            onTap: () => showItemCard(context, c, key),
          ),
      ],
    );
  }
}
