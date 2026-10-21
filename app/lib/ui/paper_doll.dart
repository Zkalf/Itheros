import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'item_square.dart';
import 'slot_sheet.dart';

/// The classic equipment view (spec 0008 §3.5): a plain figure outline with
/// slots around it. Left: Head to Trinket 1; right: Gloves to Trinket 2;
/// bottom: both hands (amendment 3). Empty slots show a faint outline.
class PaperDoll extends StatelessWidget {
  const PaperDoll({super.key, required this.controller});

  final GameController controller;

  // Spec 0008 amendment 3: the hands alone in the bottom row, the trinkets at
  // the foot of the columns.
  static const _left = [
    'head',
    'neck',
    'shoulder',
    'cloak',
    'chest',
    'bracer',
    'trinket1',
  ];
  static const _right = [
    'gloves',
    'belt',
    'legs',
    'boots',
    'ring1',
    'ring2',
    'trinket2',
  ];
  static const _bottom = ['mainHand', 'offHand'];

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
          // Any slot, empty or not, opens its sheet (amendment 3).
          onTap: () => showSlotSheet(context, c, id),
        ),
      );
    }

    Widget column(List<String> ids) =>
        Column(children: [for (final id in ids) slot(id)]);

    // Slots added in data later (a data-only change) join the bottom row,
    // so worn gear always shows.
    final placed = {..._left, ..._right, ..._bottom};
    final bottom = [
      ..._bottom,
      for (final g in data.gearSlots)
        if (!placed.contains(g.id)) g.id,
    ];

    return LayoutBuilder(
      builder: (context, box) {
        // Two slot columns and the figure share the width; squares stay
        // tappable on a phone.
        final side = (box.maxWidth / 4.5).clamp(48.0, 72.0);
        return Column(
          key: const ValueKey('paper-doll'),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: side, child: column(_left)),
                Expanded(
                  child: Icon(
                    Icons.accessibility_new,
                    size: side * 2.5,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                SizedBox(width: side, child: column(_right)),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final id in bottom) SizedBox(width: side, child: slot(id)),
              ],
            ),
          ],
        );
      },
    );
  }
}
