/// What a level-up card lists, in the order of spec 0002 §9.1.
enum NewsKind {
  /// A new rank and its ceremony line.
  rank,

  /// A gathering spot the player can now work (spec 0008 amendment 1).
  gatheringSpot,

  /// A recipe the player can now craft (spec 0008 amendment 2).
  recipe,
  talentPoint,

  /// A monster that is now exactly the player's level.
  yourLevel,

  /// A monster that just turned grey; it still drops its loot.
  turnedGrey,
}

class LevelNews {
  const LevelNews(this.kind, this.id);

  final NewsKind kind;

  /// Rank name, enemy, node or recipe id; empty for a talent point.
  final String id;

  @override
  bool operator ==(Object other) =>
      other is LevelNews && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'LevelNews(${kind.name}, $id)';
}
