enum ActivityKind { travel, fight, gather, craft }

/// What the player asked the character to do. Every activity costs steps.
class Activity {
  const Activity.travel(String to) : this._(ActivityKind.travel, to);
  const Activity.fight(String enemy) : this._(ActivityKind.fight, enemy);
  const Activity.gather(String node) : this._(ActivityKind.gather, node);
  const Activity.craft(String recipe) : this._(ActivityKind.craft, recipe);
  const Activity._(this.kind, this.target);

  factory Activity.fromJson(Map<String, Object?> json) => Activity._(
    ActivityKind.values.byName(json['kind'] as String),
    json['target'] as String,
  );

  final ActivityKind kind;

  /// Destination, enemy, node or recipe id, depending on [kind].
  final String target;

  Map<String, Object?> toJson() => {'kind': kind.name, 'target': target};

  @override
  bool operator ==(Object other) =>
      other is Activity && other.kind == kind && other.target == target;

  @override
  int get hashCode => Object.hash(kind, target);

  @override
  String toString() => 'Activity.${kind.name}($target)';
}

/// A player action the rules don't allow (locked, wrong place, no materials).
class ActivityError implements Exception {
  ActivityError(this.message);

  final String message;

  @override
  String toString() => 'ActivityError: $message';
}
