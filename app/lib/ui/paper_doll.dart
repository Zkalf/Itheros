import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'item_card.dart';
import 'item_square.dart';

/// The classic equipment view (spec 0008 §3.5): a plain figure outline with
/// slots around it. Left: Head to Bracer; right: Gloves to Ring 2; bottom:
/// the trinkets and both hands. Empty slots show a faint outline.
class PaperDoll extends StatelessWidget {
  const PaperDoll({super.key, required this.controller});

  final GameController controller;

  static const _left = ['head', 'neck', 'shoulder', 'cloak', 'chest', 'bracer'];
  static const _right = ['gloves', 'belt', 'legs', 'boots', 'ring1', 'ring2'];
  static const _bottom = ['trinket1', 'trinket2', 'mainHand', 'offHand'];

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
          onTap: worn == null
              ? null
              : () => showItemCard(context, c, worn, wornIn: id),
        ),
      );
    }

    Widget column(List<String> ids) =>
        Column(children: [for (final id in ids) slot(id)]);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final id in _bottom)
                  SizedBox(width: side, child: slot(id)),
              ],
            ),
          ],
        );
      },
    );
  }
}
