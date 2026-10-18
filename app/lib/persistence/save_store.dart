import 'dart:convert';
import 'dart:io';

import 'save_data.dart';

/// Where the save lives.
abstract interface class SaveStorage {
  Future<SaveData?> load();
  Future<void> save(SaveData data);
}

/// One JSON save file, replaced atomically: the new save is written and
/// flushed to a temp file, then renamed over the old one. A crash before the
/// rename leaves the previous save intact.
class SaveStore implements SaveStorage {
  SaveStore(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}${Platform.pathSeparator}save.json');
  File get _temp =>
      File('${directory.path}${Platform.pathSeparator}save.json.tmp');

  @override
  Future<SaveData?> load() async {
    if (!await _file.exists()) return null;
    final json = jsonDecode(await _file.readAsString());
    return SaveData.fromJson(json as Map<String, Object?>);
  }

  @override
  Future<void> save(SaveData data) async {
    await directory.create(recursive: true);
    await _temp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await _temp.rename(_file.path);
  }
}

/// In-memory storage for widget tests (no real I/O in fake-async zones).
class MemorySaveStore implements SaveStorage {
  MemorySaveStore([this._json]);

  Map<String, Object?>? _json;

  @override
  Future<SaveData?> load() async =>
      _json == null ? null : SaveData.fromJson(_json!);

  @override
  Future<void> save(SaveData data) async => _json = data.toJson();
}
