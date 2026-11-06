import 'package:flutter/material.dart';

import 'theme.dart';

/// Tabs as buttons in boxes on a plate, under an app bar (spec 0014 §2.2):
/// the Journal's Log, Bestiary and Lore, and the bank screen's Bank and Bag
/// (spec 0020 amendment 3). The selected box has the selected look
/// (amendment 4). A [keys] entry names its tab, for tests.
class TabBoxes extends StatelessWidget implements PreferredSizeWidget {
  const TabBoxes({super.key, required this.labels, this.keys = const []});

  final List<String> labels;
  final List<Key> keys;

  // A tab of 40, the TabBar's 2 for its indicator, the plate's padding of 3
  // and border of 1 on each side, and the gutter below.
  @override
  Size get preferredSize =>
      const Size.fromHeight(40 + 2 + 2 * (3 + 1) + gutter);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
    padding: const EdgeInsets.all(3),
    decoration: plateDecoration,
    child: TabBar(
      tabs: [
        for (final (i, label) in labels.indexed)
          Tab(
            key: i < keys.length ? keys[i] : null,
            height: 40,
            child: _TabBox(i, label),
          ),
      ],
    ),
  );
}

class _TabBox extends StatelessWidget {
  const _TabBox(this.index, this.label);

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    // The animation, not the index: the index changes only once a swipe has
    // settled, so the lit tab follows the finger from halfway on.
    final tabs = DefaultTabController.of(context).animation!;
    return ListenableBuilder(
      listenable: tabs,
      builder: (context, _) => ControlBox(
        fill: tabs.value.round() == index ? Quiet.selected : Quiet.slate,
        child: SizedBox.expand(child: Center(child: Text(label))),
      ),
    );
  }
}
