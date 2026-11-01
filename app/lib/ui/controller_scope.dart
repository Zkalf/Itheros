import 'package:flutter/widgets.dart';

import '../game_controller.dart';

/// Gives widgets the [GameController] and rebuilds them when it changes.
class ControllerScope extends InheritedNotifier<GameController> {
  const ControllerScope({
    super.key,
    required GameController controller,
    required super.child,
  }) : super(notifier: controller);

  static GameController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ControllerScope>()!.notifier!;

  /// The controller without a rebuild when it changes: for `initState`.
  static GameController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ControllerScope>()!.notifier!;
}
