// Issue #60: release.ps1 writes the sample save of the new version before
// its full check, so a test that fails on the new fixture stops the release
// (spec 0007 §8). The test reads the script; it runs nothing.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release.ps1 writes the sample save before the full check', () {
    final script = File('../scripts/release.ps1').readAsStringSync();
    final sample = script.indexOf('dart run tool/sample_save.dart');
    final check = script.indexOf(r'& "$PSScriptRoot\check.ps1"');
    expect(sample, isNot(-1), reason: 'the sample save step');
    expect(check, isNot(-1), reason: 'the full check step');
    expect(sample, lessThan(check), reason: 'the sample save comes first');
  });

  // Spec 0018 §2.2: the check and the friend build see
  // releases/<version>.md, so the rename comes before them, and the copy of
  // the notes (plan 0029) comes after the rename.
  test('release.ps1 renames next.md, then copies the notes, before the full '
      'check', () {
    final script = File('../scripts/release.ps1').readAsStringSync();
    final rename = script.indexOf('Repo mv releases/next.md');
    // The first copy after the rename: Undo, above it, copies again too.
    final copy = script.indexOf('copy-notes.ps1', rename + 1);
    final check = script.indexOf(r'& "$PSScriptRoot\check.ps1"');
    expect(rename, isNot(-1), reason: 'the rename');
    expect(copy, isNot(-1), reason: 'the copy of the notes');
    expect(rename, lessThan(copy), reason: 'the rename comes first');
    expect(copy, lessThan(check), reason: 'the copy comes before the check');
  });

  // check.ps1 leaves out the pacing sims when a change does not touch
  // packages/; a release always runs them.
  test('release.ps1 runs the full check with the pacing sims', () {
    final script = File('../scripts/release.ps1').readAsStringSync();
    expect(script, contains(r'& "$PSScriptRoot\check.ps1" -Pacing'));
  });

  test('the pacing test carries the tag that check.ps1 leaves out', () {
    final pacing = File('../packages/game_core/test/pacing_test.dart')
        .readAsStringSync();
    final check = File('../scripts/check.ps1').readAsStringSync();
    expect(pacing, contains("@Tags(['pacing'])"));
    expect(check, contains('-x pacing'));
  });

  // Plan 0029: the tests and the APK get the notes from the copy.
  for (final name in ['check.ps1', 'test.ps1']) {
    test('$name copies the notes before the tests', () {
      final script = File('../scripts/$name').readAsStringSync();
      final copy = script.indexOf('copy-notes.ps1');
      // The command, not the words "flutter test" in the help text.
      final test = script.indexOf(RegExp(r'flutter test [@-]'));
      expect(copy, isNot(-1), reason: 'the copy of the notes');
      expect(copy, lessThan(test), reason: 'the copy comes first');
    });
  }
}
