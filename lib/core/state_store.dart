import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_state.dart';

class StateStore {
  AppStateModel _state;
  bool recoveredFromCorruption;
  final _stateController = StreamController<AppStateModel>.broadcast();

  StateStore(this._state, {this.recoveredFromCorruption = false});

  AppStateModel get state => _state;
  Stream<AppStateModel> get stateStream => _stateController.stream;

  void _notifyStateChange() {
    _stateController.add(_state);
  }

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
    try {
      final text = await f.readAsString();
      final model = decodeState(text);
      return StateStore(model);
    } catch (e) {
      // If reading or decoding fails, reset to a safe default & flag recovery.
      final fallback = AppStateModel(
        settings: const AppSettings(),
        recents: const [],
      );
      try {
        await f.writeAsString(encodeState(fallback));
      } catch (_) {
        // Ignore secondary errors; we'll still return the fallback in-memory state.
      }
      return StateStore(fallback, recoveredFromCorruption: true);
    }
  }

  Future<void> save() async {
    final f = await _file();
    await f.writeAsString(encodeState(_state));
    _notifyStateChange();
  }

  void updateState(AppStateModel newState) {
    _state = newState;
    _notifyStateChange();
  }

  Future<void> upsertRecent({
    required String path,
    required int positionMs,
    required int durationMs,
  }) async {
    _state = _state.upsertRecent(
      path: path,
      positionMs: positionMs,
      durationMs: durationMs,
    );
    await save();
  }

  Future<void> clearRecents() async {
    _state = _state.clearRecents();
    await save();
  }

  Future<void> removeRecent(String path) async {
    // Remove by normalized path to avoid slash / case variations.
    String norm(String s) => s.replaceAll('\\', '/').toLowerCase();

    final filtered = _state.recents
        .where((r) => norm(r.path) != norm(path))
        .toList();
    if (filtered.length == _state.recents.length) return; // nothing to remove

    _state = _state.copyWith(recents: filtered);
    await save();
  }

  void dispose() {
    _stateController.close();
  }
}
