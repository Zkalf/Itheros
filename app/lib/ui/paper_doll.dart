import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'item_card.dart';
import 'item_square.dart';
import 'slot_sheet.dart';

/// The worn gear (spec 0008 §3.5): the 16 slots in a plain grid of four
/// columns, with no figure (amendment 8). Empty slots show a faint outline.
class PaperDoll extends StatelessWidget {
  const PaperDoll({super.key, required this.controller});

  final GameController controller;

  // Head, Chest, Belt and Legs down the second column; the pairs in the
  // outer columns (amendment 8, change 2).
  static const _rows = [
    ['shoulder', 'head', 'neck', 'cloak'],
    ['mainHand', 'chest', 'gloves', 'offHand'],
    ['ring1', 'belt', 'bracer', 'ring2'],
    ['trinket1', 'legs', 'boots', 'trinket2'],
  ];

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final data = c.game.data;
    final s = c.state;
    final twoHanded =
        data.itemOf(s.equipment['mainHand'] ?? '')?.twoHanded ?? false;

    Widget slot(String id) {
      final worn = s.equipment[id];
      return Padding(
        padding: const EdgeInsets.all(3),
        child: ItemSquare(
          key: ValueKey('slot-$id'),
          data: data,
          item: worn,
          emptySlot: id,
          dimmed: id == 'offHand' && twoHanded && worn == null,
          // A filled slot opens the card of its item, an empty one its sheet
          // (amendment 4). An item the data no longer has (an old save) has
          // no card, so its sheet opens, with Unequip.
          onTap: () => worn == null || data.itemOf(worn) == null
              ? showSlotSheet(context, c, id)
              : showItemCard(context, c, worn, wornIn: id),
        ),
      );
    }

    // Only slots the data has (a renamed slot must not crash its sheet).
    final known = {for (final g in data.gearSlots) g.id};
    // Slots added in data later (a data-only change) join a last row, so
    // worn gear always shows.
    final placed = {for (final r in _rows) ...r};
    final extra = [
      for (final g in data.gearSlots)
        if (!placed.contains(g.id)) g.id,
    ];
    final columns = _rows.first.length;

    return LayoutBuilder(
      builder: (context, box) {
        // The squares share the width; they stay tappable on a phone.
        final side = (box.maxWidth / columns).clamp(48.0, 72.0);
        Widget cell(String id) =>
            SizedBox(width: side, child: known.contains(id) ? slot(id) : null);
        return Column(
          key: const ValueKey('paper-doll'),
          children: [
            for (final r in _rows)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [for (final id in r) cell(id)],
              ),
            if (extra.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                children: [for (final id in extra) cell(id)],
              ),
          ],
        );
      },
    );
  }
}
