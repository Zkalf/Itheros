// A picture for each profession: spec 0014 amendment 7, criteria 1-6
// (plan 0045).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'images_test.dart' show diskImages;
import 'ui_test.dart';

void main() {
  const professions = [
    'mining',
    'woodcutting',
    'crafting',
    'fishing',
    'hunting',
    'cooking',
  ];
  Finder within(String key, Finder f) =>
      find.descendant(of: find.byKey(ValueKey(key)), matching: f);
  Finder picture(String id) => find.byKey(ValueKey('profession-picture-$id'));
  Finder glyph(String id) => find.byKey(ValueKey('profession-glyph-$id'));

  test('criterion 1: each profession has its picture file', () {
    for (final id in professions) {
      expect(
        File('assets/images/professions/$id.webp').existsSync(),
        isTrue,
        reason: id,
      );
    }
  });

  testWidgets('criterion 2: each card in the Professions tab shows its '
      'picture at 32 dp', (t) async {
    await pumpGame(t, images: diskImages);
    await openTab(t, 'professions');
    for (final id in professions) {
      await t.ensureVisible(picture(id).first);
      expect(picture(id), findsWidgets, reason: id);
      expect(t.getSize(picture(id).first), const Size(32, 32), reason: id);
    }
  });

  testWidgets('criterion 3: the profession screen shows the picture in its '
      'header', (t) async {
    await pumpGame(t, images: diskImages);
    await openTab(t, 'professions');
    await t.ensureVisible(
      find.byKey(const ValueKey('profession-button-mining')),
    );
    await t.tap(find.byKey(const ValueKey('profession-button-mining')));
    await t.pumpAndSettle();
    final head = within('profession-head-mining', picture('mining'));
    expect(head, findsOneWidget);
    expect(t.getSize(head), const Size(32, 32));
  });

  testWidgets('criterion 4: a teacher row on Now shows the picture of the '
      "teacher's profession", (t) async {
    await pumpGame(t, images: diskImages);
    final row = find.byKey(const ValueKey('teacher-mining'));
    await t.ensureVisible(row);
    final pic = within('teacher-mining', picture('mining'));
    expect(pic, findsOneWidget);
    expect(t.getSize(pic), const Size(32, 32));
  });

  testWidgets('criterion 5: without a picture file, the glyph shows in the '
      'three places', (t) async {
    await pumpGame(t);
    await t.ensureVisible(find.byKey(const ValueKey('teacher-mining')));
    expect(within('teacher-mining', glyph('mining')), findsOneWidget);
    expect(picture('mining'), findsNothing);
    await openTab(t, 'professions');
    expect(glyph('mining'), findsWidgets);
    await t.ensureVisible(
      find.byKey(const ValueKey('profession-button-mining')),
    );
    await t.tap(find.byKey(const ValueKey('profession-button-mining')));
    await t.pumpAndSettle();
    expect(within('profession-head-mining', glyph('mining')), findsOneWidget);
  });

  testWidgets('criterion 6: the Professions tab button keeps its glyph', (
    t,
  ) async {
    await pumpGame(t, images: diskImages);
    expect(find.byIcon(Icons.handyman), findsWidgets);
  });
}
