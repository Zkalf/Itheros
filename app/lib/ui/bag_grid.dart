import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'item_card.dart';
import 'item_square.dart';
import 'kind_chips.dart';

/// One big bag as a grid (spec 0008 §3.5): gear first, by slot order then
/// best first, then materials in data order. Identical items stack, one
/// square for each stack, full stacks first (spec 0021 amendment 4). The
/// chips above it show one kind at a time (spec 0020 amendment 2).
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
    // The chips of the four kinds above the grid (spec 0020 amendment 2).
    return KindFilter(
      controller: c,
      list: 'bag',
      items: s.inventory,
      builder: (shown) => GridView.count(
        key: const ValueKey('bag'),
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (final key in shown)
            for (final (i, n) in stacks(
              s.inventory[key]!,
              data.stackOf(key),
            ).indexed)
              ItemSquare(
                // The first square keeps the item's key; the next ones count
                // on from 2.
                key: ValueKey(i == 0 ? 'bag-$key' : 'bag-$key-${i + 1}'),
                data: data,
                item: key,
                count: n,
                // A 48 dp socket in the centre of each cell (spec 0014 §2.3).
                socket: 48,
                // Each square opens the card of the whole item (rule 7).
                onTap: () => showItemCard(context, c, key),
              ),
        ],
      ),
    );
  }
}

/// [count] split into stacks of [size]: full stacks first, then the rest.
/// 237 in stacks of 100 gives 100, 100, 37 (spec 0021 amendment 4, rule 6).
List<int> stacks(int count, int size) => [
  for (var left = count; left > 0; left -= size) left < size ? left : size,
];
