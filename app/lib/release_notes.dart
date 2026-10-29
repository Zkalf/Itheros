import 'package:flutter/services.dart';

/// A version "x.y.z" (spec 0018 §2.1): ordered by x, then y, then z.
class Version implements Comparable<Version> {
  const Version(this.major, this.minor, this.patch);

  static final _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  /// Null for a text that is not "x.y.z", such as "next".
  static Version? tryParse(String text) {
    final m = _pattern.firstMatch(text);
    if (m == null) return null;
    return Version(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  final int major, minor, patch;

  @override
  int compareTo(Version other) => major != other.major
      ? major.compareTo(other.major)
      : minor != other.minor
      ? minor.compareTo(other.minor)
      : patch.compareTo(other.patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// The release notes that come with the app (spec 0018 §2.1): the text of
/// each version, and of `releases/next.md` if the build has it.
class ReleaseNotes {
  const ReleaseNotes(this.versions, {this.next});

  /// From file names and texts: `x.y.z.md` and `next.md`. Each other file is
  /// skipped.
  factory ReleaseNotes.fromFiles(Map<String, String> files) {
    final versions = <String, String>{};
    String? next;
    for (final MapEntry(key: name, value: text) in files.entries) {
      if (!name.endsWith('.md')) continue;
      final base = name.substring(0, name.length - 3);
      if (base == 'next') {
        next = text;
      } else if (Version.tryParse(base) != null) {
        versions[base] = text;
      }
    }
    return ReleaseNotes(versions, next: next);
  }

  /// No notes: a build without the copy of `releases/` (plan 0029), and
  /// tests that do not test the notes.
  static const empty = ReleaseNotes({});

  /// The folder of the copy of `releases/` in the assets (plan 0029).
  static const folder = 'assets/releases/';

  static Future<ReleaseNotes> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final keys = [
      for (final key in manifest.listAssets())
        if (key.startsWith(folder)) key,
    ];
    // All files at once: the app waits for them before its first frame.
    final texts = await Future.wait(keys.map(bundle.loadString));
    return ReleaseNotes.fromFiles({
      for (final (i, key) in keys.indexed)
        key.substring(folder.length): texts[i],
    });
  }

  /// The text of each version, by "x.y.z".
  final Map<String, String> versions;

  /// The text of `releases/next.md`, for the owner's build only (§3.4).
  final String? next;

  /// The versions of the card at open, newest first (§2.3): each one after
  /// [lastVersion], up to [appVersion]. With no [lastVersion] (a save from
  /// before spec 0018), only [appVersion].
  List<String> toShow(String? lastVersion, String appVersion) {
    final last = lastVersion == null ? null : Version.tryParse(lastVersion);
    if (last == null) {
      return versions.containsKey(appVersion) ? [appVersion] : const [];
    }
    return _newestFirst((v) => v.compareTo(last) > 0, appVersion);
  }

  /// The versions in Settings, newest first (§3.4): each one up to
  /// [appVersion].
  List<String> upTo(String appVersion) => _newestFirst((_) => true, appVersion);

  List<String> _newestFirst(bool Function(Version) keep, String appVersion) {
    final app = Version.tryParse(appVersion);
    if (app == null) return const [];
    final list = [
      for (final v in versions.keys.map(Version.tryParse).nonNulls)
        if (v.compareTo(app) <= 0 && keep(v)) v,
    ]..sort((a, b) => b.compareTo(a));
    return [for (final v in list) '$v'];
  }
}

/// A piece of the text of a [NoteBlock]: plain or bold.
class NotePart {
  const NotePart(this.text, {this.bold = false});

  final String text;
  final bool bold;
}

/// A paragraph (depth 0), a list item (depth 1) or an item of a list inside
/// an item (depth 2) of the notes (spec 0018 §3.3, amendment 1).
class NoteBlock {
  const NoteBlock(this.parts, {this.depth = 0});

  final List<NotePart> parts;
  final int depth;
}

/// The blocks of [text], in the format of spec 0018 §3.3 and its
/// amendment 1. Any other Markdown stays as plain text, with its marks.
List<NoteBlock> parseNotes(String text) => [
  for (final (depth, words) in _rawBlocks(text))
    NoteBlock(_parts(words), depth: depth),
];

/// The depth and the text of each block of [text], with its marks. The
/// reader and the check of the format cut the notes the same way.
List<(int, String)> _rawBlocks(String text) {
  final blocks = <(int, String)>[];
  int? depth;
  final words = <String>[];
  void flush() {
    if (depth case final d?) blocks.add((d, words.join(' ')));
    depth = null;
    words.clear();
  }

  void start(int d, String line) {
    flush();
    depth = d;
    words.add(line.trim());
  }

  for (final raw in text.split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flush();
    } else if (line.startsWith('- ')) {
      start(1, line.substring(2));
    } else if (line.startsWith('  - ') && (depth ?? 0) >= 1) {
      start(2, line.substring(4));
    } else if (line.startsWith('  ') && (depth ?? 0) >= 1) {
      words.add(line.trim());
    } else if (depth == 0) {
      words.add(line.trim());
    } else {
      start(0, line);
    }
  }
  flush();
  return blocks;
}

/// The plain and bold parts of [text]: text between `**` and `**` is bold.
List<NotePart> _parts(String text) {
  final pieces = text.split('**');
  // An open `**` stays as it is (§3.3 rule 5).
  if (pieces.length.isEven) return [NotePart(text)];
  return [
    for (var i = 0; i < pieces.length; i++)
      if (pieces[i].isNotEmpty) NotePart(pieces[i], bold: i.isOdd),
  ];
}

final _outside = [
  RegExp(r'^\s*#'), // a heading
  RegExp(r'^\s*\d+\.\s'), // a numbered list
  RegExp(r'^\s*[*+]\s'), // a list with * or +
  RegExp(r'^\s*\|'), // a table
  // An item starts with 0 or 2 spaces: 4 would be a third list, 1 or 3 an
  // item that the reader joins to the item above.
  RegExp(r'^( | {3,})- '),
  RegExp(r'\[[^\]]*\]\('), // a link
  RegExp('`'), // code
  RegExp(r'(^|[\s(])_\S'), // an emphasis with _
];

/// True when [text] uses only the format of spec 0018 §3.3 and its
/// amendment 1. A test checks each file in `releases/` with it.
bool usesOnlyKnownMarks(String text) {
  for (final line in text.split('\n')) {
    if (_outside.any((p) => p.hasMatch(line))) return false;
  }
  // Each `**` pairs inside its own paragraph or item, as the reader shows it.
  for (final (_, block) in _rawBlocks(text)) {
    final pieces = block.split('**');
    if (pieces.length.isEven) return false;
    if (pieces.any((p) => p.contains('*'))) return false;
  }
  return true;
}
