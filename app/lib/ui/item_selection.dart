import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'labels.dart';
import 'salvage_all.dart';
import 'theme.dart';

/// The selected items of one list (spec 0020 amendment 8): a hold on an item
/// starts the selection, and a tap then adds or removes an item (rules 3
/// and 4). A selected item is the whole item, all of its count (rule 5).
class ItemSelection extends ChangeNotifier {
  final _keys = <String>{};

  /// The selected item keys.
  Set<String> get keys => Set.of(_keys);

  /// Whether the selection runs: it ends with its last item (rule 19).
  bool get running => _keys.isNotEmpty;

  int get count => _keys.length;

  bool has(String key) => _keys.contains(key);

  /// Selects [key]: the hold.
  void select(String key) {
    if (_keys.add(key)) notifyListeners();
  }

  /// Selects [key], or removes it if it is selected: the tap while the
  /// selection runs.
  void toggle(String key) {
    if (!_keys.remove(key)) _keys.add(key);
    notifyListeners();
  }

  /// Ends the selection.
  void clear() {
    if (_keys.isEmpty) return;
    _keys.clear();
    notifyListeners();
  }

  /// Drops the items that left the list, for example after a sync. The
  /// screen calls it while it builds, so it tells no listener.
  void keepOnly(Iterable<String> held) => _keys.retainAll(held.toSet());
}

/// The bar of a selection, at the bottom of the screen (rules 8 to 11): ×,
/// "3 selected", then the [actions] of the list.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.selection,
    required this.actions,
  });

  final ItemSelection selection;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('selection-bar'),
    padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
    child: DecoratedBox(
      decoration: plateDecoration,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('select-cancel'),
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: selection.clear,
            ),
            const SizedBox(width: 8),
            // The items as the list shows them, not their counts (rule 9).
            Expanded(
              child: Text(
                '${selection.count} selected',
                key: const ValueKey('select-count'),
              ),
            ),
            for (final action in actions) ...[const SizedBox(width: 8), action],
          ],
        ),
      ),
    ),
  );
}

/// Store or Take of a selection's bar (rules 12 and 13): it ends the
/// selection, moves the whole count of each selected item and says how many
/// items moved. It does not ask first.
class MoveSelectedButton extends StatelessWidget {
  const MoveSelectedButton({
    super.key,
    required this.controller,
    required this.selection,
    required this.take,
  });

  final GameController controller;
  final ItemSelection selection;

  /// From the bank to the bag; else from the bag to the bank.
  final bool take;

  Future<void> _move(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final keys = selection.keys;
    selection.clear();
    try {
      final moved = await controller.moveItems(keys, take: take);
      if (moved == 0) return;
      // The new message replaces the one on screen (#176).
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(movedNote(moved, take: take))));
    } on ActivityError catch (e) {
      // The sync before the move can end a walk away from Camp (rule 18).
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    key: ValueKey(take ? 'select-take' : 'select-store'),
    onPressed: () => _move(context),
    child: Text(take ? 'Take' : 'Store'),
  );
}

/// The selected bag items that a salvage takes, in the bag's order: gear and
/// tools, not a starter tool (rule 14; spec 0010 amendment 9, rule 1).
List<String> salvageOf(Game game, GameState s, Set<String> selected) => [
  for (final key in bagOrder(game.data, selected))
    if (game.salvageable(s, key)) key,
];

/// "Salvage (14)" of a selection's bar (rules 10, 11 and 14): it ends the
/// selection, asks once, then salvages [keys] as one batch.
class SalvageSelectedButton extends StatelessWidget {
  const SalvageSelectedButton({
    super.key,
    required this.controller,
    required this.selection,
    required this.keys,
  });

  final GameController controller;
  final ItemSelection selection;

  /// What [salvageOf] gives for the selection: never empty.
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final bag = controller.state.inventory;
    final n = keys.fold(0, (n, k) => n + (bag[k] ?? 0));
    return OutlinedButton(
      key: const ValueKey('select-salvage'),
      onPressed: () {
        selection.clear();
        unawaited(salvageAll(context, controller, keys, plural(n, 'item')));
      },
      child: Text('Salvage ($n)'),
    );
  }
}

/// The teal check mark of a selected item (rule 6).
class SelectedMark extends StatelessWidget {
  const SelectedMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('selected-mark'),
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      color: Quiet.teal,
      shape: BoxShape.circle,
      border: Border.all(width: 2),
    ),
    child: const Icon(Icons.check, size: 13, color: Quiet.onTeal),
  );
}

/// [socket] with the check mark on its top left corner when [selected]. The
/// ring of the quality and the count stay in view (rule 6).
Widget markSelected(Widget socket, {required bool selected}) => !selected
    ? socket
    : Stack(
        clipBehavior: Clip.none,
        children: [
          socket,
          const Positioned(left: -6, top: -6, child: SelectedMark()),
        ],
      );
