import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_state.dart';

class StateStore {
  AppStateModel state;

  StateStore(this.state);

  static const _fileName = 'app_state.json';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final f = File(p.join(dir.path, _fileName));
    if (!await f.exists()) {
      await f.create(recursive: true);
      await f.writeAsString(
        encodeState(
          AppStateModel(settings: const AppSettings(), recents: const []),
        ),
      );
    }
    return f;
  }

  static Future<StateStore> load() async {
    final f = await _file();
    final text = await f.readAsString();
    final model = decodeState(text);
    return StateStore(model);
  }

  Future<void> save() async {
    final f = await _file();
    await f.writeAsString(encodeState(state));
  }

  Future<void> upsertRecent({
    required String path,
    required int positionMs,
    required int durationMs,
  }) async {
    state = state.upsertRecent(
      path: path,
      positionMs: positionMs,
      durationMs: durationMs,
    );
    await save();
  }

  Future<void> clearRecents() async {
    state = state.clearRecents();
    await save();
  }
}
