import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';

/// The word on the chip of each kind (spec 0020 amendment 2, rule 3).
String itemKindName(ItemKind k) => switch (k) {
  ItemKind.gear => 'Gear',
  ItemKind.tool => 'Tools',
  ItemKind.meal => 'Meals',
  ItemKind.material => 'Materials',
};

/// The chips All, Gear, Tools, Meals and Materials above a list of items,
/// and the list of the picked kind below them, in the bag's order (spec 0020
/// amendment 2, rules 3-11). [list] names the list whose pick the controller
/// keeps (see `GameController.kindPicks`).
class KindFilter extends StatefulWidget {
  const KindFilter({
    super.key,
    required this.controller,
    required this.list,
    required this.items,
    required this.builder,
  });

  final GameController controller;
  final String list;

  /// The item keys of the list, in any order.
  final Iterable<String> items;

  /// Draws the items of the picked kind, in the bag's order. Never called
  /// with no items.
  final Widget Function(List<String> shown) builder;

  @override
  State<KindFilter> createState() => _KindFilterState();
}

class _KindFilterState extends State<KindFilter> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final data = c.game.data;
    final picked = c.kindPicks[widget.list];
    final shown = [
      for (final k in bagOrder(data, widget.items))
        if (picked == null || data.kindOf(k) == picked) k,
    ];
    Widget chip(String id, String label, ItemKind? kind) => ChoiceChip(
      key: ValueKey('kind-${widget.list}-$id'),
      label: Text(label),
      selected: picked == kind,
      onSelected: (_) => setState(() {
        if (kind == null) {
          c.kindPicks.remove(widget.list);
        } else {
          c.kindPicks[widget.list] = kind;
        }
      }),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            chip('all', 'All', null),
            for (final k in ItemKind.values) chip(k.name, itemKindName(k), k),
          ],
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            key: ValueKey('kind-${widget.list}-empty'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text('Nothing of this kind here.'),
          )
        else
          widget.builder(shown),
      ],
    );
  }
}
