// lib/features/library/library_screen.dart
import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/state_store.dart';
import '../../core/playlist_service.dart';
import '../../core/path_utils.dart'; // <- for filenameOf
import '../player/player_screen.dart';

class LibraryScreen extends StatefulWidget {
  final StateStore store;
  final PlaylistService playlist;

  const LibraryScreen({super.key, required this.store, required this.playlist});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  AppStateModel get state => widget.store.state;

  Future<void> _openFiles() async {
    final files = await PlaylistService.pickFiles();
    if (files.isEmpty) return;

    widget.playlist.clear();
    widget.playlist.addFiles(files);
    final first = widget.playlist.currentPath!;
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          state: state,
          store: widget.store,
          initialPath: first,
          playlist: widget.playlist,
        ),
      ),
    );
    setState(() {}); // refresh recents when back
  }

  Future<void> _openFolder() async {
    final dir = await PlaylistService.pickFolder();
    if (dir == null) return;

    widget.playlist.clear();
    widget.playlist.addFolder(dir);
    final first = widget.playlist.currentPath;
    if (first == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No videos found')));
      return;
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          state: state,
          store: widget.store,
          initialPath: first,
          playlist: widget.playlist,
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _clearAll() async {
    await widget.store.clearRecents();
    setState(() {});
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final recents = state.recents;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0f1e),
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Clear recents',
            onPressed: recents.isEmpty ? null : _clearAll,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _openFiles,
                  icon: const Icon(Icons.video_file_rounded),
                  label: const Text('Open File(s)'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _openFolder,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Open Folder as Playlist'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: recents.isEmpty
                  ? Center(
                      child: Text(
                        'No recents yet.\nOpen a file or a folder to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: recents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = recents[i];
                        final name = filenameOf(it.path);
                        final pos = Duration(milliseconds: it.lastPositionMs);
                        final dur = Duration(milliseconds: it.durationMs);

                        return Material(
                          color: Colors.white.withValues(alpha: .04),
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .06),
                              ),
                            ),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Last position: ${_fmt(pos)} / ${_fmt(dur)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .75),
                                fontSize: 12,
                              ),
                            ),
                            trailing: FilledButton(
                              onPressed: () async {
                                // keep whatever playlist you had; just open this file
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      state: state,
                                      store: widget.store,
                                      initialPath: it.path,
                                      playlist: widget.playlist,
                                    ),
                                  ),
                                );
                                setState(() {});
                              },
                              child: const Text('Resume'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
