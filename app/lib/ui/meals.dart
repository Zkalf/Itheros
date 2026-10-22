import 'package:game_core/game_core.dart';

import 'labels.dart';

/// The running meal in one line (spec 0011 §8.2): "Venison skewer · +6%
/// Attack · 1,850 steps left · auto-eat until out (4)"; null with none.
String? mealLine(Game game, GameState s, {bool withAuto = true}) {
  final meal = s.meal;
  if (meal == null) return null;
  final labels = Labels(game.data);
  final auto = s.autoEat;
  return [
    labels.item(meal.key),
    labels.mealBuff(meal.key),
    '${fmt(meal.left)} steps left',
    if (withAuto && auto != null)
      'auto-eat '
          '${auto.meal == game.data.itemOf(meal.key)?.id ? '' : '${labels.item(auto.meal)} '}'
          '${autoEatMode(auto)} (${game.owned(s, auto.meal)})',
  ].join(' · ');
}

/// "until out", or "keep 2" for "only N" (spec 0011 §5.4).
String autoEatMode(AutoEat auto) =>
    auto.keep == 0 ? 'until out' : 'keep ${auto.keep}';

/// The auto-eat choice in words, for the Cooking card: "Auto-eat: Venison
/// skewer, until out (4 in the bag)".
String autoEatLine(Game game, GameState s) {
  final auto = s.autoEat;
  if (auto == null) return 'Auto-eat: off. Pick a meal in your bag.';
  return 'Auto-eat: ${Labels(game.data).item(auto.meal)}, '
      '${autoEatMode(auto)} (${game.owned(s, auto.meal)} in the bag)';
}
