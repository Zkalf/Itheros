import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

/// A monster's level in its colour, or a skull when far above the player
/// (spec 0002 §3, §9.2).
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

  @override
  Widget build(BuildContext context) {
    final skull = colour == LevelColour.skull;
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorOf(colour),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        skull ? '💀' : '$level',
        semanticsLabel: skull ? 'Level: far too strong' : 'Level $level',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colour == LevelColour.yellow ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
