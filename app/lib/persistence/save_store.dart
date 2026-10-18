import 'dart:convert';
import 'dart:io';

import 'save_data.dart';

/// One JSON save file, replaced atomically: the new save is written and
/// flushed to a temp file, then renamed over the old one. A crash before the
/// rename leaves the previous save intact.
class SaveStore {
  SaveStore(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}${Platform.pathSeparator}save.json');
  File get _temp =>
      File('${directory.path}${Platform.pathSeparator}save.json.tmp');

  Future<SaveData?> load() async {
    if (!await _file.exists()) return null;
    final json = jsonDecode(await _file.readAsString());
    return SaveData.fromJson(json as Map<String, Object?>);
  }

  Future<void> save(SaveData data) async {
    await directory.create(recursive: true);
    await _temp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await _temp.rename(_file.path);
  }
}
