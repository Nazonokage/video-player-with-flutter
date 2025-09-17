// lib/core/playlist_service.dart (sketch)
class PlaylistService {
  final List<String> items = [];
  int currentIndex = -1;

  String? get currentPath => (currentIndex >= 0 && currentIndex < items.length)
      ? items[currentIndex]
      : null;

  void setIndex(int i) => currentIndex = i;

  Future<void> addFiles(List<String> paths) async {
    for (final p in paths) {
      if (!items.contains(p)) items.add(p);
    }
    if (currentIndex < 0 && items.isNotEmpty) currentIndex = 0;
  }

  Future<void> removeAt(int i) async {
    if (i >= 0 && i < items.length) {
      final removingCurrent = i == currentIndex;
      items.removeAt(i);
      if (items.isEmpty) {
        currentIndex = -1;
      } else if (removingCurrent) {
        currentIndex = i.clamp(0, items.length - 1);
      } else if (i < currentIndex) {
        currentIndex -= 1;
      }
    }
  }

  Future<void> clear() async {
    items.clear();
    currentIndex = -1;
  }

  String? next() {
    if (items.isEmpty || currentIndex < 0) return null;
    if (currentIndex + 1 >= items.length) return null;
    currentIndex += 1;
    return items[currentIndex];
  }

  String? previous() {
    if (items.isEmpty || currentIndex <= 0) return null;
    currentIndex -= 1;
    return items[currentIndex];
  }
}
