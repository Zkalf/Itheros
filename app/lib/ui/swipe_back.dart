import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// The slide of [CupertinoPageTransitionsBuilder] (#141), with a swipe to the
/// right from anywhere on the screen that goes back (spec 0014 amendment 5).
/// The edge swipe of Flutter stays.
class SwipeBackPageTransitionsBuilder extends PageTransitionsBuilder {
  const SwipeBackPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => const CupertinoPageTransitionsBuilder().buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    _SwipeBack(route: route, child: child),
  );
}

/// The swipe. It joins the gesture arena as a horizontal drag, so a tap or a
/// vertical scroll of a child wins as before; a touch must move past the
/// touch slop to the side before it counts.
class _SwipeBack extends StatefulWidget {
  const _SwipeBack({required this.route, required this.child});

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_SwipeBack> createState() => _SwipeBackState();
}

class _SwipeBackState extends State<_SwipeBack> {
  /// Screen widths per second: a quicker swipe goes back from any distance.
  /// The value of Flutter's edge swipe.
  static const _minFling = 1.0;

  /// How long the screen takes to slide out or back after the finger lets go,
  /// as with Flutter's edge swipe.
  static const _settle = Duration(milliseconds: 350);

  /// The route's animation while the finger drags it; null when no swipe runs.
  AnimationController? _drag;

  /// The drag went left first: it does nothing until the finger lets go.
  var _ignored = false;

  // The route's own animation, as Flutter's edge swipe moves it. It is a
  // protected member of TransitionRoute.
  // ignore: invalid_use_of_protected_member
  AnimationController? get _controller => widget.route.controller;

  void _update(DragUpdateDetails d) {
    if (_ignored) return;
    final dx = d.primaryDelta ?? 0;
    if (_drag == null) {
      // Only a swipe to the right goes back (spec 0014 amendment 5).
      if (dx <= 0 || !widget.route.popGestureEnabled) {
        _ignored = true;
        return;
      }
      _drag = _controller;
      if (_drag == null) return;
      widget.route.navigator?.didStartUserGesture();
    }
    _drag!.value -= dx / context.size!.width;
  }

  void _end(DragEndDetails d) {
    final drag = _drag;
    _drag = null;
    _ignored = false;
    if (drag == null) return;
    final route = widget.route;
    final navigator = route.navigator!;
    final velocity = d.velocity.pixelsPerSecond.dx / context.size!.width;
    // The rules of Flutter's edge swipe: a quick swipe decides by its
    // direction, a slow one by how far the screen moved.
    final stay = !route.isCurrent
        ? route.isActive
        : velocity.abs() >= _minFling
        ? velocity <= 0
        : drag.value > 0.5;
    const curve = Curves.fastEaseInToSlowEaseOut;
    if (stay) {
      drag.animateTo(1, duration: _settle, curve: curve);
    } else {
      if (route.isCurrent) navigator.pop();
      if (drag.isAnimating) {
        drag.animateBack(0, duration: _settle, curve: curve);
      }
    }
    if (drag.isAnimating) {
      late AnimationStatusListener done;
      done = (_) {
        navigator.didStopUserGesture();
        drag.removeStatusListener(done);
      };
      drag.addStatusListener(done);
    } else {
      navigator.didStopUserGesture();
    }
  }

  void _cancel() {
    final drag = _drag;
    _drag = null;
    _ignored = false;
    if (drag == null) return;
    drag.animateTo(1, duration: _settle, curve: Curves.fastEaseInToSlowEaseOut);
    widget.route.navigator?.didStopUserGesture();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragUpdate: _update,
    onHorizontalDragEnd: _end,
    onHorizontalDragCancel: _cancel,
    child: widget.child,
  );
}
