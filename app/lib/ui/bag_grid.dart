import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'item_card.dart';
import 'item_square.dart';
import 'kind_chips.dart';

/// One big bag as a grid (spec 0008 §3.5): gear first, by slot order then
/// best first, then materials in data order. Identical items stack. The
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
      items: s.inventory.keys,
      builder: (shown) => GridView.count(
        key: const ValueKey('bag'),
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (final key in shown)
            ItemSquare(
              key: ValueKey('bag-$key'),
              data: data,
              item: key,
              count: s.inventory[key]!,
              // A 48 dp socket in the centre of each cell (spec 0014 §2.3).
              socket: 48,
              onTap: () => showItemCard(context, c, key),
            ),
        ],
      ),
    );
  }
}
