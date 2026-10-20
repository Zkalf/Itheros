import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/version.dart';

/// Every released version's save must load in this one (spec 0007 §8).
void main() {
  final fixtures =
      Directory('test/fixtures/saves')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('there is at least one sample save', () {
    expect(fixtures, isNotEmpty);
  });

  for (final f in fixtures) {
    final name = f.uri.pathSegments.last;
    test('$name loads with level, XP, bank and items kept', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final raw = json['game'] as Map<String, Object?>;
      final save = SaveData.fromJson(json);
      expect(save.game.xp, raw['xp']);
      expect(save.game.bank, raw['bank']);
      expect(save.game.location, raw['location']);
      expect(save.game.inventory, raw['inventory']);
      expect(save.journal, hasLength((json['journal'] as List).length));
    });
  }

  test('the version shown in the game matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final name = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, name);
  });
}
