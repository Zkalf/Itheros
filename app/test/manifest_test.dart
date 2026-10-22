import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the game stays upright: portrait only', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:screenOrientation="portrait"'));
  });
}
