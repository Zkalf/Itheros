import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'item_sort.dart';

/// The word on the chip of each kind (spec 0020 amendment 2, rule 3).
String itemKindName(ItemKind k) => switch (k) {
  ItemKind.gear => 'Gear',
  ItemKind.tool => 'Tools',
  ItemKind.meal => 'Meals',
  ItemKind.material => 'Materials',
};

/// The chips All, Gear, Tools, Meals and Materials above a list of items,
/// then the search field and the sort button, and the list of the items that
/// match below them (spec 0020 amendments 2 and 4). [list] names the list
/// whose kind and sort the controller keeps (see `GameController.kindPicks`,
/// `GameController.sortPicks`). The search lives in this widget only, so it
/// clears when the list leaves the screen (amendment 4, rule 9).
class KindFilter extends StatefulWidget {
  const KindFilter({
    super.key,
    required this.controller,
    required this.list,
    required this.items,
    required this.builder,
  });

  final GameController controller;
  final String list;

  /// The items of the list and their counts, in any order.
  final Map<String, int> items;

  /// Draws the items that match, in the picked order. Never called with no
  /// items.
  final Widget Function(List<String> shown) builder;

  @override
  State<KindFilter> createState() => _KindFilterState();
}

class _KindFilterState extends State<KindFilter> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  TabController? _tabs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A focused field keeps its tab page alive, so the bank screen's tabs
    // clear the search themselves when the player opens the other tab
    // (amendment 4, rule 9). The controller tells its listeners only when
    // the tab changes; a drag that springs back moves only its animation.
    final tabs = DefaultTabController.maybeOf(context);
    if (tabs == _tabs) return;
    _tabs?.removeListener(_onTab);
    _tabs = tabs?..addListener(_onTab);
  }

  void _onTab() {
    if (_search.text.isEmpty && !_focus.hasFocus) return;
    _focus.unfocus();
    setState(_search.clear);
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTab);
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final list = widget.list;
    final picked = c.kindPicks[list];
    final sort = c.sortPicks[list] ?? ItemSort.bagOrder;
    final text = _search.text.trim();
    final shown = itemsShown(
      c.game.data,
      widget.items,
      kind: picked,
      search: text,
      sort: sort,
    );
    Widget chip(String id, String label, ItemKind? kind) => ChoiceChip(
      key: ValueKey('kind-$list-$id'),
      label: Text(label),
      selected: picked == kind,
      onSelected: (_) => setState(() {
        if (kind == null) {
          c.kindPicks.remove(list);
        } else {
          c.kindPicks[list] = kind;
        }
      }),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            chip('all', 'All', null),
            for (final k in ItemKind.values) chip(k.name, itemKindName(k), k),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // The search (amendment 4, rules 3-9).
            Expanded(
              child: TextField(
                key: ValueKey('search-$list'),
                controller: _search,
                focusNode: _focus,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search',
                  // A plain ×, not the theme's boxed icon button, so it
                  // stays inside the field (rule 7).
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : InkResponse(
                          key: ValueKey('search-$list-clear'),
                          radius: 20,
                          onTap: () => setState(_search.clear),
                          child: const Tooltip(
                            message: 'Clear',
                            child: Icon(Icons.close),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // The sort (amendment 4, rules 10-15).
            PopupMenuButton<ItemSort>(
              key: ValueKey('sort-$list'),
              initialValue: sort,
              tooltip: 'Sort',
              onSelected: (s) => setState(() {
                if (s == ItemSort.bagOrder) {
                  c.sortPicks.remove(list);
                } else {
                  c.sortPicks[list] = s;
                }
              }),
              itemBuilder: (_) => [
                for (final s in ItemSort.values)
                  PopupMenuItem(
                    key: ValueKey('sort-$list-${s.name}'),
                    value: s,
                    child: Text(itemSortName(s)),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort),
                    const SizedBox(width: 6),
                    Text(itemSortName(sort)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            key: ValueKey('kind-$list-empty'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              text.isEmpty
                  ? 'Nothing of this kind here.'
                  : 'Nothing here matches "$text".',
            ),
          )
        else
          widget.builder(shown),
      ],
    );
  }
}
