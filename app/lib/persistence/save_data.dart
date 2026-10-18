import 'package:game_core/game_core.dart';

/// Everything the app persists: the game plus per-day step credit
/// (spec 0001 amendment 1). Saved in one atomic write.
class SaveData {
  SaveData({
    required this.game,
    required this.firstDay,
    required Map<String, int> credited,
  }) : credited = Map.unmodifiable(credited);

  factory SaveData.fromJson(Map<String, Object?> json) {
    if (json['version'] != version) {
      throw FormatException('Unsupported save version: ${json['version']}');
    }
    return SaveData(
      game: GameState.fromJson(json['game'] as Map<String, Object?>),
      firstDay: json['firstDay'] as String,
      credited: (json['credited'] as Map<String, Object?>).map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }

  static const version = 1;

  final GameState game;

  /// Install day (`yyyy-mm-dd`, local). Earlier days are never credited.
  final String firstDay;

  /// Steps already credited per local day (`yyyy-mm-dd`).
  final Map<String, int> credited;

  SaveData withGame(GameState game) =>
      SaveData(game: game, firstDay: firstDay, credited: credited);

  Map<String, Object?> toJson() => {
    'version': version,
    'firstDay': firstDay,
    'credited': Map.of(credited),
    'game': game.toJson(),
  };
}
