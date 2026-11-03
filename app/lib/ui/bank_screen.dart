import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'action_sheet.dart' show CountDialog;
import 'bag_spaces.dart';
import 'controller_scope.dart';
import 'item_card.dart';
import 'labels.dart';
import 'theme.dart';

/// Opens the bank screen (spec 0020 §3.1). It slides in like the Journal.
Future<void> openBank(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const BankScreen()));

/// The item bank (spec 0020 §3.2): the tabs Bag and Bank. At a place with a
/// bank, a tap on an item opens Store or Take; elsewhere the player only
/// looks.
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
          // The tab shown is teal and underlined, the other muted.
          bottom: const TabBar(
            indicatorColor: Quiet.teal,
            labelColor: Quiet.teal,
            unselectedLabelColor: Quiet.muted,
            tabs: [
              Tab(key: ValueKey('bank-tab-bag'), text: 'Bag'),
              Tab(key: ValueKey('bank-tab-bank'), text: 'Bank'),
            ],
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
                    _ItemList(controller: c, inBank: false, canMove: here),
                    _ItemList(controller: c, inBank: true, canMove: here),
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

/// The items of the bag or the bank, in the bag's order, each with its count.
class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.controller,
    required this.inBank,
    required this.canMove,
  });

  final GameController controller;
  final bool inBank;
  final bool canMove;

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
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final key in bagOrder(data, items.keys))
                ListTile(
                  key: ValueKey('${inBank ? 'bank-item' : 'bank-bag'}-$key'),
                  title: Text(
                    '${labels.item(key)} ×${items[key]}',
                    // As on the item card: Common in the normal text colour.
                    style: TextStyle(color: itemColour(data, key)),
                  ),
                  onTap: canMove
                      ? () => _showMove(context, controller, key, inBank)
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The sheet of one item: Store all and Store some…, or Take all and Take
/// some… (spec 0020 §3.2).
Future<void> _showMove(
  BuildContext context,
  GameController c,
  String key,
  bool inBank,
) async {
  final have = (inBank ? c.state.itemBank : c.state.inventory)[key] ?? 0;
  final verb = inBank ? 'Take' : 'Store';
  Future<void> move(int n) =>
      inBank ? c.takeFromBank(key, n) : c.storeInBank(key, n);
  final choice = await showModalBottomSheet<int>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text('${Labels(c.game.data).item(key)} ×$have'),
            titleTextStyle: nameStyle(sheet),
          ),
          ListTile(
            key: const ValueKey('bank-move-all'),
            leading: Icon(inBank ? Icons.backpack : Icons.account_balance),
            title: Text('$verb all'),
            onTap: () => Navigator.pop(sheet, have),
          ),
          ListTile(
            key: const ValueKey('bank-move-some'),
            leading: const Icon(Icons.pin),
            title: Text('$verb some…'),
            onTap: () async {
              final n = await showDialog<int>(
                context: sheet,
                builder: (_) => CountDialog(have),
              );
              if (sheet.mounted) Navigator.pop(sheet, n);
            },
          ),
        ],
      ),
    ),
  );
  if (choice == null || choice < 1) return;
  try {
    await move(choice > have ? have : choice);
  } on ActivityError catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
