import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class PlaylistModal extends StatefulWidget {
  final List<String> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  final Future<void> Function(List<String> paths) onAddFiles;
  final Future<void> Function(int index)? onRemoveAt;
  final Future<void> Function()? onClearAll;

  const PlaylistModal({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onAddFiles,
    this.onRemoveAt,
    this.onClearAll,
  });

  static const _videoExtensions = <String>[
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
  ];

  @override
  State<PlaylistModal> createState() => _PlaylistModalState();
}

class _PlaylistModalState extends State<PlaylistModal> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  Future<void> _removeAt(int index) async {
    final removed = _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTile(
        removed,
        index,
        animation,
        selected: false,
        isRemoval: true,
      ),
      duration: const Duration(milliseconds: 300),
    );
    if (widget.onRemoveAt != null) {
      await widget.onRemoveAt!(index);
    }
  }

  Future<void> _clearAll() async {
    if (_items.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a2235),
        title: const Text(
          'Clear Playlist?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all videos from the playlist.',
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

    for (int i = _items.length - 1; i >= 0; i--) {
      await Future.delayed(const Duration(milliseconds: 60)); // stagger
      _removeAt(i);
    }
    if (widget.onClearAll != null) await widget.onClearAll!();
  }

  Widget _buildTile(
    String path,
    int index,
    Animation<double> animation, {
    required bool selected,
    required bool isRemoval,
  }) {
    // Only slide when removing; for normal render keep it aligned (no offset).
    final slideEnd = isRemoval ? const Offset(-0.3, 0) : Offset.zero;
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final slide = Tween<Offset>(
      begin: Offset.zero,
      end: slideEnd,
    ).animate(fade);

    final fileName = p.basename(path);
    final dirName = p.dirname(path).replaceAll('\\', '/');

    return SizeTransition(
      sizeFactor: fade,
      child: SlideTransition(
        position: slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Material(
            color: selected
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              onTap: () {
                widget.onSelect(index);
                Navigator.of(context).maybePop();
              },
              leading: Icon(
                selected
                    ? Icons.play_arrow_rounded
                    : Icons.video_library_rounded,
                color: selected ? Colors.lightBlueAccent : Colors.white70,
              ),
              title: Tooltip(
                message: fileName,
                waitDuration: const Duration(milliseconds: 600),
                child: Text(
                  fileName,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              subtitle: dirName.isEmpty
                  ? null
                  : Tooltip(
                      message: dirName,
                      waitDuration: const Duration(milliseconds: 600),
                      child: Text(
                        dirName,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
              trailing: widget.onRemoveAt != null
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      child: IconButton(
                        tooltip: 'Remove from playlist',
                        splashRadius: 20,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => _removeAt(index),
                      ),
                    )
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: const Color(0xFF0f152b),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
              child: Row(
                children: [
                  const Text(
                    'Playlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Add files',
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.custom,
                        allowedExtensions: PlaylistModal._videoExtensions,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final paths = result.files
                            .map((f) => f.path)
                            .whereType<String>()
                            .toList();
                        if (paths.isNotEmpty) {
                          await widget.onAddFiles(paths);
                          setState(() {
                            // append visually to the end with no slide (not a removal)
                            for (final pth in paths) {
                              _items.add(pth);
                              _listKey.currentState?.insertItem(
                                _items.length - 1,
                                duration: const Duration(milliseconds: 180),
                              );
                            }
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    splashRadius: 20,
                  ),
                  IconButton(
                    tooltip: 'Clear all',
                    onPressed: _clearAll,
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                    ),
                    splashRadius: 20,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Playlist items (always visible, aligned)
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyPlaylist()
                  : AnimatedList(
                      key: _listKey,
                      initialItemCount: _items.length,
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      itemBuilder: (context, i, animation) {
                        final path = _items[i];
                        return _buildTile(
                          path,
                          i,
                          animation,
                          selected: i == widget.currentIndex,
                          isRemoval: false, // <- no left shift unless removing
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

class _EmptyPlaylist extends StatelessWidget {
  const _EmptyPlaylist();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Playlist is empty.\nAdd files to start watching.',
        style: TextStyle(color: Colors.white54),
        textAlign: TextAlign.center,
      ),
    );
  }
}
