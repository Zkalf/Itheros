// A meal that saves steps says so as a tool does: "−6% steps" (owner,
// 2026-10-25, after spec 0010 amendment 7 gave tools these words).

import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'ui_test.dart' show game;

void main() {
  final labels = Labels(game.data);

  test('a fewer-steps meal says "−N% steps", by tier', () {
    expect(labels.mealBuff('boar_stew'), '−6% steps');
    expect(labels.mealBuff('black_boar_stew'), '−10% steps');
    expect(labels.mealBuff('grouse_pie'), '−14% steps');
  });

  test('the length of a fewer-steps meal keeps its words', () {
    expect(labels.mealLength('boar_stew'), startsWith('−6% steps for '));
  });

  test('the other buffs keep their words', () {
    expect(labels.mealBuff('venison_skewer'), '+6% Attack');
  });
}
