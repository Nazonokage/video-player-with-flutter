import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class PlaylistModal extends StatelessWidget {
  final List<String> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Called when user picks files from the system file picker.
  /// Implement this to add paths into your PlaylistService (e.g., addFiles(paths)).
  final Future<void> Function(List<String> paths) onAddFiles;

  /// Optional: remove a single item at index.
  final Future<void> Function(int index)? onRemoveAt;

  /// Optional: clear the entire playlist.
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
    // common containers
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
    // audio w/ cover (some users add these too)
    'mp3', 'aac', 'flac', 'wav', 'ogg', 'm4a',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: const Color(0xFF0f152b),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title + actions
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
                  Tooltip(
                    message: 'Add files',
                    child: IconButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.custom,
                          allowedExtensions: _videoExtensions,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final paths = result.files
                              .map((f) => f.path)
                              .whereType<String>()
                              .toList();
                          if (paths.isNotEmpty) {
                            await onAddFiles(paths);
                            // Stay open so user can keep adding/selecting
                            (context as Element).markNeedsBuild();
                          }
                        }
                      },
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      splashRadius: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Clear all',
                    child: IconButton(
                      onPressed: onClearAll == null
                          ? null
                          : () async {
                              await onClearAll!.call();
                              (context as Element).markNeedsBuild();
                            },
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.white,
                      ),
                      splashRadius: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
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

            // List
            Expanded(
              child: items.isEmpty
                  ? const _EmptyPlaylist()
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        itemBuilder: (_, i) {
                          final path = items[i];
                          final selected = i == currentIndex;

                          return Material(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                onSelect(i);
                                Navigator.of(context).maybePop();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.play_arrow_rounded
                                          : Icons.video_collection_rounded,
                                      color: selected
                                          ? Colors.lightBlueAccent
                                          : Colors.white70,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        path,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (onRemoveAt != null)
                                      IconButton(
                                        tooltip: 'Remove',
                                        onPressed: () async {
                                          await onRemoveAt!.call(i);
                                          (context as Element).markNeedsBuild();
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white54,
                                          size: 18,
                                        ),
                                        splashRadius: 18,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemCount: items.length,
                      ),
                    ),
            ),

            // Footer hint
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Text(
                'Tip: you can add multiple files. Use the Playlist button in the top bar to reopen this.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.playlist_play_rounded,
              size: 52,
              color: Colors.white38,
            ),
            const SizedBox(height: 12),
            Text(
              'No videos yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Click “Add files” to build a playlist without leaving the player.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
          ],
        ),
      ),
    );
  }
}
