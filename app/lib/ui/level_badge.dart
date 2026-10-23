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

  /// The number is body text in size, so that the badge keeps its size in
  /// a row title too. The skull takes the line of the number and all but
  /// 2 dp of the padding, so each band has the same height.
  static const _size = 15.0;
  static const _line = 1.35;
  static const _padding = 6.0;
  static const _skullPadding = 2.0;
  static const _skullSize = _size * _line + 2 * (_padding - _skullPadding);

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
          // Screen readers still say the words; the image adds nothing.
          ? Semantics(
              label: 'Level: far too strong',
              child: const Image(
                image: _skull,
                width: _skullSize,
                height: _skullSize,
                excludeFromSemantics: true,
              ),
            )
          : Text(
              '$level',
              semanticsLabel: 'Level $level',
              // The level number stands alone, so it is Spectral (spec 0014
              // §2.2).
              style: TextStyle(
                fontFamily: Fonts.number,
                fontSize: _size,
                height: _line,
                fontWeight: FontWeight.w600,
                color: colour == LevelColour.yellow
                    ? Colors.black
                    : Colors.white,
              ),
            ),
    );
  }
}
