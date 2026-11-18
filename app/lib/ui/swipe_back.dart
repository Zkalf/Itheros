import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/gestures.dart' show VelocityTracker, kTouchSlop;
import 'package:flutter/material.dart';

/// The slide of [CupertinoPageTransitionsBuilder] (#141), with a swipe to the
/// right from anywhere on the screen that goes back (spec 0014 amendment 5).
/// The edge swipe of Flutter stays. On a screen that Back does not leave,
/// such as one with a selection of items, a swipe to the right does what
/// Back does there, and the screen does not move (#287).
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

  /// The finger that touched a screen that Back does not leave, such as one
  /// with a selection of items (#287); null when no such finger is down.
  int? _blockedPointer;

  /// Where [_blockedPointer] touched the screen.
  var _blockedStart = Offset.zero;

  /// The speed of [_blockedPointer].
  VelocityTracker? _blockedSpeed;

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

  // A swipe on a screen that Back does not leave. The screen does not move
  // and has nothing to drag, so the swipe watches the finger without a
  // gesture of its own: a list or the tabs of the screen keep their drags,
  // and the swipe still counts on the tabs of the bank screen (#287).
  void _down(PointerDownEvent e) {
    final route = widget.route;
    if (_blockedPointer != null ||
        !route.isCurrent ||
        route.popDisposition != RoutePopDisposition.doNotPop) {
      return;
    }
    _blockedPointer = e.pointer;
    _blockedStart = e.position;
    _blockedSpeed = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.position);
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer == _blockedPointer) {
      _blockedSpeed!.addPosition(e.timeStamp, e.position);
    }
  }

  /// When the finger lets go after a swipe to the right, the swipe does what
  /// Back does on this screen: it ends the selection, and the screen stays.
  void _up(PointerUpEvent e) {
    if (e.pointer != _blockedPointer) return;
    final speed = _blockedSpeed!.getVelocity().pixelsPerSecond.dx;
    _blockedPointer = null;
    _blockedSpeed = null;
    final width = context.size!.width;
    final move = e.position - _blockedStart;
    // Sideways, not a scroll: past the touch slop, and more to the side
    // than up or down.
    if (move.dx <= kTouchSlop || move.dx < 2 * move.dy.abs()) return;
    // The rules of the swipe that goes back: a quick swipe decides by its
    // direction, a slow one by how far the finger went.
    final right = (speed / width).abs() >= _minFling
        ? speed > 0
        : move.dx / width > 0.5;
    final route = widget.route;
    if (right && route.isCurrent) unawaited(route.navigator?.maybePop());
  }

  void _lost(PointerCancelEvent e) {
    if (e.pointer != _blockedPointer) return;
    _blockedPointer = null;
    _blockedSpeed = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: _lost,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: _cancel,
      child: widget.child,
    ),
  );
}
