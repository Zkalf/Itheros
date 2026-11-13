import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'bag_spaces.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'item_card.dart';
import 'item_selection.dart';
import 'kind_chips.dart';
import 'labels.dart';
import 'socket.dart';
import 'tab_boxes.dart';
import 'theme.dart';

/// Opens the bank screen (spec 0020 §3.1). It slides in like the Journal.
Future<void> openBank(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const BankScreen()));

/// The item bank (spec 0020 §3.2): the tabs Bank and Bag, Bank first and
/// open (amendment 3). A tap on an item
/// opens its card; at a place with a bank the card has Store or Take,
/// elsewhere the player only looks (spec 0020 amendment 2).
class BankScreen extends StatelessWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const DefaultTabController(length: 2, child: _BankTabs());
}

/// The screen under its tab controller. It holds the selection of the open
/// tab (spec 0020 amendment 8): Take on Bank, Store on Bag.
class _BankTabs extends StatefulWidget {
  const _BankTabs();

  @override
  State<_BankTabs> createState() => _BankTabsState();
}

class _BankTabsState extends State<_BankTabs> {
  final _selection = ItemSelection();
  TabController? _tabs;
  var _tab = 0;

  @override
  void initState() {
    super.initState();
    _selection.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabs = DefaultTabController.of(context);
    if (tabs == _tabs) return;
    _tabs?.removeListener(_onTab);
    _tabs = tabs..addListener(_onTab);
    _tab = tabs.index;
  }

  /// The other tab ends the selection (amendment 8, rule 19).
  void _onTab() {
    final tab = _tabs!.index;
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _selection.clear();
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTab);
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final here = c.game.hasBank(c.state.location);
    final inBank = _tab == 0;
    // The selection drops the items that left its list, and it ends away
    // from a bank (amendment 8, rules 16 and 19).
    _selection.keepOnly(
      !here ? const [] : (inBank ? c.state.itemBank : c.state.inventory).keys,
    );
    final selecting = _selection.running;
    return PopScope(
      // Back ends the selection and stays on the screen (rule 19).
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selection.clear();
      },
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
                    for (final bank in [true, false])
                      _ItemList(
                        controller: c,
                        inBank: bank,
                        // Only the open tab selects, at a place with a bank
                        // (amendment 8, rules 1 and 2).
                        selection: here && bank == inBank ? _selection : null,
                      ),
                  ],
                ),
              ),
              // The bar stays under the list (amendment 8, rule 8).
              if (selecting)
                SelectionBar(
                  selection: _selection,
                  actions: [
                    MoveSelectedButton(
                      controller: c,
                      selection: _selection,
                      take: inBank,
                    ),
                  ],
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
  const _ItemList({
    required this.controller,
    required this.inBank,
    this.selection,
  });

  final GameController controller;
  final bool inBank;

  /// The selection of this list, where one can start; else null.
  final ItemSelection? selection;

  /// Stores every material, then says how many kinds moved. A refusal shows
  /// as a note: the sync before the move can end a walk away from Camp.
  Future<void> _storeAllMaterials(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final int kinds;
    try {
      kinds = await controller.storeAllMaterials();
    } on ActivityError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (kinds == 0) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Stored $kinds ${kinds == 1 ? 'kind' : 'kinds'} of material.',
        ),
      ),
    );
  }

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
          // Every material in one tap, at a place with a bank (spec 0020
          // amendment 5, rules 5-11).
          if (controller.game.hasBank(controller.state.location) &&
              controller.game.materialsInBag(controller.state).isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('store-all-materials'),
                onPressed: () => _storeAllMaterials(context),
                icon: const Icon(Icons.account_balance),
                label: const Text('Store all materials'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
        // The chips of the four kinds; each tab keeps its own pick (spec
        // 0020 amendment 2).
        KindFilter(
          controller: controller,
          list: inBank ? 'bank-bank' : 'bank-bag',
          items: items,
          builder: (shown) => Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final key in shown)
                  ListTile(
                    key: ValueKey('${inBank ? 'bank-item' : 'bank-bag'}-$key'),
                    // The picture in a 48 dp socket, with the ring of its
                    // quality for gear and tools (amendment 2, rules 12-13).
                    // A selected row has the fill of a selected chip and
                    // the check mark on its socket (amendment 8, rule 6).
                    tileColor: (selection?.has(key) ?? false)
                        ? Quiet.selected
                        : null,
                    leading: markSelected(
                      PictureSocket.item(
                        data,
                        key,
                        picture: ImageScope.of(context)
                            .pictureOf(data, ItemThing(key)),
                        size: 48,
                      ),
                      selected: selection?.has(key) ?? false,
                    ),
                    title: Text(
                      '${labels.item(key)} ×${items[key]}',
                      // As on the item card: Common in the normal text colour.
                      style: TextStyle(color: itemColour(data, key)),
                    ),
                    // Its stats, so that alike rows differ (amendment 7).
                    subtitle: switch (labels.rowLine(key)) {
                      final line? => Text(
                        line,
                        key: ValueKey('bank-row-line-$key'),
                      ),
                      null => null,
                    },
                    // The card, with Store or Take at Camp (rules 15-19).
                    // While a selection runs, a tap selects and opens no
                    // card; a hold starts it (amendment 8, rules 3 and 4).
                    onTap: () {
                      if (selection case final picked? when picked.running) {
                        picked.toggle(key);
                        return;
                      }
                      unawaited(
                        showItemCard(
                          context,
                          controller,
                          key,
                          bank: inBank ? BankSide.bank : BankSide.bag,
                        ),
                      );
                    },
                    // Where no selection can start, a hold does nothing:
                    // it opens no card either (rule 2).
                    onLongPress: () => selection?.select(key),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
