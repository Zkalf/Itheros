part of '../data.dart';

/// What a quest asks for (spec 0024 §2.3).
enum TaskKind { kill, gather, craft, bring, wear, visit }

/// A quest's one task: [kind] of [target] (a monster, an item or a place),
/// [count] times, and its [words] for the screens.
class QuestTask {
  QuestTask._(Map<String, Object?> j)
    : kind = TaskKind.values.byName(_str(j, 'kind')),
      target = _str(j, 'target'),
      count = _int(j, 'count'),
      words = _str(j, 'words');

  final TaskKind kind;
  final String target;
  final int count;
  final String words;
}

/// A request from a person or a teacher (spec 0024 §2.1).
class QuestDef {
  QuestDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      giver = _str(j, 'giver'),
      title = _str(j, 'title'),
      after = j['after'] as String?,
      task = QuestTask._(_map(j, 'task')),
      xp = _int(j, 'xp'),
      ask = _str(j, 'ask'),
      thanks = _str(j, 'thanks');

  final String id;

  /// A person's id, or a teacher's profession id.
  final String giver;
  final String title;

  /// The quest that must be done before this one is offered, or null.
  final String? after;
  final QuestTask task;
  final int xp;

  /// What the giver says when the quest is offered, and at hand-in.
  final String ask;
  final String thanks;
}
