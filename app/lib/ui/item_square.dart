import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'away_summary_card.dart';

/// The icon for a slot id or slot kind (spec 0008 §3.5: simple icons, no art).
IconData slotIcon(String slot) =>
    switch (slot.replaceAll(RegExp(r'\d+$'), '')) {
      'head' => Icons.face,
      'neck' => Icons.diamond_outlined,
      'shoulder' => Icons.expand_less,
      'cloak' => Icons.dry_cleaning,
      'chest' => Icons.checkroom,
      'bracer' => Icons.watch,
      'gloves' => Icons.back_hand,
      'belt' => Icons.horizontal_rule,
      'legs' => Icons.airline_seat_legroom_normal,
      'boots' => Icons.hiking,
      'ring' => Icons.radio_button_unchecked,
      'trinket' => Icons.auto_awesome,
      'mainHand' => Icons.gavel,
      'offHand' => Icons.shield,
      _ => Icons.checkroom,
    };

/// Materials share one icon, so Common gear never looks like a material.
const materialIcon = Icons.grain;

/// A profession's icon, by the name its data gives (spec 0010 §8.1).
IconData professionIcon(String name) => switch (name) {
  'pickaxe' => Icons.hardware,
  'axe' => Icons.carpenter,
  'anvil' => Icons.handyman,
  _ => Icons.work,
};

/// One square of the doll or the bag. Gear: its slot's icon in a border of its
/// quality colour; a tool the same, with its profession's icon. A material: the material icon, no border. Empty ([key]
/// null): a faint outline of [emptySlot]'s icon. [count] shows in the corner
/// from 2 up.
class ItemSquare extends StatelessWidget {
  const ItemSquare({
    super.key,
    required this.data,
    this.item,
    this.emptySlot,
    this.count = 1,
    this.dimmed = false,
    this.onTap,
  });

  final GameData data;

  /// The item key shown, or null for an empty slot.
  final String? item;
  final String? emptySlot;
  final int count;

  /// Greyed out, as the off hand under a two-hander.
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = item;
    final def = key == null ? null : data.itemOf(key);
    final gear = def?.slot != null || def?.tool != null;
    final Color border;
    final IconData icon;
    final Color iconColour;
    if (key == null) {
      border = scheme.outlineVariant;
      icon = slotIcon(emptySlot ?? '');
      iconColour = scheme.outlineVariant;
    } else if (gear) {
      final q = data.qualityOf(key);
      border = q == data.qualities.first ? scheme.onSurface : qualityColour(q);
      icon = switch (def!.tool) {
        final tool? => professionIcon(data.professions[tool.profession]!.icon),
        null => slotIcon(def.slot!),
      };
      iconColour = border;
    } else {
      border = Colors.transparent;
      icon = materialIcon;
      iconColour = scheme.onSurfaceVariant;
    }
    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: Material(
        color: key == null ? Colors.transparent : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border, width: gear ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    dimmed ? Icons.link : icon,
                    color: iconColour,
                    size: 28,
                  ),
                ),
                if (count > 1)
                  Positioned(
                    right: 4,
                    bottom: 2,
                    child: Text(
                      '$count',
                      key: const ValueKey('count'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
