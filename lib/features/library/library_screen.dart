import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/app_state.dart';
import '../../core/state_store.dart';
import '../../core/playlist_service.dart';
import '../player/player_screen.dart';

class LibraryScreen extends StatefulWidget {
  final AppStateModel state;
  final StateStore store;
  final PlaylistService playlist;

  const LibraryScreen({
    super.key,
    required this.state,
    required this.store,
    required this.playlist,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _videoExts = <String>{
    'mp4',
    'm4v',
    'mov',
    'mkv',
    'webm',
    'avi',
    'wmv',
    'flv',
    'ts',
    'm2ts',
    '3gp',
    // optional audio
    'mp3', 'aac', 'flac', 'wav', 'ogg', 'm4a',
  };

  String _norm(String s) => s.replaceAll('\\', '/').toLowerCase();

  Future<void> _openFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _videoExts.toList(),
    );
    if (result == null || result.files.isEmpty) return;

    final paths = result.files.map((f) => f.path).whereType<String>().toList();
    if (paths.isEmpty) return;

    await widget.playlist.addFiles(paths);

    // If nothing is playing yet, open the first one.
    final first = widget.playlist.currentPath ?? paths.first;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          state: widget.state,
          store: widget.store,
          initialPath: first,
          playlist: widget.playlist,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openFolderPicker() async {
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null || dirPath.isEmpty) return;

    final dir = Directory(dirPath);
    if (!await dir.exists()) return;

    final files = await dir
        .list(recursive: false, followLinks: false)
        .where((e) => e is File)
        .cast<File>()
        .toList();

    final videoFiles = <String>[];
    for (final f in files) {
      final ext = p.extension(f.path).replaceFirst('.', '').toLowerCase();
      if (_videoExts.contains(ext)) {
        videoFiles.add(f.path);
      }
    }

    if (videoFiles.isEmpty) return;

    videoFiles.sort((a, b) => p.basename(a).compareTo(p.basename(b)));
    await widget.playlist.addFiles(videoFiles);

    final first = widget.playlist.currentPath ?? videoFiles.first;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          state: widget.state,
          store: widget.store,
          initialPath: first,
          playlist: widget.playlist,
        ),
      ),
    );
    setState(() {});
  }

  void _openRecent(RecentItem r) async {
    // Ensure recent exists in playlist, add if missing & set index.
    final i = widget.playlist.items.indexWhere(
      (e) => _norm(e) == _norm(r.path),
    );
    if (i == -1) {
      await widget.playlist.addFiles([r.path]);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          state: widget.state,
          store: widget.store,
          initialPath: r.path,
          playlist: widget.playlist,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _clearRecents() async {
    await widget.store.clearRecents();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final recents = widget.store.state.recents;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0f1e),
      body: SafeArea(
        child: Column(
          children: [
            // Header + Quick actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openFilePicker,
                    icon: const Icon(
                      Icons.video_library_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    label: const Text(
                      'Open File(s)',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _openFolderPicker,
                    icon: const Icon(
                      Icons.folder_open_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    label: const Text(
                      'Open Folder',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearRecents,
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    label: const Text(
                      'Clear Recents',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // Recents list
            Expanded(
              child: recents.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      itemCount: recents.length,
                      itemBuilder: (_, i) {
                        final r = recents[i];
                        final name = p.basename(r.path);
                        final pos = Duration(milliseconds: r.lastPositionMs);
                        final dur = Duration(milliseconds: r.durationMs);
                        final ts = _fmtTime(pos);
                        final ds = _fmtTime(dur);

                        return Material(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onTap: () => _openRecent(r),
                            title: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Resume at $ts • Total $ds',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => _openRecent(r),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_collection_rounded,
              size: 56,
              color: Colors.white38,
            ),
            const SizedBox(height: 14),
            const Text(
              'No recents yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use “Open File(s)” to start watching or “Open Folder” to build a playlist from a directory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
