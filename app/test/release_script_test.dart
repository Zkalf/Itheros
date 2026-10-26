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
}
