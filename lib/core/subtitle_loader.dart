import 'dart:io';

class SrtLine {
  final int startMs;
  final int endMs;
  final String text;
  SrtLine(this.startMs, this.endMs, this.text);
}

class SubtitleLoader {
  static Future<List<SrtLine>> loadSrt(String path) async {
    final lines = await File(path).readAsLines();
    final result = <SrtLine>[];
    int i = 0;

    while (i < lines.length) {
      // skip blanks
      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
      if (i >= lines.length) break;

      i++; // index line

      if (i >= lines.length) break;
      final timing = lines[i].trim();
      i++;

      final parts = timing.split('-->');
      if (parts.length != 2) continue;

      int toMs(String s) {
        final t = s.trim();
        final m = RegExp(r'(\d+):(\d+):(\d+),(\d+)').firstMatch(t);
        if (m == null) return 0;
        final h = int.parse(m.group(1)!);
        final mnt = int.parse(m.group(2)!);
        final sec = int.parse(m.group(3)!);
        final ms = int.parse(m.group(4)!);
        return (((h * 60 + mnt) * 60 + sec) * 1000 + ms);
      }

      final start = toMs(parts[0]);
      final end = toMs(parts[1]);

      final buf = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        buf.add(lines[i]);
        i++;
      }
      result.add(SrtLine(start, end, buf.join('\n')));

      while (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
    }
    return result;
  }

  static SrtLine? activeAt(List<SrtLine> srt, int posMs) {
    for (final l in srt) {
      if (posMs >= l.startMs && posMs <= l.endMs) return l;
    }
    return null;
  }
}
