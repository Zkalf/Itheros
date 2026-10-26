// Spec 0014 amendment 4 (issue #101, plan 0027): a selected chip, segment
// or tab has the fill #4C6768 and a white label, and each button label but
// a teal button's has a thin black outline.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/theme.dart'
    show ghostButton, slateButton, tealButton;

import 'quiet_teal_files_test.dart'
    show mutedRgb, selectedRgb, slateRgb, textRgb;
import 'quiet_teal_test.dart'
    show
        chipFill,
        describeAll,
        drawnUnder,
        expectRgb,
        materialOf,
        openJournal,
        richIn,
        rootStyle,
        sameRgb,
        styleOf;
import 'ui_test.dart' show openProfession, openTab, option, pumpGame;

const _white = 0xFFFFFF;

/// The outline of amendment 4, change 6: four black shadows of 0.8 dp, one
/// on each side, with no blur. The test keeps its own copy.
const _outline = [
  Shadow(offset: Offset(-.8, 0)),
  Shadow(offset: Offset(.8, 0)),
  Shadow(offset: Offset(0, -.8)),
  Shadow(offset: Offset(0, .8)),
];

final _buttons = find.byWidgetPredicate((w) => w is ButtonStyleButton);

/// The style of the label of the chip or segment with [words].
TextStyle _labelOf(WidgetTester t, String words) =>
    rootStyle(richIn(t, find.text(words)));

/// The colour of the icon in [within].
Color? _iconColour(WidgetTester t, Finder within) => IconTheme.of(
  t.element(find.descendant(of: within, matching: find.byType(Icon)).first),
).color;

/// Expects [style] to have the outline, or no shadow when [outline] is false.
void _expectOutline(TextStyle style, String what, {bool outline = true}) {
  expect(
    style.shadows ?? const <Shadow>[],
    outline ? _outline : isEmpty,
    reason: outline ? '$what: the outline' : '$what: no shadow',
  );
}

void main() {
  group('the selected look', () {
    testWidgets('criteria 1 and 4: the Gear segment is selected, Bag is not', (
      t,
    ) async {
      await pumpGame(t);
      await openTab(t, 'character');
      final segments = find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: _buttons,
      );
      Finder segment(String label) =>
          find.ancestor(of: find.text(label), matching: segments);
      expectRgb(
        materialOf(t.element(segment('Gear'))).color,
        selectedRgb,
        'Gear: fill',
      );
      expectRgb(_labelOf(t, 'Gear').color, _white, 'Gear: label');
      expectRgb(_iconColour(t, segment('Gear')), _white, 'Gear: icon');
      expectRgb(
        materialOf(t.element(segment('Bag'))).color,
        slateRgb,
        'Bag: fill',
      );
      expectRgb(_labelOf(t, 'Bag').color, textRgb, 'Bag: label');
    });

    testWidgets('criterion 2: a selected choice chip and a selected filter '
        'chip', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      final choice = find.byWidgetPredicate(
        (w) => w is ChoiceChip && w.selected,
      );
      expect(choice, findsWidgets);
      expectRgb(chipFill(t.element(choice.first)), selectedRgb, 'stop choice');
      expectRgb(
        rootStyle(
          richIn(
            t,
            find.descendant(of: choice.first, matching: find.byType(Text)),
          ),
        ).color,
        _white,
        'stop choice: label',
      );

      await pumpGame(t, level: 5, inventory: {'copper_ore': 12});
      await openProfession(t, 'crafting');
      await t.tap(find.byKey(const ValueKey('filter-mats')));
      await t.pumpAndSettle();
      final mats = find.byKey(const ValueKey('filter-mats'));
      expectRgb(chipFill(t.element(mats)), selectedRgb, 'Have mats');
      expectRgb(_labelOf(t, 'Have mats').color, _white, 'Have mats: label');
      final level = find.byKey(const ValueKey('filter-level'));
      expectRgb(chipFill(t.element(level)), slateRgb, 'Have level');
      expectRgb(_labelOf(t, 'Have level').color, textRgb, 'Have level: label');
    });

    testWidgets('criteria 3 and 4: the open Journal tab', (t) async {
      await pumpGame(t);
      await openJournal(t);
      final log = drawnUnder(t.element(find.text('Log')));
      expect(
        log.any((d) => sameRgb(d.fill, selectedRgb)),
        isTrue,
        reason: 'the open tab Log: ${describeAll(log)}',
      );
      expectRgb(_labelOf(t, 'Log').color, _white, 'Log: label');
      final lore = drawnUnder(t.element(find.text('Lore')));
      expect(
        lore.any((d) => sameRgb(d.fill, slateRgb)),
        isTrue,
        reason: 'the tab Lore: ${describeAll(lore)}',
      );
      expectRgb(_labelOf(t, 'Lore').color, textRgb, 'Lore: label');
    });

    testWidgets('criterion 5: the open tab of the bottom bar', (t) async {
      await pumpGame(t);
      final now = find.byKey(const ValueKey('tab-now'));
      final drawn = drawnUnder(t.element(now));
      expect(
        drawn.any((d) => sameRgb(d.fill, selectedRgb)),
        isTrue,
        reason: 'the open tab Now: ${describeAll(drawn)}',
      );
      expectRgb(styleOf(t, 'Now', within: now).color, _white, 'Now: label');
      expectRgb(_iconColour(t, now), _white, 'Now: icon');
      final world = find.byKey(const ValueKey('tab-world'));
      expect(
        drawnUnder(t.element(world)).any((d) => sameRgb(d.fill, selectedRgb)),
        isFalse,
        reason: 'World is not open',
      );
      expectRgb(
        styleOf(t, 'World', within: world).color,
        mutedRgb,
        'World: label',
      );
    });
  });

  group('the outline', () {
    testWidgets('criteria 6 and 7: slate and ghost buttons', (t) async {
      for (final (style, name) in [
        (slateButton, 'a slate button'),
        (ghostButton, 'a ghost button'),
      ]) {
        _expectOutline(style.textStyle!.resolve({})!, name);
      }
      await pumpGame(t);
      _expectOutline(
        styleOf(t, 'Open the World map'),
        'Open the World map (slate)',
      );
    });

    testWidgets('criterion 8: segments, chips and Journal tabs', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      for (final chip in find.byType(ChoiceChip).evaluate()) {
        final label = find.descendant(
          of: find.byElementPredicate((e) => e == chip),
          matching: find.byType(Text),
        );
        _expectOutline(
          rootStyle(richIn(t, label)),
          'the chip ${(chip.widget as ChoiceChip).selected ? '(selected)' : ''}',
        );
      }
      await pumpGame(t);
      await openTab(t, 'character');
      for (final label in ['Gear', 'Bag']) {
        _expectOutline(_labelOf(t, label), 'the segment $label');
      }
      await openJournal(t);
      for (final label in ['Log', 'Bestiary', 'Lore']) {
        _expectOutline(_labelOf(t, label), 'the Journal tab $label');
      }
    });

    testWidgets('criterion 8: filter chips', (t) async {
      await pumpGame(t, level: 5);
      await openProfession(t, 'crafting');
      for (final label in ['Have mats', 'Have level', 'Up to 5 levels ahead']) {
        _expectOutline(_labelOf(t, label), 'the filter $label');
      }
    });

    testWidgets('criterion 9: the labels of the bottom bar', (t) async {
      await pumpGame(t);
      for (final (key, label) in [
        ('now', 'Now'),
        ('world', 'World'),
        ('professions', 'Professions'),
        ('character', 'Character'),
      ]) {
        _expectOutline(
          styleOf(t, label, within: find.byKey(ValueKey('tab-$key'))),
          'the tab $label',
        );
      }
    });

    testWidgets('criterion 10: a teal button has no shadow', (t) async {
      _expectOutline(
        tealButton.textStyle!.resolve({})!,
        'a teal button',
        outline: false,
      );
      await pumpGame(t, location: 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      final start = find.descendant(
        of: find.byKey(const ValueKey('start-now')),
        matching: find.byType(Text),
      );
      _expectOutline(rootStyle(richIn(t, start)), 'Start', outline: false);
    });

    testWidgets('criterion 11: a status chip has no shadow', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 14,
        inventory: {'copper_ore': 30},
      );
      await c.addAction(const Activity.craft('copper_sword'));
      await openProfession(t, 'crafting');
      _expectOutline(
        _labelOf(t, 'Active'),
        'the status chip Active',
        outline: false,
      );
    });
  });
}
