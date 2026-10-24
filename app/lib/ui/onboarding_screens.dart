import 'dart:async' show Completer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../version.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'theme.dart';

/// The splash picture (spec 0014 §3.1 and §3.3). It is a picture of the
/// style, not a thing, so it shows with each image index and has no
/// placeholder.
final _splash = AssetImage(const Picture('pictures/splash').asset!);

/// Decodes the splash picture into the image cache, so that the first frame
/// of the splash shows it. A picture that does not load does not stop the
/// app.
Future<void> precacheSplash() {
  final done = Completer<void>();
  final stream = _splash.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    stream.removeListener(listener);
    if (!done.isCompleted) done.complete();
  }

  // The image cache keeps the picture, so the listener disposes its own
  // handle to it, as precacheImage does.
  listener = ImageStreamListener((info, _) {
    info.dispose();
    finish();
  }, onError: (_, _) => finish());
  stream.addListener(listener);
  return done.future;
}

/// The splash picture, cut to fill its box. A screen reader skips it.
Widget _picture([Alignment alignment = Alignment.center]) => Image(
  image: _splash,
  fit: BoxFit.cover,
  alignment: alignment,
  excludeFromSemantics: true,
);

/// [screen] with dark status bar icons, on the splash picture (spec 0014
/// §2.1). The app gives each other screen the light icons.
Widget _onPicture(Widget screen) =>
    AnnotatedRegion<SystemUiOverlayStyle>(value: darkStatusBar, child: screen);

/// The splash (spec 0014 §3.3): the splash picture fills the screen, behind
/// both bars. ITHEROS is near the top. A plate at the bottom holds the teal
/// loading bar, "Reading your steps" and the version.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _onPicture(
      Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // The cut keeps the traveller and the signpost on the left in
            // view (the design, phone 01).
            _picture(const Alignment(-.6, 0)),
            SafeArea(
              child: Column(
                children: [
                  // The wordmark stands a tenth of the free height below
                  // the status bar, as in the design (phone 01).
                  const Spacer(),
                  const _Wordmark(),
                  const Spacer(flex: 9),
                  Card(
                    margin: const EdgeInsets.all(gutter),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                      child: Column(
                        children: [
                          const LinearProgressIndicator(color: Quiet.teal),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  'Reading your steps',
                                  style: text.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              // As Settings shows it.
                              Text(
                                'Version $appVersion',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ITHEROS in Cormorant Garamond, dark on the sky of the splash picture,
/// under a rule of two lines and a diamond (the design, phone 01).
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  // The letters stand 0.3 em apart (the design tokens).
  static const _size = 50.0;
  static const _spacing = _size * .3;

  @override
  Widget build(BuildContext context) {
    final rule = Quiet.onTeal.withValues(alpha: .55);
    Widget line() =>
        SizedBox(width: 64, height: 1, child: ColoredBox(color: rule));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // A narrow phone or a large text size shrinks the word to fit.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                line(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: SizedBox.square(
                      dimension: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: rule, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
                line(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'ITHEROS',
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                fontSize: _size,
                letterSpacing: _spacing,
                height: 1,
                color: Quiet.onTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The welcome and "Health Connect is needed" (spec 0014 §3.3): the splash
/// picture at the top, behind the status bar. Below it, today's words and
/// the teal button stand on a plate.
class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _onPicture(
      Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _picture()),
            // The plate takes the lower 45% of the screen, as in the design
            // (phones 02 and 03), or more if its words need it. Thus the
            // picture keeps its height from one screen to the other.
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height * .45,
              ),
              child: SafeArea(
                top: false,
                child: Card(
                  margin: const EdgeInsets.all(gutter),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(title, style: text.headlineSmall),
                            const SizedBox(height: 12),
                            Text(body, style: text.bodyLarge),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: FilledButton(
                            onPressed: onPressed,
                            child: Text(button),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    return _Message(
      title: 'Your steps are your power',
      body:
          'Every fight, ore and crafted item is paid for with steps you walk. '
          'Allow step access so your walks count. Your step data stays on '
          'this phone. Steps walked before you install the game don\'t count.',
      button: 'Allow step access',
      onPressed: controller.requestPermission,
    );
  }
}

class UnavailableScreen extends StatelessWidget {
  const UnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ControllerScope.of(context);
    return _Message(
      title: 'Health Connect is needed',
      body:
          'This game reads your steps from Health Connect. Install or update '
          'Health Connect from the Play Store, then try again.',
      button: 'Try again',
      onPressed: controller.start,
    );
  }
}
