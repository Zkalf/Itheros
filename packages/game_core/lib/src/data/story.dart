part of '../data.dart';

/// A named character of the world with a place and lines (spec 0023 §2.1).
class PersonDef {
  PersonDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      title = _str(j, 'title'),
      location = _str(j, 'location'),
      lines = List.unmodifiable(_maps(j, 'lines').map(LineDef._));

  final String id;
  final String name;
  final String title;
  final String location;

  /// In data order: the newest open line is the last open one (§2.2).
  final List<LineDef> lines;
}

/// One thing a person says (spec 0023 §2.2): open once its condition holds
/// and its origin fits; it may give a lore page when heard.
class LineDef {
  LineDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      text = _str(j, 'text'),
      after = switch (j['after']) {
        final Map<String, Object?> m => Criterion._(m),
        _ => null,
      },
      origin = j['origin'] as String?,
      page = j['page'] as String?,
      who = j['who'] as String?;

  final String id;
  final String text;

  /// The condition (§2.3): a counter or level criterion; null when open from
  /// the start.
  final Criterion? after;
  final String? origin;
  final String? page;

  /// For a King line: the teacher's profession, or [GameData.trainerId].
  final String? who;
}

/// Where a lore page comes from (spec 0023 §2.4).
enum PageSource { start, visit, deed, line, find }

/// A piece of lore about a place or the story (spec 0023 §2.4).
class PageDef {
  PageDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      place = _str(j, 'place'),
      source = PageSource.values.byName(_str(j, 'source')),
      after = switch (j['after']) {
        final Map<String, Object?> m => Criterion._(m),
        _ => null,
      },
      title = _str(j, 'title'),
      text = _str(j, 'text');

  final String id;
  final String place;
  final PageSource source;

  /// For a deed page: the deed.
  final Criterion? after;
  final String title;
  final String text;
}
