import 'dart:async';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'bag_spaces.dart';
import 'bank_screen.dart';
import 'bag_grid.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'item_selection.dart';
import 'paper_doll.dart';
import 'salvage_all.dart';
import 'socket.dart';
import 'stat_sheet.dart';
import 'talents_tab.dart';
import 'text_size.dart';
import 'theme.dart';

/// The three tabs of Character.
enum CharacterPane { gear, bag, talents }

/// Who am I (spec 0008 §3.5, amendment 7): the name with the level, the rank
/// and one row of stats above three small tabs,
/// Gear (the paper doll), Bag and Talents (spec 0015 §3.1). Equipping costs
/// no steps.

class CharacterTab extends StatefulWidget {
  const CharacterTab({super.key, this.pane});

  /// The pane to open on; the camp tour picks one (spec 0022 rule 18).
  final CharacterPane? pane;

  @override
  State<CharacterTab> createState() => _CharacterTabState();
}

class _CharacterTabState extends State<CharacterTab> {
  // It opens on the bag (#179).
  late var _pane = widget.pane ?? CharacterPane.bag;

  /// The plate of the panes, which the camp tour scrolls to the top, so its
  /// card does not hide the pane it talks about (intent 0021).
  final _panes = GlobalKey();

  /// The selected items of the bag (spec 0020 amendment 8). It ends with
  /// this tab, so another tab of the game ends it (rule 19).
  final _selection = ItemSelection();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selection.addListener(() => setState(() {}));
    if (widget.pane == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final panes = _panes.currentContext;
      if (!mounted || panes == null) return;
      unawaited(Scrollable.ensureVisible(panes));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    // The meal's share, marked on its stats (spec 0011 §8.3).
    final meal = game.mealBonus(s);
    // A stat of the block: its number, and a tap opens its sheet (spec 0009
    // amendment 4).
    Widget stat(StatKind kind, {int meal = 0}) => _Stat(
      kind.label,
      StatInfo.value(game, s, kind),
      meal: meal,
      onTap: () => showStatSheet(context, game, s, kind),
    );
    final level = game.level(s);
    final rank = game.rank(level).name;
    final points = game.talentPointsLeft(s);
    final text = Theme.of(context).textTheme;
    final who = s.character;

    // A selection of the bag (spec 0020 amendment 8): Store at a place with
    // a bank, Salvage at a forge (rule 1). It drops the items that left the
    // bag, and it ends when no action is left (rule 19).
    final store = game.hasBank(s.location);
    final forge = game.atForge(s);
    final canSelect = _pane == CharacterPane.bag && (store || forge);
    _selection.keepOnly(canSelect ? s.inventory.keys : const []);
    final selecting = _selection.running;
    final salvage = forge
        ? salvageOf(game, s, _selection.keys)
        : const <String>[];

    final page = ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // The portrait next to the name (spec 0014 §4.2).
                    if (who != null) ...[
                      PictureSocket(
                        key: const ValueKey('character-portrait'),
                        picture: ImageScope.of(context).pictureOf(
                          game.data,
                          PlayerThing(who.origin, who.gender),
                        ),
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Name with the level beside it, then rank · origin
                    // (spec 0012 §4.4, spec 0008 amendment 7). At a large
                    // text size the level wraps under the name.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                if (who != null)
                                  Text(
                                    who.name,
                                    key: const ValueKey('character-name'),
                                    style: text.headlineSmall,
                                  )
                                else
                                  _RankTitle(rank),
                                Text.rich(
                                  numberSpan('Level $level'),
                                  key: const ValueKey('stat-Level'),
                                  style: text.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          if (who != null) ...[
                            const SizedBox(height: 4),
                            _RankAndOrigin(
                              rank,
                              game.fill(
                                game.data.origins[who.origin]?.title ?? '',
                                who,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                // One row at the usual text size; it wraps at a large one.
                // Spec 0009 §2.2: with base Crit, each within its cap.
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    key: const ValueKey('stats-row'),
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    children: [
                      stat(StatKind.hp, meal: meal.hp),
                      stat(StatKind.attack, meal: meal.attack),
                      stat(StatKind.defense, meal: meal.defense),
                      stat(StatKind.crit, meal: meal.crit),
                      // The chance at the player's level (amendment 4).
                      stat(StatKind.hit),
                      stat(StatKind.dodge),
                      stat(StatKind.block),
                    ],
                  ),
                ),
                if (points > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$points talent point${points == 1 ? '' : 's'} to spend',
                    key: const ValueKey('talent-line'),
                    // Teal, so that a player does not miss it (spec 0015
                    // amendment 6).
                    style: text.bodyMedium?.copyWith(color: Quiet.teal),
                  ),
                ],
              ],
            ),
          ),
        ),
        // The segments, the doll and the bag stand on plates (spec 0014
        // §2.2).
        Card(
          key: _panes,
          child: Padding(
            padding: const EdgeInsets.all(gutter),
            child: SegmentedButton<CharacterPane>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: CharacterPane.gear,
                  label: Text('Gear', key: ValueKey('tab-gear')),
                  icon: Icon(Icons.accessibility_new),
                ),
                ButtonSegment(
                  value: CharacterPane.bag,
                  label: Text('Bag', key: ValueKey('tab-bag')),
                  icon: Icon(Icons.backpack),
                ),
                ButtonSegment(
                  value: CharacterPane.talents,
                  label: Text('Talents', key: ValueKey('tab-talents')),
                  icon: Icon(Icons.auto_awesome),
                ),
              ],
              selected: {_pane},
              showSelectedIcon: false,
              // Another pane ends the selection of the bag (spec 0020
              // amendment 8, rule 19).
              onSelectionChanged: (v) {
                _selection.clear();
                setState(() => _pane = v.single);
              },
            ),
          ),
        ),
        // Each talent tree is a plate of its own (spec 0015 amendment 6).
        if (_pane == CharacterPane.talents)
          TalentsTab(controller: c)
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: switch (_pane) {
                CharacterPane.gear => PaperDoll(controller: c),
                CharacterPane.bag => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The bag's spaces (spec 0021 points 13, 14).
                    BagSpacesLine(game: c.game, state: c.state),
                    const SizedBox(height: 8),
                    BagGrid(
                      controller: c,
                      selection: canSelect ? _selection : null,
                    ),
                    // At a forge, salvage all of a quality (spec 0010
                    // amendment 9).
                    SalvageAllButtons(controller: c),
                    const SizedBox(height: 10),
                    // The item bank, open everywhere (spec 0020 §3.1).
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const ValueKey('bag-bank'),
                        onPressed: () => openBank(context),
                        icon: const Icon(Icons.account_balance),
                        label: const Text('Bank'),
                      ),
                    ),
                  ],
                ),
                CharacterPane.talents => const SizedBox.shrink(),
              },
            ),
          ),
      ],
    );
    return PopScope(
      // Back ends the selection and stays on the screen (rule 19).
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selection.clear();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: page),
          // The bar stays under the list (rule 8).
          if (selecting)
            SelectionBar(
              selection: _selection,
              actions: [
                if (store)
                  MoveSelectedButton(
                    controller: c,
                    selection: _selection,
                    take: false,
                  ),
                if (salvage.isNotEmpty)
                  SalvageSelectedButton(
                    controller: c,
                    selection: _selection,
                    keys: salvage,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The rank, then "· origin" on the same line (spec 0012 §4.4). If the line
/// is too narrow for both, the origin shows on a line of its own below the
/// rank, without the dot. The origin is body text (spec 0014 §2.2).
class _RankAndOrigin extends StatelessWidget {
  const _RankAndOrigin(this.rank, this.origin);

  final String rank;
  final String origin;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final line = '· $origin';
    return LayoutBuilder(
      builder: (context, box) {
        final fits =
            textSizeOf(context, rank, _RankTitle.styleOf(context)).width +
                _RankTitle.gap +
                textSizeOf(context, line, style).width <=
            box.maxWidth;
        final title = _RankTitle(rank);
        final shown = Text(
          fits ? line : origin,
          key: const ValueKey('character-origin'),
          style: style,
        );
        return fits
            ? Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [title, shown],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, shown],
              );
      },
    );
  }
}

/// The rank name. Seven quick taps switch test walk on or off (spec 0004
/// decision 5), in owner builds only (spec 0007 §4).
class _RankTitle extends StatefulWidget {
  const _RankTitle(this.name);

  final String name;

  /// The space after the rank, before "· origin".
  static const gap = 6.0;

  /// The rank is teal (spec 0014 §2.1).
  static TextStyle? styleOf(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(color: Quiet.teal);

  @override
  State<_RankTitle> createState() => _RankTitleState();
}

class _RankTitleState extends State<_RankTitle> {
  static const _taps = 7;
  static const _gap = Duration(seconds: 2);

  var _count = 0;
  DateTime? _last;

  void _tap() {
    final now = DateTime.now();
    final last = _last;
    _count = last != null && now.difference(last) < _gap ? _count + 1 : 1;
    _last = now;
    if (_count < _taps) return;
    _count = 0;
    final c = ControllerScope.of(context);
    if (!c.testWalkAllowed) return;
    final on = !c.testWalkOn;
    unawaited(c.setTestWalk(on));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Test walk ${on ? 'on' : 'off'}')));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _tap,
    child: Padding(
      padding: const EdgeInsets.only(right: _RankTitle.gap),
      child: Text(widget.name, style: _RankTitle.styleOf(context)),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.meal = 0, this.onTap});

  final String label;
  final String value;

  /// What the running meal adds, shown as "+2 meal".
  final int meal;

  /// Opens the stat's sheet (spec 0009 amendment 4).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: ValueKey('stat-$label'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        // Wide enough for a thumb, and no padding at the sides: the seven
        // stats fill the row of a 408 dp phone (spec 0008 amendment 7).
        constraints: const BoxConstraints(minWidth: 44),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            // A stat value is a number that stands alone (spec 0014 §2.2).
            Text(
              value,
              style: text.titleMedium?.copyWith(fontFamily: Fonts.number),
            ),
            Text(label, style: text.labelSmall?.copyWith(color: Quiet.muted)),
            if (meal > 0) Text('+$meal meal', style: text.labelSmall),
          ],
        ),
      ),
    );
  }
}
