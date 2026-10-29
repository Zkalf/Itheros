// The release notes in the app (spec 0018 §2.1, §2.3, §3.3 and its
// amendment 1): versions, the versions that the card shows, the format of the
// notes, and the files in `releases/`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/release_notes.dart';
import 'package:walkingrpg/version.dart';

/// Notes for each of [versions], each with the line "Notes of `x.y.z`.".
ReleaseNotes notesUpTo(List<String> versions, {String? next}) =>
    ReleaseNotes({for (final v in versions) v: 'Notes of $v.'}, next: next);

const _all = ['0.2.0', '0.3.0', '0.4.0', '0.5.0', '0.5.1', '0.6.0'];

/// The `.md` files of a folder, by name. None if the folder does not exist.
Map<String, String> _mdFiles(String path) => {
  if (Directory(path).existsSync())
    for (final f in Directory(path).listSync().whereType<File>())
      if (f.path.endsWith('.md')) f.uri.pathSegments.last: f.readAsStringSync(),
};

void main() {
  group('versions (spec 0018 §2.1)', () {
    test('0.10.0 comes after 0.9.0 (criterion 4)', () {
      expect(
        Version.tryParse('0.10.0')!.compareTo(Version.tryParse('0.9.0')!),
        greaterThan(0),
      );
    });

    test('x, then y, then z decide the order', () {
      final sorted = [
        '1.0.0',
        '0.5.1',
        '0.10.0',
        '0.5.0',
      ].map((v) => Version.tryParse(v)!).toList()..sort();
      expect(sorted.map((v) => '$v'), ['0.5.0', '0.5.1', '0.10.0', '1.0.0']);
    });

    test('a name that is not x.y.z is no version', () {
      expect(Version.tryParse('next'), isNull);
      expect(Version.tryParse('0.5'), isNull);
      expect(Version.tryParse('signing-cert'), isNull);
    });

    test('fromFiles takes x.y.z.md and next.md, and skips the rest', () {
      final notes = ReleaseNotes.fromFiles({
        '0.4.0.md': 'Four.',
        '0.5.0.md': 'Five.',
        'next.md': 'Next.',
        'signing-cert.txt': 'AB:CD',
        'README.md': 'Read me.',
      });
      expect(notes.versions, {'0.4.0': 'Four.', '0.5.0': 'Five.'});
      expect(notes.next, 'Next.');
    });
  });

  group('the versions on the card (spec 0018 §2.3, §2.4)', () {
    final notes = notesUpTo(_all, next: 'Next.');

    test('a skip from 0.3.0 to 0.6.0 shows 0.6.0, 0.5.1, 0.5.0, 0.4.0 '
        '(criterion 5)', () {
      expect(notes.toShow('0.3.0', '0.6.0'), [
        '0.6.0',
        '0.5.1',
        '0.5.0',
        '0.4.0',
      ]);
    });

    test('a fix release shows its own notes (decision 3)', () {
      expect(notes.toShow('0.5.0', '0.5.1'), ['0.5.1']);
    });

    test('the last version equal to the app version shows nothing '
        '(criterion 6)', () {
      expect(notes.toShow('0.5.0', '0.5.0'), isEmpty);
    });

    test('an empty last version shows only the app version (criterion 7)', () {
      expect(notes.toShow(null, '0.6.0'), ['0.6.0']);
    });

    test('an empty last version and no notes of the app version show '
        'nothing', () {
      expect(notesUpTo(['0.5.0']).toShow(null, '0.6.0'), isEmpty);
    });

    test(
      'a last version after the app version shows nothing (criterion 9)',
      () {
        expect(notes.toShow('0.6.0', '0.5.0'), isEmpty);
      },
    );

    test('next.md never shows on the card (criterion 13)', () {
      expect(notes.toShow('0.2.0', '0.6.0'), isNot(contains('next')));
      expect(notesUpTo([], next: 'Next.').toShow(null, '0.6.0'), isEmpty);
    });

    test('Settings lists each version up to the app version, newest first '
        '(criterion 25)', () {
      expect(notes.upTo('0.5.0'), ['0.5.0', '0.4.0', '0.3.0', '0.2.0']);
    });
  });

  group('the format of the notes (spec 0018 §3.3, amendment 1)', () {
    String plain(NoteBlock b) => b.parts.map((p) => p.text).join();

    test('a first line is a paragraph, "- " lines are items', () {
      final blocks = parseNotes('Small fixes.\n\n- One.\n- Two.\n');
      expect(blocks.map((b) => b.depth), [0, 1, 1]);
      expect(blocks.map(plain), ['Small fixes.', 'One.', 'Two.']);
    });

    test('a line with two spaces joins the item above it (criterion 19)', () {
      final blocks = parseNotes(
        '- **Change:** tap the action, or one\n'
        '  that waits.\n',
      );
      expect(blocks, hasLength(1));
      expect(
        plain(blocks.single),
        'Change: tap the action, or one that waits.',
      );
    });

    test('text between ** is bold, without the ** (criterion 20)', () {
      final parts = parseNotes('- **Fixed:** a meal.').single.parts;
      expect(parts.map((p) => (p.text, p.bold)), [
        ('Fixed:', true),
        (' a meal.', false),
      ]);
    });

    test('"  - " under an item is an item of a second list '
        '(amendment criterion 1)', () {
      final blocks = parseNotes(
        '- **30 achievements:** Early.\n'
        '  - **Milestones** come on the way.\n'
        '  - **Feats** take a long grind.\n'
        '- **The away report** draws your route.\n',
      );
      expect(blocks.map((b) => b.depth), [1, 2, 2, 1]);
      expect(plain(blocks[1]), 'Milestones come on the way.');
    });

    test('a line with four spaces joins an item of the second list', () {
      final blocks = parseNotes('- Top.\n  - Inner,\n    more.\n');
      expect(blocks.map(plain), ['Top.', 'Inner, more.']);
    });

    test('a line with two spaces and no "- " still joins the item '
        '(amendment criterion 3)', () {
      final blocks = parseNotes('- A walk\n  takes a slot.\n');
      expect(blocks.map(plain), ['A walk takes a slot.']);
    });

    test('the known marks pass', () {
      expect(
        usesOnlyKnownMarks('Fixes.\n\n- **A:** b\n  c\n  - **D** e\n'),
        isTrue,
      );
    });

    for (final (name, text) in [
      ('a heading', '# New\n'),
      ('a link', '- See [the guide](INSTALL.md).\n'),
      ('a numbered list', '1. One.\n'),
      ('a star list', '* One.\n'),
      ('one star', '- *Fixed:* a meal.\n'),
      ('an underscore emphasis', '- _Fixed_ a meal.\n'),
      ('code', '- Run `check`.\n'),
      ('a table', '| a | b |\n'),
      ('an open **', '- **Fixed: a meal.\n'),
      ('a third list', '- A\n  - B\n    - C\n'),
      // PR #132 review: ** pairs inside one item, not across two items.
      ('a ** that spans two items', '- **Bold start\n- end**\n'),
      // PR #132 review: an item starts with 0 or 2 spaces only.
      ('an item with 3 spaces', '- Item\n   - sub\n'),
      ('an item with 1 space', ' - Item\n'),
    ]) {
      test('$name is outside the format (criterion 3)', () {
        expect(usesOnlyKnownMarks(text), isFalse);
      });
    }
  });

  group('the files in releases/ (spec 0018 §2.1)', () {
    final releases = _mdFiles('../releases');

    test('releases/<appVersion>.md exists (criterion 2)', () {
      expect(releases.keys, contains('$appVersion.md'));
    });

    for (final MapEntry(:key, :value) in releases.entries) {
      test('$key uses only the format of §3.3 (criterion 3, amendment '
          'criterion 2)', () {
        expect(usesOnlyKnownMarks(value), isTrue);
      });
    }

    test(
      'the copy in assets/releases equals releases/ (plan 0029)',
      () {
        final copy = _mdFiles('assets/releases');
        expect(copy, releases);
      },
      skip: _mdFiles('assets/releases').isEmpty
          ? 'no copy: scripts/copy-notes.ps1 did not run'
          : false,
    );
  });
}
