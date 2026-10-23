import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'images.dart';
import 'socket.dart';
import 'theme.dart';

/// The icon for a slot id or slot kind: the faint icon of an empty doll slot.
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

/// A profession's icon, by the name its data gives (spec 0010 §8.1).
IconData professionIcon(String name) => switch (name) {
  'pickaxe' => Icons.hardware,
  'axe' => Icons.carpenter,
  'anvil' => Icons.handyman,
  'fish' => Icons.phishing,
  'bow' => Icons.my_location,
  'pot' => Icons.soup_kitchen,
  _ => Icons.work,
};

/// One square of the doll or the bag: the picture of its item in a socket
/// (spec 0014 §2.3). Gear and tools have the ring of their quality, and
/// [count] shows in the badge from 2 up. Empty ([item] null): the faint icon
/// of [emptySlot] in an empty socket, with no PH mark.
class ItemSquare extends StatelessWidget {
  const ItemSquare({
    super.key,
    required this.data,
    this.item,
    this.emptySlot,
    this.count = 1,
    this.dimmed = false,
    this.onTap,
    this.socket,
  });

  final GameData data;

  /// The item key shown, or null for an empty slot.
  final String? item;
  final String? emptySlot;
  final int count;

  /// Greyed out with the link icon, as the off hand under a two-hander.
  final bool dimmed;
  final VoidCallback? onTap;

  /// The size of the socket in the centre of the square (48 dp in the bag),
  /// or null for a socket that fills the square (the doll, plan 0017
  /// choice 10).
  final double? socket;

  @override
  Widget build(BuildContext context) {
    final key = item;
    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = socket ?? box.maxWidth;
                final def = key == null ? null : data.itemOf(key);
                return Center(
                  child: key == null
                      ? DecoratedBox(
                          decoration: socketDecoration(size),
                          child: SizedBox.square(
                            dimension: size,
                            child: Icon(
                              dimmed ? Icons.link : slotIcon(emptySlot ?? ''),
                              color: Quiet.steel.withValues(alpha: .3),
                              size: 28,
                            ),
                          ),
                        )
                      : PictureSocket(
                          picture: ImageScope.of(context)
                              .pictureOf(data, ItemThing(key)),
                          size: size,
                          quality: def?.slot != null || def?.tool != null
                              ? data.qualityOf(key)
                              : null,
                          count: count,
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
