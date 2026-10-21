import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'away_summary_card.dart';
import 'labels.dart';

/// Opens the card for [item] (spec 0008 §3.5). [wornIn] is set when it was
/// tapped on the doll.
Future<void> showItemCard(
  BuildContext context,
  GameController c,
  String item, {
  String? wornIn,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) =>
      ItemCard(controller: c, item: item, wornIn: wornIn, host: context),
);

/// The item's name in its quality colour, the quality and kind in words, its
/// stats, how it compares with what is worn, and Equip / Swap / Unequip. A
/// material says where it comes from and what uses it.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.controller,
    required this.item,
    required this.host,
    this.wornIn,
  });

  final GameController controller;
  final String item;
  final String? wornIn;

  /// The screen behind the sheet, for messages after the sheet closes.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final data = game.data;
    final labels = Labels(data);
    final text = Theme.of(context).textTheme;
    final def = data.itemOf(item)!;
    final gear = def.slot != null;
    final q = data.qualityOf(item);
    final colour = gear && q != data.qualities.first ? qualityColour(q) : null;

    final rows = <Widget>[
      Text(
        labels.plain(item),
        key: const ValueKey('card-name'),
        style: text.titleLarge?.copyWith(color: colour),
      ),
      const SizedBox(height: 4),
      Text(labels.kind(item), key: const ValueKey('card-kind')),
      const SizedBox(height: 8),
      if (gear) ...[
        Text(labels.bonus(data.bonusOf(item)).join(' · ')),
        if (def.twoHanded)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Uses both hands: your shield goes to the bag.'),
          ),
        const SizedBox(height: 12),
        ..._gearActions(context, labels),
      ] else
        ..._materialLines(labels),
    ];
    return SafeArea(
      child: Padding(
        key: const ValueKey('item-card'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }

  List<Widget> _gearActions(BuildContext context, Labels labels) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    if (wornIn case final slot?) {
      return [
        _button(
          context,
          const ValueKey('card-unequip'),
          'Unequip',
          () => c.unequip(slot),
        ),
      ];
    }
    final slots = game.slotsFor(item);
    final free = slots.where((id) => !s.equipment.containsKey(id)).toList();
    // An empty slot first (spec 0008 decision 11); otherwise a swap with each
    // slot it fits.
    final targets = free.isNotEmpty ? [free.first] : slots;
    return [
      for (final slot in targets) ...[
        Text(switch (s.equipment[slot]) {
          final worn? => 'Instead of your ${labels.plain(worn)}',
          null => '${labels.slot(slot)} is empty',
        }, style: Theme.of(context).textTheme.bodySmall),
        // The change counts everything it takes off (a two-hander's shield).
        Text(
          labels.delta(game.compare(s, item, slot)),
          key: ValueKey('compare-$slot'),
        ),
        const SizedBox(height: 8),
        _button(
          context,
          ValueKey(
            free.isNotEmpty
                ? 'card-equip'
                : slots.length == 1
                ? 'card-swap'
                : 'card-swap-$slot',
          ),
          free.isNotEmpty
              ? 'Equip'
              : slots.length == 1
              ? 'Swap'
              : 'Swap with ${labels.plain(s.equipment[slot]!)}',
          () => c.equip(item, slot: slot),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _materialLines(Labels labels) {
    final game = controller.game;
    final (enemies, nodes) = game.itemSources(controller.state, item);
    final uses = game.itemUses(item);
    return [
      if (enemies.isNotEmpty)
        Text('Drops from: ${enemies.map(labels.enemy).join(', ')}'),
      if (nodes.isNotEmpty)
        Text('Mined at: ${nodes.map(labels.node).join(', ')}'),
      if (uses.isNotEmpty)
        Text('Used in: ${uses.map(labels.recipe).join(', ')}'),
    ];
  }

  Widget _button(
    BuildContext context,
    Key key,
    String label,
    Future<void> Function() action,
  ) => FilledButton.tonal(
    key: key,
    onPressed: () async {
      final messenger = ScaffoldMessenger.of(host);
      Navigator.of(context).pop();
      try {
        await action();
      } on ActivityError catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    },
    child: Text(label),
  );
}
