import 'dart:io';
import 'package:path/path.dart' as p;

const kVideoExts = <String>{
  '.mp4',
  '.mkv',
  '.mov',
  '.avi',
  '.webm',
  '.m4v',
  '.wmv',
};

String filenameOf(String path) => p.basename(path);

bool isVideoPath(String path) =>
    kVideoExts.contains(p.extension(path).toLowerCase());

List<FileSystemEntity> listVideosSync(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const [];
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => isVideoPath(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}
