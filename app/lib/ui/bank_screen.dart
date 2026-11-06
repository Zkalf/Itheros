import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'bag_spaces.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'item_card.dart';
import 'kind_chips.dart';
import 'labels.dart';
import 'socket.dart';
import 'tab_boxes.dart';
import 'theme.dart';

/// Opens the bank screen (spec 0020 §3.1). It slides in like the Journal.
Future<void> openBank(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const BankScreen()));

/// The item bank (spec 0020 §3.2): the tabs Bag and Bank. A tap on an item
/// opens its card; at a place with a bank the card has Store or Take,
/// elsewhere the player only looks (spec 0020 amendment 2).
class BankScreen extends StatelessWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final here = c.game.hasBank(c.state.location);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: const ValueKey('bank-screen'),
        appBar: AppBar(
          leading: const BackPlate(),
          title: const Text('Bank'),
          // Buttons in boxes, as the Journal's; Bank first, and the screen
          // opens on it (spec 0020 amendment 3).
          bottom: const TabBoxes(
            labels: ['Bank', 'Bag'],
            keys: [ValueKey('bank-tab-bank'), ValueKey('bank-tab-bag')],
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!here)
                const Padding(
                  padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, 0),
                  child: Text('Items move only at Camp.'),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ItemList(controller: c, inBank: true),
                    _ItemList(controller: c, inBank: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The items of the bag or the bank, in the bag's order, each with its
/// picture and count, under the chips of the four kinds.
class _ItemList extends StatelessWidget {
  const _ItemList({required this.controller, required this.inBank});

  final GameController controller;
  final bool inBank;

  @override
  Widget build(BuildContext context) {
    final data = controller.game.data;
    final labels = Labels(data);
    final items = inBank
        ? controller.state.itemBank
        : controller.state.inventory;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(gutter),
        child: Text(inBank ? 'The bank is empty.' : 'The bag is empty.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        // The bag's spaces (spec 0021 point 18).
        if (!inBank) ...[
          BagSpacesLine(game: controller.game, state: controller.state),
          const SizedBox(height: 8),
        ],
        // The chips of the four kinds; each tab keeps its own pick (spec
        // 0020 amendment 2).
        KindFilter(
          controller: controller,
          list: inBank ? 'bank-bank' : 'bank-bag',
          items: items.keys,
          builder: (shown) => Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final key in shown)
                  ListTile(
                    key: ValueKey('${inBank ? 'bank-item' : 'bank-bag'}-$key'),
                    // The picture in a 48 dp socket, with the ring of its
                    // quality for gear and tools (amendment 2, rules 12-13).
                    leading: PictureSocket.item(
                      data,
                      key,
                      picture: ImageScope.of(context)
                          .pictureOf(data, ItemThing(key)),
                      size: 48,
                    ),
                    title: Text(
                      '${labels.item(key)} ×${items[key]}',
                      // As on the item card: Common in the normal text colour.
                      style: TextStyle(color: itemColour(data, key)),
                    ),
                    // The card, with Store or Take at Camp (rules 15-19).
                    onTap: () => showItemCard(
                      context,
                      controller,
                      key,
                      bank: inBank ? BankSide.bank : BankSide.bag,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
