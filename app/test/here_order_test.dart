// Camp's services first on Now, and the Bank row without a button: spec
// 0020 amendment 6 criteria 1-7 (plan 0060).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/actions.dart';

import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final bankRow = key('bank-card');
  const services = ['bank-card', 'here-forge', 'here-fire'];
  final teachers = [
    for (final p in game.data.professions.values)
      if (p.teacher.location == 'camp') 'teacher-${p.id}',
  ];

  testWidgets('criteria 1 and 2: Bank, Forge, Camp fire, the six teachers in '
      'their order, then the trainer', (t) async {
    await pumpGame(t);
    expect(teachers, hasLength(6));
    final rows = [...services, ...teachers, 'trainer'];
    final tops = [for (final r in rows) t.getTopLeft(key(r)).dy];
    for (var i = 1; i < rows.length; i++) {
      expect(
        tops[i],
        greaterThan(tops[i - 1]),
        reason: '${rows[i]} under ${rows[i - 1]}',
      );
    }
  });

  testWidgets('criterion 3: at 408 by 884 dp the three services are in view '
      'with "Here" at the top', (t) async {
    await pumpGame(t);
    t.view.physicalSize = const Size(408, 884);
    await t.pumpAndSettle();
    final here = find.widgetWithText(Heading, 'Here');
    await Scrollable.ensureVisible(t.element(here));
    await t.pumpAndSettle();
    final bar = t.getTopLeft(find.byType(NavigationBar)).dy;
    expect(t.getTopLeft(here).dy, lessThan(bar));
    for (final r in services) {
      final rect = t.getRect(key(r));
      expect(rect.top, greaterThan(t.getTopLeft(here).dy), reason: r);
      expect(rect.bottom, lessThanOrEqualTo(bar), reason: '$r in view');
    }
  });

  testWidgets('criteria 4 and 5: the Bank row has its words and no button', (
    t,
  ) async {
    await pumpGame(t);
    expect(find.text('Open bank'), findsNothing);
    expect(key('open-bank'), findsNothing);
    expect(
      find.descendant(
        of: bankRow,
        matching: find.byWidgetPredicate(
          (w) => w is ButtonStyleButton || w is IconButton,
        ),
      ),
      findsNothing,
    );
    for (final words in ['Bank', 'Store items and take them back']) {
      expect(
        find.descendant(of: bankRow, matching: find.text(words)),
        findsOneWidget,
        reason: words,
      );
    }
    expect(
      find.descendant(
        of: bankRow,
        matching: find.byIcon(Icons.account_balance),
      ),
      findsOneWidget,
    );
  });

  testWidgets('criterion 6: a tap on the Bank row opens the bank', (t) async {
    await pumpGame(t);
    await t.ensureVisible(bankRow);
    await t.pumpAndSettle();
    await t.tap(bankRow);
    await t.pumpAndSettle();
    expect(key('bank-screen'), findsOneWidget);
  });

  testWidgets('criterion 7: away from Camp, Now shows no Bank row', (t) async {
    await pumpGame(t, location: 'goblin_woods');
    expect(bankRow, findsNothing);
  });
}
