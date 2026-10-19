import 'package:game_core/game_core.dart';

/// Everything the app persists: the game plus per-day step credit
/// (spec 0001 amendment 1) and screen settings (spec 0002 §9). Saved in one
/// atomic write.
class SaveData {
  SaveData({
    required this.game,
    required this.firstDay,
    required Map<String, int> credited,
    this.nextGoalHidden = false,
    Set<String> seen = const {},
  }) : credited = Map.unmodifiable(credited),
       seen = Set.unmodifiable(seen);

  factory SaveData.fromJson(Map<String, Object?> json) {
    final v = json['version'];
    if (v != 1 && v != version) {
      throw FormatException('Unsupported save version: $v');
    }
    return SaveData(
      game: GameState.fromJson(json['game'] as Map<String, Object?>),
      firstDay: json['firstDay'] as String,
      credited: (json['credited'] as Map<String, Object?>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      nextGoalHidden: json['nextGoalHidden'] as bool? ?? false,
      seen: (json['seen'] as List<Object?>? ?? const []).cast<String>().toSet(),
    );
  }

  /// 2: adds [nextGoalHidden] and [seen].
  static const version = 2;

  final GameState game;

  /// Install day (`yyyy-mm-dd`, local). Earlier days are never credited.
  final String firstDay;

  /// Steps already credited per local day (`yyyy-mm-dd`).
  final Map<String, int> credited;

  /// The player hid the "Next goal" line (allowed from level 10).
  final bool nextGoalHidden;

  /// Areas and monsters whose flavour line was already shown.
  final Set<String> seen;

  SaveData withGame(GameState game) => copyWith(game: game);

  SaveData copyWith({
    GameState? game,
    Map<String, int>? credited,
    bool? nextGoalHidden,
    Set<String>? seen,
  }) => SaveData(
    game: game ?? this.game,
    firstDay: firstDay,
    credited: credited ?? this.credited,
    nextGoalHidden: nextGoalHidden ?? this.nextGoalHidden,
    seen: seen ?? this.seen,
  );

  Map<String, Object?> toJson() => {
    'version': version,
    'firstDay': firstDay,
    'credited': Map.of(credited),
    'nextGoalHidden': nextGoalHidden,
    'seen': seen.toList()..sort(),
    'game': game.toJson(),
  };
}
