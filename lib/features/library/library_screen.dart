import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/app_state.dart';
import '../../core/state_store.dart';
import '../../core/playlist_service.dart';
import '../player/player_screen.dart';
import 'recent_tile.dart';

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
    'mp3',
    'aac',
    'flac',
    'wav',
    'ogg',
    'm4a',
  };

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<RecentItem> _items;

  String _norm(String s) => s.replaceAll('\\', '/').toLowerCase();

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.store.state.recents);
  }

  // ---------- Pickers ----------
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
      if (_videoExts.contains(ext)) videoFiles.add(f.path);
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

  // ---------- Open a recent ----------
  Future<void> _openRecent(RecentItem r) async {
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

  // ---------- Remove one with AnimatedList animation ----------
  Future<void> _removeOne(int index) async {
    final removed = _items.removeAt(index);

    // Animate slide-left + fade + collapse height
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedTile(context, removed, animation),
      duration: const Duration(milliseconds: 300),
    );

    // Persist removal
    await widget.store.removeRecent(removed.path);
  }

  // ---------- Clear all with staggered animation ----------
  Future<void> _clearRecents() async {
    if (_items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a2235),
        title: const Text(
          'Clear Recents?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete all your recent items from local storage.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final total = _items.length;
    for (int i = total - 1; i >= 0; i--) {
      await Future.delayed(const Duration(milliseconds: 50)); // staggered
      final removed = _items.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _buildAnimatedTile(context, removed, animation),
        duration: const Duration(milliseconds: 300),
      );
    }
    await widget.store.clearRecents();
  }

  // ---------- Builder used during removal animation ----------
  Widget _buildAnimatedTile(
    BuildContext context,
    RecentItem r,
    Animation<double> anim,
  ) {
    // CSS-like feel from your HTML: translateX(-100%) + fade + collapse
    final slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.25, 0),
    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
    final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);

    return SizeTransition(
      sizeFactor: fade,
      axisAlignment: 1.0,
      child: SlideTransition(
        position: slide,
        child: Opacity(
          opacity: fade.value,
          child: RecentTile(
            item: r,
            onTap: () => _openRecent(r),
            // During the closing animation, we don't want a second dismiss:
            onDismissed: null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0f1e),
      body: SafeArea(
        child: Column(
          children: [
            // Header + actions
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

            // Animated Recents
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyState()
                  : AnimatedList(
                      key: _listKey,
                      initialItemCount: _items.length,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      itemBuilder: (context, index, animation) {
                        final r = _items[index];
                        return SizeTransition(
                          sizeFactor: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                          child: RecentTile(
                            item: r,
                            onTap: () => _openRecent(r),
                            onDismissed: () => _removeOne(index),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.video_collection_rounded,
              size: 56,
              color: Colors.white38,
            ),
            SizedBox(height: 14),
            Text('No recents yet', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
