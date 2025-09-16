import 'package:file_picker/file_picker.dart';
import 'path_utils.dart';

class PlaylistService {
  final List<String> _paths = [];
  int _index = 0;

  List<String> get items => List.unmodifiable(_paths);
  int get currentIndex => _index;
  String? get currentPath => _paths.isEmpty ? null : _paths[_index];

  void clear() {
    _paths.clear();
    _index = 0;
  }

  void setIndex(int i) {
    if (i < 0 || i >= _paths.length) return;
    _index = i;
  }

  void addFiles(Iterable<String> paths) {
    final vids = paths.where(isVideoPath);
    _paths.addAll(vids);
    if (_paths.isNotEmpty && _index >= _paths.length) _index = 0;
  }

  void addFolder(String dirPath) {
    final vids = listVideosSync(dirPath).map((e) => e.path);
    addFiles(vids);
  }

  String? next() {
    if (_paths.isEmpty) return null;
    _index = (_index + 1) % _paths.length;
    return currentPath;
  }

  String? previous() {
    if (_paths.isEmpty) return null;
    _index = (_index - 1) < 0 ? _paths.length - 1 : _index - 1;
    return currentPath;
  }

  /// UI helpers

  static Future<List<String>> pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: kVideoExts.map((e) => e.substring(1)).toList(),
    );
    return res?.files.map((e) => e.path).whereType<String>().toList() ?? [];
  }

  static Future<String?> pickFolder() async {
    return FilePicker.platform.getDirectoryPath();
  }
}
