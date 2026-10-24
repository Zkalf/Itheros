import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'theme.dart';

/// A monster's level in its colour, or the skull image when far above the
/// player (spec 0002 §3, §9.2; spec 0014 §2.3).
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, required this.colour});

  final int level;
  final LevelColour colour;

  static Color colorOf(LevelColour c) => switch (c) {
    LevelColour.grey => const Color(0xFF9E9E9E),
    LevelColour.green => const Color(0xFF43A047),
    LevelColour.yellow => const Color(0xFFFBC02D),
    LevelColour.orange => const Color(0xFFFB8C00),
    LevelColour.red => const Color(0xFFE53935),
    LevelColour.skull => const Color(0xFF8E0000),
  };

  /// The skull of the band: a picture, not a placeholder, so it shows with
  /// each image index.
  static const _skull = AssetImage('assets/images/pictures/skull.webp');

  /// The level number stands alone, so it is Spectral (spec 0014 §2.2). It
  /// is body text in size, so that the badge keeps its size in a row title
  /// too.
  static const _number = TextStyle(
    fontFamily: Fonts.number,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );
  static const _padding = 6.0;
  static const _skullPadding = 2.0;

  @override
  Widget build(BuildContext context) {
    final skull = colour == LevelColour.skull;
    return Container(
      width: 44,
      padding: EdgeInsets.symmetric(vertical: skull ? _skullPadding : _padding),
      decoration: BoxDecoration(
        color: colorOf(colour),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: skull
          ? _skullOf(context)
          : Text(
              '$level',
              semanticsLabel: 'Level $level',
              style: _number.copyWith(
                color: colour == LevelColour.yellow
                    ? Colors.black
                    : Colors.white,
              ),
            ),
    );
  }

  /// The skull takes the line of the number and all but 2 dp of the
  /// padding, so each band has the same height at each text size of the
  /// phone. The line comes from a layout of the number, as a band with a
  /// number lays it out. Screen readers still say the words; the image adds
  /// nothing.
  Widget _skullOf(BuildContext context) {
    final number = TextPainter(
      text: TextSpan(
        text: '$level',
        style: DefaultTextStyle.of(context).style.merge(_number),
      ),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
    )..layout();
    final size = number.height + 2 * (_padding - _skullPadding);
    number.dispose();
    return Semantics(
      label: 'Level: far too strong',
      child: Image(
        image: _skull,
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
    );
  }
}
