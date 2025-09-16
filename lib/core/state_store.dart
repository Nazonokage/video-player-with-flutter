import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'app_state.dart';

class StateStore {
  static const _file = 'app_state.json';
  Future<File> _stateFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_file');
  }

  Future<AppStateModel> load() async {
    try {
      final f = await _stateFile();
      if (!await f.exists()) return AppStateModel.empty();
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return AppStateModel.fromJson(j);
    } catch (_) {
      return AppStateModel.empty();
    }
  }

  Future<void> save(AppStateModel s) async {
    final f = await _stateFile();
    await f.create(recursive: true);
    await f.writeAsString(jsonEncode(s.toJson()));
  }
}
