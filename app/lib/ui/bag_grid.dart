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
    final order = [for (final g in data.gearSlots) g.kind];
    int slotRank(String key) => order.indexOf(data.itemOf(key)!.slot!);
    final gear =
        [
          for (final k in s.inventory.keys)
            if (data.itemOf(k)?.slot != null) k,
        ]..sort((a, b) {
          final bySlot = slotRank(a).compareTo(slotRank(b));
          return bySlot != 0
              ? bySlot
              : data.scoreOf(b).compareTo(data.scoreOf(a));
        });
    final ids = data.items.keys.toList();
    final materials = [
      for (final k in s.inventory.keys)
        if (data.itemOf(k)?.slot == null) k,
    ]..sort((a, b) => ids.indexOf(a).compareTo(ids.indexOf(b)));

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
