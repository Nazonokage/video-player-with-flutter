import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_state.dart';

class StateStore {
  AppStateModel state;
  bool recoveredFromCorruption;

  StateStore(this.state, {this.recoveredFromCorruption = false});

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

  Future<void> removeRecent(String path) async {
    // Remove by normalized path to avoid slash / case variations.
    String norm(String s) => s.replaceAll('\\', '/').toLowerCase();

    final filtered = state.recents
        .where((r) => norm(r.path) != norm(path))
        .toList();
    if (filtered.length == state.recents.length) return; // nothing to remove

    state = state.copyWith(recents: filtered);
    await save();
  }
}
